import 'package:smartbudget/core/config/app_config.dart';

/// Which legal document to render.
enum LegalDoc { privacy, terms }

/// One titled paragraph of a legal document.
class LegalSection {
  const LegalSection(this.heading, this.body);
  final String heading;
  final String body;
}

/// Plain-language legal content that accurately reflects how the app actually
/// handles data (local-first, optional cloud sync, no tracking). Kept here as
/// long-form prose rather than in the ARB files, and easy for the operator to
/// review/customize before launch.
abstract final class LegalContent {
  /// Bump when the wording changes materially (shown as "last updated").
  static const String lastUpdated = '2026-09-20';

  static String get _app => AppConfig.appName;
  static String get _brand => AppConfig.parentBrand;
  static String get _email => AppConfig.supportEmail;

  static List<LegalSection> sections(LegalDoc doc, {required bool ar}) =>
      switch (doc) {
        LegalDoc.privacy => ar ? _privacyAr : _privacyEn,
        LegalDoc.terms => ar ? _termsAr : _termsEn,
      };

  // ---- Privacy (English) ----
  static List<LegalSection> get _privacyEn => <LegalSection>[
        LegalSection(
          'Overview',
          'This policy explains what $_app stores, where it is stored, and the '
              'choices you have. In plain terms: your financial data is yours, '
              'it stays on your device by default, and we do not sell it or '
              'track you.',
        ),
        const LegalSection(
          'What we store',
          'Only the information you enter yourself: income, expenses, budgets, '
              'goals, custom categories, and your display preferences (theme, '
              'language, and base currency).',
        ),
        const LegalSection(
          'Where your data lives',
          'By default everything is saved locally in your browser on your '
              'device — no account is required and no financial data leaves your '
              'device. If the operator has enabled cloud sync and you sign in '
              'and choose to back up, a copy of your data is stored in the '
              'operator\'s Supabase database, tied to your account and protected '
              'by row-level security so that only you can read it.',
        ),
        const LegalSection(
          'Accounts and authentication',
          'When sign-in is enabled, your email address is used only to '
              'authenticate you (handled by Supabase). It is not used for '
              'advertising or shared for marketing.',
        ),
        const LegalSection(
          'Third-party data services',
          'To show live figures the app requests public market data: currency '
              'exchange rates (open.er-api.com) and crypto prices (CoinGecko). '
              'These requests contain only currency or asset symbols — never '
              'your personal or financial data. Optional receipt scanning uses '
              'an AI key that you provide; it is stored encrypted and used only '
              'to read the receipt image you submit.',
        ),
        const LegalSection(
          'What we do not do',
          'We do not sell or rent your data, show advertising, or run '
              'behavioural tracking or analytics on your financial activity.',
        ),
        const LegalSection(
          'Your controls',
          'You can export a full backup at any time, remove your data by '
              'clearing this site\'s storage in your browser, and — when cloud '
              'sync is enabled — sign out or overwrite your cloud backup.',
        ),
        LegalSection(
          'Changes and contact',
          'We may update this policy; the date shown above reflects the latest '
              'version. Questions about privacy: $_email.',
        ),
      ];

  // ---- Privacy (Arabic) ----
  static List<LegalSection> get _privacyAr => <LegalSection>[
        LegalSection(
          'نظرة عامة',
          'توضّح هذه السياسة ما الذي يخزّنه $_app وأين يُخزَّن وما الخيارات '
              'المتاحة لك. باختصار: بياناتك المالية ملكك، وتبقى على جهازك '
              'افتراضياً، ولا نبيعها ولا نتعقّبك.',
        ),
        const LegalSection(
          'ما الذي نخزّنه',
          'فقط المعلومات التي تُدخلها بنفسك: المداخيل والمصاريف والميزانيات '
              'والأهداف والفئات المخصّصة وتفضيلات العرض (السمة واللغة والعملة '
              'الأساسية).',
        ),
        const LegalSection(
          'أين تُحفظ بياناتك',
          'افتراضياً يُحفظ كل شيء محلياً في متصفحك على جهازك — لا حاجة لحساب '
              'ولا تغادر أي بيانات مالية جهازك. وإذا فعّل المشغّل المزامنة '
              'السحابية وسجّلت الدخول واخترت النسخ الاحتياطي، تُخزَّن نسخة من '
              'بياناتك في قاعدة بيانات Supabase الخاصة بالمشغّل، مرتبطة بحسابك '
              'ومحميّة بأمان على مستوى الصفوف بحيث لا يقرؤها سواك.',
        ),
        const LegalSection(
          'الحسابات وتسجيل الدخول',
          'عند تفعيل تسجيل الدخول، يُستخدم بريدك الإلكتروني للتحقق من هويتك فقط '
              '(عبر Supabase). لا يُستخدم للإعلانات ولا يُشارك لأغراض تسويقية.',
        ),
        const LegalSection(
          'خدمات البيانات الخارجية',
          'لعرض القيم الحيّة يطلب التطبيق بيانات سوق عامة: أسعار صرف العملات '
              '(open.er-api.com) وأسعار العملات الرقمية (CoinGecko). هذه الطلبات '
              'تحتوي على رموز العملات أو الأصول فقط — ولا تتضمّن أي بيانات شخصية '
              'أو مالية. أما مسح الإيصالات الاختياري فيستخدم مفتاح ذكاء اصطناعي '
              'توفّره أنت، ويُخزَّن مشفَّراً ويُستخدم فقط لقراءة صورة الإيصال التي '
              'ترسلها.',
        ),
        const LegalSection(
          'ما الذي لا نفعله',
          'لا نبيع بياناتك أو نؤجّرها، ولا نعرض إعلانات، ولا نُجري تعقّباً '
              'سلوكياً أو تحليلات على نشاطك المالي.',
        ),
        const LegalSection(
          'خياراتك وتحكّمك',
          'يمكنك تصدير نسخة احتياطية كاملة في أي وقت، وإزالة بياناتك بمسح تخزين '
              'هذا الموقع من متصفحك، و— عند تفعيل المزامنة السحابية — تسجيل '
              'الخروج أو استبدال نسختك السحابية.',
        ),
        LegalSection(
          'التحديثات والتواصل',
          'قد نحدّث هذه السياسة؛ ويعكس التاريخ أعلاه أحدث نسخة. لأي استفسار حول '
              'الخصوصية: $_email.',
        ),
      ];

  // ---- Terms (English) ----
  static List<LegalSection> get _termsEn => <LegalSection>[
        LegalSection(
          'Acceptance',
          'By using $_app you agree to these terms. If you do not agree, please '
              'do not use the app.',
        ),
        const LegalSection(
          'What the service is',
          'A personal budgeting and planning tool for tracking income, '
              'expenses, budgets, goals, and related insights.',
        ),
        const LegalSection(
          'Not financial or religious advice',
          'Calculations such as budgets, projections, and the Zakat estimate '
              'are informational tools to help you plan. They are not '
              'professional financial, tax, or religious advice. For religious '
              'obligations such as Zakat, verify with a qualified scholar; for '
              'financial decisions, consult a qualified advisor.',
        ),
        const LegalSection(
          'Your responsibilities',
          'You are responsible for the accuracy of the data you enter, for '
              'keeping your own backups, and for safeguarding any API keys you '
              'add to the app.',
        ),
        const LegalSection(
          'Availability and "as is"',
          'The app is provided "as is", without warranties of any kind. Live '
              'market data depends on third-party sources and may be delayed, '
              'incomplete, or unavailable. Features may change or be removed.',
        ),
        const LegalSection(
          'Acceptable use',
          'Do not misuse the service, attempt to break or bypass its security, '
              'or use it for any unlawful purpose.',
        ),
        LegalSection(
          'Brand and ownership',
          'The $_app name, the $_brand brand, and the app\'s design and code '
              'remain the property of their owner. Your data remains yours.',
        ),
        LegalSection(
          'Changes and contact',
          'These terms may change; continued use after an update means you '
              'accept the revised terms. Questions: $_email.',
        ),
      ];

  // ---- Terms (Arabic) ----
  static List<LegalSection> get _termsAr => <LegalSection>[
        LegalSection(
          'القبول',
          'باستخدامك $_app فإنك توافق على هذه الشروط. وإن لم توافق فيرجى عدم '
              'استخدام التطبيق.',
        ),
        const LegalSection(
          'ما هي الخدمة',
          'أداة لإدارة الميزانية والتخطيط الشخصي لتتبّع المداخيل والمصاريف '
              'والميزانيات والأهداف والرؤى المرتبطة بها.',
        ),
        const LegalSection(
          'ليست استشارة مالية أو دينية',
          'الحسابات مثل الميزانيات والإسقاطات وتقدير الزكاة هي أدوات إرشادية '
              'تساعدك على التخطيط، وليست استشارة مالية أو ضريبية أو دينية '
              'احترافية. وللالتزامات الدينية كالزكاة تحقّق من عالم مؤهّل، '
              'وللقرارات المالية استشر مختصاً مؤهّلاً.',
        ),
        const LegalSection(
          'مسؤولياتك',
          'أنت مسؤول عن دقّة البيانات التي تُدخلها، وعن الاحتفاظ بنسخك '
              'الاحتياطية، وعن حماية أي مفاتيح API تضيفها إلى التطبيق.',
        ),
        const LegalSection(
          'التوافر و"كما هي"',
          'يُقدَّم التطبيق "كما هو" دون أي ضمانات. تعتمد بيانات السوق الحيّة على '
              'مصادر خارجية وقد تكون متأخّرة أو ناقصة أو غير متاحة. وقد تتغيّر '
              'الميزات أو تُزال.',
        ),
        const LegalSection(
          'الاستخدام المقبول',
          'لا تُسِئ استخدام الخدمة، ولا تحاول اختراق أمانها أو تجاوزه، ولا '
              'تستخدمها لأي غرض غير قانوني.',
        ),
        LegalSection(
          'العلامة والملكية',
          'يبقى اسم $_app وعلامة $_brand وتصميم التطبيق وشيفرته ملكاً لصاحبها. '
              'وتبقى بياناتك ملكاً لك.',
        ),
        LegalSection(
          'التغييرات والتواصل',
          'قد تتغيّر هذه الشروط؛ ويعني استمرارك في الاستخدام بعد التحديث قبولك '
              'للشروط المعدّلة. لأي استفسار: $_email.',
        ),
      ];
}
