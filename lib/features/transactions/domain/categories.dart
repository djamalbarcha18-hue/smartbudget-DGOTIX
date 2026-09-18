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
}
