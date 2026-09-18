import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// Default categories and payment methods — mirrored exactly from SmartBudget
/// V1 (Config.gs). These are product data, not financial rules; kept identical
/// so migrated data lines up. Users will be able to customize them later.
abstract final class Catalog {
  static const List<String> incomeCategories = <String>[
    'راتب أساسي',
    'مكافآت وحوافز',
    'عمل حر',
    'دخل استثماري',
    'إيجارات',
    'أرباح تجارية',
    'هدايا',
    'أخرى',
  ];

  static const List<String> expenseCategories = <String>[
    'الطعام',
    'النقل',
    'السكن',
    'الفواتير',
    'الصحة',
    'التعليم',
    'التسوق',
    'الترفيه',
    'الاشتراكات',
    'السفر',
    'الطوارئ',
    'أخرى',
  ];

  static const List<String> paymentMethods = <String>[
    'نقداً',
    'بطاقة بنكية',
    'تحويل الكتروني',
    'أخرى',
  ];

  static List<String> categoriesFor(TransactionType type) =>
      type == TransactionType.income ? incomeCategories : expenseCategories;
}
