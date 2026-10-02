import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/receipts/data/gemini_online_engine.dart';
import 'package:smartbudget/features/receipts/data/offline_ocr_engine.dart';
import 'package:smartbudget/features/receipts/data/receipt_scan_cache.dart';
import 'package:smartbudget/features/receipts/domain/invoice_analyzer.dart';
import 'package:smartbudget/features/receipts/domain/invoice_duplicates.dart';
import 'package:smartbudget/features/receipts/domain/invoice_reading.dart';
import 'package:smartbudget/features/receipts/domain/receipt_ocr_engine.dart';
import 'package:smartbudget/features/receipts/domain/scanned_receipt.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

final onlineReceiptEngineProvider =
    Provider<ReceiptOcrEngine>((ref) => const GeminiOnlineEngine());

final offlineReceiptEngineProvider =
    Provider<ReceiptOcrEngine>((ref) => const OfflineOcrEngine());

/// True when the cloud scanner CAN run: a real backend is configured and a user
/// is signed in (the scan itself uses DGOTIX's server key and the plan quota).
final receiptScanEnabledProvider = Provider<bool>((ref) {
  return AppEnv.hasSupabase &&
      ref.watch(authControllerProvider).isAuthenticated;
});

final receiptScannerProvider =
    Provider<ReceiptScanner>((ref) => ReceiptScanner(ref));

/// What the user sees while a scan runs.
enum ScanStage { preparing, reading, checking }

/// Orchestrates: capture → memory → one cloud reading → checks on the device.
class ReceiptScanner {
  ReceiptScanner(this._ref, {ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final Ref _ref;
  final ImagePicker _picker;

  /// Receipts need sharp text, not big photos: 1280 px across keeps small
  /// print legible while sending far less than a full camera image (the
  /// height allows long receipts).
  static const double maxWidth = 1280;
  static const double maxHeight = 2560;
  static const int jpegQuality = 80;

  ReceiptScanCache get _cache => ReceiptScanCache(
      _ref.read(authControllerProvider).user?.id ?? 'guest');

  Future<ScannedReceipt> scan({
    required ImageSource source,
    void Function(ScanStage stage)? onStage,
  }) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: jpegQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    if (file == null) {
      throw const ReceiptScanException(ReceiptScanError.cancelled);
    }

    onStage?.call(ScanStage.preparing);
    final Stopwatch sw = Stopwatch()..start();
    final Uint8List bytes = await file.readAsBytes();
    final String hash = sha256.convert(bytes).toString();
    final ReceiptScanCache cache = _cache;
    final Map<String, dynamic>? known = await cache.lookup(hash);
    final int prepare = sw.elapsedMilliseconds;
    if (known != null) {
      return _check(known, hash,
          ScanTimings(prepare: prepare, fromCache: true), onStage);
    }

    final ReceiptImage image =
        ReceiptImage(bytes: bytes, mimeType: _mimeFor(file));
    onStage?.call(ScanStage.reading);
    sw
      ..reset()
      ..start();
    final ScannedReceipt read = await _recognize(image);
    final int reading = sw.elapsedMilliseconds;
    final Map<String, dynamic>? raw = read.raw;
    if (raw == null) return read; // older scanner: total only

    await cache.store(hash, raw);
    return _check(
      raw,
      hash,
      ScanTimings(prepare: prepare, reading: reading, model: read.timings.model),
      onStage,
    );
  }

  ScannedReceipt _check(
    Map<String, dynamic> raw,
    String hash,
    ScanTimings timings,
    void Function(ScanStage stage)? onStage,
  ) {
    onStage?.call(ScanStage.checking);
    final Stopwatch sw = Stopwatch()..start();
    final InvoiceReading reading = InvoiceAnalyzer.analyze(
      raw,
      today: AppClock.now(),
      knownCategories: Catalog.expenseCategories.toSet(),
    );
    return ScannedReceipt.fromInvoice(
      reading,
      raw: raw,
      timings: timings.copyWith(checks: sw.elapsedMilliseconds),
      imageHash: hash,
    );
  }

  Future<ScannedReceipt> _recognize(ReceiptImage image) async {
    final bool online = _ref.read(receiptScanEnabledProvider);
    if (!online) {
      final ReceiptOcrEngine offline = _ref.read(offlineReceiptEngineProvider);
      if (offline.isAvailable) return offline.recognize(image);
      throw ReceiptScanException(
        AppEnv.hasSupabase
            ? ReceiptScanError.notSignedIn
            : ReceiptScanError.backendUnavailable,
      );
    }
    try {
      return await _ref.read(onlineReceiptEngineProvider).recognize(image);
    } on ReceiptScanException catch (e) {
      // Fall back to on-device OCR only when the cloud is unreachable.
      if (e.code == ReceiptScanError.network) {
        final ReceiptOcrEngine offline =
            _ref.read(offlineReceiptEngineProvider);
        if (offline.isAvailable) return offline.recognize(image);
      }
      rethrow;
    }
  }

  /// "This invoice may be a duplicate": an invoice added before, or an
  /// expense already recorded that day for the same amount.
  Future<bool> isLikelyDuplicate(ScannedReceipt r) async {
    final InvoiceReading? reading = r.invoice;
    if (reading == null) return false;
    final DateTime today = AppClock.now();
    final List<InvoiceFingerprint> previous = <InvoiceFingerprint>[
      for (final Map<String, dynamic> raw
          in await _cache.added(exceptHash: r.imageHash))
        InvoiceFingerprint.of(InvoiceAnalyzer.analyze(raw, today: today)),
    ];
    final List<Transaction> txns =
        _ref.read(transactionsProvider).valueOrNull ?? const <Transaction>[];
    return InvoiceDuplicates.isLikelyDuplicate(
      reading,
      previous: previous,
      expenses: <RecordedExpense>[
        for (final Transaction t in txns)
          if (t.isExpense)
            RecordedExpense(
              date: t.date,
              amount: t.amount.asDouble,
              currency: t.amount.currencyCode,
              description: t.description,
            ),
      ],
    );
  }

  /// The user went on to add this invoice as an expense.
  Future<void> markAdded(ScannedReceipt r) async {
    if (r.imageHash != null) await _cache.markAdded(r.imageHash!);
  }

  String _mimeFor(XFile file) {
    final String? m = file.mimeType;
    if (m != null && m.isNotEmpty) return m;
    final String name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
