import 'package:flutter/material.dart';

import 'package:smartbudget/design_system/icons/sb_icons.dart';
import 'package:smartbudget/features/wallets/domain/wallet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

String walletName(AppLocalizations l, Wallet w) =>
    w.isGeneral ? l.walletGeneral : w.name;

String walletTypeName(AppLocalizations l, WalletType t) => switch (t) {
      WalletType.cash => l.walletTypeCash,
      WalletType.bank => l.walletTypeBank,
      WalletType.card => l.walletTypeCard,
      WalletType.ewallet => l.walletTypeEwallet,
      WalletType.savings => l.walletTypeSavings,
      WalletType.other => l.walletTypeOther,
    };

IconData walletIcon(Wallet w) => w.isGeneral
    ? Icons.account_balance_wallet_outlined
    : switch (w.type) {
        WalletType.cash => Icons.payments_outlined,
        WalletType.bank => Icons.account_balance_outlined,
        WalletType.card => Icons.credit_card_rounded,
        WalletType.ewallet => Icons.phone_iphone_rounded,
        WalletType.savings => SbIcons.moneyBox,
        WalletType.other => Icons.wallet_outlined,
      };

Color walletColor(Wallet w) => w.isGeneral
    ? const Color(0xFF64748B)
    : switch (w.type) {
        WalletType.cash => const Color(0xFF10B981),
        WalletType.bank => const Color(0xFF1680F7),
        WalletType.card => const Color(0xFF8B5CF6),
        WalletType.ewallet => const Color(0xFF06B6D4),
        WalletType.savings => const Color(0xFFF59E0B),
        WalletType.other => const Color(0xFF14B8A6),
      };
