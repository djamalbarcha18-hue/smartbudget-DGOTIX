import 'package:flutter/material.dart';

import 'package:smartbudget/core/l10n/app_lang_context.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/trips/domain/destination.dart';
import 'package:smartbudget/features/trips/presentation/trip_text.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// "Where to?": search the suggested places in any language, pick one of the
/// user's past places or a popular one, or keep any typed text.
class DestinationPicker extends StatefulWidget {
  const DestinationPicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.catalog,
    this.past = const <String>[],
    this.errorText,
  });

  /// The chosen place as text, or null.
  final String? value;
  final ValueChanged<String?> onChanged;
  final DestinationCatalog catalog;

  /// Places of the user's earlier trips, most recent first.
  final List<String> past;
  final String? errorText;

  @override
  State<DestinationPicker> createState() => _DestinationPickerState();
}

class _DestinationPickerState extends State<DestinationPicker> {
  final TextEditingController _query = TextEditingController();
  bool _all = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _pick(String text) {
    _query.clear();
    widget.onChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final AppLang lang = appLangOf(context);
    final DestinationCatalog catalog = widget.catalog;
    final String? value = widget.value;

    final Widget label =
        Text(l.tripWhere, style: t.labelMedium?.copyWith(color: c.textMuted));

    if (value != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          label,
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(
                DsSpacing.sm, DsSpacing.sm, DsSpacing.xs, DsSpacing.sm),
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              borderRadius: DsRadius.brMd,
              border: Border.all(color: c.brand.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: <Widget>[
                DestinationAvatar(destination: catalog.byText(value)),
                const SizedBox(width: DsSpacing.md),
                Expanded(
                  child: Text(catalog.display(value, lang),
                      style:
                          t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  tooltip: l.tripChangePlace,
                  icon: Icon(Icons.edit_location_alt_outlined,
                      color: c.textMuted),
                  onPressed: () => widget.onChanged(null),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final String q = _query.text;
    final String nq = PlaceText.normalize(q);
    final List<Widget> body = <Widget>[];

    if (nq.isEmpty) {
      if (widget.past.isNotEmpty) {
        body
          ..add(_SubLabel(l.tripFromYourTrips))
          ..add(_Chips(<Widget>[
            for (final String p in widget.past)
              _PlaceChip(
                destination: catalog.byText(p),
                label: catalog.display(p, lang),
                onTap: () => _pick(p),
              ),
          ]));
      }
      final List<Destination> shown = _all ? catalog.all : catalog.popular();
      body
        ..add(_SubLabel(l.tripPopular))
        ..add(_Chips(<Widget>[
          for (final Destination d in shown)
            _PlaceChip(
              destination: d,
              label: d.nameFor(lang),
              onTap: () => _pick(d.nameFor(lang)),
            ),
        ]));
      if (catalog.all.length > 6) {
        body.add(Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            icon: Icon(
                _all ? Icons.expand_less_rounded : Icons.expand_more_rounded),
            label:
                Text(_all ? l.tripShowLess : l.tripShowAll(catalog.all.length)),
            onPressed: () => setState(() => _all = !_all),
          ),
        ));
      }
    } else {
      // The user's own typed places first, then the suggested ones.
      final List<String> pastTyped = <String>[
        for (final String p in widget.past)
          if (catalog.byText(p) == null &&
              PlaceText.matchRank(PlaceText.normalize(p), nq) != null)
            p,
      ];
      final List<Destination> found = catalog.search(q).take(8).toList();
      final bool exact = catalog.byText(q) != null ||
          pastTyped.any((String p) => PlaceText.normalize(p) == nq);
      body.add(const SizedBox(height: DsSpacing.xs));
      for (final String p in pastTyped) {
        body.add(_ResultRow(
          leading: const DestinationAvatar(size: 32),
          title: p,
          trailing: Icon(Icons.history_rounded, size: 16, color: c.textFaint),
          onTap: () => _pick(p),
        ));
      }
      for (final Destination d in found) {
        body.add(_ResultRow(
          leading: DestinationAvatar(destination: d, size: 32),
          title: d.nameFor(lang),
          onTap: () => _pick(d.nameFor(lang)),
        ));
      }
      if (!exact) {
        final String typed = PlaceText.clean(q);
        body.add(_ResultRow(
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              borderRadius: DsRadius.brMd,
              border: Border.all(color: c.border),
            ),
            child:
                Icon(Icons.add_location_alt_outlined, size: 18, color: c.brand),
          ),
          title: l.tripUseText(typed),
          onTap: () => _pick(typed),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        label,
        const SizedBox(height: 6),
        TextField(
          controller: _query,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          onSubmitted: (String v) {
            final Destination? d = catalog.byText(v);
            if (d != null) {
              _pick(d.nameFor(lang));
            } else if (PlaceText.normalize(v).isNotEmpty) {
              _pick(PlaceText.clean(v));
            }
          },
          decoration: InputDecoration(
            hintText: l.tripWhereHint,
            errorText: widget.errorText,
            prefixIcon: Icon(Icons.search_rounded, color: c.textMuted),
          ),
        ),
        ...body,
      ],
    );
  }
}

class _SubLabel extends StatelessWidget {
  const _SubLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
          top: DsSpacing.md, bottom: DsSpacing.sm),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: c.textFaint, fontWeight: FontWeight.w700)),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips(this.children);
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: DsSpacing.sm,
        runSpacing: DsSpacing.sm,
        children: children,
      );
}

class _PlaceChip extends StatelessWidget {
  const _PlaceChip(
      {required this.destination, required this.label, required this.onTap});
  final Destination? destination;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: DestinationAvatar(destination: destination, size: 22),
        label: Text(label),
        onPressed: onTap,
      );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.leading,
    required this.title,
    required this.onTap,
    this.trailing,
  });
  final Widget leading;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: DsRadius.brMd,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
            horizontal: DsSpacing.xs, vertical: DsSpacing.sm),
        child: Row(
          children: <Widget>[
            leading,
            const SizedBox(width: DsSpacing.md),
            Expanded(
                child:
                    Text(title, style: Theme.of(context).textTheme.bodyMedium)),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
