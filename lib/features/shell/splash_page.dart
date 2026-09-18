import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/brand/dgotix_brand_lockup.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';

/// Shown while the auth state is still resolving (status == unknown), so a
/// returning user never sees a flash of the login screen.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Scaffold(
      backgroundColor: c.bgPage,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const DgotixBrandLockup(logoHeight: 40, showTagline: true),
            const SizedBox(height: DsSpacing.xxl),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: c.brand),
            ),
          ],
        ),
      ),
    );
  }
}
