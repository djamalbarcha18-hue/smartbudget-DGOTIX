import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/auth/application/auth_controller.dart';
import 'package:smartbudget/features/auth/presentation/auth_helpers.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// «or» and «Continue with Google», under the e-mail form of the sign-in and
/// sign-up pages. Nothing at all while Google sign-in is off.
class GoogleSignInSection extends ConsumerStatefulWidget {
  const GoogleSignInSection({super.key});

  @override
  ConsumerState<GoogleSignInSection> createState() =>
      _GoogleSignInSectionState();
}

class _GoogleSignInSectionState extends ConsumerState<GoogleSignInSection> {
  bool _opening = false;

  Future<void> _go() async {
    if (_opening) return;
    final AppLocalizations l = AppLocalizations.of(context);
    setState(() => _opening = true);
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
      // The router follows once the session arrives.
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authFailureMessage(error, l))));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(googleSignInEnabledProvider)) return const SizedBox.shrink();
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: DsSpacing.lg),
        Row(
          children: <Widget>[
            Expanded(child: Divider(color: c.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
              child: Text(l.authOr,
                  style: t.labelMedium?.copyWith(color: c.textMuted)),
            ),
            Expanded(child: Divider(color: c.border)),
          ],
        ),
        const SizedBox(height: DsSpacing.lg),
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: _opening ? null : _go,
            style: OutlinedButton.styleFrom(
              backgroundColor: c.surface,
              foregroundColor: c.textPrimary,
              side: BorderSide(color: c.border),
              shape: const RoundedRectangleBorder(borderRadius: DsRadius.brMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (_opening)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CustomPaint(painter: _GoogleG()),
                  ),
                const SizedBox(width: DsSpacing.md),
                Flexible(
                  child: Text(l.authContinueGoogle,
                      overflow: TextOverflow.ellipsis,
                      style:
                          t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Google's four-colour «G».
class _GoogleG extends CustomPainter {
  const _GoogleG();

  static const Color _blue = Color(0xFF4285F4);
  static const Color _green = Color(0xFF34A853);
  static const Color _yellow = Color(0xFFFBBC05);
  static const Color _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final double stroke = s * 0.2;
    final Rect r = Rect.fromCircle(
        center: size.center(Offset.zero), radius: (s - stroke) / 2);
    Paint arc(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    double deg(double d) => d * math.pi / 180;
    // Angles clockwise from 3 o'clock; the opening is on the right.
    canvas.drawArc(r, deg(-40), deg(-90), false, arc(_red));
    canvas.drawArc(r, deg(-130), deg(-95), false, arc(_yellow));
    canvas.drawArc(r, deg(135), deg(-95), false, arc(_green));
    canvas.drawArc(r, deg(45), deg(-45), false, arc(_blue));
    // The bar of the G.
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2, size.height / 2 - stroke / 2,
          r.right - size.width / 2 + stroke / 2, stroke),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(_GoogleG old) => false;
}
