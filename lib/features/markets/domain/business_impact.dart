import 'package:flutter/foundation.dart';

/// A NEUTRAL note describing which sectors a commodity's price tends to touch.
/// This is economic context only — never investment advice, never buy/sell.
@immutable
class ImpactNote {
  const ImpactNote({required this.sectorsEn, required this.sectorsAr});
  final List<String> sectorsEn;
  final List<String> sectorsAr;
}

/// Static knowledge base of commodity → affected sectors (by commodity code).
/// Extending it is a data-only edit.
abstract final class BusinessImpact {
  static const Map<String, ImpactNote> _byCode = <String, ImpactNote>{
    'XAU': ImpactNote(
      sectorsEn: <String>['Jewelry', 'Savings & reserves', 'Hedging'],
      sectorsAr: <String>['المجوهرات', 'الادّخار والاحتياطيات', 'التحوّط'],
    ),
    'XAG': ImpactNote(
      sectorsEn: <String>['Jewelry', 'Electronics', 'Solar panels'],
      sectorsAr: <String>['المجوهرات', 'الإلكترونيات', 'الألواح الشمسية'],
    ),
    'XPT': ImpactNote(
      sectorsEn: <String>['Auto catalysts', 'Industry', 'Jewelry'],
      sectorsAr: <String>['محفّزات السيارات', 'الصناعة', 'المجوهرات'],
    ),
    'XPD': ImpactNote(
      sectorsEn: <String>['Auto catalysts', 'Electronics'],
      sectorsAr: <String>['محفّزات السيارات', 'الإلكترونيات'],
    ),
    'XCU': ImpactNote(
      sectorsEn: <String>['Electrical manufacturing', 'Construction', 'EV industry'],
      sectorsAr: <String>['التصنيع الكهربائي', 'البناء', 'صناعة السيارات الكهربائية'],
    ),
    'ALU': ImpactNote(
      sectorsEn: <String>['Packaging', 'Automotive', 'Construction'],
      sectorsAr: <String>['التغليف', 'السيارات', 'البناء'],
    ),
    'NIK': ImpactNote(
      sectorsEn: <String>['Stainless steel', 'EV batteries'],
      sectorsAr: <String>['الفولاذ المقاوم للصدأ', 'بطاريات السيارات الكهربائية'],
    ),
    'COB': ImpactNote(
      sectorsEn: <String>['EV batteries', 'Electronics'],
      sectorsAr: <String>['بطاريات السيارات الكهربائية', 'الإلكترونيات'],
    ),
    'IORE62': ImpactNote(
      sectorsEn: <String>['Steel production', 'Construction', 'Infrastructure'],
      sectorsAr: <String>['إنتاج الصلب', 'البناء', 'البنية التحتية'],
    ),
    'HRC': ImpactNote(
      sectorsEn: <String>['Automotive', 'Appliances', 'Manufacturing'],
      sectorsAr: <String>['السيارات', 'الأجهزة', 'التصنيع'],
    ),
    'REBAR': ImpactNote(
      sectorsEn: <String>['Construction', 'Infrastructure'],
      sectorsAr: <String>['البناء', 'البنية التحتية'],
    ),
    'BRENT': ImpactNote(
      sectorsEn: <String>['Transportation', 'Logistics', 'Manufacturing', 'Energy costs'],
      sectorsAr: <String>['النقل', 'اللوجستيات', 'التصنيع', 'تكاليف الطاقة'],
    ),
    'WTI': ImpactNote(
      sectorsEn: <String>['Transportation', 'Logistics', 'Energy costs'],
      sectorsAr: <String>['النقل', 'اللوجستيات', 'تكاليف الطاقة'],
    ),
    'NGAS': ImpactNote(
      sectorsEn: <String>['Power generation', 'Heating', 'Fertilizers'],
      sectorsAr: <String>['توليد الكهرباء', 'التدفئة', 'الأسمدة'],
    ),
    'WHEAT': ImpactNote(
      sectorsEn: <String>['Food prices', 'Bakeries', 'Import costs'],
      sectorsAr: <String>['أسعار الغذاء', 'المخابز', 'تكاليف الاستيراد'],
    ),
    'CORN': ImpactNote(
      sectorsEn: <String>['Animal feed', 'Food industry'],
      sectorsAr: <String>['علف الحيوانات', 'الصناعة الغذائية'],
    ),
  };

  static ImpactNote? forCode(String code) => _byCode[code];
}
