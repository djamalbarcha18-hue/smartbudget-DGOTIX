import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smartbudget/features/receipts/domain/receipt_ocr_engine.dart';
import 'package:smartbudget/features/receipts/domain/scanned_receipt.dart';

/// Cloud OCR via the `receipt-scan` Supabase Edge Function (Gemini Flash).
///
/// The image never goes to Google directly; it is proxied through the function.
/// DGOTIX is the only AI provider: the function scans with DGOTIX's server key
/// and meters every scan against the plan's cloud-OCR quota (users never bring
/// their own key). Only ever used when Supabase is configured AND a user is
/// signed in (the controller checks).
class GeminiOnlineEngine implements ReceiptOcrEngine {
  const GeminiOnlineEngine();

  @override
  bool get isAvailable => true;

  @override
  Future<ScannedReceipt> recognize(ReceiptImage image) async {
    final SupabaseClient client = Supabase.instance.client;
    final String b64 = base64Encode(image.bytes);

    late final FunctionResponse res;
    try {
      res = await client.functions.invoke(
        'receipt-scan',
        body: <String, dynamic>{
          'imageBase64': b64,
          'mimeType': image.mimeType,
        },
      );
    } on FunctionException catch (e) {
      throw _mapFunctionException(e);
    } catch (_) {
      throw const ReceiptScanException(ReceiptScanError.network);
    }

    final Object? data = res.data;
    if (data is! Map) {
      throw const ReceiptScanException(ReceiptScanError.providerError);
    }
    final Map<String, dynamic> map = data.cast<String, dynamic>();

    if (map['ok'] == true) {
      return ScannedReceipt.fromCloudJson(map);
    }
    final String? reason = map['reason']?.toString();
    if (reason == 'unreadable') {
      throw const ReceiptScanException(ReceiptScanError.unreadable);
    }
    if (reason == 'no_total') {
      throw const ReceiptScanException(ReceiptScanError.noTotal);
    }
    throw ReceiptScanException(_codeFromError(map['error']?.toString()));
  }

  ReceiptScanException _mapFunctionException(FunctionException e) {
    String? err;
    final Object? details = e.details;
    if (details is Map) {
      err = details['error']?.toString();
    }
    return ReceiptScanException(_codeFromError(err), status: e.status);
  }

  ReceiptScanError _codeFromError(String? err) {
    switch (err) {
      case 'ocr_unavailable':
        return ReceiptScanError.backendUnavailable;
      case 'rate_limited':
        return ReceiptScanError.rateLimited;
      case 'quota_exceeded':
        return ReceiptScanError.quotaExceeded;
      case 'missing_token':
      case 'invalid_token':
        return ReceiptScanError.notSignedIn;
      case 'no_image':
      case 'provider_error':
      case 'empty_response':
      case 'bad_json':
        return ReceiptScanError.providerError;
      default:
        return ReceiptScanError.unknown;
    }
  }
}
