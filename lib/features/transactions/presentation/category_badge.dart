import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbudget/design_system/icons/sb_icons.dart';
import 'package:smartbudget/design_system/tokens/ds_colors.dart';
import 'package:smartbudget/features/transactions/application/category_icon_style.dart';
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

/// The colour of each built-in category. Every category keeps one colour
/// everywhere (its badge, the list, the chart), and the categories that
/// often sit side by side on a chart (food, housing, bills, transport,
/// restaurants...) have different ones. Expenses use warm tones only (reds,
/// oranges, pinks, browns); income uses a wider, mostly cool set led by
/// green. A category the user made takes the colour of its family.
class CategoryTone {
  const CategoryTone._(this.light, this.dark);

  /// Deeper on light themes (readable on its badge), softer on dark ones.
  final Color light;
  final Color dark;

  Color of(Brightness b) => b == Brightness.dark ? dark : light;
}

/// Warm tones for expenses.
abstract final class ExpenseTone {
  static const CategoryTone red =
      CategoryTone._(Color(0xFFC8332F), Color(0xFFF27D78));
  static const CategoryTone orange =
      CategoryTone._(Color(0xFFC2631F), Color(0xFFF0A868));
  static const CategoryTone amber =
      CategoryTone._(Color(0xFFA37508), Color(0xFFE3B341));
  static const CategoryTone brown =
      CategoryTone._(Color(0xFF8A5A2B), Color(0xFFB07C4F));
  static const CategoryTone rose =
      CategoryTone._(Color(0xFFBA3F78), Color(0xFFF09AC0));
  static const CategoryTone magenta =
      CategoryTone._(Color(0xFF9C2F8C), Color(0xFFD98BD0));
  static const CategoryTone wine =
      CategoryTone._(Color(0xFF7E2A42), Color(0xFFCC5F7C));
  static const CategoryTone plum =
      CategoryTone._(Color(0xFF6E3B8E), Color(0xFFA98CE0));

  static const List<CategoryTone> all = <CategoryTone>[
    red, orange, amber, brown, rose, magenta, wine, plum, //
  ];
}

/// Tones for income: green first (steady pay), then a varied set.
abstract final class IncomeTone {
  static const CategoryTone green =
      CategoryTone._(Color(0xFF2F8F3E), Color(0xFF7CC47F));
  static const CategoryTone blue =
      CategoryTone._(Color(0xFF3B6FD4), Color(0xFF8AB4F8));
  static const CategoryTone orange =
      CategoryTone._(Color(0xFFC2631F), Color(0xFFF0A868));
  static const CategoryTone purple =
      CategoryTone._(Color(0xFF7352BE), Color(0xFFB7A1F0));
  static const CategoryTone pink =
      CategoryTone._(Color(0xFFBA3F78), Color(0xFFF09AC0));
  static const CategoryTone slate =
      CategoryTone._(Color(0xFF55657B), Color(0xFFA3B1C6));
  static const CategoryTone teal =
      CategoryTone._(Color(0xFF0B8577), Color(0xFF4FB8A8));
  static const CategoryTone coral =
      CategoryTone._(Color(0xFFD1493F), Color(0xFFF08A80));
  static const CategoryTone olive =
      CategoryTone._(Color(0xFF6E7E1A), Color(0xFFB5C25A));
  static const CategoryTone sky =
      CategoryTone._(Color(0xFF1E88B8), Color(0xFF6CC0E5));
  static const CategoryTone brown =
      CategoryTone._(Color(0xFF9A5B2E), Color(0xFFC99470));
  static const CategoryTone gold =
      CategoryTone._(Color(0xFFA37508), Color(0xFFE3B341));

  static const List<CategoryTone> all = <CategoryTone>[
    green, blue, orange, purple, pink, slate, //
    teal, coral, olive, sky, brown, gold, //
  ];
}

const Map<String, CategoryTone> _expenseTones = <String, CategoryTone>{
  'الطعام': ExpenseTone.orange,
  'السكن': ExpenseTone.brown,
  'الفواتير': ExpenseTone.amber,
  'النقل': ExpenseTone.plum,
  'المطاعم': ExpenseTone.red,
  'الاتصالات والإنترنت': ExpenseTone.magenta,
  'التسوق': ExpenseTone.rose,
  'الوقود': ExpenseTone.wine,
  'الأقساط والقروض': ExpenseTone.brown,
  'الصحة': ExpenseTone.rose,
  'السيارة': ExpenseTone.plum,
  'الملابس': ExpenseTone.magenta,
  'الأطفال والعائلة': ExpenseTone.rose,
  'التعليم': ExpenseTone.plum,
  'الاشتراكات': ExpenseTone.magenta,
  'الترفيه': ExpenseTone.red,
  'المنظفات ومستلزمات المنزل': ExpenseTone.amber,
  'العناية الشخصية والتجميل': ExpenseTone.rose,
  'السفر': ExpenseTone.orange,
  'الهدايا': ExpenseTone.red,
  'الصيانة والإصلاح': ExpenseTone.brown,
  'التأمين': ExpenseTone.wine,
  'الإلكترونيات والأجهزة': ExpenseTone.plum,
  'المناسبات الاجتماعية': ExpenseTone.red,
  'الضرائب والرسوم': ExpenseTone.wine,
  'صدقة وتبرّعات': ExpenseTone.amber,
  'الأثاث والمنزل': ExpenseTone.brown,
  'الرياضة واللياقة': ExpenseTone.orange,
  'الادخار والاستثمار': ExpenseTone.amber,
  'زكاة': ExpenseTone.amber,
  'الحيوانات الأليفة': ExpenseTone.orange,
  'الطوارئ': ExpenseTone.red,
  'الحج والعمرة': ExpenseTone.brown,
  'الخدمات المهنية والقانونية': ExpenseTone.wine,
  'البرمجيات والأدوات الرقمية': ExpenseTone.plum,
  'أخرى': ExpenseTone.wine,
};

const Map<String, CategoryTone> _incomeTones = <String, CategoryTone>{
  'راتب أساسي': IncomeTone.green,
  'مكافآت وحوافز': IncomeTone.gold,
  'مكافأة نهاية الخدمة': IncomeTone.teal,
  'معاش تقاعدي': IncomeTone.slate,
  'عمل حر': IncomeTone.blue,
  'عمل بدوام جزئي': IncomeTone.sky,
  'عمولات': IncomeTone.purple,
  'أرباح تجارية': IncomeTone.orange,
  'تجارة إلكترونية': IncomeTone.coral,
  'دخل استثماري': IncomeTone.olive,
  'أرباح أسهم وتوزيعات': IncomeTone.brown,
  'أرباح العملات الرقمية': IncomeTone.orange,
  'إيجارات': IncomeTone.teal,
  'تأجير قصير الأمد': IncomeTone.teal,
  'بيع أصول أو ممتلكات': IncomeTone.brown,
  'محتوى رقمي وإبداعي': IncomeTone.pink,
  'استرجاع نقدي ومكافآت': IncomeTone.gold,
  'منحة أو إعانة': IncomeTone.pink,
  'ميراث': IncomeTone.slate,
  'استرداد أو تعويض': IncomeTone.sky,
  'هدايا': IncomeTone.pink,
  'زكاة أو صدقة مستلمة': IncomeTone.coral,
  'أخرى': IncomeTone.slate,
};

/// The built-in tone of [category], or null for a category the user made.
CategoryTone? categoryToneOf(String category, TransactionType type) =>
    (type == TransactionType.income ? _incomeTones : _expenseTones)[category];

/// The one colour of [category]: its own tone when built in, otherwise the
/// colour of its family (the one the user picked, or the neutral default).
Color categoryColor(String category, TransactionType type,
    Map<String, CustomCategoryLook> looks, DsColors c, Brightness b) {
  final CategoryTone? tone = categoryToneOf(category, type);
  if (tone != null) return tone.of(b);
  return familyColor(resolveCategoryStyle(category, type, looks).family, c, b);
}

/// Colours for the slices of a category chart, in order: each category's
/// own colour, as on its badge. Only when two categories on the ring share
/// a colour does the later one take a free tone instead (the one furthest
/// from every colour on the ring and from "Other"), so no two slices look
/// alike.
List<Color> chartColorsFor(List<String> categories, TransactionType type,
    Map<String, CustomCategoryLook> looks, DsColors c, Brightness b) {
  final List<Color> own = <Color>[
    for (final String cat in categories) categoryColor(cat, type, looks, c, b),
  ];
  final Color other = chartOtherColor(b);
  final List<Color> used = <Color>[];
  for (int i = 0; i < own.length; i++) {
    // Keep clear of what is already on the ring and of the slices to come.
    double distance(Color x) => <double>[
          for (final Color u in used) _colorDistance(x, u),
          for (int j = i + 1; j < own.length; j++) _colorDistance(x, own[j]),
          _colorDistance(x, other),
        ].reduce(math.min);
    final Color base = own[i];
    if (used.every((Color u) => _colorDistance(base, u) >= 15)) {
      used.add(base);
      continue;
    }
    final List<Color> free = <Color>[
      for (final CategoryTone t in type == TransactionType.income
          ? IncomeTone.all
          : ExpenseTone.all)
        if (!used.contains(t.of(b))) t.of(b),
    ];
    used.add(free.isEmpty
        ? base
        : free.reduce((Color a, Color e) => distance(e) > distance(a) ? e : a));
  }
  return used;
}

/// The "Other" slice: a quiet dusty rose, warm but softer than any category
/// colour, so it reads as "the rest" and is never taken for a category.
Color chartOtherColor(Brightness b) =>
    b == Brightness.dark ? const Color(0xFF6B5552) : const Color(0xFFC9A9A6);

/// How different two colours look to the eye (CIE76 distance in Lab).
/// Around 20 and above, two slices are easy to tell apart.
double _colorDistance(Color a, Color b) {
  final List<double> x = _lab(a), y = _lab(b);
  final double d0 = x[0] - y[0], d1 = x[1] - y[1], d2 = x[2] - y[2];
  return math.sqrt(d0 * d0 + d1 * d1 + d2 * d2);
}

List<double> _lab(Color c) {
  double lin(double u) =>
      u <= 0.04045 ? u / 12.92 : math.pow((u + 0.055) / 1.055, 2.4).toDouble();
  final double r = lin(c.r), g = lin(c.g), bl = lin(c.b);
  final double x = (0.4124 * r + 0.3576 * g + 0.1805 * bl) / 0.95047;
  final double y = 0.2126 * r + 0.7152 * g + 0.0722 * bl;
  final double z = (0.0193 * r + 0.1192 * g + 0.9505 * bl) / 1.08883;
  double f(double t) =>
      t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
  return <double>[
    116 * f(y) - 16,
    500 * (f(x) - f(y)),
    200 * (f(y) - f(z)),
  ];
}

/// The colour of a family, for categories the user made (deeper on light
/// themes, softer on dark ones). Expense families take warm tones; income
/// keeps green for steady pay, amber for passive income, blue for own work,
/// pink for gifts and aid.
Color familyColor(CategoryFamily f, DsColors c, Brightness b) {
  final bool dark = b == Brightness.dark;
  switch (f) {
    case CategoryFamily.basics:
      return ExpenseTone.brown.of(b);
    case CategoryFamily.food:
      return ExpenseTone.orange.of(b);
    case CategoryFamily.mobility:
      return ExpenseTone.plum.of(b);
    case CategoryFamily.lifestyle:
      return ExpenseTone.rose.of(b);
    case CategoryFamily.commitments:
      return ExpenseTone.wine.of(b);
    case CategoryFamily.income:
      return dark ? const Color(0xFF10B981) : const Color(0xFF059669);
    case CategoryFamily.incomePassive:
      return dark ? const Color(0xFFF5C15C) : const Color(0xFFA8680C);
    case CategoryFamily.incomeWork:
      return dark ? const Color(0xFF8AB4F8) : const Color(0xFF3B6FD4);
    case CategoryFamily.incomeGift:
      return dark ? const Color(0xFFF09AC0) : const Color(0xFFBA3F78);
  }
}

/// Optical balance of the icons. Material icons fill their square very
/// differently: a walking figure is narrow, a percent sign has a lot of air,
/// a gift box is dense. Each icon's ink was measured (its width, height and
/// how much of the box it fills) and the ones that look small are drawn a
/// little larger, the dense ones a little smaller, so a list of badges reads
/// as one even rhythm. Keyed by code point (Material icons only); anything
/// not listed is drawn at 1.0.
const Map<int, double> _opticalScale = <int, double>{
  0xee7a: 0.96,
  0xee99: 0.96,
  0xee9b: 0.98,
  0xeedd: 1.18,
  0xef06: 0.96,
  0xef2d: 0.92,
  0xef38: 1.02,
  0xef3d: 0.9,
  0xef4c: 1.08,
  0xef4f: 0.96,
  0xef56: 0.92,
  0xef8f: 0.96,
  0xefbb: 0.9,
  0xefc4: 0.98,
  0xefc6: 1.06,
  0xf010: 1.12,
  0xf01a: 1.08,
  0xf07a: 1.06,
  0xf085: 1.06,
  0xf0c0: 0.92,
  0xf0f2: 1.02,
  0xf107: 1.04,
  0xf151: 0.9,
  0xf17c: 1.04,
  0xf1be: 0.96,
  0xf1c2: 0.9,
  0xf266: 0.9,
  0xf285: 0.92,
  0xf2ef: 0.94,
  0xf316: 0.98,
  0xf325: 1.1,
  0xf339: 1.04,
  0xf33c: 0.96,
  0xf353: 1.06,
  0xf379: 1.08,
  0xf37d: 1.02,
  0xf37e: 0.94,
  0xf3a9: 0.92,
  0xf3bb: 1.02,
  0xf3ca: 1.06,
  0xf3ef: 0.94,
  0xf3fb: 0.96,
  0xf4a9: 0.92,
  0xf737: 1.08,
  0xf8d9: 1.18,
  0xf0099: 0.98,
  0xf01cf: 1.18,
  0xf0254: 1.1,
  0xf02bf: 1.04,
  0xf039c: 0.96,
  0xf054a: 1.06,
  0xf05d6: 0.9,
  0xf0636: 0.9,
  0xf063f: 0.96,
  0xf0695: 1.08,
  0xf06a4: 0.9,
};

/// The factor to draw [icon] at so that it looks as large as its neighbours.
double opticalScaleOf(IconData icon) => icon.fontFamily == 'MaterialIcons'
    ? (_opticalScale[icon.codePoint] ?? 1.0)
    : 1.0;

/// How large the icon is inside its badge, as a share of the badge: 10%
/// larger than before, the circle itself unchanged.
const double kBadgeGlyph = 0.55;

/// The share of the family colour in a badge's background.
const double kBadgeTint = 0.14;

/// Round soft badge: outline icon on a 14% tint of the family colour. Income
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
    // Plain: a quiet grey badge, the shape of the icon says which category.
    final bool plain = ref.watch(categoryIconsPlainProvider);
    final Color color = plain
        ? c.textMuted
        : categoryColor(category, type, ref.watch(categoryStylesProvider), c,
            Theme.of(context).brightness);
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
              color:
                  plain ? c.surfaceMuted : color.withValues(alpha: kBadgeTint),
            ),
            child: Icon(s.icon,
                color: color,
                size: size * kBadgeGlyph * opticalScaleOf(s.icon)),
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
