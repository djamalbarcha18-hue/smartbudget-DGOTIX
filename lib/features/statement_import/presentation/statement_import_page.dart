import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:smartbudget/core/l10n/app_lang_context.dart';
import 'package:smartbudget/core/l10n/date_text.dart';
import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/backup/data/file_io.dart';
import 'package:smartbudget/features/exchange_rates/application/rates_controller.dart';
import 'package:smartbudget/features/statement_import/domain/statement_parser.dart';
import 'package:smartbudget/features/statement_import/domain/table_reader.dart';
import 'package:smartbudget/features/transactions/application/custom_categories_controller.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/domain/transaction_repository.dart';
import 'package:smartbudget/features/wallets/application/wallets_controller.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';
import 'package:smartbudget/features/wallets/presentation/wallet_text.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// Adds many transactions at once from an Excel or CSV file: a bank
/// statement, or a list exported from another app (or from SmartBudget).
/// The file is read on the device; nothing is added before the user checks
/// the columns and the rows and taps «Add».
class StatementImportPage extends ConsumerStatefulWidget {
  const StatementImportPage({super.key, this.pick = pickDataFile});

  /// Lets the user choose the file (replaced in tests).
  final Future<({String name, Uint8List bytes})?> Function() pick;

  /// Rows shown before «… and N more».
  static const int preview = 30;

  @override
  ConsumerState<StatementImportPage> createState() =>
      _StatementImportPageState();
}

class _StatementImportPageState extends ConsumerState<StatementImportPage> {
  String? _name;
  SheetTable? _table;
  TableError? _error;
  int _header = -1;
  ImportColumns _columns = const ImportColumns(<ImportField, int>{});
  bool _unsignedIncome = false;
  String? _walletId;
  StatementRead? _read;
  bool _busy = false;

  /// The column choices are open: when the guess is incomplete, or the
  /// user opened them.
  bool _showColumns = false;

  /// The fields the user can point at a column, in the order shown.
  static const List<ImportField> _fields = <ImportField>[
    ImportField.date,
    ImportField.description,
    ImportField.amount,
    ImportField.debit,
    ImportField.credit,
    ImportField.type,
    ImportField.category,
  ];

  Future<void> _pick() async {
    final String lang = Localizations.localeOf(context).languageCode;
    setState(() => _busy = true);
    try {
      final ({String name, Uint8List bytes})? f = await widget.pick();
      if (f == null || !mounted) return;
      try {
        final SheetTable t = TableReader.read(f.bytes, lang: lang);
        final g = StatementParser.guess(t);
        setState(() {
          _name = f.name;
          _table = t;
          _error = null;
          _header = g.header;
          _columns = g.columns;
          _unsignedIncome = false;
          _showColumns = !g.columns.usable;
        });
        _reread();
      } on TableReadException catch (e) {
        setState(() {
          _name = f.name;
          _table = null;
          _read = null;
          _error = e.error;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reread() {
    final SheetTable? t = _table;
    if (t == null) return;
    final CustomCategories cc = ref.read(customCategoriesProvider);
    setState(() => _read = StatementParser.read(t, _header, _columns,
        today: AppClock.now(),
        unsignedIncome: _unsignedIncome,
        customIncome: cc.income,
        customExpense: cc.expense));
  }

  /// The wallet a row goes to: the chosen one, or the one holding the
  /// row's currency; null when no wallet holds it.
  String? _walletFor(StatementRow r, List<Wallet> wallets, String chosen) {
    final String? code = r.currency;
    if (code == null || ref.read(walletCurrencyProvider(chosen)) == code) {
      return chosen;
    }
    return wallets
        .where((Wallet w) => !w.isGeneral && w.currency == code)
        .firstOrNull
        ?.id;
  }

  Future<void> _add(List<(StatementRow, String)> rows) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final GoRouter router = GoRouter.of(context);
    setState(() => _busy = true);
    final String base = ref.read(baseCurrencyProvider);
    final Map<String, double> rates = ref.read(ratesProvider);
    final DateTime now = AppClock.now();
    final List<Transaction> txns = <Transaction>[
      for (final (StatementRow r, String wallet) in rows)
        () {
          final Money money = Money.fromDouble(
              r.amount, ref.read(walletCurrencyProvider(wallet)));
          return Transaction(
            id: r.id,
            date: r.date,
            type: r.type,
            category: r.category,
            amount: money,
            baseAmount: WalletMath.baseValue(money, base, rates),
            description: r.description,
            notes: r.notes,
            walletId: wallet == Wallet.generalId ? null : wallet,
            createdAt: now,
          );
        }(),
    ];
    final TransactionRepository repo = ref.read(financeRepositoryProvider);
    final int added = await repo.importMany(txns);
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(SnackBar(
      content: Text(l.quickAdded(added)),
      action: SnackBarAction(
        label: l.quickUndo,
        onPressed: () =>
            repo.deleteMany(txns.map((Transaction t) => t.id).toList()),
      ),
    ));
    router.go('/transactions');
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final AppLang lang = appLangOf(context);
    final Locale locale = Localizations.localeOf(context);
    final List<Wallet> wallets = ref.watch(walletsProvider);
    final String chosen =
        _walletId ?? ref.watch(effectiveDefaultWalletProvider);
    final List<Transaction> existing =
        ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[];
    final SheetTable? table = _table;
    final StatementRead? read = _read;

    // Rows to add, rows already in the app, currencies no wallet holds.
    final List<(StatementRow, String)> toAdd = <(StatementRow, String)>[];
    final Set<String> noWallet = <String>{};
    int known = 0;
    if (read != null) {
      final Set<int> recorded =
          StatementParser.alreadyRecorded(read.rows, existing);
      for (int i = 0; i < read.rows.length; i++) {
        final StatementRow r = read.rows[i];
        if (recorded.contains(i)) {
          known++;
          continue;
        }
        final String? w = _walletFor(r, wallets, chosen);
        if (w == null) {
          noWallet.add(r.currency!);
        } else {
          toAdd.add((r, w));
        }
      }
    }

    Widget line(String text, Color color, IconData icon) => Padding(
          padding: const EdgeInsets.only(bottom: DsSpacing.xs),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                  child:
                      Text(text, style: t.bodySmall?.copyWith(color: color))),
            ],
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(l.importStatementTitle, style: t.headlineSmall),
          const SizedBox(height: DsSpacing.sm),
          Text(l.importStatementHint,
              style: t.bodyMedium?.copyWith(color: c.textMuted)),
          const SizedBox(height: DsSpacing.sm),
          line(l.importOnDevice, c.textMuted, Icons.lock_outline_rounded),
          const SizedBox(height: DsSpacing.lg),
          DsButton(
            label: l.importChooseFile,
            icon: Icons.upload_file_outlined,
            variant: table == null
                ? DsButtonVariant.primary
                : DsButtonVariant.secondary,
            onPressed: _busy ? null : _pick,
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: DsSpacing.md),
            line(
                _error == TableError.oldExcel
                    ? l.importOldExcel
                    : l.importUnreadable,
                c.expense,
                Icons.error_outline_rounded),
          ],
          if (table != null && read != null) ...<Widget>[
            const SizedBox(height: DsSpacing.md),
            line(
                l.importFileRows(
                    _name ?? '', table.rows.length - (_header + 1)),
                c.textMuted,
                Icons.description_outlined),
            const SizedBox(height: DsSpacing.md),
            GlassCard(
              hoverable: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  InkWell(
                    borderRadius: DsRadius.brMd,
                    onTap: () => setState(() => _showColumns = !_showColumns),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(l.importColumns, style: t.titleSmall),
                              const SizedBox(height: DsSpacing.xs),
                              Text(
                                _showColumns
                                    ? l.importColumnsHint
                                    : <String>[
                                        for (final ImportField f in _fields)
                                          if (_columns[f] != null)
                                            '${_fieldLabel(l, f)}: '
                                                '${_columnName(l, table, _columns[f]!)}',
                                      ].join(' · '),
                                style:
                                    t.bodySmall?.copyWith(color: c.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                            _showColumns
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: c.textMuted),
                      ],
                    ),
                  ),
                  if (_showColumns) const SizedBox(height: DsSpacing.md),
                  if (_showColumns)
                    for (final ImportField f in _fields)
                      _ColumnRow(
                        label: _fieldLabel(l, f),
                        value: _columns[f],
                        columns: <(int, String)>[
                          for (int i = 0; i < table.columns; i++)
                            (i, _columnName(l, table, i)),
                        ],
                        noneLabel: l.importColNone,
                        onChanged: (int? col) {
                          _columns = _columns.set(f, col);
                          _reread();
                        },
                      ),
                  if (_columns[ImportField.amount] != null &&
                      _columns[ImportField.type] == null &&
                      !read.signed) ...<Widget>[
                    const SizedBox(height: DsSpacing.sm),
                    Text(l.importUnsignedAs,
                        style: t.labelMedium?.copyWith(color: c.textMuted)),
                    const SizedBox(height: DsSpacing.xs),
                    SegmentedButton<bool>(
                      segments: <ButtonSegment<bool>>[
                        ButtonSegment<bool>(
                            value: false,
                            label: Text(l.txnTypeExpense),
                            icon: const Icon(Icons.north_east_rounded)),
                        ButtonSegment<bool>(
                            value: true,
                            label: Text(l.txnTypeIncome),
                            icon: const Icon(Icons.south_west_rounded)),
                      ],
                      selected: <bool>{_unsignedIncome},
                      onSelectionChanged: (Set<bool> s) {
                        _unsignedIncome = s.first;
                        _reread();
                      },
                    ),
                  ],
                  if (wallets.length > 1) ...<Widget>[
                    const SizedBox(height: DsSpacing.md),
                    _ColumnRow(
                      label: l.fieldWallet,
                      value: wallets.indexWhere((Wallet w) => w.id == chosen),
                      columns: <(int, String)>[
                        for (int i = 0; i < wallets.length; i++)
                          (i, walletName(l, wallets[i])),
                      ],
                      onChanged: (int? i) => setState(
                          () => _walletId = i == null ? null : wallets[i].id),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: DsSpacing.lg),
            if (!_columns.usable)
              line(l.importNeedColumns, c.warning, Icons.info_outline_rounded)
            else ...<Widget>[
              line(l.importCountAdd(toAdd.length), c.textPrimary,
                  Icons.playlist_add_check_rounded),
              if (known > 0)
                line(l.importCountKnown(known), c.textMuted,
                    Icons.done_all_rounded),
              if (read.unreadable > 0)
                line(l.importCountBad(read.unreadable), c.warning,
                    Icons.report_gmailerrorred_rounded),
              for (final String code in noWallet)
                line(l.quickNoWalletFor(code), c.expense,
                    Icons.account_balance_wallet_outlined),
              const SizedBox(height: DsSpacing.sm),
              for (final (StatementRow r, String w)
                  in toAdd.take(StatementImportPage.preview))
                _RowTile(
                  row: r,
                  category: Catalog.label(r.category, lang: lang),
                  day: dayText(locale, r.date),
                  amount: MoneyFormatter.format(Money.fromDouble(
                      r.amount, ref.watch(walletCurrencyProvider(w)))),
                ),
              if (toAdd.length > StatementImportPage.preview)
                Padding(
                  padding: const EdgeInsets.only(bottom: DsSpacing.sm),
                  child: Text(
                      l.importMore(toAdd.length - StatementImportPage.preview),
                      textAlign: TextAlign.center,
                      style: t.bodySmall?.copyWith(color: c.textMuted)),
                ),
              const SizedBox(height: DsSpacing.md),
              if (toAdd.isEmpty)
                line(l.importNothing, c.textMuted, Icons.check_circle_outline)
              else
                DsButton(
                  label: l.importAdd(toAdd.length),
                  icon: Icons.check_rounded,
                  onPressed: _busy ? null : () => _add(toAdd),
                ),
            ],
          ],
          const SizedBox(height: DsSpacing.xl),
        ],
      ),
    );
  }

  static String _fieldLabel(AppLocalizations l, ImportField f) => switch (f) {
        ImportField.date => l.fieldDate,
        ImportField.description => l.fieldDescription,
        ImportField.amount => l.fieldAmount,
        ImportField.debit => l.importColDebit,
        ImportField.credit => l.importColCredit,
        ImportField.type => l.fieldType,
        ImportField.category => l.fieldCategory,
        _ => f.name,
      };

  /// The header's text, or «Column 3: 24/10/2026» from the first row.
  String _columnName(AppLocalizations l, SheetTable t, int i) {
    if (_header >= 0) {
      final String h = t.cell(_header, i).trim();
      if (h.isNotEmpty) return h;
    }
    final String sample =
        _header + 1 < t.rows.length ? t.cell(_header + 1, i).trim() : '';
    return sample.isEmpty
        ? l.importColumnN(i + 1)
        : '${l.importColumnN(i + 1)}: $sample';
  }
}

/// «Date  [Transaction Date ▾]»: a field and the column it is read from.
class _ColumnRow extends StatelessWidget {
  const _ColumnRow({
    required this.label,
    required this.value,
    required this.columns,
    required this.onChanged,
    this.noneLabel,
  });

  final String label;
  final int? value;
  final List<(int, String)> columns;
  final ValueChanged<int?> onChanged;

  /// The «not in the file» choice; none when a value is required.
  final String? noneLabel;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpacing.sm),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 104,
            child: Text(label, style: t.labelLarge),
          ),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: DsRadius.brMd,
                border: Border.all(color: c.border),
              ),
              child: DropdownButton<int?>(
                value: value,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                dropdownColor: c.bgElevated,
                items: <DropdownMenuItem<int?>>[
                  if (noneLabel != null)
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(noneLabel!,
                          style: t.bodyMedium?.copyWith(color: c.textFaint)),
                    ),
                  for (final (int i, String name) in columns)
                    DropdownMenuItem<int?>(
                      value: i,
                      child: Text(name,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({
    required this.row,
    required this.category,
    required this.day,
    required this.amount,
  });

  final StatementRow row;
  final String category;
  final String day;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final bool income = row.type == TransactionType.income;
    return Container(
      margin: const EdgeInsets.only(bottom: DsSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.md, vertical: DsSpacing.sm),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: DsRadius.brMd,
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(income ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 18, color: income ? c.income : c.expense),
          const SizedBox(width: DsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(category,
                    style: t.titleSmall
                        ?.copyWith(color: row.recognized ? null : c.warning)),
                Text(
                  <String>[
                    if (row.description.isNotEmpty) row.description,
                    day,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(color: c.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: DsSpacing.sm),
          Text(amount,
              style: t.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: income ? c.income : c.expense)),
        ],
      ),
    );
  }
}
