import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';

/// The signed-in user's round picture.
///
/// Shows the Google account picture when there is one. The device loads it
/// straight from Google: it never passes through, or is stored on, our
/// backend. Without a picture, while it loads, or if it cannot be loaded
/// (offline, removed by its owner), a circle with the name's first letter is
/// drawn on the device instead.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 17,
  });

  final String? name;
  final String? imageUrl;
  final double radius;

  /// First letter of [name], upper-cased; empty when there is no name.
  static String initialOf(String? name) {
    final String trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return '';
    return trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final String initial = initialOf(name);
    final double size = radius * 2;

    final Widget fallback = Center(
      child: initial.isEmpty
          ? Icon(Icons.person_outline_rounded, size: radius + 1, color: c.brand)
          : Text(
              initial,
              style: TextStyle(
                color: c.brand,
                fontSize: radius * 0.95,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
    );

    final String? url = imageUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: c.brand.withValues(alpha: 0.18),
      child: url == null
          ? fallback
          : ClipOval(
              child: SizedBox(
                width: size,
                height: size,
                child: Image.network(
                  url,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  excludeFromSemantics: true,
                  frameBuilder: (BuildContext context, Widget child,
                          int? frame, bool wasSynchronouslyLoaded) =>
                      wasSynchronouslyLoaded || frame != null
                          ? child
                          : fallback,
                  errorBuilder: (BuildContext context, Object error,
                          StackTrace? stackTrace) =>
                      fallback,
                ),
              ),
            ),
    );
  }
}
