import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/design_system/components/ds_skeleton.dart';
import 'package:smartbudget/design_system/components/ds_states.dart';
import 'package:smartbudget/features/sync/application/data_loading.dart';
import 'package:smartbudget/features/sync/application/sync_controller.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// [DsSkeleton] with the app's words: «loading» for screen readers and,
/// after a long wait, «taking longer than usual» with «try again». Trying
/// again runs [onRetry], or a sync round when there is none.
class PageSkeleton extends ConsumerWidget {
  const PageSkeleton({super.key, required this.child, this.onRetry});

  final Widget child;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    return DsSkeleton(
      semanticsLabel: l.loadingLabel,
      slowMessage: l.loadingSlow,
      retryLabel: l.loadRetry,
      onRetry: onRetry ??
          () => ref.read(syncControllerProvider.notifier).syncNow(),
      child: child,
    );
  }
}

/// A load that failed: a plain message (never the raw error) and «try again».
class PageLoadError extends StatelessWidget {
  const PageLoadError({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return DsError(
        message: l.loadFailed, onRetry: onRetry, retryLabel: l.loadRetry);
  }
}

/// The body of a page that lists [T]s: what is on the device shows at once;
/// [skeleton] stands in while it is still on its way (see [awaitingData]);
/// a failed load says so with «try again».
class AsyncListBody<T> extends ConsumerWidget {
  const AsyncListBody({
    super.key,
    required this.value,
    required this.skeleton,
    required this.data,
    required this.onRetry,
  });

  final AsyncValue<List<T>> value;
  final Widget skeleton;
  final Widget Function(List<T> items) data;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (value.hasError && !value.hasValue) {
      return PageLoadError(onRetry: onRetry);
    }
    if (awaitingData(value,
        cloudPending: ref.watch(firstCloudCopyPendingProvider))) {
      return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: PageSkeleton(child: skeleton),
      );
    }
    return data(value.requireValue);
  }
}
