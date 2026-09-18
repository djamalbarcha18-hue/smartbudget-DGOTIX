import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/receipts/data/gemini_key_service.dart';
import 'package:smartbudget/features/receipts/data/gemini_online_engine.dart';
import 'package:smartbudget/features/receipts/data/offline_ocr_engine.dart';
import 'package:smartbudget/features/receipts/domain/receipt_ocr_engine.dart';
import 'package:smartbudget/features/receipts/domain/scanned_receipt.dart';

final geminiKeyServiceProvider =
    Provider<GeminiKeyService>((ref) => const GeminiKeyService());

final onlineReceiptEngineProvider =
    Provider<ReceiptOcrEngine>((ref) => const GeminiOnlineEngine());

final offlineReceiptEngineProvider =
    Provider<ReceiptOcrEngine>((ref) => const OfflineOcrEngine());

/// True when the cloud scanner CAN run: a real backend is configured and a user
/// is signed in. (Whether the user has set a key is checked at scan time.)
final receiptScanEnabledProvider = Provider<bool>((ref) {
  return AppEnv.hasSupabase &&
      ref.watch(authControllerProvider).isAuthenticated;
});

/// Whether the signed-in user has stored a Gemini key.
final geminiKeyStatusProvider = FutureProvider<bool>((ref) async {
  if (!ref.watch(receiptScanEnabledProvider)) return false;
  return ref.watch(geminiKeyServiceProvider).hasKey();
});

final receiptScannerProvider =
    Provider<ReceiptScanner>((ref) => ReceiptScanner(ref));

/// Orchestrates: capture → connectivity/engine selection → recognize.
class ReceiptScanner {
  ReceiptScanner(this._ref, {ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final Ref _ref;
  final ImagePicker _picker;

  Future<ScannedReceipt> scan({required ImageSource source}) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (file == null) {
      throw const ReceiptScanException(ReceiptScanError.cancelled);
    }
    final Uint8List bytes = await file.readAsBytes();
    final ReceiptImage image =
        ReceiptImage(bytes: bytes, mimeType: _mimeFor(file));

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
