import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smartbudget/features/receipts/domain/receipt_ocr_engine.dart';

/// Manages the signed-in user's own Gemini key via the `save-gemini-key`
/// Edge Function (BYOK). The plaintext key leaves the device once, on [save];
/// afterwards only its presence can be queried.
class GeminiKeyService {
  const GeminiKeyService();

  Future<bool> hasKey() async {
    final Map<String, dynamic> res = await _invoke(<String, dynamic>{
      'action': 'status',
    });
    return res['hasKey'] == true;
  }

  Future<void> save(String apiKey) async {
    final Map<String, dynamic> res = await _invoke(<String, dynamic>{
      'action': 'save',
      'apiKey': apiKey.trim(),
    });
    if (res['ok'] != true) {
      throw const ReceiptScanException(ReceiptScanError.invalidKey);
    }
  }

  Future<void> remove() async {
    await _invoke(<String, dynamic>{'action': 'delete'});
  }

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    try {
      final FunctionResponse res = await Supabase.instance.client.functions
          .invoke('save-gemini-key', body: body);
      final Object? data = res.data;
      return data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};
    } on FunctionException catch (e) {
      final Object? details = e.details;
      final String? err =
          details is Map ? details['error']?.toString() : null;
      if (err == 'invalid_key') {
        throw const ReceiptScanException(ReceiptScanError.invalidKey);
      }
      if (err == 'missing_token' || err == 'invalid_token') {
        throw const ReceiptScanException(ReceiptScanError.notSignedIn);
      }
      throw ReceiptScanException(ReceiptScanError.unknown, status: e.status);
    } catch (_) {
      throw const ReceiptScanException(ReceiptScanError.network);
    }
  }
}
