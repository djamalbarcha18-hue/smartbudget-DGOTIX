import 'dart:ui';

import 'package:flutter/material.dart';

/// Glassmorphism tokens — premium and restrained: translucent surfaces over an
/// ambient backdrop (see `DsBackdrop`), a light blur, hairline borders, a soft
/// top highlight and depth from shadows rather than neon glow.
///
/// Consumed by [GlassCard], the shell panels and any surface that wants the
/// frosted look, so the whole app shares one glass language.
@immutable
class DsGlass extends ThemeExtension<DsGlass> {
  const DsGlass({
    required this.blurSigma,
    required this.fill,
    required this.fillTop,
    required this.fillStrong,
    required this.borderColor,
    required this.hoverBorder,
    required this.highlight,
    required this.glow,
    required this.shadow,
    required this.hoverShadow,
  });

  /// Backdrop blur strength (kept moderate — readability first).
  final double blurSigma;

  /// Translucent fill at the bottom of a glass surface.
  final Color fill;

  /// Slightly lighter fill at the top-start of the surface's gradient.
  final Color fillTop;

  /// A denser glass for structural panels (sidebar, top bar) and overlays.
  final Color fillStrong;

  /// Hairline border.
  final Color borderColor;

  /// Border of a hovered / focused interactive surface.
  final Color hoverBorder;

  /// Inner top highlight that sells the "glass edge".
  final Color highlight;

  /// Soft accent glow (used sparingly: active nav item, focused surfaces).
  final Color glow;

  /// Ambient shadow at rest, and when lifted on hover.
  final List<BoxShadow> shadow;
  final List<BoxShadow> hoverShadow;

  ImageFilter get blur => ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma);

  static const DsGlass dark = DsGlass(
    blurSigma: 18,
    fill: Color(0x8C0A1B2B), // deep navy @ 55%
    fillTop: Color(0x8C15334A), // lifted teal-navy @ 55%
    fillStrong: Color(0xCC081626),
    borderColor: Color(0x24B9E6F2), // cool white @ 14%
    hoverBorder: Color(0x662DD4BF), // teal @ 40%
    highlight: Color(0x33FFFFFF),
    glow: Color(0x262DD4BF),
    shadow: <BoxShadow>[
      BoxShadow(color: Color(0x59000000), blurRadius: 30, offset: Offset(0, 16)),
    ],
    hoverShadow: <BoxShadow>[
      BoxShadow(color: Color(0x73000000), blurRadius: 36, offset: Offset(0, 20)),
      BoxShadow(color: Color(0x1A2DD4BF), blurRadius: 24),
    ],
  );

  static const DsGlass light = DsGlass(
    blurSigma: 16,
    fill: Color(0xB3FFFFFF), // white @ 70%
    fillTop: Color(0xE6FFFFFF),
    fillStrong: Color(0xD9FFFFFF),
    borderColor: Color(0x1F0F2A3D),
    hoverBorder: Color(0x660D9488),
    highlight: Color(0xE6FFFFFF),
    glow: Color(0x1A0D9488),
    shadow: <BoxShadow>[
      BoxShadow(color: Color(0x140F2A3D), blurRadius: 24, offset: Offset(0, 12)),
    ],
    hoverShadow: <BoxShadow>[
      BoxShadow(color: Color(0x240F2A3D), blurRadius: 30, offset: Offset(0, 16)),
    ],
  );

  @override
  DsGlass copyWith({
    double? blurSigma,
    Color? fill,
    Color? fillTop,
    Color? fillStrong,
    Color? borderColor,
    Color? hoverBorder,
    Color? highlight,
    Color? glow,
    List<BoxShadow>? shadow,
    List<BoxShadow>? hoverShadow,
  }) {
    return DsGlass(
      blurSigma: blurSigma ?? this.blurSigma,
      fill: fill ?? this.fill,
      fillTop: fillTop ?? this.fillTop,
      fillStrong: fillStrong ?? this.fillStrong,
      borderColor: borderColor ?? this.borderColor,
      hoverBorder: hoverBorder ?? this.hoverBorder,
      highlight: highlight ?? this.highlight,
      glow: glow ?? this.glow,
      shadow: shadow ?? this.shadow,
      hoverShadow: hoverShadow ?? this.hoverShadow,
    );
  }

  @override
  DsGlass lerp(covariant DsGlass? other, double t) {
    if (other == null) return this;
    return DsGlass(
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t) ?? blurSigma,
      fill: Color.lerp(fill, other.fill, t)!,
      fillTop: Color.lerp(fillTop, other.fillTop, t)!,
      fillStrong: Color.lerp(fillStrong, other.fillStrong, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      hoverBorder: Color.lerp(hoverBorder, other.hoverBorder, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      shadow: BoxShadow.lerpList(shadow, other.shadow, t) ?? shadow,
      hoverShadow:
          BoxShadow.lerpList(hoverShadow, other.hoverShadow, t) ?? hoverShadow,
    );
  }
}

extension DsGlassX on BuildContext {
  DsGlass get dsGlass => Theme.of(this).extension<DsGlass>()!;
}
