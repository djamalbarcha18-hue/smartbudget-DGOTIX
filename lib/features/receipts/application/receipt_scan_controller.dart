
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/receipts/data/gemini_online_engine.dart';
import 'package:smartbudget/features/receipts/data/offline_ocr_engine.dart';
import 'package:smartbudget/features/receipts/data/receipt_image_native.dart';
import 'package:smartbudget/features/receipts/data/receipt_image_prep.dart';
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
  /// print legible while sending far less than a full camera image. The
  /// height allows long receipts, which are then read in strips.
  static const double maxWidth = 1280;
  static const double maxHeight = 4096;
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
    if (known != null) {
      return _check(
          known,
          hash,
          ScanTimings(prepare: sw.elapsedMilliseconds, fromCache: true),
          onStage);
    }

    // Crop, gray, faded print, strips: by the browser's own engine on the
    // web, in a background isolate on mobile. Anything unsure: as photographed.
    final PreparedReceipt prepared = await _prepare(bytes);
    final bool changed = !identical(prepared.parts.first, bytes);
    final ReceiptImage image = ReceiptImage(
      bytes: prepared.parts.first,
      parts: prepared.parts.length > 1 ? prepared.parts : const <Uint8List>[],
      mimeType: changed ? 'image/jpeg' : _mimeFor(file),
    );
    final int prepare = sw.elapsedMilliseconds;
    onStage?.call(ScanStage.reading);
    sw
      ..reset()
      ..start();
    final ScannedReceipt read = await _recognize(image);
    final int reading = sw.elapsedMilliseconds;
    final Map<String, dynamic>? raw = read.raw;
    if (raw == null) return read; // older scanner: total only

    // Only cloud readings are remembered: an offline one is read again by
    // the cloud next time.
    final bool offline = raw['src'] == 'device';
    if (!offline) await cache.store(hash, raw);
    return _check(
      raw,
      hash,
      ScanTimings(
        prepare: prepare,
        reading: reading,
        model: read.timings.model,
        originalBytes: prepared.originalBytes,
        sentBytes: prepared.sentBytes,
        parts: prepared.parts.length,
      ),
      onStage,
      fromCloud: !offline,
    );
  }

  static Future<PreparedReceipt> _prepare(Uint8List bytes) async {
    try {
      if (kIsWeb) {
        return await prepareWithPlatform(bytes) ??
            PreparedReceipt(parts: <Uint8List>[bytes], originalBytes: bytes.length);
      }
      return await compute(prepareReceiptInBackground, bytes);
    } catch (_) {
      return PreparedReceipt(parts: <Uint8List>[bytes], originalBytes: bytes.length);
    }
  }

  ScannedReceipt _check(
    Map<String, dynamic> raw,
    String hash,
    ScanTimings timings,
    void Function(ScanStage stage)? onStage, {
    bool fromCloud = true,
  }) {
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
      fromCloud: fromCloud,
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
      // Read on the device when the cloud can't: no connection, the plan's
      // cloud scans used up, or the service down.
      if (const <ReceiptScanError>{
        ReceiptScanError.network,
        ReceiptScanError.quotaExceeded,
        ReceiptScanError.rateLimited,
        ReceiptScanError.backendUnavailable,
      }.contains(e.code)) {
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
