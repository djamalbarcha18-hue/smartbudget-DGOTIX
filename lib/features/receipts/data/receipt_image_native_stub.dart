import 'dart:typed_data';

import 'package:smartbudget/features/receipts/data/receipt_image_prep.dart';

/// No native path here: null, the caller prepares the photo in Dart.
Future<PreparedReceipt?> prepareWithPlatform(Uint8List bytes) async => null;
