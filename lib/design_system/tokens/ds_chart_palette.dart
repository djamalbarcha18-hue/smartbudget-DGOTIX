import 'package:flutter/painting.dart';

/// A qualitative (categorical) palette for distribution charts.
///
/// Hues are spaced for separability and vary in luminance so adjacent segments
/// stay distinct in both light and dark themes (and are reasonably
/// colorblind-tolerant). Assign by index, wrapping with `%`.
abstract final class DsChartPalette {
  static const List<Color> categorical = <Color>[
    Color(0xFF3B82F6), // blue
    Color(0xFFF59E0B), // amber
    Color(0xFF10B981), // emerald
    Color(0xFF8B5CF6), // violet
    Color(0xFFEF4444), // red
    Color(0xFF14B8A6), // teal
    Color(0xFFEC4899), // pink
    Color(0xFF84CC16), // lime
    Color(0xFF6366F1), // indigo
    Color(0xFF64748B), // slate (used for the aggregated "Other")
  ];

  static Color at(int i) => categorical[i % categorical.length];

  /// Neutral color reserved for the aggregated "Other" slice.
  static const Color other = Color(0xFF64748B);
}
