import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:smartbudget/design_system/components/ds_button.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/design_system/tokens/ds_spacing.dart';
import 'package:smartbudget/features/receipts/application/receipt_scan_controller.dart';
import 'package:smartbudget/features/receipts/domain/receipt_ocr_engine.dart';
import 'package:smartbudget/features/receipts/domain/scanned_receipt.dart';
import 'package:smartbudget/features/transactions/domain/categories.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';
import 'package:smartbudget/features/transactions/presentation/transaction_editor_sheet.dart';
import 'package:smartbudget/l10n/gen/app_localizations.dart';

/// "Scan receipt" action: capture → cloud OCR → prefilled Add-expense sheet.
class ReceiptScanButton extends ConsumerStatefulWidget {
  const ReceiptScanButton({super.key});

  @override
  ConsumerState<ReceiptScanButton> createState() => _ReceiptScanButtonState();
}

class _ReceiptScanButtonState extends ConsumerState<ReceiptScanButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return DsButton(
      label: _busy ? l.receiptScanning : l.scanReceipt,
      icon: Icons.document_scanner_outlined,
      variant: DsButtonVariant.secondary,
      onPressed: _busy ? null : _start,
    );
  }

  Future<void> _start() async {
    final ImageSource? source = await _chooseSource();
    if (source == null) return;
    await _run(source);
  }

  Future<ImageSource?> _chooseSource() {
    final AppLocalizations l = AppLocalizations.of(context);
    final DsColors c = context.dsColors;
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: c.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: DsSpacing.sm),
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: c.brand),
              title: Text(l.sourceCamera),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: c.brand),
              title: Text(l.sourceGallery),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            const SizedBox(height: DsSpacing.sm),
          ],
        ),
      ),
    );
  }

  Future<void> _run(ImageSource source) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final GoRouter router = GoRouter.of(context);

    setState(() => _busy = true);
    try {
      final ScannedReceipt r =
          await ref.read(receiptScannerProvider).scan(source: source);

      final TransactionDraft draft = TransactionDraft(
        amount: r.totalAmount,
        // Only prefill a category the dropdown actually offers.
        category: Catalog.expenseCategories.contains(r.category)
            ? r.category
            : null,
        date: r.date,
        description: r.merchantName,
      );

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l.receiptScanFilled)),
      );
      await TransactionEditorSheet.show(
        navigator.context,
        type: TransactionType.expense,
        prefill: draft,
      );
    } on ReceiptScanException catch (e) {
      if (e.code == ReceiptScanError.cancelled) return;
      // A quota wall is upgrade-only (never "use your own key").
      final SnackBarAction? action = e.code == ReceiptScanError.quotaExceeded
          ? SnackBarAction(label: l.aiUpgrade, onPressed: () => router.go('/plans'))
          : null;
      messenger.showSnackBar(
        SnackBar(content: Text(_messageFor(e.code, l)), action: action),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(_messageFor(
        ReceiptScanError.unknown,
        l,
      ))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageFor(ReceiptScanError code, AppLocalizations l) {
    switch (code) {
      case ReceiptScanError.backendUnavailable:
        return l.receiptErrBackend;
      case ReceiptScanError.notSignedIn:
        return l.receiptErrSignIn;
      case ReceiptScanError.unreadable:
        return l.receiptErrUnreadable;
      case ReceiptScanError.noTotal:
        return l.receiptErrNoTotal;
      case ReceiptScanError.network:
        return l.receiptErrNetwork;
      case ReceiptScanError.rateLimited:
        return l.receiptErrRateLimited;
      case ReceiptScanError.quotaExceeded:
        return l.receiptErrQuota;
      case ReceiptScanError.offlineUnsupported:
        return l.receiptErrOffline;
      case ReceiptScanError.providerError:
      case ReceiptScanError.unknown:
      case ReceiptScanError.cancelled:
        return l.receiptErrGeneric;
    }
  }
}
