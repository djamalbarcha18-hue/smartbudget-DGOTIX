/// "Share SmartBudget": the public link to the platform and a QR code for it.
///
/// Pure Dart (no Flutter) so it is unit-testable. The QR is produced as a
/// self-contained SVG: vector, so it stays sharp at any print size.
library;

import 'package:barcode/barcode.dart';

import 'package:smartbudget/core/config/app_config.dart';

abstract final class ShareQr {
  /// The link the QR code opens.
  ///
  /// Uses [AppConfig.publicUrl] when set (e.g. a custom domain). Otherwise it
  /// is the address the app is currently served from, minus any in-app route,
  /// so it keeps working if the site moves. Falls back to the known deployment
  /// when there is no web address (tests, non-web builds).
  static String appUrl({Uri? current}) {
    if (AppConfig.publicUrl.trim().isNotEmpty) return AppConfig.publicUrl.trim();
    final Uri base = current ?? Uri.base;
    if (base.scheme == 'http' || base.scheme == 'https') {
      String path = base.path;
      if (!path.endsWith('/')) {
        // Drop a trailing file name (e.g. index.html) but keep the base dir.
        final int slash = path.lastIndexOf('/');
        path = slash >= 0 ? path.substring(0, slash + 1) : '/';
      }
      return Uri(
        scheme: base.scheme,
        host: base.host,
        port: base.hasPort ? base.port : null,
        path: path,
      ).toString();
    }
    return AppConfig.fallbackUrl;
  }

  /// A QR code for [data] as a standalone SVG: dark modules on white, with the
  /// 4-module quiet zone scanners need, so it reads on any background (dark
  /// mode, coloured flyers). High error correction tolerates print wear.
  static String svg(String data, {double size = 512}) {
    final Barcode qr = Barcode.qrCode(
        errorCorrectLevel: BarcodeQRCorrectionLevel.high);
    // The standard quiet zone is 4 modules on each side. The smallest QR
    // symbol is 21 modules wide, so size/5 (> 4/21 of the width) guarantees
    // at least 4 modules for every symbol size; larger symbols get more.
    final double margin = size / 5;
    final double total = size + margin * 2;
    String body = qr.toSvg(
      data,
      x: margin,
      y: margin,
      width: size,
      height: size,
      drawText: false,
      fullSvg: false,
    );
    // Portable markup: a plain fill attribute and no empty text element.
    body = body
        .replaceAllMapped(RegExp(r'style="fill: (#[0-9a-fA-F]{6})"'),
            (Match m) => 'fill="${m[1]}"')
        .replaceAll(RegExp(r'<text[^>]*>\s*</text>'), '');
    final String t = total.toStringAsFixed(0);
    return '<svg xmlns="http://www.w3.org/2000/svg" '
        'width="$t" height="$t" viewBox="0 0 $t $t">'
        '<rect width="$t" height="$t" fill="#ffffff"/>'
        '$body'
        '</svg>';
  }
}
