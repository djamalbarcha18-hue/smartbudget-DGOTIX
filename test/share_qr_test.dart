import 'package:flutter_test/flutter_test.dart';

import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/features/share/domain/share_qr.dart';

void main() {
  group('ShareQr.appUrl', () {
    test('drops the in-app route and keeps the base folder', () {
      expect(
        ShareQr.appUrl(
            current: Uri.parse(
                'https://djamalbarcha18-hue.github.io/smartbudget-DGOTIX/#/settings')),
        'https://djamalbarcha18-hue.github.io/smartbudget-DGOTIX/',
      );
    });

    test('keeps a non-default port and drops query and file name', () {
      expect(ShareQr.appUrl(current: Uri.parse('http://localhost:8080/#/plans')),
          'http://localhost:8080/');
      expect(
          ShareQr.appUrl(
              current: Uri.parse('https://example.com/app/index.html?x=1')),
          'https://example.com/app/');
    });

    test('falls back to the known deployment when there is no web address',
        () {
      expect(ShareQr.appUrl(current: Uri.parse('file:///tmp/test')),
          AppConfig.fallbackUrl);
    });
  });

  group('ShareQr.svg', () {
    final String svg = ShareQr.svg('https://example.com/');

    test('is a standalone SVG with a white background', () {
      expect(svg, startsWith('<svg xmlns="http://www.w3.org/2000/svg"'));
      expect(svg, endsWith('</svg>'));
      expect(svg, contains('fill="#ffffff"'));
    });

    test('draws dark modules with portable markup', () {
      expect(svg, contains('<path d="M '));
      expect(svg, contains('fill="#000000"'));
      expect(svg, isNot(contains('style=')));
      expect(svg, isNot(contains('<text')));
    });

    test('is deterministic and depends on the data', () {
      expect(ShareQr.svg('https://example.com/'), svg);
      expect(ShareQr.svg('https://example.org/'), isNot(svg));
    });

    test('size controls the canvas, including the quiet zone', () {
      final String big = ShareQr.svg('https://example.com/', size: 1024);
      // 1024 + 2 × 1024/5 = 1433.6 → 1434
      expect(big, contains('viewBox="0 0 1434 1434"'));
    });
  });
}
