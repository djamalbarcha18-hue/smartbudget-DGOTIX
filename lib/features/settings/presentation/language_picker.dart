import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/l10n/app_lang.dart';
import 'package:smartbudget/core/l10n/language_names.dart';
import 'package:smartbudget/core/localization/locale_controller.dart';
import 'package:smartbudget/design_system/tokens/ds_breakpoints.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// The language picker: a bottom sheet on phones, a dialog on wider screens.
/// Each language shows its own name and, under it, its name in the current
/// language; a search field appears once the list is long. Picking one
/// switches through [LanguageSwitch], with a way back in the old language.
abstract final class LanguagePicker {
  /// Past this many languages the list gets a search field.
  static const int searchFrom = 9;

  static Future<void> show(BuildContext context) async {
    final AppLang? picked = context.isMobile
        ? await showModalBottomSheet<AppLang>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const _LanguageSheet(),
          )
        : await showDialog<AppLang>(
            context: context,
            builder: (_) => Dialog(
              insetPadding: const EdgeInsets.all(DsSpacing.xl),
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 440, maxHeight: 640),
                child: const _LanguageSheet(dialog: true),
              ),
            ),
          );
    if (picked != null && context.mounted) {
      await LanguageSwitch.to(context, picked);
    }
  }
}

/// Changes the app language smoothly: the screen fades to the page colour,
/// the language (and text direction) changes underneath, and it fades back.
/// A short notice then offers the way back, named in the previous language,
/// for a reader who picked one they can't read.
abstract final class LanguageSwitch {
  static final ValueNotifier<bool> _curtain = ValueNotifier<bool>(false);
  static const Duration fadeIn = Duration(milliseconds: 140);
  static const Duration fadeOut = Duration(milliseconds: 260);

  static Future<void> to(BuildContext context, AppLang lang,
      {bool offerUndo = true}) async {
    final ProviderContainer ref = ProviderScope.containerOf(context);
    final AppLang from =
        AppLang.fromCode(ref.read(localeProvider).languageCode);
    if (from == lang) return;
    final ScaffoldMessengerState? messenger =
        ScaffoldMessenger.maybeOf(context);
    final bool still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (!still) {
      _curtain.value = true;
      await Future<void>.delayed(fadeIn);
    }
    await ref.read(localeProvider.notifier).set(Locale(lang.code));
    if (!still) {
      await SchedulerBinding.instance.endOfFrame;
      _curtain.value = false;
    }

    if (!offerUndo || messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        content: Row(
          children: <Widget>[
            const Icon(Icons.check_circle_rounded,
                size: 18, color: Colors.white),
            const SizedBox(width: DsSpacing.sm),
            Flexible(child: Text(lang.nativeName)),
          ],
        ),
        action: SnackBarAction(
          label: '↩ ${from.nativeName}',
          onPressed: () =>
              ref.read(localeProvider.notifier).set(Locale(from.code)),
        ),
      ));
  }
}

/// Wraps the app (MaterialApp.builder) with the curtain [LanguageSwitch]
/// fades in and out.
class LanguageSwitchCurtain extends StatelessWidget {
  const LanguageSwitchCurtain({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Color bg = context.dsColors.bgPage;
    return Stack(
      children: <Widget>[
        child,
        Positioned.fill(
          child: ValueListenableBuilder<bool>(
            valueListenable: LanguageSwitch._curtain,
            builder: (BuildContext context, bool on, _) => IgnorePointer(
              ignoring: !on,
              child: AnimatedOpacity(
                opacity: on ? 1 : 0,
                duration: on ? LanguageSwitch.fadeIn : LanguageSwitch.fadeOut,
                curve: Curves.easeOut,
                child: ColoredBox(color: bg),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A field showing the current language that opens [LanguagePicker]
/// (Settings).
class LanguagePickerField extends ConsumerWidget {
  const LanguagePickerField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final AppLang lang =
        AppLang.fromCode(ref.watch(localeProvider).languageCode);
    final Widget field = Material(
      color: c.surfaceMuted,
      borderRadius: DsRadius.brMd,
      child: InkWell(
        borderRadius: DsRadius.brMd,
        onTap: () => LanguagePicker.show(context),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.md, vertical: DsSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: DsRadius.brMd,
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: <Widget>[
              _CodeBadge(lang: lang, selected: true),
              const SizedBox(width: DsSpacing.md),
              Expanded(
                child: Text(lang.nativeName,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Icon(Icons.unfold_more_rounded, size: 20, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
    // Not the full width of a wide Settings card.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420), child: field),
    );
  }
}

class _LanguageSheet extends ConsumerStatefulWidget {
  const _LanguageSheet({this.dialog = false});

  final bool dialog;

  @override
  ConsumerState<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends ConsumerState<_LanguageSheet> {
  static const double _rowHeight = 64;
  final TextEditingController _query = TextEditingController();
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    final String current = ref.read(localeProvider).languageCode;
    final int i = AppLang.offered.indexWhere((AppLang l) => l.code == current);
    // Opens with the current language in view.
    _scroll =
        ScrollController(initialScrollOffset: i > 3 ? (i - 2) * _rowHeight : 0);
  }

  @override
  void dispose() {
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<AppLang> _matches(AppLang ui) {
    final String q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return AppLang.offered;
    return <AppLang>[
      for (final AppLang l in AppLang.offered)
        if (<String>[
          l.code,
          l.nativeName,
          LanguageNames.of(l, inLang: ui),
          LanguageNames.of(l, inLang: AppLang.en),
        ].any((String s) => s.toLowerCase().contains(q)))
          l,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final AppLocalizations l = AppLocalizations.of(context);
    final AppLang ui = AppLang.fromCode(ref.watch(localeProvider).languageCode);
    final List<AppLang> shown = _matches(ui);
    final bool searchable = AppLang.offered.length >= LanguagePicker.searchFrom;

    // With search, the sheet keeps its height while the list narrows, so it
    // doesn't jump under the finger; it sits above the keyboard.
    final double room = MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      height: searchable ? (widget.dialog ? 640 : room * 0.85) : null,
      margin: EdgeInsets.only(
          bottom: widget.dialog ? 0 : MediaQuery.viewInsetsOf(context).bottom),
      constraints: BoxConstraints(maxHeight: room * 0.85),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: widget.dialog
            ? DsRadius.brXl
            : const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: c.border),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (!widget.dialog)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: DsSpacing.sm),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: c.borderStrong, borderRadius: DsRadius.brPill),
                ),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                  DsSpacing.xl, DsSpacing.md, DsSpacing.sm, DsSpacing.xs),
              child: Row(
                children: <Widget>[
                  Icon(Icons.translate_rounded, color: c.brand),
                  const SizedBox(width: DsSpacing.sm),
                  Expanded(
                    child: Text(l.settingsLanguage,
                        style: t.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    icon: Icon(Icons.close_rounded, color: c.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            if (searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    DsSpacing.lg, 0, DsSpacing.lg, DsSpacing.sm),
                child: TextField(
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText:
                        MaterialLocalizations.of(context).searchFieldLabel,
                    prefixIcon: Icon(Icons.search_rounded,
                        size: 20, color: c.textMuted),
                    suffixIcon: _query.text.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(Icons.close_rounded,
                                size: 18, color: c.textMuted),
                            onPressed: () => setState(() => _query.clear()),
                          ),
                    filled: true,
                    fillColor: c.surfaceMuted,
                    border: OutlineInputBorder(
                        borderRadius: DsRadius.brMd,
                        borderSide: BorderSide(color: c.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: DsRadius.brMd,
                        borderSide: BorderSide(color: c.border)),
                  ),
                ),
              ),
            Flexible(
              child: shown.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(DsSpacing.xl),
                      child: Text(l.searchNoResults,
                          textAlign: TextAlign.center,
                          style: t.bodyMedium?.copyWith(color: c.textMuted)),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(
                          DsSpacing.sm, 0, DsSpacing.sm, DsSpacing.md),
                      itemExtent: _rowHeight,
                      itemCount: shown.length,
                      itemBuilder: (BuildContext context, int i) =>
                          _LanguageRow(
                        lang: shown[i],
                        ui: ui,
                        selected: shown[i] == ui,
                        onTap: () => Navigator.of(context).pop(shown[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.lang,
    required this.ui,
    required this.selected,
    required this.onTap,
  });

  final AppLang lang;
  final AppLang ui;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final String local = LanguageNames.of(lang, inLang: ui);
    final bool showLocal = local.toLowerCase() != lang.nativeName.toLowerCase();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? c.brand.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: DsRadius.brMd,
        child: InkWell(
          borderRadius: DsRadius.brMd,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
            child: Row(
              children: <Widget>[
                _CodeBadge(lang: lang, selected: selected),
                const SizedBox(width: DsSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(lang.nativeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleSmall?.copyWith(
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w600,
                              color: selected ? c.brand : c.textPrimary)),
                      if (showLocal)
                        Text(local,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall?.copyWith(color: c.textMuted)),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(Icons.check_circle_rounded,
                      size: 22, color: c.brand),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The language's code in a small round badge (flags would be wrong: Arabic,
/// English or Spanish belong to many countries).
class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.lang, required this.selected});

  final AppLang lang;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? c.brand : c.brand.withValues(alpha: 0.10),
      ),
      child: Text(
        lang.code.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: selected ? c.onBrand : c.brand),
      ),
    );
  }
}
