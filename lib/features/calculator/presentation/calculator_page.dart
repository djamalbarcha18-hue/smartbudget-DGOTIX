import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/number_style.dart';
import 'package:smartbudget/core/settings/number_style_controller.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/calculator/domain/calculator_engine.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// A light calculator for everyday sums: on the device, nothing stored, no
/// currency imposed. Only the display listens to the state; the keys are
/// built once.
class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final ValueNotifier<CalcState> _state =
      ValueNotifier<CalcState>(CalcState.initial);
  final FocusNode _focus = FocusNode(debugLabel: 'calculator');

  @override
  void dispose() {
    _state.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _press(CalcState Function(CalcState) key) {
    HapticFeedback.selectionClick();
    _state.value = key(_state.value);
  }

  /// A physical keyboard, when there is one: digits, + - * / x, % . , = and
  /// Enter, Backspace, Delete and Escape.
  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final LogicalKeyboardKey k = e.logicalKey;
    CalcState Function(CalcState)? action;
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      action = Calculator.equals;
    } else if (k == LogicalKeyboardKey.backspace) {
      action = Calculator.backspace;
    } else if (k == LogicalKeyboardKey.escape || k == LogicalKeyboardKey.delete) {
      action = Calculator.clear;
    } else {
      final String? ch = e.character;
      if (ch != null && ch.length == 1) {
        final int? d = int.tryParse(ch);
        action = d != null
            ? (CalcState s) => Calculator.digit(s, d)
            : switch (ch) {
                '+' => (CalcState s) => Calculator.op(s, CalcOp.add),
                '-' => (CalcState s) => Calculator.op(s, CalcOp.subtract),
                '*' || 'x' || 'X' =>
                  (CalcState s) => Calculator.op(s, CalcOp.multiply),
                '/' => (CalcState s) => Calculator.op(s, CalcOp.divide),
                '%' => Calculator.percent,
                '.' || ',' => Calculator.decimalPoint,
                '=' => Calculator.equals,
                _ => null,
              };
      }
    }
    if (action == null) return KeyEventResult.ignored;
    _state.value = action(_state.value);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;

    // Keys are laid out left to right in every language, like any
    // calculator; labels and announcements follow the app's language.
    final List<_Key> keys = <_Key>[
      _Key.fn('AC', l.calcClear, Calculator.clear, id: 'clear'),
      _Key.icon(Icons.backspace_outlined, l.calcBackspace, Calculator.backspace,
          id: 'backspace'),
      _Key.fn('%', l.calcPercent, Calculator.percent, id: 'percent'),
      _Key.op('÷', l.calcDivide, CalcOp.divide),
      _Key.digit(7), _Key.digit(8), _Key.digit(9),
      _Key.op('×', l.calcMultiply, CalcOp.multiply),
      _Key.digit(4), _Key.digit(5), _Key.digit(6),
      _Key.op('−', l.calcSubtract, CalcOp.subtract),
      _Key.digit(1), _Key.digit(2), _Key.digit(3),
      _Key.op('+', l.calcAdd, CalcOp.add),
      _Key.fn('+/−', l.calcToggleSign, Calculator.toggleSign, id: 'sign'),
      _Key.digit(0),
      _Key.decimal(l.calcDecimal),
      _Key.equals(l.calcEquals),
    ];

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          final double width =
              box.maxWidth.clamp(0, 440).toDouble() - 2 * DsSpacing.lg;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(DsSpacing.lg),
            child: Center(
              child: SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(l.navCalculator,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: DsSpacing.lg),
                    GlassCard(
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: _Display(state: _state),
                      ),
                    ),
                    const SizedBox(height: DsSpacing.lg),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: DsSpacing.md,
                        crossAxisSpacing: DsSpacing.md,
                        childAspectRatio: 1.1,
                        children: <Widget>[
                          for (final _Key k in keys)
                            _KeyButton(
                              keyDef: k,
                              colors: c,
                              onPressed: () => _press(k.action),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The expression line and the number, the only part rebuilt on each key.
class _Display extends ConsumerWidget {
  const _Display({required this.state});
  final ValueNotifier<CalcState> state;

  static String _opSign(CalcOp op) => switch (op) {
        CalcOp.add => '+',
        CalcOp.subtract => '−',
        CalcOp.multiply => '×',
        CalcOp.divide => '÷',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NumberStyle style = ref.watch(numberStyleProvider);
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    String fmt(String plain) =>
        CalcFormat.format(plain, group: style.group, decimal: style.decimal);

    return ValueListenableBuilder<CalcState>(
      valueListenable: state,
      builder: (BuildContext context, CalcState s, Widget? _) {
        final String main = switch (s.error) {
          CalcError.divideByZero => l.calcDivideByZero,
          CalcError.tooLarge => l.calcTooLarge,
          null => fmt(Calculator.display(s)),
        };
        final String line = s.pending != null && s.accumulator != null
            ? '${fmt(s.accumulator!.plain())} ${_opSign(s.pending!)}'
            : '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            SizedBox(
              height: 22,
              child: Text(line,
                  key: const Key('calc-line'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleSmall?.copyWith(color: c.textMuted)),
            ),
            const SizedBox(height: DsSpacing.xs),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    main,
                    key: const Key('calc-display'),
                    maxLines: 1,
                    textDirection: s.error == null
                        ? TextDirection.ltr
                        : Directionality.of(context),
                    style: t.displaySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: s.error == null ? c.textPrimary : c.expense,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _KeyKind { digit, fn, op, equals }

class _Key {
  const _Key._(this.label, this.semantic, this.action, this.kind, this.id,
      {this.icon});

  factory _Key.digit(int d) => _Key._('$d', '$d',
      (CalcState s) => Calculator.digit(s, d), _KeyKind.digit, 'd$d');

  factory _Key.decimal(String semantic) => _Key._(
      '.', semantic, Calculator.decimalPoint, _KeyKind.digit, 'decimal');

  factory _Key.fn(String label, String semantic,
          CalcState Function(CalcState) action, {required String id}) =>
      _Key._(label, semantic, action, _KeyKind.fn, id);

  factory _Key.icon(IconData icon, String semantic,
          CalcState Function(CalcState) action, {required String id}) =>
      _Key._('', semantic, action, _KeyKind.fn, id, icon: icon);

  factory _Key.op(String label, String semantic, CalcOp op) => _Key._(
      label,
      semantic,
      (CalcState s) => Calculator.op(s, op),
      _KeyKind.op,
      'op-${op.name}');

  factory _Key.equals(String semantic) =>
      _Key._('=', semantic, Calculator.equals, _KeyKind.equals, 'equals');

  final String label;
  final String semantic;
  final CalcState Function(CalcState) action;
  final _KeyKind kind;
  final String id;
  final IconData? icon;
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.keyDef,
    required this.colors,
    required this.onPressed,
  });

  final _Key keyDef;
  final DsColors colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final DsColors c = colors;
    final (Color bg, Color fg) = switch (keyDef.kind) {
      _KeyKind.equals => (c.brand, Colors.white),
      _KeyKind.op => (c.brand.withValues(alpha: 0.14), c.brand),
      _KeyKind.fn => (c.surfaceMuted, c.textPrimary),
      _KeyKind.digit => (c.surface, c.textPrimary),
    };
    final TextStyle? style = Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: fg,
        fontWeight:
            keyDef.kind == _KeyKind.digit ? FontWeight.w500 : FontWeight.w600);
    return Semantics(
      button: true,
      label: keyDef.semantic,
      excludeSemantics: true,
      child: Material(
        color: bg,
        borderRadius: DsRadius.brLg,
        child: InkWell(
          key: Key('calc-${keyDef.id}'),
          borderRadius: DsRadius.brLg,
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: DsRadius.brLg,
              border: keyDef.kind == _KeyKind.digit
                  ? Border.all(color: c.border.withValues(alpha: 0.6))
                  : null,
            ),
            child: keyDef.icon != null
                ? Icon(keyDef.icon, color: fg, size: 24)
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(keyDef.label, style: style),
                  ),
          ),
        ),
      ),
    );
  }
}
