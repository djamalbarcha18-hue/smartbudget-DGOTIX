import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/billing/domain/feature_catalog.dart';
import 'package:smartbudget/features/billing/presentation/upgrade_prompt.dart';
import 'package:smartbudget/features/daret/application/daret_controller.dart';
import 'package:smartbudget/features/daret/application/daret_import.dart';
import 'package:smartbudget/features/daret/domain/daret.dart';
import 'package:smartbudget/features/daret/domain/daret_link.dart';
import 'package:smartbudget/features/daret/presentation/daret_schedule.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// A daret someone shared, offered to the member who opened the link: they
/// say which name is theirs and get their own copy to track.
class DaretImportSheet extends ConsumerStatefulWidget {
  const DaretImportSheet({super.key, required this.shared});

  final SharedDaret shared;

  static Future<void> show(BuildContext context, SharedDaret shared) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DaretImportSheet(shared: shared),
      );

  @override
  ConsumerState<DaretImportSheet> createState() => _DaretImportSheetState();
}

class _DaretImportSheetState extends ConsumerState<DaretImportSheet> {
  int? _me;
  bool _saving = false;

  Future<void> _skip() async {
    await DaretPending.clear();
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _add() async {
    final int? me = _me;
    if (me == null || _saving) return;
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);
    // The same limit on how many darets as adding one by hand. Refused: the
    // offer stays for later (an upgrade, or a daret that ends). The size of
    // the circle is not checked: joining one is free whatever its size, the
    // limit on members is for whoever builds it.
    if (!PlanLimits.allowAdd(
        context,
        Feature.darets,
        (ProviderContainer c) =>
            c.read(daretsProvider).valueOrNull?.length ?? 0)) {
      return;
    }
    setState(() => _saving = true);
    final Daret mine = widget.shared.toDaret(
        id: DaretActions.newId(), meIndex: me, createdAt: AppClock.now());
    await ref.read(daretActionsProvider).save(mine);
    await DaretPending.clear();
    navigator.maybePop();
    messenger.showSnackBar(SnackBar(
        content: Text(l.daretImportDone(daretYmd(DaretMath.myTurn(mine))))));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final SharedDaret s = widget.shared;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          color: c.bgElevated,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(DsSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(l.daretImportTitle,
                style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(l.daretImportWho,
                style: t.bodyMedium?.copyWith(color: c.textMuted)),
            const SizedBox(height: DsSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: DaretScheduleCard(
                  name: s.name,
                  contribution: s.contribution,
                  frequency: s.frequency,
                  start: s.start,
                  members: s.members,
                  selected: _me,
                  onSelect: (int i) => setState(() => _me = i),
                ),
              ),
            ),
            const SizedBox(height: DsSpacing.md),
            DsButton(
              key: const ValueKey<String>('daret-import-add'),
              expand: true,
              label: l.daretImportAdd,
              icon: Icons.add_rounded,
              onPressed: _me == null || _saving ? null : _add,
            ),
            const SizedBox(height: DsSpacing.xs),
            TextButton(
              key: const ValueKey<String>('daret-import-skip'),
              onPressed: _saving ? null : _skip,
              child: Text(l.daretImportSkip),
            ),
          ],
        ),
      ),
    );
  }
}

/// Offers a daret that arrived by link, once the signed-in app is on screen.
/// Sits in the app shell, so it waits for sign-in and the lock.
class DaretImportListener extends ConsumerStatefulWidget {
  const DaretImportListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DaretImportListener> createState() =>
      _DaretImportListenerState();
}

class _DaretImportListenerState extends ConsumerState<DaretImportListener> {
  static bool _offeredThisRun = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    if (_offeredThisRun) return;
    final SharedDaret? shared = await DaretPending.read();
    if (!mounted || shared == null) return;
    List<Daret> mine;
    try {
      mine = await ref.read(daretsProvider.future);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    // Their own link, or one opened before: already here.
    if (mine.any(shared.sameScheduleAs)) {
      await DaretPending.clear();
      return;
    }
    _offeredThisRun = true;
    await DaretImportSheet.show(context, shared);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
