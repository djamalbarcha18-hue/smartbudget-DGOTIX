import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// Default categories and payment methods (product data, not financial rules).
///
/// Expanded for a global audience while staying halal-oriented: no gambling,
/// betting, lottery or interest/riba income. Existing categories are preserved
/// (stored transactions keep their category); new ones are additive, and
/// 'أخرى' (Other) always stays last. Users can customize these later.
abstract final class Catalog {
  static const List<String> incomeCategories = <String>[
    'راتب أساسي',
    'مكافآت وحوافز',
    'مكافأة نهاية الخدمة',
    'معاش تقاعدي',
    'عمل حر',
    'عمولات',
    'أرباح تجارية',
    'دخل استثماري',
    'أرباح أسهم وتوزيعات',
    'أرباح العملات الرقمية',
    'إيجارات',
    'تأجير قصير الأمد',
    'تجارة إلكترونية',
    'بيع أصول أو ممتلكات',
    'محتوى رقمي وإبداعي',
    'استرجاع نقدي ومكافآت',
    'منحة أو إعانة',
    'ميراث',
    'استرداد أو تعويض',
    'هدايا',
    'زكاة أو صدقة مستلمة',
    'أخرى',
  ];

  static const List<String> expenseCategories = <String>[
    'الطعام',
    'المطاعم',
    'النقل',
    'السكن',
    'الفواتير',
    'الاتصالات والإنترنت',
    'الصحة',
    'التعليم',
    'الأطفال والعائلة',
    'التسوق',
    'الملابس',
    'الترفيه',
    'الرياضة واللياقة',
    'الاشتراكات',
    'السفر',
    'الأقساط والقروض',
    'التأمين',
    'الضرائب والرسوم',
    'الصيانة والإصلاح',
    'الأثاث والمنزل',
    'الوقود',
    'الخدمات المهنية والقانونية',
    'البرمجيات والأدوات الرقمية',
    'الحج والعمرة',
    'صدقة وتبرّعات',
    'زكاة',
    'الادخار والاستثمار',
    'الطوارئ',
    'أخرى',
  ];

  static const List<String> paymentMethods = <String>[
    'نقداً',
    'بطاقة بنكية',
    'بطاقة ائتمان',
    'محفظة إلكترونية',
    'Apple Pay',
    'Google Pay',
    'PayPal',
    'تحويل الكتروني',
    'تحويل بنكي فوري',
    'الدفع عند الاستلام',
    'محفظة عملات رقمية',
    'أموال عبر الهاتف',
    'شيك',
    'بطاقة هدايا أو قسيمة',
    'أخرى',
  ];

  static List<String> categoriesFor(TransactionType type) =>
      type == TransactionType.income ? incomeCategories : expenseCategories;

  /// English display labels keyed by the stored (Arabic) category/method value.
  /// The stored value never changes (so data stays stable); only the DISPLAY is
  /// localized. Latin-named methods (Apple Pay…) fall through to themselves.
  static const Map<String, String> _en = <String, String>{
    // Income
    'راتب أساسي': 'Base salary',
    'مكافآت وحوافز': 'Bonuses & incentives',
    'مكافأة نهاية الخدمة': 'End-of-service',
    'معاش تقاعدي': 'Pension',
    'عمل حر': 'Freelance',
    'عمولات': 'Commissions',
    'أرباح تجارية': 'Business profits',
    'دخل استثماري': 'Investment income',
    'أرباح أسهم وتوزيعات': 'Dividends',
    'أرباح العملات الرقمية': 'Crypto gains',
    'إيجارات': 'Rental income',
    'تأجير قصير الأمد': 'Short-term rentals',
    'تجارة إلكترونية': 'E-commerce',
    'بيع أصول أو ممتلكات': 'Asset/property sale',
    'محتوى رقمي وإبداعي': 'Digital & creator content',
    'استرجاع نقدي ومكافآت': 'Cashback & rewards',
    'منحة أو إعانة': 'Grant/subsidy',
    'ميراث': 'Inheritance',
    'استرداد أو تعويض': 'Refund/compensation',
    'هدايا': 'Gifts',
    'زكاة أو صدقة مستلمة': 'Received charity/zakat',
    // Expenses
    'الطعام': 'Groceries',
    'المطاعم': 'Dining out',
    'النقل': 'Transport',
    'السكن': 'Housing',
    'الفواتير': 'Bills & utilities',
    'الاتصالات والإنترنت': 'Telecom & internet',
    'الصحة': 'Health',
    'التعليم': 'Education',
    'الأطفال والعائلة': 'Children & family',
    'التسوق': 'Shopping',
    'الملابس': 'Clothing',
    'الترفيه': 'Entertainment',
    'الرياضة واللياقة': 'Sports & fitness',
    'الاشتراكات': 'Subscriptions',
    'السفر': 'Travel',
    'الأقساط والقروض': 'Loans & installments',
    'التأمين': 'Insurance',
    'الضرائب والرسوم': 'Taxes & fees',
    'الصيانة والإصلاح': 'Maintenance & repairs',
    'الأثاث والمنزل': 'Home & furniture',
    'الوقود': 'Fuel',
    'الخدمات المهنية والقانونية': 'Professional & legal services',
    'البرمجيات والأدوات الرقمية': 'Software & digital tools',
    'الحج والعمرة': 'Hajj & Umrah',
    'صدقة وتبرّعات': 'Charity & donations',
    'زكاة': 'Zakat',
    'الادخار والاستثمار': 'Savings & investment',
    'الطوارئ': 'Emergency',
    // Payment methods
    'نقداً': 'Cash',
    'بطاقة بنكية': 'Debit card',
    'بطاقة ائتمان': 'Credit card',
    'محفظة إلكترونية': 'E-wallet',
    'تحويل الكتروني': 'Bank transfer',
    'تحويل بنكي فوري': 'Instant transfer',
    'الدفع عند الاستلام': 'Cash on delivery',
    'محفظة عملات رقمية': 'Crypto wallet',
    'أموال عبر الهاتف': 'Mobile money',
    'شيك': 'Cheque',
    'بطاقة هدايا أو قسيمة': 'Gift card / Voucher',
    // Shared
    'أخرى': 'Other',
  };

  /// Localized display label for a stored category/payment value.
  static String label(String value, {required bool ar}) =>
      ar ? value : (_en[value] ?? value);
}
