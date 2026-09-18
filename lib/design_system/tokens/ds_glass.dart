import 'dart:ui';

import 'package:flutter/material.dart';

/// Glassmorphism tokens — **moderate & premium** (per brand direction):
/// semi-transparent cards, light blur, fine borders, soft shadows, subtle
/// gradient. No neon / gaming excess.
///
/// Consumed by [GlassCard] and any surface that wants the frosted look.
@immutable
class DsGlass extends ThemeExtension<DsGlass> {
  const DsGlass({
    required this.blurSigma,
    required this.fill,
    required this.fillTop,
    required this.borderColor,
    required this.highlight,
    required this.shadow,
  });

  /// Backdrop blur strength (kept light — 12–18 is the tasteful range).
  final double blurSigma;

  /// Base translucent fill of the card.
  final Color fill;

  /// Slightly lighter fill for the top of the subtle vertical gradient.
  final Color fillTop;

  /// Hairline border.
  final Color borderColor;

  /// Inner top highlight (1px) that sells the "glass edge".
  final Color highlight;

  /// Soft ambient shadow.
  final List<BoxShadow> shadow;

  ImageFilter get blur => ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma);

  static const DsGlass dark = DsGlass(
    blurSigma: 16,
    fill: Color(0x991E293B), // slate-800 @ 60%
    fillTop: Color(0xB32A3A54),
    borderColor: Color(0x1FFFFFFF),
    highlight: Color(0x24FFFFFF),
    shadow: [
      BoxShadow(color: Color(0x59000000), blurRadius: 28, offset: Offset(0, 14)),
    ],
  );

  static const DsGlass light = DsGlass(
    blurSigma: 14,
    fill: Color(0xCCFFFFFF), // white @ 80%
    fillTop: Color(0xF2FFFFFF),
    borderColor: Color(0x14000000),
    highlight: Color(0x99FFFFFF),
    shadow: [
      BoxShadow(color: Color(0x140F172A), blurRadius: 24, offset: Offset(0, 12)),
    ],
  );

  @override
  DsGlass copyWith({
    double? blurSigma,
    Color? fill,
    Color? fillTop,
    Color? borderColor,
    Color? highlight,
    List<BoxShadow>? shadow,
  }) {
    return DsGlass(
      blurSigma: blurSigma ?? this.blurSigma,
      fill: fill ?? this.fill,
      fillTop: fillTop ?? this.fillTop,
      borderColor: borderColor ?? this.borderColor,
      highlight: highlight ?? this.highlight,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  DsGlass lerp(covariant DsGlass? other, double t) {
    if (other == null) return this;
    return DsGlass(
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t) ?? blurSigma,
      fill: Color.lerp(fill, other.fill, t)!,
      fillTop: Color.lerp(fillTop, other.fillTop, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      shadow: BoxShadow.lerpList(shadow, other.shadow, t) ?? shadow,
    );
  }
}

extension DsGlassX on BuildContext {
  DsGlass get dsGlass => Theme.of(this).extension<DsGlass>()!;
}
