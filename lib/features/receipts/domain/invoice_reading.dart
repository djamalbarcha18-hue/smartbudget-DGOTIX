/// A read invoice: the fields that matter for a budget, each with a confidence,
/// and the result of the arithmetic checks. Pure (no Flutter, no IO).
///
/// Only header, items and totals are kept: logos, addresses, phone numbers,
/// cashier names, card and transaction numbers, QR codes and marketing text
/// are never extracted in the first place.
library;

/// How much attention a reading needs from the user.
enum ReviewLevel {
  /// Every checked field is confident and the totals add up.
  verified,

  /// Usable, but something is worth a glance (e.g. no date on the receipt).
  warning,

  /// A calculation doesn't add up or a key figure is unsure: the user should
  /// check before saving.
  review,
}

/// Where the confidence thresholds sit. Adjustable in one place.
class ReviewPolicy {
  const ReviewPolicy({this.accept = 0.90, this.warn = 0.70});

  /// At or above: accepted without a warning.
  final double accept;

  /// Below: the user must review.
  final double warn;

  static const ReviewPolicy standard = ReviewPolicy();

  ReviewLevel levelOf(double confidence) => confidence >= accept
      ? ReviewLevel.verified
      : confidence >= warn
          ? ReviewLevel.warning
          : ReviewLevel.review;
}

/// Something the checks found. The UI turns each into a short message.
enum InvoiceIssue {
  /// quantity × unit price ≠ line total on at least one line.
  lineMismatch,

  /// The lines don't add up to the subtotal.
  itemsVsSubtotal,

  /// subtotal − discount + tax ≠ total.
  summaryMismatch,

  /// No total printed; the one shown was calculated from the other figures.
  totalComputed,

  /// No total could be read or calculated.
  totalMissing,

  /// Total − paid ≠ amount due.
  dueMismatch,

  /// No currency printed or inferable.
  currencyUnknown,

  /// The printed currency sign and code disagree.
  currencyConflict,

  /// No date on the receipt.
  dateMissing,

  /// A date in the future or long ago.
  dateSuspicious,

  /// An ambiguous amount ("1.250") was read the way that makes it add up.
  amountResolvedByContext,
}

class InvoiceItem {
  const InvoiceItem({
    required this.name,
    this.quantity,
    this.unitPrice,
    this.lineTotal,
    required this.confidence,
    this.mismatch = false,
    this.resolvedByContext = false,
    this.editedByUser = false,
  });

  final String name;

  /// Null when not printed (never assumed to be 1).
  final double? quantity;
  final double? unitPrice;
  final double? lineTotal;

  /// 0..1.
  final double confidence;

  /// quantity × unit price doesn't match the line total.
  final bool mismatch;

  /// An ambiguous amount on this line was read the way that adds up.
  final bool resolvedByContext;
  final bool editedByUser;

  InvoiceItem copyWith({
    String? name,
    double? quantity,
    double? unitPrice,
    double? lineTotal,
    double? confidence,
    bool? mismatch,
    bool? resolvedByContext,
    bool? editedByUser,
    bool clearQuantity = false,
    bool clearUnitPrice = false,
    bool clearLineTotal = false,
  }) =>
      InvoiceItem(
        name: name ?? this.name,
        quantity: clearQuantity ? null : (quantity ?? this.quantity),
        unitPrice: clearUnitPrice ? null : (unitPrice ?? this.unitPrice),
        lineTotal: clearLineTotal ? null : (lineTotal ?? this.lineTotal),
        confidence: confidence ?? this.confidence,
        mismatch: mismatch ?? this.mismatch,
        resolvedByContext: resolvedByContext ?? this.resolvedByContext,
        editedByUser: editedByUser ?? this.editedByUser,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'name': name,
        'quantity': quantity,
        'unit_price': unitPrice,
        'line_total': lineTotal,
        'confidence': _round2(confidence),
      };
}

class InvoiceChecks {
  const InvoiceChecks({
    this.itemsSumMatchesSubtotal,
    this.totalMatchesCalculation,
    this.taxIncludedInSubtotal = false,
    this.issues = const <InvoiceIssue>{},
  });

  /// Null when there was nothing to compare (no items or no subtotal).
  final bool? itemsSumMatchesSubtotal;
  final bool? totalMatchesCalculation;

  /// The subtotal already contains the tax (French "dont TVA" receipts).
  final bool taxIncludedInSubtotal;
  final Set<InvoiceIssue> issues;

  bool get hasErrors => issues.any(_errors.contains);

  static const Set<InvoiceIssue> _errors = <InvoiceIssue>{
    InvoiceIssue.lineMismatch,
    InvoiceIssue.itemsVsSubtotal,
    InvoiceIssue.summaryMismatch,
    InvoiceIssue.dueMismatch,
    InvoiceIssue.totalMissing,
  };
}

/// Per-field confidence, 0..1 (0 when the field wasn't found).
class InvoiceConfidence {
  const InvoiceConfidence({
    this.invoiceNumber = 0,
    this.date = 0,
    this.currency = 0,
    this.total = 0,
  });

  final double invoiceNumber;
  final double date;
  final double currency;
  final double total;

  Map<String, double> toJson() => <String, double>{
        'invoice_number_confidence': _round2(invoiceNumber),
        'date_confidence': _round2(date),
        'currency_confidence': _round2(currency),
        'total_confidence': _round2(total),
      };
}

class InvoiceReading {
  const InvoiceReading({
    this.invoiceNumber,
    this.date,
    this.currency,
    this.supplier,
    this.customer,
    this.category,
    this.items = const <InvoiceItem>[],
    this.subtotal,
    this.discount,
    this.tax,
    this.total,
    this.amountPaid,
    this.amountDue,
    this.totalComputed = false,
    required this.confidence,
    required this.checks,
    this.currencyDecimals = 2,
  });

  final String? invoiceNumber;
  final DateTime? date;

  /// ISO 4217, or null when unknown (never assumed, never converted here).
  final String? currency;
  final String? supplier;
  final String? customer;

  /// Best-fit expense category (app's Arabic label), or null.
  final String? category;
  final List<InvoiceItem> items;
  final double? subtotal;

  /// Always positive (an amount taken off).
  final double? discount;
  final double? tax;

  /// The grand total: printed, or calculated when [totalComputed].
  final double? total;
  final double? amountPaid;
  final double? amountDue;
  final bool totalComputed;
  final InvoiceConfidence confidence;
  final InvoiceChecks checks;
  final int currencyDecimals;

  ReviewLevel level([ReviewPolicy policy = ReviewPolicy.standard]) {
    if (checks.hasErrors) return ReviewLevel.review;
    final List<double> key = <double>[
      confidence.total,
      for (final InvoiceItem i in items) i.confidence,
    ];
    final double lowest = key.reduce((double a, double b) => a < b ? a : b);
    final ReviewLevel byKey = policy.levelOf(lowest);
    if (byKey != ReviewLevel.verified) return byKey;
    // Date and currency alone never block: the user picks them anyway.
    if (confidence.date < policy.accept ||
        confidence.currency < policy.accept) {
      return ReviewLevel.warning;
    }
    return ReviewLevel.verified;
  }

  /// Items that need the user's eye.
  Iterable<InvoiceItem> itemsToReview([
    ReviewPolicy policy = ReviewPolicy.standard,
  ]) =>
      items.where((InvoiceItem i) => i.mismatch || i.confidence < policy.warn);

  Map<String, Object?> toJson() => <String, Object?>{
        'invoice_number': invoiceNumber,
        'date': date == null
            ? null
            : '${date!.year.toString().padLeft(4, '0')}-'
                '${date!.month.toString().padLeft(2, '0')}-'
                '${date!.day.toString().padLeft(2, '0')}',
        'currency': currency,
        'supplier': supplier,
        'customer': customer,
        'items': items.map((InvoiceItem i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'total': total,
        'amount_paid': amountPaid,
        'amount_due': amountDue,
        ...confidence.toJson(),
        'validation': <String, Object?>{
          'items_sum_matches_subtotal': checks.itemsSumMatchesSubtotal,
          'total_matches_calculation': checks.totalMatchesCalculation,
          'has_errors': checks.hasErrors,
        },
      };
}

double _round2(double v) => (v * 100).roundToDouble() / 100;
