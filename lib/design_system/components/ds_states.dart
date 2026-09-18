import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';

/// Consistent loading state.
class DsLoading extends StatelessWidget {
  const DsLoading({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.6, color: c.brand),
          ),
          if (message != null) ...<Widget>[
            const SizedBox(height: DsSpacing.md),
            Text(message!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Consistent empty state (used wherever no SmartBudget data is available yet —
/// preferred over fabricating placeholder numbers).
class DsEmpty extends StatelessWidget {
  const DsEmpty({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 40, color: c.textFaint),
            const SizedBox(height: DsSpacing.md),
            Text(title, style: t.titleMedium, textAlign: TextAlign.center),
            if (message != null) ...<Widget>[
              const SizedBox(height: DsSpacing.xs),
              Text(
                message!,
                style: t.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...<Widget>[
              const SizedBox(height: DsSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Consistent error state.
class DsError extends StatelessWidget {
  const DsError({super.key, required this.message, this.onRetry, this.retryLabel});
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline_rounded, size: 40, color: c.expense),
            const SizedBox(height: DsSpacing.md),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: DsSpacing.lg),
              TextButton(
                onPressed: onRetry,
                child: Text(retryLabel ?? 'Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
