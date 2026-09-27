import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/core/money/money.dart';
import 'package:smartbudget/core/money/money_formatter.dart';
import 'package:smartbudget/core/settings/base_currency_controller.dart';
import 'package:smartbudget/core/time/app_clock.dart';
import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/components/glass_card.dart';
import 'package:smartbudget/design_system/tokens/ds_breakpoints.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_radius.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/transactions/application/transactions_controller.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/wallets/application/wallets_controller.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';
import 'package:smartbudget/features/wallets/presentation/wallet_sheets.dart';
import 'package:smartbudget/features/wallets/presentation/wallet_text.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

String _ymd(DateTime d) =>
    '\u2066${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}\u2069';

class WalletsPage extends ConsumerWidget {
  const WalletsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final String currency = ref.watch(baseCurrencyProvider);
    final List<Wallet> wallets = ref.watch(walletsProvider);
    final Map<String, int> balances = ref.watch(walletBalancesProvider);
    final List<WalletMove> moves =
        ref.watch(walletMovesProvider).valueOrNull ?? const <WalletMove>[];
    final bool hasWallets = wallets.length > 1;
    final int total = WalletMath.total(balances);

    final bool wide = !context.isMobile;
    Widget grid(List<Widget> children) => LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) {
            final int cols = !wide
                ? 1
                : box.maxWidth > 1000
                    ? 3
                    : 2;
            final double w =
                (box.maxWidth - DsSpacing.lg * (cols - 1)) / cols;
            return Wrap(
              spacing: DsSpacing.lg,
              runSpacing: DsSpacing.lg,
              children: <Widget>[
                for (final Widget ch in children) SizedBox(width: w, child: ch),
              ],
            );
          },
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: DsSpacing.md,
            runSpacing: DsSpacing.md,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(l.navWallets, style: t.headlineSmall),
                  const SizedBox(height: DsSpacing.xs),
                  Text(l.walletsSubtitle,
                      style: t.bodySmall?.copyWith(color: c.textMuted)),
                ],
              ),
              Wrap(
                spacing: DsSpacing.sm,
                runSpacing: DsSpacing.sm,
                children: <Widget>[
                  if (hasWallets)
                    DsButton(
                      label: l.walletTransfer,
                      icon: Icons.swap_horiz_rounded,
                      variant: DsButtonVariant.secondary,
                      onPressed: () => TransferSheet.show(context),
                    ),
                  DsButton(
                    label: l.walletNew,
                    icon: Icons.add_rounded,
                    onPressed: () => WalletEditorSheet.show(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.xl),

          // Total across all wallets.
          GlassCard(
            accent: c.brand,
            child: Row(
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: c.brand.withValues(alpha: 0.14),
                    borderRadius: DsRadius.brMd,
                  ),
                  child: Icon(Icons.account_balance_wallet_rounded,
                      color: c.brand, size: 28),
                ),
                const SizedBox(width: DsSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(l.walletTotal,
                          style: t.labelLarge?.copyWith(color: c.textMuted)),
                      Text(MoneyFormatter.format(Money(total, currency)),
                          style: t.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: total < 0 ? c.expense : null)),
                      Text(
                        hasWallets
                            ? l.walletIn(wallets.length)
                            : l.walletOnlyGeneral,
                        style: t.bodySmall?.copyWith(color: c.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DsSpacing.xl),
          grid(<Widget>[
            for (final Wallet w in wallets)
              _WalletCard(wallet: w, balance: balances[w.id] ?? 0),
          ]),
          if (moves.isNotEmpty) ...<Widget>[
            const SizedBox(height: DsSpacing.xxl),
            Text(l.walletMoves,
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: DsSpacing.md),
            GlassCard(
              child: Column(
                children: <Widget>[
                  for (final WalletMove m in moves.take(12))
                    _MoveRow(move: m, wallets: wallets),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WalletCard extends ConsumerWidget {
  const _WalletCard({required this.wallet, required this.balance});
  final Wallet wallet;
  final int balance;

  Future<void> _delete(BuildContext context, WidgetRef ref, AppLocalizations l) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.walletDeleteTitle(walletName(l, wallet))),
        content: Text(l.walletDeleteBody),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l.delete)),
        ],
      ),
    );
    if (ok == true) await ref.read(walletActionsProvider).delete(wallet.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final String currency = ref.watch(baseCurrencyProvider);
    final bool isDefault =
        ref.watch(effectiveDefaultWalletProvider) == wallet.id;
    final List<Transaction> txns =
        ref.watch(transactionsProvider).valueOrNull ?? const <Transaction>[];
    final Set<String> known = <String>{
      for (final Wallet w in ref.watch(walletsProvider)) w.id,
    };
    final DateTime now = AppClock.now();
    final ({int income, int expense}) flow = WalletMath.monthFlow(
        wallet.id, txns, known, currency, now.year, now.month);
    final Color color = walletColor(wallet);

    return GlassCard(
      child: InkWell(
        borderRadius: DsRadius.brMd,
        onTap: () => _WalletDetails.show(context, wallet),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: DsRadius.brMd,
                  ),
                  child: Icon(walletIcon(wallet), color: color, size: 22),
                ),
                const SizedBox(width: DsSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(walletName(l, wallet),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                          wallet.isGeneral
                              ? l.walletGeneralHint
                              : walletTypeName(l, wallet.type),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall?.copyWith(color: c.textMuted)),
                    ],
                  ),
                ),
                if (isDefault)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.brand.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(l.walletDefault,
                        style: t.labelSmall?.copyWith(
                            color: c.brand, fontWeight: FontWeight.w700)),
                  ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      size: 18, color: c.textFaint),
                  color: c.bgElevated,
                  onSelected: (String v) async {
                    switch (v) {
                      case 'edit':
                        await WalletEditorSheet.show(context, existing: wallet);
                      case 'default':
                        await ref
                            .read(defaultWalletProvider.notifier)
                            .set(wallet.id);
                      case 'reconcile':
                        await ReconcileSheet.show(context, wallet);
                      case 'transfer':
                        await TransferSheet.show(context, fromId: wallet.id);
                      case 'delete':
                        if (context.mounted) await _delete(context, ref, l);
                    }
                  },
                  itemBuilder: (_) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                        value: 'reconcile', child: Text(l.walletReconcile)),
                    if (ref.read(hasWalletsProvider))
                      PopupMenuItem<String>(
                          value: 'transfer', child: Text(l.walletTransfer)),
                    if (!isDefault)
                      PopupMenuItem<String>(
                          value: 'default', child: Text(l.walletMakeDefault)),
                    PopupMenuItem<String>(value: 'edit', child: Text(l.edit)),
                    if (!wallet.isGeneral)
                      PopupMenuItem<String>(
                          value: 'delete', child: Text(l.delete)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: DsSpacing.lg),
            Text(MoneyFormatter.format(Money(balance, currency)),
                style: t.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: balance < 0 ? c.expense : null)),
            const SizedBox(height: DsSpacing.sm),
            Row(
              children: <Widget>[
                Icon(Icons.south_west_rounded, size: 14, color: c.income),
                const SizedBox(width: 4),
                Text(MoneyFormatter.format(Money(flow.income, currency)),
                    style: t.labelMedium?.copyWith(color: c.income)),
                const SizedBox(width: DsSpacing.md),
                Icon(Icons.north_east_rounded, size: 14, color: c.expense),
                const SizedBox(width: 4),
                Text(MoneyFormatter.format(Money(flow.expense, currency)),
                    style: t.labelMedium?.copyWith(color: c.expense)),
                const Spacer(),
                Text(l.walletThisMonth,
                    style: t.labelSmall?.copyWith(color: c.textFaint)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoveRow extends ConsumerWidget {
  const _MoveRow({required this.move, required this.wallets});
  final WalletMove move;
  final List<Wallet> wallets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final Set<String> known = <String>{for (final Wallet w in wallets) w.id};
    String nameOf(String? id) => walletName(
        l,
        wallets.firstWhere(
            (Wallet w) => w.id == WalletMath.resolve(id, known)));
    final bool transfer = move.kind == MoveKind.transfer;
    final String title = transfer
        ? l.walletMoveTransfer(nameOf(move.fromId), nameOf(move.toId))
        : l.walletMoveAdjust(nameOf(move.toId));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DsSpacing.sm),
      child: Row(
        children: <Widget>[
          Icon(transfer ? Icons.swap_horiz_rounded : Icons.tune_rounded,
              size: 20, color: c.brand),
          const SizedBox(width: DsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: t.bodyMedium),
                Text(
                    move.note.isEmpty
                        ? _ymd(move.date)
                        : '${_ymd(move.date)} · ${move.note}',
                    style: t.labelSmall?.copyWith(color: c.textMuted)),
              ],
            ),
          ),
          Text(MoneyFormatter.format(move.amount),
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          IconButton(
            tooltip: l.delete,
            icon: Icon(Icons.close_rounded, size: 16, color: c.textFaint),
            onPressed: () =>
                ref.read(walletActionsProvider).deleteMove(move.id),
          ),
        ],
      ),
    );
  }
}

/// Tapping a wallet: its latest transactions.
class _WalletDetails extends ConsumerWidget {
  const _WalletDetails({required this.wallet});
  final Wallet wallet;

  static Future<void> show(BuildContext context, Wallet w) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _WalletDetails(wallet: w),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    final TextTheme t = Theme.of(context).textTheme;
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final Set<String> known = <String>{
      for (final Wallet w in ref.watch(walletsProvider)) w.id,
    };
    final List<Transaction> txns = (ref.watch(transactionsProvider).valueOrNull ??
            const <Transaction>[])
        .where((Transaction x) =>
            WalletMath.resolve(x.walletId, known) == wallet.id)
        .toList()
      ..sort((Transaction a, Transaction b) => b.date.compareTo(a.date));

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(DsSpacing.xl),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(walletIcon(wallet), color: walletColor(wallet)),
                const SizedBox(width: DsSpacing.sm),
                Expanded(
                  child: Text(walletName(l, wallet),
                      style: t.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: c.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: DsSpacing.sm),
            if (txns.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: DsSpacing.xl),
                child: Text(l.walletNoTxns,
                    textAlign: TextAlign.center,
                    style: t.bodyMedium?.copyWith(color: c.textMuted)),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: txns.length > 30 ? 30 : txns.length,
                  separatorBuilder: (_, __) => Divider(color: c.border, height: 1),
                  itemBuilder: (BuildContext context, int i) {
                    final Transaction x = txns[i];
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: DsSpacing.sm),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                    x.description.isEmpty
                                        ? Catalog.label(x.category, ar: ar)
                                        : x.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.bodyMedium),
                                Text(
                                    '${Catalog.label(x.category, ar: ar)} · ${_ymd(x.date)}',
                                    style: t.labelSmall
                                        ?.copyWith(color: c.textMuted)),
                              ],
                            ),
                          ),
                          Text(
                            '${x.isIncome ? '+' : '−'}${MoneyFormatter.format(x.amount)}',
                            style: t.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: x.isIncome ? c.income : c.expense),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
