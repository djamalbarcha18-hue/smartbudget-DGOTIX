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
/// handles data (local-first, optional cloud sync, optional AI, optional paid
/// subscriptions). Kept here as long-form prose rather than in the ARB files,
/// and easy for the operator to review/customize before launch.
///
/// This is a plain-language template, not legal advice — the operator should
/// have it reviewed for their jurisdiction before relying on it.
abstract final class LegalContent {
  /// Bump when the wording changes materially (shown as "last updated").
  static const String lastUpdated = '2026-09-23';

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
              'track you. Some optional features (cloud sync, the AI assistant, '
              'cloud receipt scanning, and paid subscriptions) send specific '
              'data to a service only when you choose to use them, as described '
              'below.',
        ),
        const LegalSection(
          'What we store',
          'The information you enter yourself: income, expenses, budgets, '
              'goals, debts, custom categories, and your display preferences '
              '(theme, language, base currency). When you use optional online '
              'features we also keep a small amount of account data: your plan '
              'and subscription status, and per-period usage counts for the AI '
              'assistant and cloud receipt scanning — used only to apply your '
              'plan\'s limits. We do not store the content of your AI questions.',
        ),
        const LegalSection(
          'Where your data lives',
          'By default everything is saved locally in your browser on your '
              'device — no account is required and no financial data leaves your '
              'device. If cloud sync is enabled and you sign in and choose to '
              'back up, a copy of your data is stored in the operator\'s '
              'Supabase database, tied to your account and protected by '
              'row-level security so that only you can read it.',
        ),
        const LegalSection(
          'Accounts and authentication',
          'When sign-in is enabled, your email address is used only to '
              'authenticate you (handled by Supabase). It is not used for '
              'advertising or shared for marketing.',
        ),
        const LegalSection(
          'DGOTIX AI assistant',
          'The AI assistant is optional. When you send a question, the text of '
              'that question and a compact summary of the relevant figures are '
              'sent to an AI provider (Google Gemini, OpenAI, or Anthropic) to '
              'generate a reply — either through our secure server, which uses '
              'our own provider keys and records only usage metadata (never your '
              'question text or your figures), or, if you connect your own key, '
              'directly with that provider under your own account. Your inputs '
              'are processed under the chosen provider\'s policies; we do not use '
              'your data to train any model, and we do not store your prompts. '
              'AI answers are generated automatically and can be inaccurate.',
        ),
        const LegalSection(
          'Receipt scanning',
          'Scanning a receipt on your device happens locally and sends nothing. '
              'Optional cloud scanning sends the receipt image to an AI provider '
              '(through our server using our key, or your own key) only to '
              'extract the merchant, date, amount and category; we do not store '
              'the image.',
        ),
        const LegalSection(
          'Payments and subscriptions',
          'Paid plans are optional. If you subscribe, payment is processed by '
              'our payment provider (Paddle or PayPal). We never see or store '
              'your full card details. We store your plan, subscription status, '
              'renewal date, and the provider\'s subscription identifiers so we '
              'can give you the right access, plus a record of any promotional '
              'code you redeem. The payment provider processes your payment '
              'information under its own privacy policy.',
        ),
        const LegalSection(
          'Third-party services',
          'Depending on the features you use: Supabase (sign-in, cloud backup, '
              'and the server functions); Paddle and PayPal (payments); Google, '
              'OpenAI and Anthropic (the AI assistant and cloud receipt '
              'scanning); and public market-data sources for live figures — '
              'currency rates (open.er-api.com) and crypto prices (CoinGecko), '
              'whose requests contain only currency or asset symbols, never your '
              'personal or financial data. Any AI key you provide yourself is '
              'stored encrypted and never appears in logs.',
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
              'sync is enabled — sign out or overwrite your cloud backup. You can '
              'cancel a paid subscription at any time (see the Terms).',
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
              'افتراضياً، ولا نبيعها ولا نتعقّبك. بعض الميزات الاختيارية (المزامنة '
              'السحابية، ومساعد الذكاء الاصطناعي، ومسح الإيصالات السحابي، '
              'والاشتراكات المدفوعة) ترسل بيانات محدّدة إلى خدمةٍ ما فقط عندما '
              'تختار استخدامها، كما هو موضّح أدناه.',
        ),
        const LegalSection(
          'ما الذي نخزّنه',
          'المعلومات التي تُدخلها بنفسك: المداخيل والمصاريف والميزانيات والأهداف '
              'والديون والفئات المخصّصة وتفضيلات العرض (السمة واللغة والعملة '
              'الأساسية). وعند استخدام الميزات الاختيارية عبر الإنترنت نحتفظ أيضاً '
              'بقدرٍ يسير من بيانات الحساب: باقتك وحالة اشتراكك، وعدد مرات '
              'استخدامك للمساعد الذكي ولمسح الإيصالات السحابي في كل فترة — '
              'لتطبيق حدود باقتك فقط. ولا نخزّن محتوى أسئلتك للذكاء الاصطناعي.',
        ),
        const LegalSection(
          'أين تُحفظ بياناتك',
          'افتراضياً يُحفظ كل شيء محلياً في متصفحك على جهازك — لا حاجة لحساب '
              'ولا تغادر أي بيانات مالية جهازك. وإذا فُعّلت المزامنة السحابية '
              'وسجّلت الدخول واخترت النسخ الاحتياطي، تُخزَّن نسخة من بياناتك في '
              'قاعدة بيانات Supabase الخاصة بالمشغّل، مرتبطة بحسابك ومحميّة بأمان '
              'على مستوى الصفوف بحيث لا يقرؤها سواك.',
        ),
        const LegalSection(
          'الحسابات وتسجيل الدخول',
          'عند تفعيل تسجيل الدخول، يُستخدم بريدك الإلكتروني للتحقق من هويتك فقط '
              '(عبر Supabase). لا يُستخدم للإعلانات ولا يُشارك لأغراض تسويقية.',
        ),
        const LegalSection(
          'مساعد DGOTIX AI',
          'مساعد الذكاء الاصطناعي اختياري. عند إرسال سؤال، يُرسَل نصّ السؤال '
              'وملخّص موجز للأرقام المعنيّة إلى مزوّد ذكاء اصطناعي (Google Gemini '
              'أو OpenAI أو Anthropic) لتوليد الإجابة — إمّا عبر خادمنا الآمن الذي '
              'يستخدم مفاتيحنا نحن ويسجّل بيانات استخدام فقط (لا نصّ سؤالك ولا '
              'أرقامك)، أو — إن ربطت مفتاحك الخاص — مباشرةً مع ذلك المزوّد تحت '
              'حسابك أنت. تُعالَج مدخلاتك وفق سياسات المزوّد المختار؛ ولا نستخدم '
              'بياناتك لتدريب أي نموذج، ولا نخزّن مطالباتك. وإجابات الذكاء '
              'الاصطناعي مولّدة آلياً وقد تكون غير دقيقة.',
        ),
        const LegalSection(
          'مسح الإيصالات',
          'مسح الإيصال على جهازك يتم محلياً ولا يرسل شيئاً. أمّا المسح السحابي '
              'الاختياري فيُرسل صورة الإيصال إلى مزوّد ذكاء اصطناعي (عبر خادمنا '
              'بمفتاحنا، أو بمفتاحك الخاص) فقط لاستخراج اسم التاجر والتاريخ '
              'والمبلغ والفئة؛ ولا نخزّن الصورة.',
        ),
        const LegalSection(
          'المدفوعات والاشتراكات',
          'الباقات المدفوعة اختيارية. إذا اشتركت، تُعالَج عملية الدفع عبر مزوّد '
              'الدفع لدينا (Paddle أو PayPal). لا نرى ولا نخزّن بيانات بطاقتك '
              'الكاملة. نخزّن باقتك وحالة اشتراكك وتاريخ التجديد ومعرّفات الاشتراك '
              'لدى المزوّد لنمنحك الوصول الصحيح، إضافةً إلى سجلّ بأي كود ترويجي '
              'تستخدمه. ويعالج مزوّد الدفع معلومات دفعك وفق سياسة خصوصيته الخاصة.',
        ),
        const LegalSection(
          'خدمات الأطراف الخارجية',
          'حسب الميزات التي تستخدمها: Supabase (تسجيل الدخول والنسخ الاحتياطي '
              'السحابي ودوال الخادم)؛ وPaddle وPayPal (المدفوعات)؛ وGoogle '
              'وOpenAI وAnthropic (المساعد الذكي ومسح الإيصالات السحابي)؛ ومصادر '
              'بيانات سوق عامة للقيم الحيّة — أسعار العملات (open.er-api.com) '
              'وأسعار العملات الرقمية (CoinGecko)، وطلباتها تحتوي على رموز '
              'العملات أو الأصول فقط، لا أي بيانات شخصية أو مالية. وأي مفتاح ذكاء '
              'اصطناعي توفّره أنت يُخزَّن مشفَّراً ولا يظهر في السجلّات.',
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
              'الخروج أو استبدال نسختك السحابية. ويمكنك إلغاء الاشتراك المدفوع في '
              'أي وقت (انظر الشروط).',
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
              'expenses, budgets, goals, and related insights, with optional AI '
              'help, receipt scanning, cloud backup, and paid plans.',
        ),
        const LegalSection(
          'Not financial or religious advice',
          'Calculations such as budgets, projections, the Zakat estimate, and '
              'anything the AI assistant produces are informational tools to '
              'help you plan. They are not professional financial, tax, or '
              'religious advice. For religious obligations such as Zakat, verify '
              'with a qualified scholar; for financial decisions, consult a '
              'qualified advisor.',
        ),
        const LegalSection(
          'AI features',
          'The AI assistant and cloud receipt scanning produce automated output '
              'that may be inaccurate, incomplete, or out of date — always check '
              'anything important before acting on it. These features are '
              'optional and subject to fair-use limits that depend on your plan; '
              'they may be paused or changed to keep the service reliable.',
        ),
        const LegalSection(
          'Subscriptions, billing and renewals',
          'The core app is free. Paid plans (such as Basic and Pro) unlock '
              'higher limits and extra features at the prices shown in the app. '
              'A paid plan renews automatically each billing period (monthly or '
              'yearly) until you cancel. Payments are processed by our payment '
              'provider (Paddle or PayPal); applicable taxes may be added and '
              'are handled by that provider where it acts as merchant of record. '
              'You can cancel at any time and keep access until the end of the '
              'period you already paid for. Prices and plan features may change; '
              'we will show the current terms in the app before you subscribe.',
        ),
        const LegalSection(
          'Refunds',
          'Except where required by law, payments are generally non-refundable '
              'once a billing period has started, since you keep access until '
              'its end. Refund requests are handled according to the payment '
              'provider\'s policy and applicable consumer law — contact us at '
              'the address below and we will help.',
        ),
        const LegalSection(
          'Promotional codes',
          'Coupons and discount codes are optional and change only the price of '
              'a checkout (or grant a trial). Each code has its own conditions '
              '(validity period, usage limits, one per customer) and may be '
              'withdrawn or expire. They hold no cash value and cannot be '
              'combined unless stated.',
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
              'market data, AI, and payment features depend on third-party '
              'services and may be delayed, incomplete, or unavailable. An '
              'outage of an optional service never affects your ability to use '
              'the core budgeting tools. Features may change or be removed.',
        ),
        const LegalSection(
          'Acceptable use',
          'Do not misuse the service, attempt to break or bypass its security '
              'or plan limits, or use it for any unlawful purpose.',
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
              'والميزانيات والأهداف والرؤى المرتبطة بها، مع مساعدة اختيارية '
              'بالذكاء الاصطناعي ومسح الإيصالات والنسخ الاحتياطي السحابي والباقات '
              'المدفوعة.',
        ),
        const LegalSection(
          'ليست استشارة مالية أو دينية',
          'الحسابات مثل الميزانيات والإسقاطات وتقدير الزكاة وأي شيء يولّده '
              'المساعد الذكي هي أدوات إرشادية تساعدك على التخطيط، وليست استشارة '
              'مالية أو ضريبية أو دينية احترافية. وللالتزامات الدينية كالزكاة '
              'تحقّق من عالم مؤهّل، وللقرارات المالية استشر مختصاً مؤهّلاً.',
        ),
        const LegalSection(
          'ميزات الذكاء الاصطناعي',
          'ينتج المساعد الذكي ومسح الإيصالات السحابي مخرجات آلية قد تكون غير '
              'دقيقة أو ناقصة أو غير محدّثة — تحقّق دائماً من أي أمر مهم قبل '
              'التصرّف بناءً عليه. هذه الميزات اختيارية وتخضع لحدود استخدام عادل '
              'تعتمد على باقتك، وقد تُوقَف أو تُعدَّل للحفاظ على موثوقية الخدمة.',
        ),
        const LegalSection(
          'الاشتراكات والفوترة والتجديد',
          'التطبيق الأساسي مجاني. تفتح الباقات المدفوعة (مثل Basic وPro) حدوداً '
              'أعلى وميزات إضافية بالأسعار المعروضة في التطبيق. تتجدّد الباقة '
              'المدفوعة تلقائياً في كل فترة فوترة (شهرياً أو سنوياً) حتى تُلغيها. '
              'تُعالَج المدفوعات عبر مزوّد الدفع لدينا (Paddle أو PayPal)؛ وقد '
              'تُضاف ضرائب مطبّقة يتولّاها ذلك المزوّد حيث يكون البائع المسجَّل. '
              'يمكنك الإلغاء في أي وقت مع الاحتفاظ بالوصول حتى نهاية الفترة '
              'المدفوعة. وقد تتغيّر الأسعار وميزات الباقات؛ وسنعرض الشروط الحالية '
              'في التطبيق قبل اشتراكك.',
        ),
        const LegalSection(
          'الاستردادات',
          'باستثناء ما يوجبه القانون، تكون المدفوعات عادةً غير قابلة للاسترداد '
              'بعد بدء فترة الفوترة، لأنك تحتفظ بالوصول حتى نهايتها. تُعالَج طلبات '
              'الاسترداد وفق سياسة مزوّد الدفع وقانون حماية المستهلك المطبّق — '
              'تواصل معنا على العنوان أدناه وسنساعدك.',
        ),
        const LegalSection(
          'الأكواد الترويجية',
          'الكوبونات وأكواد الخصم اختيارية وتغيّر سعر الدفع فقط (أو تمنح فترة '
              'تجريبية). لكل كود شروطه الخاصة (مدة الصلاحية، حدود الاستخدام، '
              'واحد لكل عميل) وقد يُسحب أو تنتهي صلاحيته. ولا قيمة نقدية له ولا '
              'يُجمع مع غيره ما لم يُذكر ذلك.',
        ),
        const LegalSection(
          'مسؤولياتك',
          'أنت مسؤول عن دقّة البيانات التي تُدخلها، وعن الاحتفاظ بنسخك '
              'الاحتياطية، وعن حماية أي مفاتيح API تضيفها إلى التطبيق.',
        ),
        const LegalSection(
          'التوافر و"كما هي"',
          'يُقدَّم التطبيق "كما هو" دون أي ضمانات. تعتمد بيانات السوق الحيّة '
              'والذكاء الاصطناعي وميزات الدفع على خدمات خارجية وقد تكون متأخّرة أو '
              'ناقصة أو غير متاحة. وانقطاع أي خدمة اختيارية لا يؤثّر أبداً في '
              'قدرتك على استخدام أدوات الميزانية الأساسية. وقد تتغيّر الميزات أو '
              'تُزال.',
        ),
        const LegalSection(
          'الاستخدام المقبول',
          'لا تُسِئ استخدام الخدمة، ولا تحاول اختراق أمانها أو حدود باقتها أو '
              'تجاوزها، ولا تستخدمها لأي غرض غير قانوني.',
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
