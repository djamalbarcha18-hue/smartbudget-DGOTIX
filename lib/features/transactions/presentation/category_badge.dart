import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/design_system/icons/sb_icons.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/features/transactions/application/category_styles_controller.dart';
import 'package:smartbudget/features/transactions/domain/transaction.dart';

/// The calm colour families of the category icon system: five for expenses,
/// four (all income) for income. A category belongs to exactly one.
enum CategoryFamily {
  basics,
  food,
  mobility,
  lifestyle,
  commitments,

  /// Income, in four calm hues by kind: steady pay (green), passive income
  /// (gold), own work (blue), gifts and aid (rose).
  income,
  incomePassive,
  incomeWork,
  incomeGift;

  bool get isIncome => index >= CategoryFamily.income.index;
}

/// Icon + family of one built-in category.
class CategoryStyle {
  const CategoryStyle(this.icon, this.family);
  final IconData icon;
  final CategoryFamily family;

  /// Built-in categories are keyed by their stored (Arabic) name. An unknown
  /// name (a user-made category) gets a neutral tag until phase 2 lets the
  /// user pick an icon.
  static CategoryStyle of(String category, TransactionType type) {
    if (type == TransactionType.income) {
      return _income[category] ??
          const CategoryStyle(Icons.more_horiz_rounded, CategoryFamily.income);
    }
    return _expense[category] ??
        const CategoryStyle(
            Icons.label_outline_rounded, CategoryFamily.commitments);
  }

  static bool hasStyle(String category, TransactionType type) =>
      (type == TransactionType.income ? _income : _expense)
          .containsKey(category);

  static const CategoryFamily _i = CategoryFamily.income;
  static const CategoryFamily _p = CategoryFamily.incomePassive;
  static const CategoryFamily _w = CategoryFamily.incomeWork;
  static const CategoryFamily _g = CategoryFamily.incomeGift;
  static const Map<String, CategoryStyle> _income = <String, CategoryStyle>{
    'راتب أساسي': CategoryStyle(Icons.payments_outlined, _i),
    'مكافآت وحوافز': CategoryStyle(Icons.emoji_events_outlined, _i),
    'مكافأة نهاية الخدمة':
        CategoryStyle(Icons.assignment_turned_in_outlined, _i),
    'معاش تقاعدي': CategoryStyle(Icons.elderly_outlined, _i),
    'عمل حر': CategoryStyle(Icons.laptop_mac_outlined, _w),
    'عمل بدوام جزئي': CategoryStyle(Icons.schedule_outlined, _w),
    'عمولات': CategoryStyle(Icons.percent_outlined, _w),
    'أرباح تجارية': CategoryStyle(Icons.storefront_outlined, _w),
    'دخل استثماري': CategoryStyle(Icons.trending_up_rounded, _p),
    'أرباح أسهم وتوزيعات': CategoryStyle(Icons.pie_chart_outline_rounded, _p),
    'أرباح العملات الرقمية': CategoryStyle(Icons.currency_bitcoin_outlined, _p),
    'إيجارات': CategoryStyle(Icons.apartment_outlined, _p),
    'تأجير قصير الأمد': CategoryStyle(Icons.bed_outlined, _p),
    'تجارة إلكترونية': CategoryStyle(Icons.shopping_cart_outlined, _w),
    'بيع أصول أو ممتلكات': CategoryStyle(Icons.sell_outlined, _p),
    'محتوى رقمي وإبداعي': CategoryStyle(Icons.movie_creation_outlined, _w),
    'استرجاع نقدي ومكافآت': CategoryStyle(Icons.currency_exchange_outlined, _g),
    'منحة أو إعانة': CategoryStyle(Icons.volunteer_activism_outlined, _g),
    'ميراث': CategoryStyle(Icons.account_balance_outlined, _g),
    'استرداد أو تعويض': CategoryStyle(Icons.assignment_return_outlined, _g),
    'هدايا': CategoryStyle(Icons.card_giftcard_outlined, _g),
    'زكاة أو صدقة مستلمة': CategoryStyle(Icons.favorite_border_rounded, _g),
    'أخرى': CategoryStyle(Icons.more_horiz_rounded, _i),
  };

  static const CategoryFamily _b = CategoryFamily.basics;
  static const CategoryFamily _f = CategoryFamily.food;
  static const CategoryFamily _m = CategoryFamily.mobility;
  static const CategoryFamily _l = CategoryFamily.lifestyle;
  static const CategoryFamily _c = CategoryFamily.commitments;
  static const Map<String, CategoryStyle> _expense = <String, CategoryStyle>{
    'الطعام': CategoryStyle(Icons.shopping_basket_outlined, _f),
    'المطاعم': CategoryStyle(Icons.restaurant_outlined, _f),
    'النقل': CategoryStyle(Icons.directions_bus_outlined, _m),
    'السكن': CategoryStyle(Icons.home_outlined, _b),
    'الفواتير': CategoryStyle(Icons.receipt_long_outlined, _b),
    'الاتصالات والإنترنت': CategoryStyle(Icons.router_outlined, _b),
    'الصحة': CategoryStyle(Icons.medical_services_outlined, _l),
    'التعليم': CategoryStyle(Icons.school_outlined, _c),
    'الأطفال والعائلة': CategoryStyle(Icons.child_care_outlined, _l),
    'الهدايا': CategoryStyle(Icons.card_giftcard_outlined, _l),
    'المناسبات الاجتماعية': CategoryStyle(Icons.celebration_outlined, _l),
    'التسوق': CategoryStyle(Icons.shopping_bag_outlined, _l),
    'الإلكترونيات والأجهزة': CategoryStyle(Icons.devices_outlined, _l),
    'الملابس': CategoryStyle(Icons.checkroom_outlined, _l),
    'العناية الشخصية والتجميل': CategoryStyle(Icons.spa_outlined, _l),
    'الترفيه': CategoryStyle(Icons.theaters_outlined, _l),
    'الرياضة واللياقة': CategoryStyle(Icons.fitness_center_outlined, _l),
    'الاشتراكات': CategoryStyle(Icons.subscriptions_outlined, _c),
    'السفر': CategoryStyle(Icons.flight_outlined, _l),
    'الأقساط والقروض': CategoryStyle(Icons.credit_card_outlined, _c),
    'التأمين': CategoryStyle(Icons.shield_outlined, _c),
    'الضرائب والرسوم': CategoryStyle(Icons.account_balance_outlined, _c),
    'الصيانة والإصلاح': CategoryStyle(Icons.build_outlined, _b),
    'الأثاث والمنزل': CategoryStyle(Icons.chair_outlined, _b),
    'المنظفات ومستلزمات المنزل':
        CategoryStyle(Icons.cleaning_services_outlined, _b),
    'الحيوانات الأليفة': CategoryStyle(Icons.pets_outlined, _l),
    'الوقود': CategoryStyle(Icons.local_gas_station_outlined, _m),
    'السيارة': CategoryStyle(Icons.directions_car_outlined, _m),
    'الخدمات المهنية والقانونية': CategoryStyle(Icons.gavel_outlined, _c),
    'البرمجيات والأدوات الرقمية': CategoryStyle(Icons.terminal_rounded, _c),
    'الحج والعمرة': CategoryStyle(Icons.mosque_outlined, _c),
    'صدقة وتبرّعات': CategoryStyle(Icons.volunteer_activism_outlined, _c),
    'زكاة': CategoryStyle(Icons.handshake_outlined, _c),
    'الادخار والاستثمار': CategoryStyle(SbIcons.moneyBox, _c),
    'الطوارئ': CategoryStyle(Icons.health_and_safety_outlined, _c),
    'أخرى': CategoryStyle(Icons.more_horiz_rounded, _c),
  };
}

/// The icons a user may give a category of their own (stored by key).
const Map<String, IconData> pickableCategoryIcons = <String, IconData>{
  'cart': Icons.shopping_cart_outlined,
  'food': Icons.restaurant_outlined,
  'coffee': Icons.local_cafe_outlined,
  'home': Icons.home_outlined,
  'car': Icons.directions_car_outlined,
  'bus': Icons.directions_bus_outlined,
  'health': Icons.medical_services_outlined,
  'school': Icons.school_outlined,
  'child': Icons.child_care_outlined,
  'gift': Icons.card_giftcard_outlined,
  'shirt': Icons.checkroom_outlined,
  'phone': Icons.smartphone_outlined,
  'wifi': Icons.wifi_rounded,
  'bolt': Icons.bolt_outlined,
  'water': Icons.water_drop_outlined,
  'fitness': Icons.fitness_center_outlined,
  'movie': Icons.theaters_outlined,
  'game': Icons.sports_esports_outlined,
  'book': Icons.menu_book_outlined,
  'pets': Icons.pets_outlined,
  'plane': Icons.flight_outlined,
  'tools': Icons.build_outlined,
  'work': Icons.work_outline_rounded,
  'star': Icons.star_border_rounded,
};

/// The colour families a user may pick for an expense category.
const List<CategoryFamily> pickableFamilies = <CategoryFamily>[
  CategoryFamily.basics,
  CategoryFamily.food,
  CategoryFamily.mobility,
  CategoryFamily.lifestyle,
  CategoryFamily.commitments,
];

/// The colour families a user may pick for an income category.
const List<CategoryFamily> pickableIncomeFamilies = <CategoryFamily>[
  CategoryFamily.income,
  CategoryFamily.incomePassive,
  CategoryFamily.incomeWork,
  CategoryFamily.incomeGift,
];

/// The style of [category]: the built-in one, or, for a category the user
/// made, the look they picked (neutral when they picked none).
CategoryStyle resolveCategoryStyle(String category, TransactionType type,
    Map<String, CustomCategoryLook> looks) {
  final CategoryStyle base = CategoryStyle.of(category, type);
  final CustomCategoryLook? look = looks[categoryLookKey(type, category)];
  if (look == null || CategoryStyle.hasStyle(category, type)) return base;
  final IconData? icon = pickableCategoryIcons[look.iconKey];
  if (icon == null) return base;
  return CategoryStyle(
      icon,
      CategoryFamily.values.firstWhere(
          (CategoryFamily f) =>
              f.name == look.familyName &&
              f.isIncome == (type == TransactionType.income),
          orElse: () => type == TransactionType.income
              ? CategoryFamily.income
              : CategoryFamily.commitments));
}

/// Colours for the slices of a category chart, in order: each category takes
/// its family colour, so the chart and the badges speak one language. When
/// several categories share a family, later ones are shifted lighter or
/// darker so neighbouring slices stay apart.
List<Color> chartColorsFor(List<String> categories, TransactionType type,
    Map<String, CustomCategoryLook> looks, DsColors c, Brightness b) {
  final Map<CategoryFamily, int> seen = <CategoryFamily, int>{};
  return <Color>[
    for (final String cat in categories)
      () {
        final CategoryFamily f = resolveCategoryStyle(cat, type, looks).family;
        final int n = seen[f] = (seen[f] ?? -1) + 1;
        final Color base = familyColor(f, c, b);
        if (n == 0) return base;
        final HSLColor h = HSLColor.fromColor(base);
        // 2nd lighter, 3rd darker, 4th lighter still...
        final double step = 0.12 * ((n + 1) ~/ 2) * (n.isOdd ? 1 : -1);
        return h.withLightness((h.lightness + step).clamp(0.2, 0.85)).toColor();
      }(),
  ];
}

/// Calm, theme-aware colour of a family: earthy, muted, and each hue far
/// enough from the next to tell apart at a glance. Deeper on light themes,
/// softer on dark ones.
Color familyColor(CategoryFamily f, DsColors c, Brightness b) {
  final bool dark = b == Brightness.dark;
  switch (f) {
    case CategoryFamily.basics:
      return dark ? const Color(0xFF8FB0D6) : const Color(0xFF597CA3);
    case CategoryFamily.food:
      return dark ? const Color(0xFFE39A6E) : const Color(0xFFB76334);
    case CategoryFamily.mobility:
      return dark ? const Color(0xFFA99AC9) : const Color(0xFF7A6A9E);
    case CategoryFamily.lifestyle:
      return dark ? const Color(0xFFD98BA8) : const Color(0xFFB8577A);
    case CategoryFamily.commitments:
      return dark ? const Color(0xFF8CC2AE) : const Color(0xFF568374);
    case CategoryFamily.income:
      return dark ? const Color(0xFF86C187) : const Color(0xFF4F8750);
    case CategoryFamily.incomePassive:
      return dark ? const Color(0xFFDDBF72) : const Color(0xFF927732);
    case CategoryFamily.incomeWork:
      return dark ? const Color(0xFF8FB0D6) : const Color(0xFF597CA3);
    case CategoryFamily.incomeGift:
      return dark ? const Color(0xFFD98BA8) : const Color(0xFFB8577A);
  }
}

/// The share of the family colour in a badge's background.
const double kBadgeTint = 0.18;

/// Round soft badge: outline icon on an 18% tint of the family colour. Income
/// carries a tiny arrow in its corner so it reads at a glance.
class CategoryBadge extends ConsumerWidget {
  const CategoryBadge({
    super.key,
    required this.category,
    required this.type,
    this.size = 40,
  });

  final String category;
  final TransactionType type;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DsColors c = context.dsColors;
    final CategoryStyle s =
        resolveCategoryStyle(category, type, ref.watch(categoryStylesProvider));
    final Color color = familyColor(s.family, c, Theme.of(context).brightness);
    final bool income = type == TransactionType.income;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: kBadgeTint),
            ),
            child: Icon(s.icon, color: color, size: size * 0.5),
          ),
          if (income)
            PositionedDirectional(
              end: -1,
              bottom: -1,
              child: Container(
                width: size * 0.36,
                height: size * 0.36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: familyColor(
                      CategoryFamily.income, c, Theme.of(context).brightness),
                  border: Border.all(color: c.surface, width: 1.5),
                ),
                child: Icon(Icons.south_west_rounded,
                    size: size * 0.22, color: c.onBrand),
              ),
            ),
        ],
      ),
    );
  }
}
