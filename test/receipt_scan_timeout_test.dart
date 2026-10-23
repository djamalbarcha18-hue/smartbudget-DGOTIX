import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_glass.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/domain/plan.dart';
import 'package:smartbudget/features/receipts/application/receipt_scan_controller.dart';
import 'package:smartbudget/features/receipts/data/gemini_online_engine.dart';
import 'package:smartbudget/features/receipts/domain/invoice_analyzer.dart';
import 'package:smartbudget/features/receipts/domain/receipt_ocr_engine.dart';
import 'package:smartbudget/features/receipts/domain/scanned_receipt.dart';
import 'package:smartbudget/features/receipts/presentation/invoice_review_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

final ReceiptImage photo = ReceiptImage(
    bytes: Uint8List.fromList(<int>[1, 2, 3]), mimeType: 'image/jpeg');

/// A reading as the device's own reader returns it.
Map<String, dynamic> deviceReading() => <String, dynamic>{
      'src': 'device',
      'r': true,
      'dt': '2026-10-01',
      'cur': 'USD',
      'sup': 'Shop',
      'it': <Map<String, dynamic>>[],
      'tot': '9.50',
    };

Future<ReceiptScanError?> errorOf(Future<Object?> f) async {
  try {
    await f;
    return null;
  } on ReceiptScanException catch (e) {
    return e.code;
  }
}

class _PickOne extends ImagePicker {
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async =>
      XFile.fromData(Uint8List.fromList(<int>[9, 9, 9, 9]),
          name: 'r.jpg', mimeType: 'image/jpeg');
}

class _Engine implements ReceiptOcrEngine {
  _Engine(this.run, {this.isAvailable = true});
  final Future<ScannedReceipt> Function() run;
  @override
  final bool isAvailable;
  @override
  Future<ScannedReceipt> recognize(ReceiptImage image) => run();
}

ScannedReceipt fromDevice() => ScannedReceipt(
      merchantName: '',
      date: null,
      totalAmount: 0,
      currency: '',
      category: '',
      confidence: 0,
      fromCloud: false,
      raw: deviceReading(),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('cloud reading', () {
    test('a reading that never comes back gives up as "no connection"',
        () async {
      final GeminiOnlineEngine engine = GeminiOnlineEngine(
        timeout: const Duration(milliseconds: 50),
        invoke: (_) => Completer<FunctionResponse>().future,
      );
      expect(await errorOf(engine.recognize(photo)), ReceiptScanError.network);
    });

    test('the app waits 45 s for a reading', () {
      expect(GeminiOnlineEngine.defaultTimeout, const Duration(seconds: 45));
    });

    test('the server giving up on the model reads as "no connection"',
        () async {
      final GeminiOnlineEngine engine = GeminiOnlineEngine(
        invoke: (_) async => throw const FunctionException(
            status: 504, details: <String, dynamic>{'error': 'timeout'}),
      );
      expect(await errorOf(engine.recognize(photo)), ReceiptScanError.network);
    });

    test("the plan's scans used up asks to upgrade; the day's cap says later",
        () async {
      GeminiOnlineEngine answering(Map<String, dynamic> details) =>
          GeminiOnlineEngine(
            invoke: (_) async =>
                throw FunctionException(status: 429, details: details),
          );
      expect(
          await errorOf(answering(<String, dynamic>{'error': 'quota_exceeded'})
              .recognize(photo)),
          ReceiptScanError.quotaExceeded);
      expect(
          await errorOf(answering(<String, dynamic>{
            'error': 'quota_exceeded',
            'scope': 'daily'
          }).recognize(photo)),
          ReceiptScanError.rateLimited);
    });
  });

  test('FREE: 3 cloud scans a month', () {
    final Quota q = FeatureCatalog.quotaFor(Feature.cloudOcr, Plan.free)!;
    expect(q.limit, 3);
    expect(q.window, QuotaWindow.monthly);
  });

  group('scans used up on a phone', () {
    ProviderContainer scanner(ReceiptOcrEngine online,
            {bool offlineAvailable = true}) =>
        ProviderContainer(overrides: <Override>[
          receiptScanEnabledProvider.overrideWithValue(true),
          onlineReceiptEngineProvider.overrideWithValue(online),
          offlineReceiptEngineProvider.overrideWithValue(
              _Engine(() async => fromDevice(), isAvailable: offlineAvailable)),
          receiptScannerProvider.overrideWith(
              (Ref ref) => ReceiptScanner(ref, picker: _PickOne())),
        ]);

    test('the receipt is read on the device, and the upgrade is offered',
        () async {
      final ProviderContainer c = scanner(_Engine(() async =>
          throw const ReceiptScanException(ReceiptScanError.quotaExceeded)));
      addTearDown(c.dispose);
      final ScannedReceipt r = await c
          .read(receiptScannerProvider)
          .scan(source: ImageSource.gallery);
      expect(r.fromCloud, isFalse);
      expect(r.cloudQuotaReached, isTrue);
      expect(r.invoice?.total, 9.5);
    });

    test('no connection: read on the device, no upgrade offer', () async {
      final ProviderContainer c = scanner(_Engine(() async =>
          throw const ReceiptScanException(ReceiptScanError.network)));
      addTearDown(c.dispose);
      final ScannedReceipt r = await c
          .read(receiptScannerProvider)
          .scan(source: ImageSource.gallery);
      expect(r.fromCloud, isFalse);
      expect(r.cloudQuotaReached, isFalse);
    });

    test('without a device reader (web) the upgrade message is shown',
        () async {
      final ProviderContainer c = scanner(
          _Engine(() async =>
              throw const ReceiptScanException(ReceiptScanError.quotaExceeded)),
          offlineAvailable: false);
      addTearDown(c.dispose);
      expect(
          await errorOf(
              c.read(receiptScannerProvider).scan(source: ImageSource.gallery)),
          ReceiptScanError.quotaExceeded);
    });
  });

  testWidgets('the review says the cloud scans are used up, with Upgrade',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    bool upgraded = false;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
        DsColors.dark,
        DsGlass.dark
      ]),
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => InvoiceReviewSheet.show(
              context,
              reading: InvoiceAnalyzer.analyze(deviceReading(),
                  today: DateTime(2026, 10, 2)),
              timings: const ScanTimings(),
              offline: true,
              cloudQuotaReached: true,
              onUpgrade: () => upgraded = true,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final AppLocalizations l =
        await AppLocalizations.delegate.load(const Locale('ar'));
    expect(find.text(l.invoiceCloudQuotaUsed), findsOneWidget);
    // Instead of the plain "read offline" notice.
    expect(find.text(l.invoiceReadOffline), findsNothing);

    await tester.tap(find.text(l.aiUpgrade));
    await tester.pumpAndSettle();
    expect(upgraded, isTrue);
    expect(find.text(l.invoiceCloudQuotaUsed), findsNothing);
  });
}
