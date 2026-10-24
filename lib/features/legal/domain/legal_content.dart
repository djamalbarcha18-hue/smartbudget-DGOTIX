import 'package:smartbudget/core/config/app_config.dart';
import 'package:smartbudget/core/env/app_env.dart';
import 'package:smartbudget/core/l10n/app_lang.dart';

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
  static const String lastUpdated = '2026-10-24';

  static String get _app => AppConfig.appName;
  static String get _brand => AppConfig.parentBrand;

  /// How to reach us, phrased to finish a sentence ("contact us …"). Uses the
  /// support email once one is configured, otherwise the in-app Help page — a
  /// placeholder address is never shown.
  static String get _reachEn => AppConfig.hasSupportEmail
      ? 'at ${AppConfig.supportEmail}'
      : 'through the Help & Support page in the app';
  static String get _reachAr => AppConfig.hasSupportEmail
      ? 'على ${AppConfig.supportEmail}'
      : 'عبر صفحة المساعدة والدعم في التطبيق';

  static String get _reachFr => AppConfig.hasSupportEmail
      ? 'à ${AppConfig.supportEmail}'
      : 'via la page Aide et assistance de l\'application';

  static String get _reachId => AppConfig.hasSupportEmail
      ? 'di ${AppConfig.supportEmail}'
      : 'melalui halaman Bantuan & Dukungan di aplikasi';

  static String get _reachEs => AppConfig.hasSupportEmail
      ? 'en ${AppConfig.supportEmail}'
      : 'desde la página Ayuda y soporte de la app';

  static String get _reachTr => AppConfig.hasSupportEmail
      ? '${AppConfig.supportEmail} adresinden'
      : 'uygulamadaki Yardım ve destek sayfasından';

  static String get _reachMs => AppConfig.hasSupportEmail
      ? 'di ${AppConfig.supportEmail}'
      : 'melalui halaman Bantuan & sokongan dalam aplikasi';

  static String get _reachUr => AppConfig.hasSupportEmail
      ? '${AppConfig.supportEmail} پر'
      : 'ایپ میں مدد اور سپورٹ کے صفحے کے ذریعے';

  static List<LegalSection> sections(LegalDoc doc, {required AppLang lang}) =>
      switch (doc) {
        LegalDoc.privacy => lang.pick(_privacyAr, _privacyEn,
            fr: _privacyFr, id: _privacyId, es: _privacyEs,
            tr: _privacyTr, ms: _privacyMs, ur: _privacyUr),
        LegalDoc.terms => lang.pick(_termsAr, _termsEn,
            fr: _termsFr, id: _termsId, es: _termsEs,
            tr: _termsTr, ms: _termsMs, ur: _termsUr),
      };

  // ---- Privacy (English) ----
  static List<LegalSection> get _privacyEn => <LegalSection>[
        LegalSection(
          'Overview',
          'This policy explains what $_app stores, where it is stored, and '
              'the choices you have. In short: your financial data is yours, it '
              'is saved on your device first, and we never sell it, show you ads '
              'or track you. A few optional features (sign-in and sync, DGOTIX '
              'AI, cloud receipt scanning and paid plans) send specific data to a'
              ' service only when you use them, as described below.',
        ),
        const LegalSection(
          'What we store',
          'The information you enter yourself: income, expenses, budgets, '
              'goals, debts, wallets, custom categories and your display '
              'preferences (theme, language, base currency). If you create an '
              'account we also keep your email address, your plan and '
              'subscription status, and per-period usage counts for DGOTIX AI and'
              ' cloud receipt scanning — used only to apply your plan\'s limits. '
              'We do not store your questions to DGOTIX AI or your receipt '
              'images; if you report an AI answer, we keep that answer and your '
              'optional note so we can review it.',
        ),
        const LegalSection(
          'Where your data lives',
          'Everything is saved on your device first (in the app, or in your '
              'browser for the web version), so the app works even without an '
              'account or a connection. If you sign in, your data also syncs '
              'automatically between your devices: a copy is stored in our '
              'database (hosted by Supabase), tied to your account and isolated '
              'so that only you can read it. You can turn sync off in Settings; '
              'your data then stays on this device only.',
        ),
        const LegalSection(
          'Your account and emails',
          'Your email address is used to sign you in and to send account '
              'emails, such as address confirmation and password reset (delivered'
              ' through Brevo). It is never used for advertising or shared for '
              'marketing. When you sign up or sign in, a quick human check '
              '(Cloudflare Turnstile) keeps automated abuse out.',
        ),
        const LegalSection(
          'DGOTIX AI',
          'DGOTIX AI is optional. When you ask a question, the text of that '
              'question and a summary of your figures (totals by month and '
              'category for up to 12 months, budgets, wallet balances, goals, '
              'recurring transactions, seasonal budgets and savings circles — '
              'amounts and dates only, never descriptions, notes or the names you'
              ' give things) are sent through our secure server to an AI provider'
              ' (Google Gemini, OpenAI or Anthropic) to generate the answer. Our '
              'server uses our own provider keys and records usage metadata only,'
              ' never your question or your figures. We do not use your data to '
              'train any model. Answers are generated automatically, so review '
              'important figures before you act on them.',
        ),
        const LegalSection(
          'Receipt scanning',
          'On Android, receipts can be read entirely on your device. Cloud '
              'scanning sends the receipt image through our secure server to an '
              'AI provider only to read the merchant, date, amount, items and '
              'category; the image is not stored.',
        ),
        const LegalSection(
          'Payments and subscriptions',
          'Paid plans are optional. You pay on the secure checkout of Whop '
              '(whop.com), our payment provider, or with PayPal if you choose '
              'it. They collect the billing details they need (such as your '
              'name, email, country and payment method) under their own privacy '
              'policies; we never see or store your full card details. We keep '
              'your plan, subscription status, renewal date and the payment '
              'provider\'s subscription identifiers so we can give you the '
              'right access, plus a record of any promotional code you redeem.',
        ),
        const LegalSection(
          'Service providers',
          'Depending on the features you use: Supabase (accounts, sync and '
              'our server functions); Whop and PayPal (payments); Brevo '
              '(account emails); Cloudflare Turnstile (the human check at '
              'sign-in); GitHub Pages (hosting of our website and web app); '
              'Google, OpenAI and Anthropic (DGOTIX AI and cloud receipt '
              'scanning); and public market-data sources for live figures — '
              'currency rates (open.er-api.com) and crypto prices (CoinGecko) — '
              'whose requests contain only currency or asset symbols, never '
              'your personal or financial data. Each provider processes data '
              'only to deliver its part of the service.',
        ),
        const LegalSection(
          'Security',
          'Connections to our services are encrypted (HTTPS). In our '
              'database, every user\'s records are isolated so that one account '
              'can never read another\'s. Server keys never reach the app, '
              'payment notifications are verified before they change anything, '
              'and you can add an app lock (PIN or fingerprint) on your device.',
        ),
        const LegalSection(
          'What we do not do',
          'We do not sell or rent your data, show advertising, or run '
              'behavioural tracking or analytics on your financial activity.',
        ),
        // Only trips are counted, so only with SmartTrip.
        if (AppEnv.smartTrip)
          const LegalSection(
            'Anonymous counts',
            'When you create a trip, the app sends only the words “a trip was '
                'planned”, and our server adds one to that day\'s total. Nothing '
                'else is sent or kept with it — no account, device, destination or '
                'amount — so the totals can\'t be linked to you. We use them only to'
                ' know how much the app is used and to show partners overall '
                'figures. You can turn this off in Settings, under Privacy.',
          ),
        const LegalSection(
          'How long we keep data',
          'Data on your device stays until you delete it or remove the app. '
              'Your account, synced data, usage counts and request metadata are '
              'kept while your account exists — only to run the service and '
              'apply your plan\'s limits — and are permanently erased when you '
              'delete it. Whop and PayPal keep the billing records they are '
              'legally required to keep.',
        ),
        LegalSection(
          'Your rights and controls',
          'You can view and correct your data in the app at any time, export '
              'a full backup, turn sync off, sign out, and delete your account '
              'with all its data (see below). You can cancel a paid subscription '
              'at any time (see the Terms). For any other request about your '
              'personal data — including access, correction, deletion or '
              'objection — contact us $_reachEn and we will answer promptly.',
        ),
        const LegalSection(
          'Deleting your account and data',
          'In the app or the web version, on any device, open Settings, then '
              'Account, then "Delete my account". This permanently deletes your '
              'account and everything stored for it on our servers (profile, '
              'synced data, subscription record and usage counts), and erases '
              'your data on that device. Cancel any paid subscription first. '
              'Deletion cannot be undone, so export a backup beforehand if you '
              'may want your data later.',
        ),
        LegalSection(
          'Age',
          '$_app is intended for people aged 16 and over. We do not knowingly'
              ' collect data from younger children; if you believe a child has '
              'created an account, contact us $_reachEn and we will delete it.',
        ),
        LegalSection(
          'Changes and contact',
          'We may update this policy; the date shown above reflects the '
              'latest version. For privacy questions, contact us $_reachEn.',
        ),
      ];

  // ---- Privacy (Arabic) ----
  static List<LegalSection> get _privacyAr => <LegalSection>[
        LegalSection(
          'نظرة عامة',
          'توضّح هذه السياسة ما الذي يخزّنه $_app وأين يُخزَّن وما الخيارات '
              'المتاحة لك. باختصار: بياناتك المالية ملكك، وتُحفظ أولاً على جهازك،'
              ' ولا نبيعها ولا نعرض عليك إعلانات ولا نتعقّبك. وبعض الميزات '
              'الاختيارية (تسجيل الدخول والمزامنة، وDGOTIX AI، ومسح الإيصالات '
              'السحابي، والباقات المدفوعة) ترسل بيانات محدّدة إلى خدمةٍ ما فقط '
              'عند استخدامها، كما هو موضّح أدناه.',
        ),
        const LegalSection(
          'ما الذي نخزّنه',
          'المعلومات التي تُدخلها بنفسك: المداخيل والمصاريف والميزانيات '
              'والأهداف والديون والمحافظ والفئات المخصّصة وتفضيلات العرض (السمة '
              'واللغة والعملة الأساسية). وإذا أنشأت حساباً نحتفظ أيضاً ببريدك '
              'الإلكتروني، وباقتك وحالة اشتراكك، وعدد مرات استخدامك لـ DGOTIX AI '
              'ولمسح الإيصالات السحابي في كل فترة — لتطبيق حدود باقتك فقط. ولا '
              'نخزّن أسئلتك لـ DGOTIX AI ولا صور إيصالاتك؛ وإن أبلغت عن إجابة '
              'فنحتفظ بتلك الإجابة وملاحظتك الاختيارية لمراجعتها.',
        ),
        const LegalSection(
          'أين تُحفظ بياناتك',
          'يُحفظ كل شيء أولاً على جهازك (في التطبيق، أو في متصفحك لنسخة '
              'الويب)، فيعمل التطبيق حتى دون حساب أو اتصال. وإذا سجّلت الدخول '
              'تُزامَن بياناتك تلقائياً بين أجهزتك: تُخزَّن نسخة منها في قاعدة '
              'بياناتنا (المستضافة لدى Supabase)، مرتبطة بحسابك ومعزولة بحيث لا '
              'يقرؤها سواك. ويمكنك إيقاف المزامنة من الإعدادات فتبقى بياناتك على '
              'هذا الجهاز فقط.',
        ),
        const LegalSection(
          'حسابك والرسائل',
          'يُستخدم بريدك الإلكتروني لتسجيل دخولك ولإرسال رسائل الحساب، مثل '
              'تأكيد البريد واستعادة كلمة المرور (عبر خدمة Brevo). ولا يُستخدم '
              'أبداً للإعلانات ولا يُشارك لأغراض تسويقية. وعند إنشاء الحساب أو '
              'تسجيل الدخول، يحمي تحقّقٌ بشري سريع (Cloudflare Turnstile) الخدمةَ'
              ' من الاستخدام الآلي المسيء.',
        ),
        const LegalSection(
          'DGOTIX AI',
          'DGOTIX AI اختياري. عند طرح سؤال، يُرسَل نصّ السؤال وملخّص لأرقامك '
              '(المجاميع حسب الشهر والفئة لمدة تصل إلى 12 شهراً، والميزانيات، '
              'وأرصدة المحافظ، والأهداف، والمعاملات المتكررة، وميزانيات المواسم، '
              'والجمعيات — مبالغ وتواريخ فقط، دون الأوصاف أو الملاحظات أو الأسماء '
              'التي تعطيها) عبر خادمنا الآمن إلى مزوّد ذكاء اصطناعي (Google '
              'Gemini أو OpenAI أو Anthropic) لتوليد الإجابة. ويستخدم خادمنا '
              'مفاتيحنا الخاصة ويسجّل بيانات الاستخدام فقط، لا سؤالك ولا أرقامك. '
              'ولا نستخدم بياناتك لتدريب أي نموذج. والإجابات مولّدة آلياً، فراجع '
              'الأرقام المهمة قبل أن تتصرّف بناءً عليها.',
        ),
        const LegalSection(
          'مسح الإيصالات',
          'على Android يمكن قراءة الإيصالات بالكامل على جهازك. أمّا المسح '
              'السحابي فيُرسل صورة الإيصال عبر خادمنا الآمن إلى مزوّد ذكاء '
              'اصطناعي فقط لقراءة اسم التاجر والتاريخ والمبلغ والمنتجات والفئة؛ '
              'ولا تُخزَّن الصورة.',
        ),
        const LegalSection(
          'المدفوعات والاشتراكات',
          'الباقات المدفوعة اختيارية. تدفع عبر صفحة الدفع الآمنة لدى Whop '
              '(whop.com)، مزوّد الدفع لدينا، أو عبر PayPal إن اخترته. ويجمع '
              'كلٌّ منهما بيانات الفوترة التي يحتاجها (مثل اسمك وبريدك وبلدك '
              'ووسيلة الدفع) وفق سياسة خصوصيته؛ ولا نرى ولا نخزّن بيانات بطاقتك '
              'الكاملة. ونحتفظ بباقتك وحالة اشتراكك وتاريخ التجديد ومعرّفات '
              'الاشتراك لدى مزوّد الدفع لنمنحك الوصول الصحيح، إضافةً إلى سجلّ '
              'بأي كود ترويجي تستخدمه.',
        ),
        const LegalSection(
          'مزوّدو الخدمات',
          'حسب الميزات التي تستخدمها: Supabase (الحسابات والمزامنة ودوال '
              'خادمنا)؛ وWhop وPayPal (المدفوعات)؛ وBrevo (رسائل الحساب)؛ '
              'وCloudflare Turnstile (التحقّق البشري عند الدخول)؛ وGitHub Pages '
              '(استضافة موقعنا وتطبيق الويب)؛ وGoogle وOpenAI وAnthropic '
              '(DGOTIX AI ومسح الإيصالات السحابي)؛ ومصادر بيانات سوق عامة للقيم '
              'الحيّة — أسعار العملات (open.er-api.com) وأسعار العملات الرقمية '
              '(CoinGecko) — وطلباتها تحتوي على رموز العملات أو الأصول فقط، لا '
              'أي بيانات شخصية أو مالية. ويعالج كل مزوّد البيانات فقط لتقديم '
              'الجزء الخاص به من الخدمة.',
        ),
        const LegalSection(
          'الأمان',
          'الاتصال بخدماتنا مشفّر (HTTPS). وفي قاعدة بياناتنا تُعزل سجلّات كل'
              ' مستخدم بحيث لا يستطيع أي حساب قراءة بيانات حساب آخر. ولا تصل '
              'مفاتيح الخادم إلى التطبيق أبداً، ويُتحقَّق من إشعارات الدفع قبل أن'
              ' تغيّر أي شيء، ويمكنك إضافة قفل للتطبيق (رمز أو بصمة) على جهازك.',
        ),
        const LegalSection(
          'ما الذي لا نفعله',
          'لا نبيع بياناتك أو نؤجّرها، ولا نعرض إعلانات، ولا نُجري تعقّباً '
              'سلوكياً أو تحليلات على نشاطك المالي.',
        ),
        // Only trips are counted, so only with SmartTrip.
        if (AppEnv.smartTrip)
          const LegalSection(
            'إحصاءات مجهولة',
            'عندما تُنشئ رحلة، يرسل التطبيق عبارة «أُنشئت رحلة» فقط، ويضيف '
                'خادمنا واحداً إلى مجموع ذلك اليوم. لا يُرسَل ولا يُحفظ معها أي شيء'
                ' آخر — لا حساب ولا جهاز ولا وجهة ولا مبلغ — فلا يمكن ربط هذه '
                'المجاميع بك. نستخدمها فقط لمعرفة مدى استخدام التطبيق ولعرض أرقام '
                'إجمالية على الشركاء. ويمكنك إيقاف ذلك من الإعدادات، في قسم '
                'الخصوصية.',
          ),
        const LegalSection(
          'مدة الاحتفاظ بالبيانات',
          'تبقى البيانات على جهازك حتى تحذفها أو تُزيل التطبيق. ويُحتفظ '
              'بحسابك وبياناتك المتزامنة وعدّادات الاستخدام والبيانات الوصفية '
              'للطلبات ما دام حسابك قائماً — لتشغيل الخدمة وتطبيق حدود باقتك '
              'فقط — وتُمحى نهائياً عند حذفه. ويحتفظ Whop وPayPal بسجلّات '
              'الفوترة التي يُلزمهما القانون بالاحتفاظ بها.',
        ),
        LegalSection(
          'حقوقك وتحكّمك',
          'يمكنك في أي وقت عرض بياناتك وتصحيحها داخل التطبيق، وتصدير نسخة '
              'احتياطية كاملة، وإيقاف المزامنة، وتسجيل الخروج، وحذف حسابك مع كل '
              'بياناته (انظر أدناه). ويمكنك إلغاء الاشتراك المدفوع في أي وقت '
              '(انظر الشروط). ولأي طلب آخر يخص بياناتك الشخصية — بما في ذلك '
              'الاطلاع أو التصحيح أو الحذف أو الاعتراض — تواصل معنا $_reachAr '
              'وسنجيبك سريعاً.',
        ),
        const LegalSection(
          'حذف حسابك وبياناتك',
          'من التطبيق أو نسخة الويب، على أي جهاز، افتح الإعدادات ثم «الحساب» '
              'ثم «حذف حسابي». يحذف ذلك نهائياً حسابك وكل ما خُزِّن له على '
              'خوادمنا (الملف الشخصي والبيانات المتزامنة وسجلّ الاشتراك وعدّادات '
              'الاستخدام)، ويمسح بياناتك على ذلك الجهاز. ألغِ أي اشتراك مدفوع '
              'أولاً. ولا يمكن التراجع عن الحذف، فصدّر نسخة احتياطية قبله إن كنت '
              'قد تحتاج بياناتك لاحقاً.',
        ),
        LegalSection(
          'السن',
          '$_app موجّه لمن بلغوا 16 سنة فأكثر. ولا نجمع عن علمٍ بيانات من هم '
              'أصغر سناً؛ وإن اعتقدت أن طفلاً أنشأ حساباً فتواصل معنا $_reachAr '
              'وسنحذفه.',
        ),
        LegalSection(
          'التحديثات والتواصل',
          'قد نحدّث هذه السياسة؛ ويعكس التاريخ أعلاه أحدث نسخة. ولأي استفسار '
              'حول الخصوصية تواصل معنا $_reachAr.',
        ),
      ];

  // ---- Terms (English) ----
  static List<LegalSection> get _termsEn => <LegalSection>[
        LegalSection(
          'Acceptance',
          'By using $_app you agree to these terms. If you do not agree, '
              'please do not use the app.',
        ),
        LegalSection(
          'Who can use it',
          'You must be at least 16 years old to use $_app. If you create an '
              'account, keep your sign-in details safe; you are responsible for '
              'activity on your account.',
        ),
        const LegalSection(
          'What the service is',
          'A personal budgeting and planning tool for tracking income, '
              'expenses, budgets, goals and related insights, with optional AI '
              'help, receipt scanning, sync across devices and paid plans.',
        ),
        const LegalSection(
          'Planning tools, not professional advice',
          'Budgets, projections, the Zakat calculation and DGOTIX AI\'s '
              'answers are planning tools to help you decide. They are not '
              'professional financial, tax or religious advice. For religious '
              'obligations such as Zakat, confirm with a qualified scholar; for '
              'major financial decisions, consult a qualified advisor.',
        ),
        const LegalSection(
          'AI features',
          'DGOTIX AI and cloud receipt scanning produce automated results to '
              'save you time; review important figures before acting on them. '
              'These features are included within fair-use limits that depend on '
              'your plan, and may be adjusted to keep the service fast and '
              'reliable for everyone.',
        ),
        const LegalSection(
          'Subscriptions, billing and renewals',
          'The core app is free. Paid plans (Pro) unlock higher '
              'limits and extra features at the prices shown in the app. A paid '
              'plan renews automatically each billing period (monthly or '
              'yearly) until you cancel. Payments are processed by Whop, our '
              'payment provider (or by PayPal if you choose it); applicable '
              'taxes may be added and are always shown at checkout before you '
              'pay. You can cancel at any time and keep access until the end of '
              'the period you already paid for. If prices or plan features '
              'change, the current terms are always shown before you subscribe.',
        ),
        const LegalSection(
          'Our payment provider: Whop',
          'SmartBudget is sold by DGOTIX. Checkout and billing are handled '
              'by Whop (whop.com), which processes the payment on its secure '
              'checkout, shows the full price including any taxes before you '
              'pay, and sends your receipt. You can manage or cancel your '
              'subscription from the app (Plans → Manage).',
        ),
        LegalSection(
          'Refund policy',
          'Except where required by law, payments are generally '
              'non-refundable once a billing period has started, since you keep '
              'access until its end. You can cancel at any time to stop future '
              'renewals. For a refund request or any question about a charge, '
              'contact us $_reachEn: we review each request under applicable '
              'consumer law and issue approved refunds through Whop (or '
              'PayPal).',
        ),
        const LegalSection(
          'Promotional codes',
          'Coupons and discount codes are optional and change only the price '
              'of a checkout (or grant a trial). Each code has its own conditions'
              ' (validity period, usage limits, one per customer) and may be '
              'withdrawn or expire. They hold no cash value and cannot be '
              'combined unless stated.',
        ),
        const LegalSection(
          'Your data and backups',
          'You are responsible for the accuracy of the data you enter. To '
              'keep your data safe across devices, sign in to sync it, or export '
              'a backup regularly from Settings.',
        ),
        LegalSection(
          'Availability',
          'We work to keep $_app available and reliable. To the extent '
              'permitted by law, the app is provided "as is", without warranties '
              'of any kind. Live market data, AI and payments rely on third-party'
              ' services and may occasionally be delayed or unavailable; such an '
              'interruption never stops you from using the core budgeting tools, '
              'which also work offline. Features may evolve over time.',
        ),
        const LegalSection(
          'Limitation of liability',
          'To the extent permitted by law, we are not liable for indirect or '
              'consequential losses, or for decisions you make based on the '
              'app\'s figures. Nothing in these terms limits rights you have '
              'under consumer law that cannot be waived.',
        ),
        const LegalSection(
          'Acceptable use',
          'Do not misuse the service, attempt to break or bypass its security'
              ' or plan limits, or use it for any unlawful purpose.',
        ),
        LegalSection(
          'Ending your use',
          'You can stop using $_app and delete your account at any time. We '
              'may suspend an account that breaks these terms or puts the service'
              ' or other users at risk.',
        ),
        LegalSection(
          'Brand and ownership',
          'The $_app name, the $_brand brand, and the app\'s design and code '
              'remain the property of their owner. Your data remains yours.',
        ),
        LegalSection(
          'Changes and contact',
          'We may update these terms and show the date of the latest version;'
              ' continued use after an update means you accept the revised terms.'
              ' For questions, contact us $_reachEn.',
        ),
      ];

  // ---- Terms (Arabic) ----
  static List<LegalSection> get _termsAr => <LegalSection>[
        LegalSection(
          'القبول',
          'باستخدامك $_app فإنك توافق على هذه الشروط. وإن لم توافق عليها '
              'فيُرجى عدم استخدام التطبيق.',
        ),
        LegalSection(
          'من يمكنه الاستخدام',
          'يجب أن يكون عمرك 16 سنة على الأقل لاستخدام $_app. وإذا أنشأت '
              'حساباً فحافظ على سرّية بيانات دخولك؛ فأنت مسؤول عن النشاط الذي يتم'
              ' عبر حسابك.',
        ),
        const LegalSection(
          'ما هي الخدمة',
          'أداة شخصية لإعداد الميزانية والتخطيط، لتتبّع المداخيل والمصاريف '
              'والميزانيات والأهداف والرؤى المرتبطة بها، مع مساعدة اختيارية '
              'بالذكاء الاصطناعي، ومسح الإيصالات، والمزامنة بين الأجهزة، والباقات'
              ' المدفوعة.',
        ),
        const LegalSection(
          'أدوات تخطيط لا استشارة مهنية',
          'الميزانيات والتوقعات وحساب الزكاة وإجابات DGOTIX AI أدوات تخطيط '
              'تساعدك على اتخاذ قرارك، وليست استشارة مالية أو ضريبية أو دينية '
              'مهنية. وللالتزامات الدينية كالزكاة تأكّد من عالم مؤهّل، وللقرارات '
              'المالية الكبيرة استشر مختصاً مؤهّلاً.',
        ),
        const LegalSection(
          'ميزات الذكاء الاصطناعي',
          'يقدّم DGOTIX AI ومسح الإيصالات السحابي نتائج آلية توفّر وقتك؛ '
              'فراجع الأرقام المهمة قبل التصرّف بناءً عليها. وهذه الميزات مشمولة '
              'ضمن حدود استخدام عادل تعتمد على باقتك، وقد تُعدَّل للحفاظ على سرعة'
              ' الخدمة وموثوقيتها للجميع.',
        ),
        const LegalSection(
          'الاشتراكات والفوترة والتجديد',
          'التطبيق الأساسي مجاني. وتفتح الباقات المدفوعة (الاحترافية) '
              'حدوداً أعلى وميزات إضافية بالأسعار المعروضة في '
              'التطبيق. وتتجدّد الباقة المدفوعة تلقائياً في كل فترة فوترة '
              '(شهرياً أو سنوياً) حتى تُلغيها. تُعالَج المدفوعات عبر Whop، '
              'مزوّد الدفع لدينا (أو عبر PayPal إن اخترته)؛ وقد تُضاف ضرائب '
              'مطبّقة تُعرض دائماً في صفحة الدفع قبل أن تدفع. ويمكنك الإلغاء في '
              'أي وقت مع الاحتفاظ بالوصول حتى نهاية الفترة المدفوعة. وإذا '
              'تغيّرت الأسعار أو ميزات الباقات فستُعرض الشروط الحالية دائماً '
              'قبل اشتراكك.',
        ),
        const LegalSection(
          'مزوّد الدفع لدينا: Whop',
          'تبيع DGOTIX تطبيق SmartBudget. ويتولّى Whop (whop.com) الدفع '
              'والفوترة: يعالج الدفع عبر صفحته الآمنة، ويعرض السعر الكامل '
              'شاملاً أي ضرائب قبل أن تدفع، ويرسل إليك الإيصال. ويمكنك إدارة '
              'اشتراكك أو إلغاؤه من التطبيق (الباقات ← إدارة).',
        ),
        LegalSection(
          'سياسة الاسترجاع',
          'باستثناء ما يوجبه القانون، تكون المدفوعات عادةً غير قابلة '
              'للاسترداد بعد بدء فترة الفوترة، لأنك تحتفظ بالوصول حتى نهايتها. '
              'ويمكنك الإلغاء في أي وقت لإيقاف التجديدات القادمة. لطلب استرداد '
              'أو لأي سؤال عن عملية دفع، تواصل معنا $_reachAr: ندرس كل طلب وفق '
              'قانون حماية المستهلك المطبّق، ونُعيد المبالغ الموافَق عليها عبر '
              'Whop (أو PayPal).',
        ),
        const LegalSection(
          'الأكواد الترويجية',
          'الكوبونات وأكواد الخصم اختيارية وتغيّر سعر الدفع فقط (أو تمنح فترة'
              ' تجريبية). ولكل كود شروطه الخاصة (مدة الصلاحية، وحدود الاستخدام، '
              'وواحد لكل عميل) وقد يُسحب أو تنتهي صلاحيته. ولا قيمة نقدية له ولا '
              'يُجمع مع غيره ما لم يُذكر ذلك.',
        ),
        const LegalSection(
          'بياناتك ونسخك الاحتياطية',
          'أنت مسؤول عن دقّة البيانات التي تُدخلها. ولتبقى بياناتك في أمان '
              'بين أجهزتك، سجّل الدخول لمزامنتها، أو صدّر نسخة احتياطية بانتظام '
              'من الإعدادات.',
        ),
        LegalSection(
          'التوافر',
          'نعمل على أن يبقى $_app متاحاً وموثوقاً. وفي الحدود التي يسمح بها '
              'القانون، يُقدَّم التطبيق "كما هو" دون أي ضمانات. وتعتمد بيانات '
              'السوق الحيّة والذكاء الاصطناعي والمدفوعات على خدمات خارجية قد '
              'تتأخّر أو تتوقّف أحياناً؛ ولا يمنعك ذلك أبداً من استخدام أدوات '
              'الميزانية الأساسية، التي تعمل أيضاً دون إنترنت. وقد تتطوّر الميزات'
              ' مع الوقت.',
        ),
        const LegalSection(
          'حدود المسؤولية',
          'في الحدود التي يسمح بها القانون، لا نتحمّل المسؤولية عن الخسائر '
              'غير المباشرة أو التبعية، ولا عن القرارات التي تتخذها بناءً على '
              'أرقام التطبيق. ولا يحدّ أي شيء في هذه الشروط من حقوقك التي يكفلها '
              'قانون حماية المستهلك ولا يجوز التنازل عنها.',
        ),
        const LegalSection(
          'الاستخدام المقبول',
          'لا تُسِئ استخدام الخدمة، ولا تحاول اختراق أمانها أو حدود باقتها أو'
              ' تجاوزها، ولا تستخدمها لأي غرض غير قانوني.',
        ),
        LegalSection(
          'إنهاء الاستخدام',
          'يمكنك التوقّف عن استخدام $_app وحذف حسابك في أي وقت. ويجوز لنا '
              'تعليق أي حساب يخالف هذه الشروط أو يعرّض الخدمة أو المستخدمين '
              'الآخرين للخطر.',
        ),
        LegalSection(
          'العلامة والملكية',
          'يبقى اسم $_app وعلامة $_brand وتصميم التطبيق وشيفرته ملكاً '
              'لصاحبها. وتبقى بياناتك ملكاً لك.',
        ),
        LegalSection(
          'التغييرات والتواصل',
          'قد نحدّث هذه الشروط ونعرض تاريخ أحدث نسخة منها؛ ويعني استمرارك في '
              'الاستخدام بعد التحديث قبولك للشروط المعدّلة. ولأي استفسار تواصل '
              'معنا $_reachAr.',
        ),
      ];

  // ---- Privacy (French) ----
  static List<LegalSection> get _privacyFr => <LegalSection>[
        LegalSection(
          'Vue d\'ensemble',
          'Cette politique explique ce que $_app stocke, où ces données sont '
              'stockées et les choix dont vous disposez. En bref : vos données '
              'financières vous appartiennent, elles sont d\'abord enregistrées '
              'sur votre appareil, et nous ne les vendons jamais, ne vous '
              'montrons aucune publicité et ne vous pistons pas. Quelques '
              'fonctionnalités facultatives (connexion et synchronisation, DGOTIX'
              ' AI, scan des tickets dans le cloud et formules payantes) envoient'
              ' des données précises à un service uniquement lorsque vous les '
              'utilisez, comme décrit ci-dessous.',
        ),
        const LegalSection(
          'Ce que nous stockons',
          'Les informations que vous saisissez vous-même : revenus, dépenses,'
              ' budgets, objectifs, dettes, portefeuilles, catégories '
              'personnalisées et vos préférences d\'affichage (thème, langue, '
              'devise de base). Si vous créez un compte, nous conservons aussi '
              'votre adresse e-mail, votre formule et l\'état de votre '
              'abonnement, ainsi que des compteurs d\'utilisation par période '
              'pour DGOTIX AI et le scan des tickets dans le cloud, utilisés '
              'uniquement pour appliquer les limites de votre formule. Nous ne '
              'stockons ni vos questions à DGOTIX AI ni les images de vos '
              'tickets ; si vous signalez une réponse de l\'IA, nous conservons '
              'cette réponse et votre note facultative afin de l\'examiner.',
        ),
        const LegalSection(
          'Où se trouvent vos données',
          'Tout est d\'abord enregistré sur votre appareil (dans '
              'l\'application, ou dans votre navigateur pour la version web), de '
              'sorte que l\'application fonctionne même sans compte ni connexion.'
              ' Si vous vous connectez, vos données se synchronisent aussi '
              'automatiquement entre vos appareils : une copie est stockée dans '
              'notre base de données (hébergée par Supabase), liée à votre compte'
              ' et isolée afin que vous seul puissiez la lire. Vous pouvez '
              'désactiver la synchronisation dans Paramètres ; vos données '
              'restent alors uniquement sur cet appareil.',
        ),
        const LegalSection(
          'Votre compte et les e-mails',
          'Votre adresse e-mail sert à vous connecter et à vous envoyer les '
              'e-mails liés au compte, comme la confirmation de l\'adresse et la '
              'réinitialisation du mot de passe (envoyés via Brevo). Elle n\'est '
              'jamais utilisée à des fins publicitaires ni partagée à des fins '
              'marketing. Lors de l\'inscription ou de la connexion, une '
              'vérification humaine rapide (Cloudflare Turnstile) écarte les abus'
              ' automatisés.',
        ),
        const LegalSection(
          'DGOTIX AI',
          'DGOTIX AI est facultatif. Lorsque vous posez une question, le '
              'texte de cette question et un résumé de vos chiffres (totaux par '
              'mois et par catégorie sur 12 mois au plus, budgets, soldes des '
              'portefeuilles, objectifs, transactions récurrentes, budgets '
              'saisonniers et tontines : uniquement des montants et des dates, '
              'jamais les descriptions, les notes ni les noms que vous donnez) '
              'sont envoyés via notre serveur sécurisé à un fournisseur d\'IA '
              '(Google Gemini, OpenAI ou Anthropic) pour générer la réponse. '
              'Notre serveur utilise nos propres clés de fournisseur et '
              'n\'enregistre que des métadonnées d\'utilisation, jamais votre '
              'question ni vos chiffres. Nous n\'utilisons pas vos données pour '
              'entraîner un modèle. Les réponses sont générées automatiquement : '
              'vérifiez les chiffres importants avant d\'agir.',
        ),
        const LegalSection(
          'Scan des tickets',
          'Sur Android, les tickets peuvent être lus entièrement sur votre '
              'appareil. Le scan dans le cloud envoie l\'image du ticket via '
              'notre serveur sécurisé à un fournisseur d\'IA uniquement pour lire'
              ' le commerçant, la date, le montant, les articles et la '
              'catégorie ; l\'image n\'est pas conservée.',
        ),
        const LegalSection(
          'Paiements et abonnements',
          'Les formules payantes sont facultatives. Vous payez sur la page '
              'de paiement sécurisée de Whop (whop.com), notre prestataire de '
              'paiement, ou avec PayPal si vous le choisissez. Ils collectent '
              'les informations de facturation dont ils ont besoin (comme votre '
              'nom, votre e-mail, votre pays et votre moyen de paiement) selon '
              'leur propre politique de confidentialité ; nous ne voyons ni ne '
              'conservons jamais les détails complets de votre carte. Nous '
              'conservons votre formule, l\'état de votre abonnement, sa date '
              'de renouvellement et les identifiants d\'abonnement du '
              'prestataire de paiement pour vous donner le bon accès, ainsi '
              'qu\'une trace des codes promo que vous utilisez.',
        ),
        const LegalSection(
          'Prestataires de services',
          'Selon les fonctionnalités que vous utilisez : Supabase (comptes, '
              'synchronisation et fonctions de notre serveur) ; Whop et PayPal '
              '(paiements) ; Brevo (e-mails liés au compte) ; Cloudflare '
              'Turnstile (la vérification humaine à la connexion) ; GitHub '
              'Pages (hébergement de notre site et de l\'application web) ; '
              'Google, OpenAI et Anthropic (DGOTIX AI et scan des tickets dans '
              'le cloud) ; et des sources publiques de données de marché pour '
              'les chiffres en direct : taux de change (open.er-api.com) et '
              'cours des cryptomonnaies (CoinGecko), dont les requêtes ne '
              'contiennent que des symboles de devises ou d\'actifs, jamais vos '
              'données personnelles ou financières. Chaque prestataire ne '
              'traite les données que pour fournir sa part du service.',
        ),
        const LegalSection(
          'Sécurité',
          'Les connexions à nos services sont chiffrées (HTTPS). Dans notre '
              'base de données, les enregistrements de chaque utilisateur sont '
              'isolés afin qu\'un compte ne puisse jamais lire ceux d\'un autre. '
              'Les clés du serveur n\'atteignent jamais l\'application, les '
              'notifications de paiement sont vérifiées avant de modifier quoi '
              'que ce soit, et vous pouvez ajouter un verrouillage de '
              'l\'application (code PIN ou empreinte) sur votre appareil.',
        ),
        const LegalSection(
          'Ce que nous ne faisons pas',
          'Nous ne vendons ni ne louons vos données, n\'affichons aucune '
              'publicité et ne pratiquons aucun pistage comportemental ni aucune '
              'analyse de votre activité financière.',
        ),
        // Only trips are counted, so only with SmartTrip.
        if (AppEnv.smartTrip)
          const LegalSection(
            'Comptages anonymes',
            'Lorsque vous créez un voyage, l\'application envoie seulement « un '
                'voyage a été créé », et notre serveur ajoute un au total du jour. '
                'Rien d\'autre n\'est envoyé ni conservé avec — ni compte, ni '
                'appareil, ni destination, ni montant — ces totaux ne peuvent donc '
                'pas être reliés à vous. Nous les utilisons uniquement pour savoir '
                'dans quelle mesure l\'application est utilisée et pour montrer des '
                'chiffres globaux à nos partenaires. Vous pouvez désactiver cela '
                'dans Paramètres, rubrique Confidentialité.',
          ),
        const LegalSection(
          'Durée de conservation',
          'Les données sur votre appareil y restent jusqu\'à ce que vous '
              'les supprimiez ou désinstalliez l\'application. Votre compte, '
              'vos données synchronisées, vos compteurs d\'utilisation et les '
              'métadonnées des requêtes sont conservés tant que votre compte '
              'existe, uniquement pour faire fonctionner le service et '
              'appliquer les limites de votre formule, et sont définitivement '
              'effacés lorsque vous le supprimez. Whop et PayPal conservent les '
              'justificatifs de facturation qu\'ils sont légalement tenus de '
              'conserver.',
        ),
        LegalSection(
          'Vos droits et vos choix',
          'Vous pouvez à tout moment consulter et corriger vos données dans '
              'l\'application, exporter une sauvegarde complète, désactiver la '
              'synchronisation, vous déconnecter et supprimer votre compte avec '
              'toutes ses données (voir ci-dessous). Vous pouvez résilier un '
              'abonnement payant à tout moment (voir les Conditions). Pour toute '
              'autre demande concernant vos données personnelles, notamment '
              'l\'accès, la rectification, l\'effacement ou l\'opposition, '
              'contactez-nous $_reachFr et nous vous répondrons rapidement.',
        ),
        const LegalSection(
          'Supprimer votre compte et vos données',
          'Dans l\'application ou la version web, sur n\'importe quel '
              'appareil, ouvrez Paramètres, puis Compte, puis « Supprimer mon '
              'compte ». Cela supprime définitivement votre compte et tout ce qui'
              ' est stocké pour lui sur nos serveurs (profil, données '
              'synchronisées, enregistrement d\'abonnement et compteurs '
              'd\'utilisation), et efface vos données sur cet appareil. Résiliez '
              'd\'abord tout abonnement payant. La suppression est irréversible :'
              ' exportez une sauvegarde avant si vous pourriez avoir besoin de '
              'vos données plus tard.',
        ),
        LegalSection(
          'Âge',
          '$_app est destiné aux personnes âgées de 16 ans et plus. Nous ne '
              'collectons pas sciemment de données concernant des enfants plus '
              'jeunes ; si vous pensez qu\'un enfant a créé un compte, contactez-'
              'nous $_reachFr et nous le supprimerons.',
        ),
        LegalSection(
          'Modifications et contact',
          'Nous pouvons mettre à jour cette politique ; la date indiquée ci-'
              'dessus correspond à la dernière version. Pour toute question sur '
              'la confidentialité, contactez-nous $_reachFr.',
        ),
      ];

  // ---- Terms (French) ----
  static List<LegalSection> get _termsFr => <LegalSection>[
        LegalSection(
          'Acceptation',
          'En utilisant $_app, vous acceptez les présentes conditions. Si '
              'vous ne les acceptez pas, veuillez ne pas utiliser l\'application.',
        ),
        LegalSection(
          'Qui peut l\'utiliser',
          'Vous devez avoir au moins 16 ans pour utiliser $_app. Si vous '
              'créez un compte, gardez vos identifiants en sécurité ; vous êtes '
              'responsable de l\'activité de votre compte.',
        ),
        const LegalSection(
          'Nature du service',
          'Un outil personnel de budget et de planification pour suivre les '
              'revenus, les dépenses, les budgets, les objectifs et les analyses '
              'associées, avec en option une aide par IA, le scan des tickets, la'
              ' synchronisation entre appareils et des formules payantes.',
        ),
        const LegalSection(
          'Des outils de planification, pas un conseil professionnel',
          'Les budgets, les projections, le calcul de la zakat et les '
              'réponses de DGOTIX AI sont des outils de planification pour vous '
              'aider à décider. Ils ne constituent pas un conseil professionnel '
              'financier, fiscal ou religieux. Pour les obligations religieuses '
              'comme la zakat, confirmez auprès d\'un savant qualifié ; pour les '
              'décisions financières importantes, consultez un conseiller '
              'qualifié.',
        ),
        const LegalSection(
          'Fonctionnalités d\'IA',
          'DGOTIX AI et le scan des tickets dans le cloud produisent des '
              'résultats automatisés pour vous faire gagner du temps ; vérifiez '
              'les chiffres importants avant d\'agir. Ces fonctionnalités sont '
              'incluses dans des limites d\'usage raisonnable qui dépendent de '
              'votre formule, et peuvent être ajustées pour que le service reste '
              'rapide et fiable pour tous.',
        ),
        const LegalSection(
          'Abonnements, facturation et renouvellements',
          'L\'application de base est gratuite. Les formules payantes '
              '(Pro) débloquent des limites plus élevées et des '
              'fonctionnalités supplémentaires aux prix affichés dans '
              'l\'application. Une formule payante se renouvelle '
              'automatiquement à chaque période de facturation (mensuelle ou '
              'annuelle) jusqu\'à sa résiliation. Les paiements sont traités '
              'par Whop, notre prestataire de paiement (ou par PayPal si vous '
              'le choisissez) ; les taxes applicables peuvent s\'ajouter et '
              'sont toujours affichées avant le paiement. Vous pouvez résilier '
              'à tout moment et conserver l\'accès jusqu\'à la fin de la '
              'période déjà payée. Si les prix ou les fonctionnalités changent, '
              'les conditions en vigueur sont toujours affichées avant votre '
              'abonnement.',
        ),
        const LegalSection(
          'Notre prestataire de paiement : Whop',
          'SmartBudget est vendu par DGOTIX. Le paiement et la facturation '
              'sont assurés par Whop (whop.com), qui traite le paiement sur sa '
              'page sécurisée, affiche le prix complet, taxes comprises, avant '
              'que vous payiez, et vous envoie le reçu. Vous pouvez gérer ou '
              'résilier votre abonnement depuis l\'application (Formules → '
              'Gérer).',
        ),
        LegalSection(
          'Politique de remboursement',
          'Sauf lorsque la loi l\'exige, les paiements ne sont en général '
              'pas remboursables une fois qu\'une période de facturation a '
              'commencé, puisque vous conservez l\'accès jusqu\'à sa fin. Vous '
              'pouvez résilier à tout moment pour arrêter les renouvellements '
              'futurs. Pour une demande de remboursement ou toute question sur '
              'un paiement, contactez-nous $_reachFr : nous examinons chaque '
              'demande selon le droit de la consommation applicable et '
              'effectuons les remboursements accordés via Whop (ou PayPal).',
        ),
        const LegalSection(
          'Codes promo',
          'Les coupons et codes de réduction sont facultatifs et ne modifient'
              ' que le prix d\'un paiement (ou offrent un essai). Chaque code a '
              'ses propres conditions (durée de validité, limites d\'utilisation,'
              ' un par client) et peut être retiré ou expirer. Ils n\'ont aucune '
              'valeur monétaire et ne sont pas cumulables, sauf mention '
              'contraire.',
        ),
        const LegalSection(
          'Vos données et sauvegardes',
          'Vous êtes responsable de l\'exactitude des données que vous '
              'saisissez. Pour protéger vos données d\'un appareil à l\'autre, '
              'connectez-vous pour les synchroniser, ou exportez régulièrement '
              'une sauvegarde depuis Paramètres.',
        ),
        LegalSection(
          'Disponibilité',
          'Nous faisons en sorte que $_app reste disponible et fiable. Dans '
              'la mesure permise par la loi, l\'application est fournie « en '
              'l\'état », sans garantie d\'aucune sorte. Les données de marché en'
              ' direct, l\'IA et les paiements reposent sur des services tiers et'
              ' peuvent parfois être retardés ou indisponibles ; une telle '
              'interruption ne vous empêche jamais d\'utiliser les outils de '
              'budget essentiels, qui fonctionnent aussi hors ligne. Les '
              'fonctionnalités peuvent évoluer avec le temps.',
        ),
        const LegalSection(
          'Limitation de responsabilité',
          'Dans la mesure permise par la loi, nous ne sommes pas responsables'
              ' des pertes indirectes ou consécutives, ni des décisions que vous '
              'prenez sur la base des chiffres de l\'application. Rien dans les '
              'présentes conditions ne limite les droits dont vous disposez en '
              'vertu du droit de la consommation et auxquels il ne peut être '
              'renoncé.',
        ),
        const LegalSection(
          'Utilisation acceptable',
          'N\'utilisez pas le service de manière abusive, ne tentez pas de '
              'contourner sa sécurité ou les limites des formules, et ne '
              'l\'utilisez à aucune fin illégale.',
        ),
        LegalSection(
          'Fin de l\'utilisation',
          'Vous pouvez cesser d\'utiliser $_app et supprimer votre compte à '
              'tout moment. Nous pouvons suspendre un compte qui enfreint les '
              'présentes conditions ou met en danger le service ou d\'autres '
              'utilisateurs.',
        ),
        LegalSection(
          'Marque et propriété',
          'Le nom $_app, la marque $_brand, ainsi que le design et le code de'
              ' l\'application restent la propriété de leur titulaire. Vos '
              'données restent les vôtres.',
        ),
        LegalSection(
          'Modifications et contact',
          'Nous pouvons mettre à jour ces conditions et indiquer la date de '
              'la dernière version ; continuer à utiliser l\'application après '
              'une mise à jour vaut acceptation des conditions révisées. Pour '
              'toute question, contactez-nous $_reachFr.',
        ),
      ];

  // ---- Privacy (Indonesian) ----
  static List<LegalSection> get _privacyId => <LegalSection>[
        LegalSection(
          'Ringkasan',
          'Kebijakan ini menjelaskan apa yang disimpan $_app, di mana '
              'disimpan, dan pilihan yang Anda miliki. Singkatnya: data keuangan '
              'Anda milik Anda, disimpan lebih dulu di perangkat Anda, dan kami '
              'tidak pernah menjualnya, menampilkan iklan, atau melacak Anda. '
              'Beberapa fitur opsional (masuk dan sinkron, DGOTIX AI, pemindaian '
              'struk cloud, dan paket berbayar) mengirim data tertentu ke suatu '
              'layanan hanya saat Anda memakainya, seperti dijelaskan di bawah.',
        ),
        const LegalSection(
          'Apa yang kami simpan',
          'Informasi yang Anda masukkan sendiri: pemasukan, pengeluaran, '
              'anggaran, target, utang, dompet, kategori kustom, dan preferensi '
              'tampilan (tema, bahasa, mata uang dasar). Jika Anda membuat akun, '
              'kami juga menyimpan alamat email, paket dan status langganan, '
              'serta hitungan pemakaian per periode untuk DGOTIX AI dan '
              'pemindaian struk cloud — hanya untuk menerapkan batas paket Anda. '
              'Kami tidak menyimpan pertanyaan Anda ke DGOTIX AI atau gambar '
              'struk Anda; jika Anda melaporkan jawaban AI, kami menyimpan '
              'jawaban itu dan catatan opsional Anda agar dapat ditinjau.',
        ),
        const LegalSection(
          'Tempat data Anda berada',
          'Semuanya disimpan lebih dulu di perangkat Anda (di aplikasi, atau '
              'di browser untuk versi web), sehingga aplikasi tetap berjalan '
              'tanpa akun atau koneksi. Jika Anda masuk, data juga otomatis '
              'tersinkron antarperangkat: salinannya disimpan di basis data kami '
              '(di-hosting oleh Supabase), terikat ke akun Anda dan terisolasi '
              'sehingga hanya Anda yang bisa membacanya. Anda bisa mematikan '
              'sinkron di Pengaturan; data Anda lalu hanya ada di perangkat ini.',
        ),
        const LegalSection(
          'Akun dan email Anda',
          'Alamat email dipakai untuk masuk dan mengirim email akun, seperti '
              'konfirmasi alamat dan pengaturan ulang kata sandi (dikirim melalui'
              ' Brevo). Email tidak pernah dipakai untuk iklan atau dibagikan '
              'untuk pemasaran. Saat mendaftar atau masuk, pemeriksaan manusia '
              'singkat (Cloudflare Turnstile) mencegah penyalahgunaan otomatis.',
        ),
        const LegalSection(
          'DGOTIX AI',
          'DGOTIX AI bersifat opsional. Saat Anda bertanya, teks pertanyaan '
              'dan ringkasan angka Anda (total per bulan dan kategori hingga 12 '
              'bulan, anggaran, saldo dompet, target, transaksi berulang, '
              'anggaran musiman, dan arisan — hanya jumlah dan tanggal, tidak '
              'pernah keterangan, catatan, atau nama yang Anda berikan) dikirim '
              'melalui server aman kami ke penyedia AI (Google Gemini, OpenAI, '
              'atau Anthropic) untuk membuat jawaban. Server kami memakai kunci '
              'penyedia milik kami dan hanya mencatat metadata pemakaian, tidak '
              'pernah pertanyaan atau angka Anda. Kami tidak memakai data Anda '
              'untuk melatih model apa pun. Jawaban dibuat otomatis, jadi periksa'
              ' angka penting sebelum bertindak.',
        ),
        const LegalSection(
          'Pemindaian struk',
          'Di Android, struk dapat dibaca sepenuhnya di perangkat Anda. '
              'Pemindaian cloud mengirim gambar struk melalui server aman kami ke'
              ' penyedia AI hanya untuk membaca nama toko, tanggal, jumlah, '
              'barang, dan kategori; gambarnya tidak disimpan.',
        ),
        const LegalSection(
          'Pembayaran dan langganan',
          'Paket berbayar bersifat opsional. Anda membayar di halaman '
              'pembayaran aman Whop (whop.com), penyedia pembayaran kami, atau '
              'dengan PayPal jika Anda memilihnya. Mereka mengumpulkan data '
              'penagihan yang diperlukan (seperti nama, email, negara, dan '
              'metode pembayaran) berdasarkan kebijakan privasi masing-masing; '
              'kami tidak pernah melihat atau menyimpan detail lengkap kartu '
              'Anda. Kami menyimpan paket, status langganan, tanggal '
              'perpanjangan, dan pengenal langganan dari penyedia pembayaran '
              'agar Anda mendapat akses yang tepat, serta catatan kode promo '
              'yang Anda tukarkan.',
        ),
        const LegalSection(
          'Penyedia layanan',
          'Tergantung fitur yang Anda pakai: Supabase (akun, sinkron, dan '
              'fungsi server kami); Whop dan PayPal (pembayaran); Brevo (email '
              'akun); Cloudflare Turnstile (pemeriksaan manusia saat masuk); '
              'GitHub Pages (hosting situs dan aplikasi web kami); Google, '
              'OpenAI, dan Anthropic (DGOTIX AI dan pemindaian struk cloud); '
              'serta sumber data pasar publik untuk angka langsung — kurs mata '
              'uang (open.er-api.com) dan harga kripto (CoinGecko) — yang '
              'permintaannya hanya berisi simbol mata uang atau aset, tidak '
              'pernah data pribadi atau keuangan Anda. Setiap penyedia hanya '
              'memproses data untuk menjalankan bagian layanannya.',
        ),
        const LegalSection(
          'Keamanan',
          'Koneksi ke layanan kami dienkripsi (HTTPS). Di basis data kami, '
              'catatan setiap pengguna terisolasi sehingga satu akun tidak pernah'
              ' bisa membaca milik akun lain. Kunci server tidak pernah sampai ke'
              ' aplikasi, notifikasi pembayaran diverifikasi sebelum mengubah apa'
              ' pun, dan Anda bisa menambahkan kunci aplikasi (PIN atau sidik '
              'jari) di perangkat Anda.',
        ),
        const LegalSection(
          'Apa yang tidak kami lakukan',
          'Kami tidak menjual atau menyewakan data Anda, tidak menampilkan '
              'iklan, dan tidak melakukan pelacakan perilaku atau analitik atas '
              'aktivitas keuangan Anda.',
        ),
        // Only trips are counted, so only with SmartTrip.
        if (AppEnv.smartTrip)
          const LegalSection(
            'Hitungan anonim',
            'Saat Anda membuat perjalanan, aplikasi hanya mengirim kata '
                '“perjalanan dibuat”, dan server kami menambahkan satu ke total '
                'hari itu. Tidak ada hal lain yang dikirim atau disimpan bersamanya'
                ' — tanpa akun, perangkat, tujuan, atau jumlah — sehingga total '
                'tersebut tidak dapat dikaitkan dengan Anda. Kami memakainya hanya '
                'untuk mengetahui seberapa banyak aplikasi dipakai dan untuk '
                'menunjukkan angka keseluruhan kepada mitra. Anda dapat '
                'mematikannya di Pengaturan, bagian Privasi.',
          ),
        const LegalSection(
          'Berapa lama data disimpan',
          'Data di perangkat Anda tetap ada sampai Anda menghapusnya atau '
              'menghapus aplikasi. Akun, data tersinkron, hitungan pemakaian, '
              'dan metadata permintaan disimpan selama akun Anda ada — hanya '
              'untuk menjalankan layanan dan menerapkan batas paket — dan '
              'dihapus permanen saat Anda menghapus akun. Whop dan PayPal '
              'menyimpan catatan penagihan yang diwajibkan hukum.',
        ),
        LegalSection(
          'Hak dan kendali Anda',
          'Anda dapat melihat dan memperbaiki data di aplikasi kapan saja, '
              'mengekspor cadangan lengkap, mematikan sinkron, keluar, dan '
              'menghapus akun beserta semua datanya (lihat di bawah). Anda dapat '
              'membatalkan langganan berbayar kapan saja (lihat Ketentuan). Untuk'
              ' permintaan lain tentang data pribadi Anda — termasuk akses, '
              'perbaikan, penghapusan, atau keberatan — hubungi kami $_reachId '
              'dan kami akan segera menjawab.',
        ),
        const LegalSection(
          'Menghapus akun dan data Anda',
          'Di aplikasi atau versi web, di perangkat mana pun, buka '
              'Pengaturan, lalu Akun, lalu "Hapus akun saya". Ini menghapus '
              'permanen akun Anda dan semua yang tersimpan untuknya di server '
              'kami (profil, data tersinkron, catatan langganan, dan hitungan '
              'pemakaian), serta menghapus data Anda di perangkat itu. Batalkan '
              'dulu langganan berbayar. Penghapusan tidak dapat dibatalkan, jadi '
              'ekspor cadangan lebih dulu jika mungkin masih butuh data Anda.',
        ),
        LegalSection(
          'Usia',
          '$_app ditujukan untuk orang berusia 16 tahun ke atas. Kami tidak '
              'dengan sengaja mengumpulkan data anak di bawah usia itu; jika Anda'
              ' yakin seorang anak telah membuat akun, hubungi kami $_reachId dan'
              ' kami akan menghapusnya.',
        ),
        LegalSection(
          'Perubahan dan kontak',
          'Kami dapat memperbarui kebijakan ini; tanggal di atas menunjukkan '
              'versi terbaru. Untuk pertanyaan privasi, hubungi kami $_reachId.',
        ),
      ];

  // ---- Terms (Indonesian) ----
  static List<LegalSection> get _termsId => <LegalSection>[
        LegalSection(
          'Persetujuan',
          'Dengan memakai $_app, Anda menyetujui ketentuan ini. Jika tidak '
              'setuju, mohon tidak memakai aplikasi.',
        ),
        LegalSection(
          'Siapa yang boleh memakai',
          'Anda harus berusia minimal 16 tahun untuk memakai $_app. Jika Anda'
              ' membuat akun, jaga keamanan data masuk Anda; Anda bertanggung '
              'jawab atas aktivitas di akun Anda.',
        ),
        const LegalSection(
          'Apa layanan ini',
          'Alat anggaran dan perencanaan pribadi untuk mencatat pemasukan, '
              'pengeluaran, anggaran, target, dan wawasan terkait, dengan bantuan'
              ' AI opsional, pemindaian struk, sinkron antarperangkat, dan paket '
              'berbayar.',
        ),
        const LegalSection(
          'Alat perencanaan, bukan nasihat profesional',
          'Anggaran, proyeksi, perhitungan zakat, dan jawaban DGOTIX AI '
              'adalah alat perencanaan untuk membantu Anda memutuskan. Itu bukan '
              'nasihat profesional di bidang keuangan, pajak, atau agama. Untuk '
              'kewajiban agama seperti zakat, pastikan kepada ulama yang '
              'berkompeten; untuk keputusan keuangan besar, konsultasikan dengan '
              'penasihat yang berkompeten.',
        ),
        const LegalSection(
          'Fitur AI',
          'DGOTIX AI dan pemindaian struk cloud memberi hasil otomatis untuk '
              'menghemat waktu Anda; periksa angka penting sebelum bertindak. '
              'Fitur ini disertakan dalam batas pemakaian wajar sesuai paket '
              'Anda, dan dapat disesuaikan agar layanan tetap cepat dan andal '
              'untuk semua.',
        ),
        const LegalSection(
          'Langganan, penagihan, dan perpanjangan',
          'Aplikasi inti gratis. Paket berbayar (Pro) membuka '
              'batas lebih tinggi dan fitur tambahan dengan harga yang tertera '
              'di aplikasi. Paket berbayar diperpanjang otomatis setiap periode '
              'penagihan (bulanan atau tahunan) sampai Anda membatalkannya. '
              'Pembayaran diproses oleh Whop, penyedia pembayaran kami (atau '
              'oleh PayPal jika Anda memilihnya); pajak yang berlaku dapat '
              'ditambahkan dan selalu ditampilkan sebelum Anda membayar. Anda '
              'bisa membatalkan kapan saja dan tetap punya akses sampai akhir '
              'periode yang sudah dibayar. Jika harga atau fitur paket berubah, '
              'ketentuan terbaru selalu ditampilkan sebelum Anda berlangganan.',
        ),
        const LegalSection(
          'Penyedia pembayaran kami: Whop',
          'SmartBudget dijual oleh DGOTIX. Pembayaran dan penagihan '
              'ditangani oleh Whop (whop.com), yang memproses pembayaran di '
              'halaman amannya, menampilkan harga lengkap termasuk pajak '
              'sebelum Anda membayar, dan mengirimkan tanda terima. Anda dapat '
              'mengelola atau membatalkan langganan dari aplikasi (Paket → '
              'Kelola).',
        ),
        LegalSection(
          'Kebijakan pengembalian dana',
          'Kecuali diwajibkan hukum, pembayaran umumnya tidak dapat '
              'dikembalikan setelah periode penagihan dimulai, karena Anda '
              'tetap punya akses sampai periode itu berakhir. Anda bisa '
              'membatalkan kapan saja untuk menghentikan perpanjangan '
              'berikutnya. Untuk permintaan pengembalian dana atau pertanyaan '
              'tentang tagihan, hubungi kami $_reachId: kami meninjau setiap '
              'permintaan sesuai hukum perlindungan konsumen yang berlaku dan '
              'mengembalikan dana yang disetujui melalui Whop (atau PayPal).',
        ),
        const LegalSection(
          'Kode promo',
          'Kupon dan kode diskon bersifat opsional dan hanya mengubah harga '
              'pembayaran (atau memberi masa uji coba). Setiap kode punya '
              'syaratnya sendiri (masa berlaku, batas pemakaian, satu per '
              'pelanggan) dan dapat ditarik atau kedaluwarsa. Kode tidak bernilai'
              ' tunai dan tidak dapat digabung kecuali disebutkan.',
        ),
        const LegalSection(
          'Data dan cadangan Anda',
          'Anda bertanggung jawab atas ketepatan data yang Anda masukkan. '
              'Agar data aman antarperangkat, masuk untuk menyinkronkannya, atau '
              'ekspor cadangan secara rutin dari Pengaturan.',
        ),
        LegalSection(
          'Ketersediaan',
          'Kami berupaya menjaga $_app tetap tersedia dan andal. Sejauh '
              'diizinkan hukum, aplikasi disediakan "sebagaimana adanya", tanpa '
              'jaminan apa pun. Data pasar langsung, AI, dan pembayaran '
              'bergantung pada layanan pihak ketiga dan sesekali bisa tertunda '
              'atau tidak tersedia; gangguan itu tidak pernah menghalangi Anda '
              'memakai fitur anggaran inti, yang juga berjalan offline. Fitur '
              'dapat berkembang dari waktu ke waktu.',
        ),
        const LegalSection(
          'Batasan tanggung jawab',
          'Sejauh diizinkan hukum, kami tidak bertanggung jawab atas kerugian'
              ' tidak langsung atau konsekuensial, atau atas keputusan yang Anda '
              'ambil berdasarkan angka di aplikasi. Tidak ada dalam ketentuan ini'
              ' yang membatasi hak Anda berdasarkan hukum perlindungan konsumen '
              'yang tidak dapat dikesampingkan.',
        ),
        const LegalSection(
          'Penggunaan yang wajar',
          'Jangan menyalahgunakan layanan, mencoba membobol atau mengakali '
              'keamanannya atau batas paket, atau memakainya untuk tujuan yang '
              'melanggar hukum.',
        ),
        LegalSection(
          'Mengakhiri penggunaan',
          'Anda bisa berhenti memakai $_app dan menghapus akun kapan saja. '
              'Kami dapat menangguhkan akun yang melanggar ketentuan ini atau '
              'membahayakan layanan atau pengguna lain.',
        ),
        LegalSection(
          'Merek dan kepemilikan',
          'Nama $_app, merek $_brand, serta desain dan kode aplikasi tetap '
              'menjadi milik pemiliknya. Data Anda tetap milik Anda.',
        ),
        LegalSection(
          'Perubahan dan kontak',
          'Kami dapat memperbarui ketentuan ini dan menampilkan tanggal versi'
              ' terbarunya; terus memakai aplikasi setelah pembaruan berarti Anda'
              ' menerima ketentuan yang direvisi. Untuk pertanyaan, hubungi kami '
              '$_reachId.',
        ),
      ];

  // ---- Privacy (Spanish) ----
  static List<LegalSection> get _privacyEs => <LegalSection>[
        LegalSection(
          'Resumen',
          'Esta política explica qué guarda $_app, dónde lo guarda y qué '
              'opciones tienes. En resumen: tus datos financieros son tuyos, se '
              'guardan primero en tu dispositivo y nunca los vendemos, ni te '
              'mostramos anuncios, ni te rastreamos. Algunas funciones opcionales'
              ' (inicio de sesión y sincronización, DGOTIX AI, escaneo de tickets'
              ' en la nube y planes de pago) envían datos concretos a un servicio'
              ' solo cuando las usas, como se explica abajo.',
        ),
        const LegalSection(
          'Qué guardamos',
          'La información que introduces tú: ingresos, gastos, presupuestos, '
              'metas, deudas, billeteras, categorías propias y tus preferencias '
              'de visualización (tema, idioma, moneda base). Si creas una cuenta,'
              ' guardamos también tu correo, tu plan y el estado de tu '
              'suscripción, y contadores de uso por periodo de DGOTIX AI y del '
              'escaneo en la nube, solo para aplicar los límites de tu plan. No '
              'guardamos tus preguntas a DGOTIX AI ni las imágenes de tus '
              'tickets; si reportas una respuesta de la IA, guardamos esa '
              'respuesta y tu nota opcional para revisarla.',
        ),
        const LegalSection(
          'Dónde están tus datos',
          'Todo se guarda primero en tu dispositivo (en la app, o en tu '
              'navegador en la versión web), así que la app funciona incluso sin '
              'cuenta ni conexión. Si inicias sesión, tus datos también se '
              'sincronizan solos entre tus dispositivos: una copia se guarda en '
              'nuestra base de datos (alojada en Supabase), vinculada a tu cuenta'
              ' y aislada para que solo tú puedas leerla. Puedes desactivar la '
              'sincronización en Ajustes; entonces tus datos quedan solo en ese '
              'dispositivo.',
        ),
        const LegalSection(
          'Tu cuenta y los correos',
          'Tu correo sirve para iniciar sesión y enviarte correos de la '
              'cuenta, como la confirmación de la dirección y el restablecimiento'
              ' de la contraseña (enviados a través de Brevo). Nunca se usa para '
              'publicidad ni se comparte con fines de marketing. Al registrarte o'
              ' iniciar sesión, una verificación humana rápida (Cloudflare '
              'Turnstile) frena los abusos automatizados.',
        ),
        const LegalSection(
          'DGOTIX AI',
          'DGOTIX AI es opcional. Cuando haces una pregunta, el texto de la '
              'pregunta y un resumen de tus cifras (totales por mes y categoría '
              'de hasta 12 meses, presupuestos, saldos de billeteras, metas, '
              'movimientos recurrentes, presupuestos de temporada y tandas: solo '
              'importes y fechas, nunca descripciones, notas ni los nombres que '
              'pones) se envían a través de nuestro servidor seguro a un '
              'proveedor de IA (Google Gemini, OpenAI o Anthropic) para generar '
              'la respuesta. Nuestro servidor usa nuestras propias claves de '
              'proveedor y solo registra metadatos de uso, nunca tu pregunta ni '
              'tus cifras. No usamos tus datos para entrenar ningún modelo. Las '
              'respuestas se generan automáticamente: revisa las cifras '
              'importantes antes de actuar.',
        ),
        const LegalSection(
          'Escaneo de tickets',
          'En Android, los tickets se pueden leer por completo en tu '
              'dispositivo. El escaneo en la nube envía la imagen del ticket a '
              'través de nuestro servidor seguro a un proveedor de IA solo para '
              'leer el comercio, la fecha, el importe, los artículos y la '
              'categoría; la imagen no se guarda.',
        ),
        const LegalSection(
          'Pagos y suscripciones',
          'Los planes de pago son opcionales. Pagas en la página de pago '
              'segura de Whop (whop.com), nuestro proveedor de pagos, o con '
              'PayPal si lo eliges. Ellos recogen los datos de facturación que '
              'necesitan (como tu nombre, correo, país y método de pago) según '
              'su propia política de privacidad; nunca vemos ni guardamos los '
              'datos completos de tu tarjeta. Guardamos tu plan, el estado de '
              'tu suscripción, la fecha de renovación y los identificadores de '
              'suscripción del proveedor de pagos para darte el acceso '
              'correcto, además de un registro de los códigos promocionales que '
              'canjees.',
        ),
        const LegalSection(
          'Proveedores de servicios',
          'Según las funciones que uses: Supabase (cuentas, sincronización '
              'y funciones de nuestro servidor); Whop y PayPal (pagos); Brevo '
              '(correos de la cuenta); Cloudflare Turnstile (la verificación '
              'humana al iniciar sesión); GitHub Pages (alojamiento de nuestra '
              'web y de la app web); Google, OpenAI y Anthropic (DGOTIX AI y '
              'escaneo en la nube); y fuentes públicas de datos de mercado para '
              'las cifras en directo, como tipos de cambio (open.er-api.com) y '
              'precios cripto (CoinGecko), cuyas solicitudes solo contienen '
              'símbolos de monedas o activos, nunca tus datos personales o '
              'financieros. Cada proveedor trata los datos solo para prestar su '
              'parte del servicio.',
        ),
        const LegalSection(
          'Seguridad',
          'Las conexiones con nuestros servicios están cifradas (HTTPS). En '
              'nuestra base de datos, los registros de cada usuario están '
              'aislados para que una cuenta nunca pueda leer los de otra. Las '
              'claves del servidor nunca llegan a la app, las notificaciones de '
              'pago se verifican antes de cambiar nada y puedes añadir un bloqueo'
              ' de la app (PIN o huella) en tu dispositivo.',
        ),
        const LegalSection(
          'Lo que no hacemos',
          'No vendemos ni alquilamos tus datos, no mostramos publicidad y no '
              'hacemos seguimiento del comportamiento ni analítica de tu '
              'actividad financiera.',
        ),
        // Only trips are counted, so only with SmartTrip.
        if (AppEnv.smartTrip)
          const LegalSection(
            'Recuentos anónimos',
            'Cuando creas un viaje, la app envía solo las palabras «se creó un '
                'viaje», y nuestro servidor suma uno al total de ese día. No se '
                'envía ni se guarda nada más con ello —ni cuenta, ni dispositivo, '
                'ni destino, ni importe—, así que los totales no pueden vincularse '
                'contigo. Los usamos solo para saber cuánto se usa la app y para '
                'mostrar cifras globales a los socios. Puedes desactivarlo en '
                'Ajustes, en Privacidad.',
          ),
        const LegalSection(
          'Cuánto tiempo guardamos los datos',
          'Los datos de tu dispositivo se quedan ahí hasta que los borres o '
              'desinstales la app. Tu cuenta, tus datos sincronizados, los '
              'contadores de uso y los metadatos de las solicitudes se guardan '
              'mientras exista tu cuenta, solo para prestar el servicio y '
              'aplicar los límites de tu plan, y se borran para siempre cuando '
              'la eliminas. Whop y PayPal conservan los registros de '
              'facturación que la ley les obliga a conservar.',
        ),
        LegalSection(
          'Tus derechos y opciones',
          'Puedes ver y corregir tus datos en la app cuando quieras, exportar'
              ' una copia completa, desactivar la sincronización, cerrar sesión y'
              ' eliminar tu cuenta con todos sus datos (ver abajo). Puedes '
              'cancelar una suscripción de pago en cualquier momento (ver los '
              'Términos). Para cualquier otra solicitud sobre tus datos '
              'personales, como acceso, rectificación, supresión u oposición, '
              'escríbenos $_reachEs y te responderemos sin demora.',
        ),
        const LegalSection(
          'Eliminar tu cuenta y tus datos',
          'En la app o en la versión web, en cualquier dispositivo, abre '
              'Ajustes, luego Cuenta, luego "Eliminar mi cuenta". Esto elimina '
              'para siempre tu cuenta y todo lo guardado para ella en nuestros '
              'servidores (perfil, datos sincronizados, registro de suscripción y'
              ' contadores de uso), y borra tus datos de ese dispositivo. Cancela'
              ' antes cualquier suscripción de pago. La eliminación no se puede '
              'deshacer, así que exporta una copia antes si puedes necesitar tus '
              'datos más adelante.',
        ),
        LegalSection(
          'Edad',
          '$_app está pensada para mayores de 16 años. No recogemos a '
              'sabiendas datos de menores de esa edad; si crees que un menor ha '
              'creado una cuenta, escríbenos $_reachEs y la eliminaremos.',
        ),
        LegalSection(
          'Cambios y contacto',
          'Podemos actualizar esta política; la fecha de arriba indica la '
              'última versión. Para dudas sobre privacidad, escríbenos $_reachEs.',
        ),
      ];

  // ---- Terms (Spanish) ----
  static List<LegalSection> get _termsEs => <LegalSection>[
        LegalSection(
          'Aceptación',
          'Al usar $_app aceptas estos términos. Si no estás de acuerdo, no '
              'uses la app.',
        ),
        LegalSection(
          'Quién puede usarla',
          'Debes tener al menos 16 años para usar $_app. Si creas una cuenta,'
              ' guarda bien tus datos de acceso; eres responsable de la actividad'
              ' de tu cuenta.',
        ),
        const LegalSection(
          'Qué es el servicio',
          'Una herramienta personal de presupuesto y planificación para '
              'seguir ingresos, gastos, presupuestos, metas y análisis '
              'relacionados, con ayuda opcional de IA, escaneo de tickets, '
              'sincronización entre dispositivos y planes de pago.',
        ),
        const LegalSection(
          'Herramientas de planificación, no asesoramiento profesional',
          'Los presupuestos, las proyecciones, el cálculo de la zakat y las '
              'respuestas de DGOTIX AI son herramientas de planificación para '
              'ayudarte a decidir. No son asesoramiento profesional financiero, '
              'fiscal ni religioso. Para obligaciones religiosas como la zakat, '
              'confírmalo con un erudito cualificado; para decisiones financieras'
              ' importantes, consulta a un asesor cualificado.',
        ),
        const LegalSection(
          'Funciones de IA',
          'DGOTIX AI y el escaneo de tickets en la nube ofrecen resultados '
              'automáticos para ahorrarte tiempo; revisa las cifras importantes '
              'antes de actuar. Estas funciones se incluyen con límites de uso '
              'razonable según tu plan, y pueden ajustarse para que el servicio '
              'siga siendo rápido y fiable para todos.',
        ),
        const LegalSection(
          'Suscripciones, facturación y renovaciones',
          'La app básica es gratis. Los planes de pago (Pro) '
              'desbloquean límites mayores y funciones extra a los precios que '
              'muestra la app. Un plan de pago se renueva automáticamente en '
              'cada periodo de facturación (mensual o anual) hasta que lo '
              'canceles. Los pagos los procesa Whop, nuestro proveedor de pagos '
              '(o PayPal si lo eliges); pueden añadirse los impuestos '
              'aplicables, que siempre se muestran antes de pagar. Puedes '
              'cancelar cuando quieras y conservar el acceso hasta el final del '
              'periodo ya pagado. Si cambian los precios o las funciones, los '
              'términos vigentes siempre se muestran antes de suscribirte.',
        ),
        const LegalSection(
          'Nuestro proveedor de pagos: Whop',
          'SmartBudget lo vende DGOTIX. El pago y la facturación los '
              'gestiona Whop (whop.com), que procesa el pago en su página '
              'segura, muestra el precio completo con los impuestos antes de '
              'que pagues y te envía el recibo. Puedes gestionar o cancelar tu '
              'suscripción desde la app (Planes → Gestionar).',
        ),
        LegalSection(
          'Política de reembolso',
          'Salvo que la ley lo exija, los pagos en general no son '
              'reembolsables una vez iniciado un periodo de facturación, ya que '
              'conservas el acceso hasta su final. Puedes cancelar cuando '
              'quieras para evitar futuras renovaciones. Para pedir un '
              'reembolso o preguntar por un cobro, escríbenos $_reachEs: '
              'revisamos cada solicitud según la normativa de consumo aplicable '
              'y devolvemos los importes aprobados a través de Whop (o PayPal).',
        ),
        const LegalSection(
          'Códigos promocionales',
          'Los cupones y códigos de descuento son opcionales y solo cambian '
              'el precio de un pago (o dan una prueba). Cada código tiene sus '
              'propias condiciones (vigencia, límites de uso, uno por cliente) y '
              'puede retirarse o caducar. No tienen valor en efectivo y no se '
              'pueden combinar salvo que se indique.',
        ),
        const LegalSection(
          'Tus datos y copias de seguridad',
          'Eres responsable de la exactitud de los datos que introduces. Para'
              ' proteger tus datos entre dispositivos, inicia sesión para '
              'sincronizarlos o exporta con regularidad una copia desde Ajustes.',
        ),
        LegalSection(
          'Disponibilidad',
          'Trabajamos para que $_app esté disponible y sea fiable. En la '
              'medida en que lo permita la ley, la app se ofrece "tal cual", sin '
              'garantías de ningún tipo. Los datos de mercado en directo, la IA y'
              ' los pagos dependen de servicios de terceros y a veces pueden '
              'retrasarse o no estar disponibles; esa interrupción nunca te '
              'impide usar las herramientas básicas de presupuesto, que también '
              'funcionan sin conexión. Las funciones pueden evolucionar con el '
              'tiempo.',
        ),
        const LegalSection(
          'Limitación de responsabilidad',
          'En la medida en que lo permita la ley, no somos responsables de '
              'pérdidas indirectas o consecuentes, ni de las decisiones que tomes'
              ' basándote en las cifras de la app. Nada en estos términos limita '
              'los derechos que te reconoce la normativa de consumo y a los que '
              'no se puede renunciar.',
        ),
        const LegalSection(
          'Uso aceptable',
          'No hagas un mal uso del servicio, no intentes romper ni saltarte '
              'su seguridad o los límites de los planes, ni lo uses para fines '
              'ilegales.',
        ),
        LegalSection(
          'Fin del uso',
          'Puedes dejar de usar $_app y eliminar tu cuenta cuando quieras. '
              'Podemos suspender una cuenta que incumpla estos términos o ponga '
              'en riesgo el servicio o a otros usuarios.',
        ),
        LegalSection(
          'Marca y propiedad',
          'El nombre $_app, la marca $_brand y el diseño y el código de la '
              'app siguen siendo propiedad de su titular. Tus datos siguen siendo'
              ' tuyos.',
        ),
        LegalSection(
          'Cambios y contacto',
          'Podemos actualizar estos términos e indicar la fecha de la última '
              'versión; seguir usando la app tras una actualización supone '
              'aceptar los términos revisados. Para cualquier duda, escríbenos '
              '$_reachEs.',
        ),
      ];

  // ---- Privacy (Turkish) ----
  static List<LegalSection> get _privacyTr => <LegalSection>[
        LegalSection(
          'Genel bakış',
          'Bu politika $_app uygulamasının neyi sakladığını, nerede '
              'sakladığını ve hangi seçeneklere sahip olduğunu açıklar. Kısacası:'
              ' finansal verilerin sana aittir, önce cihazına kaydedilir ve '
              'onları asla satmayız, sana reklam göstermeyiz ve seni izlemeyiz. '
              'Bazı isteğe bağlı özellikler (giriş ve senkronizasyon, DGOTIX AI, '
              'bulutta fiş tarama ve ücretli planlar) yalnızca onları '
              'kullandığında, aşağıda açıklandığı gibi belirli verileri bir '
              'hizmete gönderir.',
        ),
        const LegalSection(
          'Neleri saklıyoruz',
          'Kendin girdiğin bilgiler: gelir, giderler, bütçeler, hedefler, '
              'borçlar, cüzdanlar, özel kategoriler ve görüntüleme tercihlerin '
              '(tema, dil, ana para birimi). Bir hesap oluşturursan e-posta '
              'adresini, planını ve abonelik durumunu, ayrıca DGOTIX AI ve '
              'bulutta fiş tarama için dönem başına kullanım sayılarını da '
              'tutarız — yalnızca planının sınırlarını uygulamak için. DGOTIX '
              'AI\'a sorduğun soruları veya fiş görüntülerini saklamayız; bir '
              'yapay zekâ yanıtını bildirirsen, inceleyebilmek için o yanıtı ve '
              'isteğe bağlı notunu tutarız.',
        ),
        const LegalSection(
          'Verilerin nerede',
          'Her şey önce cihazına kaydedilir (uygulamada veya web sürümünde '
              'tarayıcında); böylece uygulama hesap veya bağlantı olmadan da '
              'çalışır. Giriş yaparsan verilerin cihazların arasında otomatik '
              'olarak da senkronize edilir: bir kopyası veritabanımızda '
              '(Supabase\'te barındırılan) saklanır, hesabına bağlıdır ve '
              'yalnızca senin okuyabileceğin şekilde yalıtılmıştır. '
              'Senkronizasyonu Ayarlar\'dan kapatabilirsin; o zaman verilerin '
              'yalnızca bu cihazda kalır.',
        ),
        const LegalSection(
          'Hesabın ve e-postalar',
          'E-posta adresin, giriş yapman ve adres onayı ile şifre sıfırlama '
              'gibi hesap e-postalarının gönderilmesi için kullanılır (Brevo '
              'üzerinden iletilir). Asla reklam için kullanılmaz veya pazarlama '
              'amacıyla paylaşılmaz. Kaydolurken veya giriş yaparken hızlı bir '
              'insan doğrulaması (Cloudflare Turnstile) otomatik kötüye kullanımı'
              ' engeller.',
        ),
        const LegalSection(
          'DGOTIX AI',
          'DGOTIX AI isteğe bağlıdır. Bir soru sorduğunda, o sorunun metni ve'
              ' rakamlarının bir özeti (12 aya kadar ay ve kategoriye göre '
              'toplamlar, bütçeler, cüzdan bakiyeleri, hedefler, tekrarlayan '
              'işlemler, sezon bütçeleri ve gün grupları — yalnızca tutarlar ve '
              'tarihler, asla açıklamalar, notlar veya verdiğin isimler değil) '
              'yanıtı üretmek için güvenli sunucumuz üzerinden bir yapay zekâ '
              'sağlayıcısına (Google Gemini, OpenAI veya Anthropic) gönderilir. '
              'Sunucumuz kendi sağlayıcı anahtarlarımızı kullanır ve yalnızca '
              'kullanım üst verilerini kaydeder, asla sorunu veya rakamlarını '
              'değil. Verilerini hiçbir modeli eğitmek için kullanmayız. Yanıtlar'
              ' otomatik üretilir; bu yüzden harekete geçmeden önce önemli '
              'rakamları gözden geçir.',
        ),
        const LegalSection(
          'Fiş tarama',
          'Android\'de fişler tamamen cihazında okunabilir. Bulutta tarama, '
              'fiş görüntüsünü yalnızca işletmeyi, tarihi, tutarı, kalemleri ve '
              'kategoriyi okumak için güvenli sunucumuz üzerinden bir yapay zekâ '
              'sağlayıcısına gönderir; görüntü saklanmaz.',
        ),
        const LegalSection(
          'Ödemeler ve abonelikler',
          'Ücretli planlar isteğe bağlıdır. Ödemeyi ödeme sağlayıcımız '
              'Whop\'un (whop.com) güvenli ödeme sayfasında ya da seçersen '
              'PayPal ile yaparsın. Bu sağlayıcılar ihtiyaç duydukları fatura '
              'bilgilerini (adın, e-postan, ülken ve ödeme yöntemin gibi) kendi '
              'gizlilik politikaları kapsamında toplar; tam kart bilgilerini '
              'asla görmeyiz veya saklamayız. Sana doğru erişimi verebilmek '
              'için planını, abonelik durumunu, yenileme tarihini ve ödeme '
              'sağlayıcısının abonelik kimliklerini, ayrıca kullandığın '
              'promosyon kodlarının kaydını tutarız.',
        ),
        const LegalSection(
          'Hizmet sağlayıcılar',
          'Kullandığın özelliklere bağlı olarak: Supabase (hesaplar, '
              'senkronizasyon ve sunucu işlevlerimiz); Whop ve PayPal '
              '(ödemeler); Brevo (hesap e-postaları); Cloudflare Turnstile '
              '(girişteki insan doğrulaması); GitHub Pages (web sitemizin ve '
              'web uygulamamızın barındırılması); Google, OpenAI ve Anthropic '
              '(DGOTIX AI ve bulutta fiş tarama); ve canlı rakamlar için '
              'herkese açık piyasa verisi kaynakları — döviz kurları '
              '(open.er-api.com) ve kripto fiyatları (CoinGecko) — bunlara '
              'giden istekler yalnızca para birimi veya varlık sembolleri '
              'içerir, asla kişisel veya finansal verilerini değil. Her '
              'sağlayıcı verileri yalnızca hizmetin kendi payına düşen kısmını '
              'sunmak için işler.',
        ),
        const LegalSection(
          'Güvenlik',
          'Hizmetlerimize olan bağlantılar şifrelenir (HTTPS). '
              'Veritabanımızda her kullanıcının kayıtları, bir hesabın '
              'diğerininkini asla okuyamayacağı şekilde yalıtılmıştır. Sunucu '
              'anahtarları uygulamaya asla ulaşmaz, ödeme bildirimleri bir şeyi '
              'değiştirmeden önce doğrulanır ve cihazına bir uygulama kilidi (PIN'
              ' veya parmak izi) ekleyebilirsin.',
        ),
        const LegalSection(
          'Yapmadıklarımız',
          'Verilerini satmayız veya kiralamayız, reklam göstermeyiz, finansal'
              ' etkinliğin üzerinde davranışsal izleme veya analiz yapmayız.',
        ),
        // Only trips are counted, so only with SmartTrip.
        if (AppEnv.smartTrip)
          const LegalSection(
            'Anonim sayımlar',
            'Bir seyahat oluşturduğunda uygulama yalnızca “bir seyahat '
                'oluşturuldu” bilgisini gönderir ve sunucumuz o günün toplamına bir'
                ' ekler. Bununla birlikte başka hiçbir şey gönderilmez veya '
                'saklanmaz — hesap, cihaz, varış yeri veya tutar yok — bu yüzden '
                'toplamlar seninle ilişkilendirilemez. Bunları yalnızca uygulamanın'
                ' ne kadar kullanıldığını bilmek ve iş ortaklarına genel rakamlar '
                'göstermek için kullanırız. Bunu Ayarlar\'da, Gizlilik bölümünden '
                'kapatabilirsin.',
          ),
        const LegalSection(
          'Verileri ne kadar tutuyoruz',
          'Cihazındaki veriler sen silene veya uygulamayı kaldırana kadar '
              'kalır. Hesabın, senkronize verilerin, kullanım sayıların ve '
              'istek üst verilerin hesabın var olduğu sürece tutulur — yalnızca '
              'hizmeti çalıştırmak ve planının sınırlarını uygulamak için — ve '
              'hesabını sildiğinde kalıcı olarak silinir. Whop ve PayPal, yasal '
              'olarak tutmaları gereken fatura kayıtlarını saklar.',
        ),
        LegalSection(
          'Hakların ve denetimlerin',
          'Verilerini uygulamada istediğin zaman görebilir ve düzeltebilir, '
              'tam bir yedek dışa aktarabilir, senkronizasyonu kapatabilir, çıkış'
              ' yapabilir ve hesabını tüm verileriyle birlikte silebilirsin '
              '(aşağıya bak). Ücretli bir aboneliği istediğin zaman iptal '
              'edebilirsin (Koşullar\'a bak). Kişisel verilerinle ilgili diğer '
              'her talep için — erişim, düzeltme, silme veya itiraz dahil — bize '
              '$_reachTr ulaş, hemen yanıt verelim.',
        ),
        const LegalSection(
          'Hesabını ve verilerini silme',
          'Uygulamada veya web sürümünde, herhangi bir cihazda Ayarlar\'ı, '
              'ardından Hesap\'ı, ardından "Hesabımı sil"i aç. Bu, hesabını ve '
              'sunucularımızda onun için saklanan her şeyi (profil, senkronize '
              'veriler, abonelik kaydı ve kullanım sayıları) kalıcı olarak siler '
              've o cihazdaki verilerini temizler. Önce ücretli aboneliğini iptal'
              ' et. Silme geri alınamaz; verilerini daha sonra isteyebileceksen '
              'önceden bir yedek dışa aktar.',
        ),
        LegalSection(
          'Yaş',
          '$_app 16 yaş ve üzeri kişiler için tasarlanmıştır. Daha küçük '
              'çocuklardan bilerek veri toplamayız; bir çocuğun hesap '
              'oluşturduğunu düşünüyorsan bize $_reachTr ulaş, hesabı silelim.',
        ),
        LegalSection(
          'Değişiklikler ve iletişim',
          'Bu politikayı güncelleyebiliriz; yukarıda gösterilen tarih en son '
              'sürümü yansıtır. Gizlilik soruların için bize $_reachTr ulaş.',
        ),
      ];

  // ---- Terms (Turkish) ----
  static List<LegalSection> get _termsTr => <LegalSection>[
        LegalSection(
          'Kabul',
          '$_app uygulamasını kullanarak bu koşulları kabul etmiş olursun. '
              'Kabul etmiyorsan lütfen uygulamayı kullanma.',
        ),
        LegalSection(
          'Kimler kullanabilir',
          '$_app uygulamasını kullanmak için en az 16 yaşında olmalısın. Bir '
              'hesap oluşturursan giriş bilgilerini güvende tut; hesabındaki '
              'etkinlikten sen sorumlusun.',
        ),
        const LegalSection(
          'Hizmet nedir',
          'Gelir, gider, bütçe, hedef ve ilgili içgörüleri takip etmek için '
              'kişisel bir bütçe ve planlama aracı; isteğe bağlı yapay zekâ '
              'yardımı, fiş tarama, cihazlar arası senkronizasyon ve ücretli '
              'planlarla.',
        ),
        const LegalSection(
          'Planlama araçları, profesyonel tavsiye değil',
          'Bütçeler, projeksiyonlar, zekât hesabı ve DGOTIX AI yanıtları '
              'karar vermene yardımcı olan planlama araçlarıdır. Profesyonel '
              'finansal, vergi veya dinî tavsiye değildir. Zekât gibi dinî '
              'yükümlülükler için yetkin bir âlimle teyit et; büyük finansal '
              'kararlar için yetkin bir danışmana başvur.',
        ),
        const LegalSection(
          'Yapay zekâ özellikleri',
          'DGOTIX AI ve bulutta fiş tarama, sana zaman kazandırmak için '
              'otomatik sonuçlar üretir; harekete geçmeden önce önemli rakamları '
              'gözden geçir. Bu özellikler planına bağlı adil kullanım sınırları '
              'içinde sunulur ve hizmeti herkes için hızlı ve güvenilir tutmak '
              'amacıyla ayarlanabilir.',
        ),
        const LegalSection(
          'Abonelikler, faturalandırma ve yenilemeler',
          'Temel uygulama ücretsizdir. Ücretli planlar (Pro), '
              'uygulamada gösterilen fiyatlarla daha yüksek sınırların ve ek '
              'özelliklerin kilidini açar. Ücretli bir plan, iptal edene kadar '
              'her faturalandırma döneminde (aylık veya yıllık) otomatik olarak '
              'yenilenir. Ödemeler ödeme sağlayıcımız Whop (ya da seçersen '
              'PayPal) tarafından işlenir; geçerli vergiler eklenebilir ve '
              'ödemeden önce her zaman gösterilir. İstediğin zaman iptal '
              'edebilir ve ödediğin dönemin sonuna kadar erişimini '
              'koruyabilirsin. Fiyatlar veya plan özellikleri değişirse, güncel '
              'koşullar abone olmadan önce her zaman gösterilir.',
        ),
        const LegalSection(
          'Ödeme sağlayıcımız: Whop',
          'SmartBudget\'ı DGOTIX satar. Ödeme ve faturalandırmayı Whop '
              '(whop.com) yürütür: ödemeyi güvenli sayfasında işler, ödemeden '
              'önce vergiler dahil tam fiyatı gösterir ve makbuzunu gönderir. '
              'Aboneliğini uygulamadan yönetebilir veya iptal edebilirsin '
              '(Planlar → Yönet).',
        ),
        LegalSection(
          'İade politikası',
          'Yasanın gerektirdiği durumlar dışında, bir faturalandırma dönemi '
              'başladıktan sonra ödemeler genellikle iade edilmez, çünkü '
              'dönemin sonuna kadar erişimin devam eder. Gelecekteki '
              'yenilemeleri durdurmak için istediğin zaman iptal edebilirsin. '
              'İade talebi veya bir ödemeyle ilgili soru için bize $_reachTr '
              'ulaş: her talebi geçerli tüketici hukukuna göre inceler, '
              'onaylanan iadeleri Whop (ya da PayPal) üzerinden yaparız.',
        ),
        const LegalSection(
          'Promosyon kodları',
          'Kuponlar ve indirim kodları isteğe bağlıdır ve yalnızca bir '
              'ödemenin fiyatını değiştirir (veya deneme süresi verir). Her kodun'
              ' kendi koşulları vardır (geçerlilik süresi, kullanım sınırları, '
              'müşteri başına bir) ve geri çekilebilir veya süresi dolabilir. '
              'Nakit değeri yoktur ve belirtilmedikçe birleştirilemez.',
        ),
        const LegalSection(
          'Verilerin ve yedeklerin',
          'Girdiğin verilerin doğruluğundan sen sorumlusun. Verilerini '
              'cihazlar arasında güvende tutmak için senkronize etmek üzere giriş'
              ' yap veya Ayarlar\'dan düzenli olarak yedek dışa aktar.',
        ),
        LegalSection(
          'Erişilebilirlik',
          '$_app uygulamasını erişilebilir ve güvenilir tutmak için '
              'çalışıyoruz. Yasanın izin verdiği ölçüde uygulama, hiçbir türde '
              'garanti olmaksızın "olduğu gibi" sunulur. Canlı piyasa verileri, '
              'yapay zekâ ve ödemeler üçüncü taraf hizmetlere dayanır ve zaman '
              'zaman gecikebilir veya kullanılamayabilir; böyle bir kesinti, '
              'çevrimdışı da çalışan temel bütçe araçlarını kullanmanı asla '
              'engellemez. Özellikler zamanla gelişebilir.',
        ),
        const LegalSection(
          'Sorumluluğun sınırlandırılması',
          'Yasanın izin verdiği ölçüde, dolaylı veya sonuç olarak ortaya '
              'çıkan kayıplardan ya da uygulamanın rakamlarına dayanarak verdiğin'
              ' kararlardan sorumlu değiliz. Bu koşullardaki hiçbir şey, tüketici'
              ' hukuku kapsamında feragat edilemeyen haklarını sınırlamaz.',
        ),
        const LegalSection(
          'Kabul edilebilir kullanım',
          'Hizmeti kötüye kullanma, güvenliğini veya plan sınırlarını kırmaya'
              ' ya da aşmaya çalışma veya hukuka aykırı herhangi bir amaçla '
              'kullanma.',
        ),
        LegalSection(
          'Kullanımı sonlandırma',
          '$_app uygulamasını kullanmayı istediğin zaman bırakabilir ve '
              'hesabını silebilirsin. Bu koşulları ihlal eden veya hizmeti ya da '
              'diğer kullanıcıları riske atan bir hesabı askıya alabiliriz.',
        ),
        LegalSection(
          'Marka ve mülkiyet',
          '$_app adı, $_brand markası ve uygulamanın tasarımı ile kodu '
              'sahibinin mülkiyetinde kalır. Verilerin sana ait kalır.',
        ),
        LegalSection(
          'Değişiklikler ve iletişim',
          'Bu koşulları güncelleyebilir ve en son sürümün tarihini '
              'gösterebiliriz; bir güncellemeden sonra kullanmaya devam etmek, '
              'revize edilmiş koşulları kabul ettiğin anlamına gelir. Soruların '
              'için bize $_reachTr ulaş.',
        ),
      ];

  // ---- Privacy (Malay) ----
  static List<LegalSection> get _privacyMs => <LegalSection>[
        LegalSection(
          'Gambaran keseluruhan',
          'Dasar ini menerangkan apa yang disimpan oleh $_app, di mana ia '
              'disimpan, dan pilihan yang anda ada. Ringkasnya: data kewangan '
              'anda milik anda, ia disimpan pada peranti anda dahulu, dan kami '
              'tidak pernah menjualnya, menunjukkan iklan kepada anda atau '
              'menjejak anda. Beberapa ciri pilihan (log masuk dan penyelarasan, '
              'DGOTIX AI, imbasan resit awan dan pelan berbayar) menghantar data '
              'tertentu kepada sesuatu perkhidmatan hanya apabila anda '
              'menggunakannya, seperti yang diterangkan di bawah.',
        ),
        const LegalSection(
          'Apa yang kami simpan',
          'Maklumat yang anda masukkan sendiri: pendapatan, perbelanjaan, '
              'bajet, matlamat, hutang, dompet, kategori tersuai dan pilihan '
              'paparan anda (tema, bahasa, mata wang asas). Jika anda mencipta '
              'akaun, kami juga menyimpan alamat e-mel anda, pelan dan status '
              'langganan anda, serta kiraan penggunaan setiap tempoh untuk DGOTIX'
              ' AI dan imbasan resit awan — hanya untuk menguatkuasakan had pelan'
              ' anda. Kami tidak menyimpan soalan anda kepada DGOTIX AI atau imej'
              ' resit anda; jika anda melaporkan jawapan AI, kami menyimpan '
              'jawapan itu dan nota pilihan anda supaya kami boleh menyemaknya.',
        ),
        const LegalSection(
          'Di mana data anda berada',
          'Semuanya disimpan pada peranti anda dahulu (dalam aplikasi, atau '
              'dalam pelayar anda untuk versi web), jadi aplikasi berfungsi '
              'walaupun tanpa akaun atau sambungan. Jika anda log masuk, data '
              'anda juga diselaraskan secara automatik antara peranti anda: satu '
              'salinan disimpan dalam pangkalan data kami (dihoskan oleh '
              'Supabase), terikat pada akaun anda dan diasingkan supaya hanya '
              'anda boleh membacanya. Anda boleh mematikan penyelarasan dalam '
              'Tetapan; data anda kemudian kekal pada peranti ini sahaja.',
        ),
        const LegalSection(
          'Akaun dan e-mel anda',
          'Alamat e-mel anda digunakan untuk log masuk dan menghantar e-mel '
              'akaun, seperti pengesahan alamat dan set semula kata laluan '
              '(dihantar melalui Brevo). Ia tidak pernah digunakan untuk '
              'pengiklanan atau dikongsi untuk pemasaran. Semasa mendaftar atau '
              'log masuk, semakan manusia yang pantas (Cloudflare Turnstile) '
              'menghalang penyalahgunaan automatik.',
        ),
        const LegalSection(
          'DGOTIX AI',
          'DGOTIX AI adalah pilihan. Apabila anda bertanya soalan, teks '
              'soalan itu dan ringkasan angka anda (jumlah mengikut bulan dan '
              'kategori sehingga 12 bulan, bajet, baki dompet, matlamat, '
              'transaksi berulang, bajet bermusim dan kumpulan kutu — jumlah dan '
              'tarikh sahaja, tidak pernah keterangan, nota atau nama yang anda '
              'berikan) dihantar melalui pelayan selamat kami kepada penyedia AI '
              '(Google Gemini, OpenAI atau Anthropic) untuk menjana jawapan. '
              'Pelayan kami menggunakan kunci penyedia kami sendiri dan hanya '
              'merekod metadata penggunaan, tidak pernah soalan atau angka anda. '
              'Kami tidak menggunakan data anda untuk melatih mana-mana model. '
              'Jawapan dijana secara automatik, jadi semak angka penting sebelum '
              'bertindak.',
        ),
        const LegalSection(
          'Imbasan resit',
          'Pada Android, resit boleh dibaca sepenuhnya pada peranti anda. '
              'Imbasan awan menghantar imej resit melalui pelayan selamat kami '
              'kepada penyedia AI hanya untuk membaca peniaga, tarikh, jumlah, '
              'item dan kategori; imej tidak disimpan.',
        ),
        const LegalSection(
          'Bayaran dan langganan',
          'Pelan berbayar adalah pilihan. Anda membayar di halaman '
              'pembayaran selamat Whop (whop.com), penyedia pembayaran kami, '
              'atau dengan PayPal jika anda memilihnya. Mereka mengumpul '
              'butiran pengebilan yang diperlukan (seperti nama, e-mel, negara '
              'dan kaedah bayaran anda) di bawah dasar privasi masing-masing; '
              'kami tidak pernah melihat atau menyimpan butiran penuh kad anda. '
              'Kami menyimpan pelan, status langganan, tarikh pembaharuan dan '
              'pengecam langganan penyedia pembayaran anda supaya kami boleh '
              'memberi akses yang betul, serta rekod mana-mana kod promosi yang '
              'anda tebus.',
        ),
        const LegalSection(
          'Penyedia perkhidmatan',
          'Bergantung pada ciri yang anda gunakan: Supabase (akaun, '
              'penyelarasan dan fungsi pelayan kami); Whop dan PayPal '
              '(bayaran); Brevo (e-mel akaun); Cloudflare Turnstile (semakan '
              'manusia semasa log masuk); GitHub Pages (pengehosan laman web '
              'dan aplikasi web kami); Google, OpenAI dan Anthropic (DGOTIX AI '
              'dan imbasan resit awan); dan sumber data pasaran awam untuk '
              'angka langsung — kadar mata wang (open.er-api.com) dan harga '
              'kripto (CoinGecko) — yang permintaannya hanya mengandungi simbol '
              'mata wang atau aset, tidak pernah data peribadi atau kewangan '
              'anda. Setiap penyedia memproses data hanya untuk menyampaikan '
              'bahagian perkhidmatannya.',
        ),
        const LegalSection(
          'Keselamatan',
          'Sambungan ke perkhidmatan kami disulitkan (HTTPS). Dalam pangkalan'
              ' data kami, rekod setiap pengguna diasingkan supaya satu akaun '
              'tidak pernah boleh membaca akaun lain. Kunci pelayan tidak pernah '
              'sampai ke aplikasi, pemberitahuan bayaran disahkan sebelum '
              'mengubah apa-apa, dan anda boleh menambah kunci aplikasi (PIN atau'
              ' cap jari) pada peranti anda.',
        ),
        const LegalSection(
          'Apa yang kami tidak lakukan',
          'Kami tidak menjual atau menyewakan data anda, menunjukkan iklan, '
              'atau menjalankan penjejakan tingkah laku atau analitik ke atas '
              'aktiviti kewangan anda.',
        ),
        // Only trips are counted, so only with SmartTrip.
        if (AppEnv.smartTrip)
          const LegalSection(
            'Kiraan tanpa nama',
            'Apabila anda mencipta perjalanan, aplikasi hanya menghantar '
                'perkataan “perjalanan dibuat”, dan pelayan kami menambah satu '
                'kepada jumlah hari itu. Tiada perkara lain dihantar atau disimpan '
                'bersamanya — tiada akaun, peranti, destinasi atau amaun — jadi '
                'jumlah itu tidak boleh dikaitkan dengan anda. Kami menggunakannya '
                'hanya untuk mengetahui sejauh mana aplikasi digunakan dan untuk '
                'menunjukkan angka keseluruhan kepada rakan kongsi. Anda boleh '
                'mematikannya dalam Tetapan, di bahagian Privasi.',
          ),
        const LegalSection(
          'Berapa lama kami menyimpan data',
          'Data pada peranti anda kekal sehingga anda memadamnya atau '
              'membuang aplikasi. Akaun, data yang diselaraskan, kiraan '
              'penggunaan dan metadata permintaan anda disimpan selagi akaun '
              'anda wujud — hanya untuk menjalankan perkhidmatan dan '
              'menguatkuasakan had pelan anda — dan dipadam secara kekal '
              'apabila anda memadamnya. Whop dan PayPal menyimpan rekod '
              'pengebilan yang diwajibkan oleh undang-undang.',
        ),
        LegalSection(
          'Hak dan kawalan anda',
          'Anda boleh melihat dan membetulkan data anda dalam aplikasi pada '
              'bila-bila masa, mengeksport sandaran penuh, mematikan '
              'penyelarasan, log keluar, dan memadam akaun anda bersama semua '
              'datanya (lihat di bawah). Anda boleh membatalkan langganan '
              'berbayar pada bila-bila masa (lihat Terma). Untuk sebarang '
              'permintaan lain tentang data peribadi anda — termasuk akses, '
              'pembetulan, pemadaman atau bantahan — hubungi kami $_reachMs dan '
              'kami akan menjawab dengan segera.',
        ),
        const LegalSection(
          'Memadam akaun dan data anda',
          'Dalam aplikasi atau versi web, pada mana-mana peranti, buka '
              'Tetapan, kemudian Akaun, kemudian "Padam akaun saya". Ini memadam '
              'akaun anda secara kekal bersama semua yang disimpan untuknya di '
              'pelayan kami (profil, data yang diselaraskan, rekod langganan dan '
              'kiraan penggunaan), dan memadam data anda pada peranti itu. '
              'Batalkan langganan berbayar dahulu. Pemadaman tidak boleh dibuat '
              'asal, jadi eksport sandaran terlebih dahulu jika anda mungkin '
              'mahukan data anda kemudian.',
        ),
        LegalSection(
          'Umur',
          '$_app ditujukan untuk mereka yang berumur 16 tahun ke atas. Kami '
              'tidak dengan sengaja mengumpul data daripada kanak-kanak yang '
              'lebih muda; jika anda percaya seorang kanak-kanak telah mencipta '
              'akaun, hubungi kami $_reachMs dan kami akan memadamnya.',
        ),
        LegalSection(
          'Perubahan dan hubungan',
          'Kami mungkin mengemas kini dasar ini; tarikh yang ditunjukkan di '
              'atas mencerminkan versi terkini. Untuk soalan privasi, hubungi '
              'kami $_reachMs.',
        ),
      ];

  // ---- Terms (Malay) ----
  static List<LegalSection> get _termsMs => <LegalSection>[
        LegalSection(
          'Penerimaan',
          'Dengan menggunakan $_app anda bersetuju dengan terma ini. Jika '
              'anda tidak bersetuju, sila jangan gunakan aplikasi ini.',
        ),
        LegalSection(
          'Siapa boleh menggunakannya',
          'Anda mesti berumur sekurang-kurangnya 16 tahun untuk menggunakan '
              '$_app. Jika anda mencipta akaun, pastikan butiran log masuk anda '
              'selamat; anda bertanggungjawab atas aktiviti pada akaun anda.',
        ),
        const LegalSection(
          'Apakah perkhidmatan ini',
          'Alat bajet dan perancangan peribadi untuk menjejak pendapatan, '
              'perbelanjaan, bajet, matlamat dan wawasan berkaitan, dengan '
              'bantuan AI pilihan, imbasan resit, penyelarasan merentas peranti '
              'dan pelan berbayar.',
        ),
        const LegalSection(
          'Alat perancangan, bukan nasihat profesional',
          'Bajet, unjuran, pengiraan zakat dan jawapan DGOTIX AI ialah alat '
              'perancangan untuk membantu anda membuat keputusan. Ia bukan '
              'nasihat kewangan, cukai atau agama profesional. Untuk kewajipan '
              'agama seperti zakat, sahkan dengan ilmuwan yang bertauliah; untuk '
              'keputusan kewangan besar, rujuk penasihat yang bertauliah.',
        ),
        const LegalSection(
          'Ciri AI',
          'DGOTIX AI dan imbasan resit awan menghasilkan keputusan automatik '
              'untuk menjimatkan masa anda; semak angka penting sebelum '
              'bertindak. Ciri ini disediakan dalam had penggunaan saksama yang '
              'bergantung pada pelan anda, dan mungkin dilaraskan untuk '
              'memastikan perkhidmatan pantas dan boleh dipercayai untuk semua.',
        ),
        const LegalSection(
          'Langganan, pengebilan dan pembaharuan',
          'Aplikasi teras adalah percuma. Pelan berbayar (Pro) '
              'membuka had yang lebih tinggi dan ciri tambahan pada harga yang '
              'ditunjukkan dalam aplikasi. Pelan berbayar diperbaharui secara '
              'automatik setiap tempoh pengebilan (bulanan atau tahunan) '
              'sehingga anda membatalkannya. Bayaran diproses oleh Whop, '
              'penyedia pembayaran kami (atau oleh PayPal jika anda '
              'memilihnya); cukai yang berkenaan mungkin ditambah dan sentiasa '
              'ditunjukkan sebelum anda membayar. Anda boleh membatalkan pada '
              'bila-bila masa dan mengekalkan akses sehingga akhir tempoh yang '
              'telah anda bayar. Jika harga atau ciri pelan berubah, terma '
              'semasa sentiasa ditunjukkan sebelum anda melanggan.',
        ),
        const LegalSection(
          'Penyedia pembayaran kami: Whop',
          'SmartBudget dijual oleh DGOTIX. Pembayaran dan pengebilan '
              'dikendalikan oleh Whop (whop.com), yang memproses bayaran di '
              'halaman selamatnya, menunjukkan harga penuh termasuk cukai '
              'sebelum anda membayar, dan menghantar resit anda. Anda boleh '
              'mengurus atau membatalkan langganan dari aplikasi (Pelan → '
              'Urus).',
        ),
        LegalSection(
          'Dasar bayaran balik',
          'Kecuali jika dikehendaki oleh undang-undang, bayaran secara '
              'amnya tidak boleh dikembalikan sebaik sahaja tempoh pengebilan '
              'bermula, kerana anda mengekalkan akses sehingga akhir tempoh '
              'itu. Anda boleh membatalkan pada bila-bila masa untuk '
              'menghentikan pembaharuan akan datang. Untuk permintaan bayaran '
              'balik atau soalan tentang caj, hubungi kami $_reachMs: kami '
              'menyemak setiap permintaan di bawah undang-undang pengguna yang '
              'berkenaan dan membuat bayaran balik yang diluluskan melalui Whop '
              '(atau PayPal).',
        ),
        const LegalSection(
          'Kod promosi',
          'Kupon dan kod diskaun adalah pilihan dan hanya mengubah harga '
              'pembayaran (atau memberi tempoh percubaan). Setiap kod mempunyai '
              'syaratnya sendiri (tempoh sah, had penggunaan, satu bagi setiap '
              'pelanggan) dan mungkin ditarik balik atau tamat tempoh. Ia tidak '
              'mempunyai nilai tunai dan tidak boleh digabungkan melainkan '
              'dinyatakan.',
        ),
        const LegalSection(
          'Data dan sandaran anda',
          'Anda bertanggungjawab atas ketepatan data yang anda masukkan. '
              'Untuk memastikan data anda selamat merentas peranti, log masuk '
              'untuk menyelaraskannya, atau eksport sandaran secara berkala dari '
              'Tetapan.',
        ),
        LegalSection(
          'Ketersediaan',
          'Kami berusaha memastikan $_app tersedia dan boleh dipercayai. '
              'Setakat yang dibenarkan oleh undang-undang, aplikasi disediakan '
              '"seadanya", tanpa sebarang jaminan. Data pasaran langsung, AI dan '
              'bayaran bergantung pada perkhidmatan pihak ketiga dan kadangkala '
              'mungkin tertunda atau tidak tersedia; gangguan sedemikian tidak '
              'pernah menghalang anda daripada menggunakan alat bajet teras, yang'
              ' juga berfungsi di luar talian. Ciri mungkin berkembang dari '
              'semasa ke semasa.',
        ),
        const LegalSection(
          'Had liabiliti',
          'Setakat yang dibenarkan oleh undang-undang, kami tidak '
              'bertanggungjawab atas kerugian tidak langsung atau berbangkit, '
              'atau atas keputusan yang anda buat berdasarkan angka aplikasi. '
              'Tiada apa-apa dalam terma ini mengehadkan hak anda di bawah '
              'undang-undang pengguna yang tidak boleh diketepikan.',
        ),
        const LegalSection(
          'Penggunaan yang dibenarkan',
          'Jangan menyalahgunakan perkhidmatan, cuba memecahkan atau memintas'
              ' keselamatan atau had pelannya, atau menggunakannya untuk sebarang'
              ' tujuan yang menyalahi undang-undang.',
        ),
        LegalSection(
          'Menamatkan penggunaan',
          'Anda boleh berhenti menggunakan $_app dan memadam akaun anda pada '
              'bila-bila masa. Kami mungkin menggantung akaun yang melanggar '
              'terma ini atau membahayakan perkhidmatan atau pengguna lain.',
        ),
        LegalSection(
          'Jenama dan pemilikan',
          'Nama $_app, jenama $_brand, serta reka bentuk dan kod aplikasi '
              'kekal menjadi hak milik pemiliknya. Data anda kekal milik anda.',
        ),
        LegalSection(
          'Perubahan dan hubungan',
          'Kami mungkin mengemas kini terma ini dan menunjukkan tarikh versi '
              'terkini; penggunaan berterusan selepas kemas kini bermakna anda '
              'menerima terma yang disemak. Untuk soalan, hubungi kami $_reachMs.',
        ),
      ];

  // ---- Privacy (Urdu) ----
  static List<LegalSection> get _privacyUr => <LegalSection>[
        LegalSection(
          'جائزہ',
          'یہ پالیسی بتاتی ہے کہ $_app کیا محفوظ کرتی ہے، کہاں محفوظ کرتی ہے،'
              ' اور آپ کے پاس کیا اختیارات ہیں۔ مختصراً: آپ کا مالی ڈیٹا آپ کا '
              'ہے، یہ پہلے آپ کی ڈیوائس پر محفوظ ہوتا ہے، اور ہم اسے کبھی نہیں '
              'بیچتے، نہ آپ کو اشتہارات دکھاتے ہیں اور نہ آپ کو ٹریک کرتے ہیں۔ '
              'چند اختیاری فیچرز (سائن ان اور ہم آہنگی، DGOTIX AI، کلاؤڈ رسید '
              'اسکیننگ اور ادا شدہ پلانز) مخصوص ڈیٹا کسی سروس کو صرف تب بھیجتے '
              'ہیں جب آپ انہیں استعمال کریں، جیسا کہ نیچے بیان کیا گیا ہے۔',
        ),
        const LegalSection(
          'ہم کیا محفوظ کرتے ہیں',
          'وہ معلومات جو آپ خود درج کرتے ہیں: آمدنی، اخراجات، بجٹ، اہداف، '
              'قرض، والیٹس، ذاتی کیٹیگریز اور آپ کی ڈسپلے ترجیحات (تھیم، زبان، '
              'بنیادی کرنسی)۔ اگر آپ اکاؤنٹ بنائیں تو ہم آپ کا ای میل ایڈریس، آپ '
              'کا پلان اور سبسکرپشن کی حیثیت، اور DGOTIX AI اور کلاؤڈ رسید '
              'اسکیننگ کے لیے ہر مدت کے استعمال کی گنتی بھی رکھتے ہیں — صرف آپ کے'
              ' پلان کی حدیں لاگو کرنے کے لیے۔ ہم DGOTIX AI سے آپ کے سوالات یا آپ'
              ' کی رسیدوں کی تصاویر محفوظ نہیں کرتے؛ اگر آپ کسی AI جواب کی رپورٹ '
              'کریں تو ہم جائزے کے لیے وہ جواب اور آپ کا اختیاری نوٹ رکھتے ہیں۔',
        ),
        const LegalSection(
          'آپ کا ڈیٹا کہاں رہتا ہے',
          'سب کچھ پہلے آپ کی ڈیوائس پر محفوظ ہوتا ہے (ایپ میں، یا ویب ورژن کے'
              ' لیے آپ کے براؤزر میں)، اس لیے ایپ اکاؤنٹ یا کنکشن کے بغیر بھی '
              'چلتی ہے۔ اگر آپ سائن ان کریں تو آپ کا ڈیٹا آپ کی ڈیوائسز کے درمیان'
              ' خود بخود ہم آہنگ بھی ہوتا ہے: ایک کاپی ہمارے ڈیٹا بیس (Supabase '
              'پر ہوسٹڈ) میں محفوظ ہوتی ہے، آپ کے اکاؤنٹ سے منسلک اور اس طرح الگ '
              'کہ صرف آپ اسے پڑھ سکیں۔ آپ سیٹنگز میں ہم آہنگی بند کر سکتے ہیں؛ '
              'پھر آپ کا ڈیٹا صرف اسی ڈیوائس پر رہتا ہے۔',
        ),
        const LegalSection(
          'آپ کا اکاؤنٹ اور ای میلز',
          'آپ کا ای میل ایڈریس سائن ان کرنے اور اکاؤنٹ کی ای میلز بھیجنے کے '
              'لیے استعمال ہوتا ہے، جیسے ایڈریس کی تصدیق اور پاس ورڈ ری سیٹ '
              '(Brevo کے ذریعے بھیجی جاتی ہیں)۔ یہ کبھی اشتہارات کے لیے استعمال '
              'یا مارکیٹنگ کے لیے شیئر نہیں ہوتا۔ سائن اپ یا سائن ان کرتے وقت ایک'
              ' فوری انسانی جانچ (Cloudflare Turnstile) خودکار غلط استعمال کو '
              'روکتی ہے۔',
        ),
        const LegalSection(
          'DGOTIX AI',
          'DGOTIX AI اختیاری ہے۔ جب آپ کوئی سوال پوچھتے ہیں تو اس سوال کا متن'
              ' اور آپ کے اعداد کا خلاصہ (12 مہینوں تک مہینے اور کیٹیگری کے لحاظ '
              'سے مجموعے، بجٹ، والیٹ بیلنس، اہداف، بار بار کی ٹرانزیکشنز، موسمی '
              'بجٹ اور کمیٹی گروپس — صرف رقوم اور تاریخیں، کبھی تفصیلات، نوٹس یا '
              'آپ کے دیے ہوئے نام نہیں) جواب تیار کرنے کے لیے ہمارے محفوظ سرور کے'
              ' ذریعے کسی AI فراہم کنندہ (Google Gemini، OpenAI یا Anthropic) کو '
              'بھیجا جاتا ہے۔ ہمارا سرور ہماری اپنی فراہم کنندہ کلیدیں استعمال '
              'کرتا ہے اور صرف استعمال کا میٹا ڈیٹا ریکارڈ کرتا ہے، کبھی آپ کا '
              'سوال یا آپ کے اعداد نہیں۔ ہم آپ کا ڈیٹا کسی ماڈل کی تربیت کے لیے '
              'استعمال نہیں کرتے۔ جوابات خود بخود تیار ہوتے ہیں، اس لیے عمل سے '
              'پہلے اہم اعداد کا جائزہ لیں۔',
        ),
        const LegalSection(
          'رسید اسکیننگ',
          'اینڈرائیڈ پر رسیدیں مکمل طور پر آپ کی ڈیوائس پر پڑھی جا سکتی ہیں۔ '
              'کلاؤڈ اسکیننگ رسید کی تصویر ہمارے محفوظ سرور کے ذریعے کسی AI فراہم'
              ' کنندہ کو صرف دکان، تاریخ، رقم، اشیاء اور کیٹیگری پڑھنے کے لیے '
              'بھیجتی ہے؛ تصویر محفوظ نہیں کی جاتی۔',
        ),
        const LegalSection(
          'ادائیگیاں اور سبسکرپشنز',
          'ادا شدہ پلانز اختیاری ہیں۔ آپ ہمارے ادائیگی فراہم کنندہ Whop '
              '(whop.com) کے محفوظ ادائیگی صفحے پر، یا چاہیں تو PayPal سے '
              'ادائیگی کرتے ہیں۔ یہ اپنی اپنی پرائیویسی پالیسی کے تحت ضروری '
              'بلنگ تفصیلات (جیسے آپ کا نام، ای میل، ملک اور ادائیگی کا طریقہ) '
              'جمع کرتے ہیں؛ ہم کبھی آپ کے کارڈ کی مکمل تفصیلات نہیں دیکھتے یا '
              'محفوظ کرتے۔ آپ کو درست رسائی دینے کے لیے ہم آپ کا پلان، سبسکرپشن '
              'کی حیثیت، تجدید کی تاریخ اور ادائیگی فراہم کنندہ کے سبسکرپشن '
              'شناخت کنندگان رکھتے ہیں، نیز کسی بھی پروموشنل کوڈ کا ریکارڈ جو '
              'آپ استعمال کریں۔',
        ),
        const LegalSection(
          'سروس فراہم کنندگان',
          'آپ کے استعمال کردہ فیچرز کے لحاظ سے: Supabase (اکاؤنٹس، ہم آہنگی '
              'اور ہمارے سرور فنکشنز)؛ Whop اور PayPal (ادائیگیاں)؛ Brevo '
              '(اکاؤنٹ ای میلز)؛ Cloudflare Turnstile (سائن ان پر انسانی جانچ)؛ '
              'GitHub Pages (ہماری ویب سائٹ اور ویب ایپ کی ہوسٹنگ)؛ Google، '
              'OpenAI اور Anthropic (DGOTIX AI اور کلاؤڈ رسید اسکیننگ)؛ اور '
              'لائیو اعداد کے لیے عوامی مارکیٹ ڈیٹا کے ذرائع — کرنسی ریٹس '
              '(open.er-api.com) اور کرپٹو قیمتیں (CoinGecko) — جن کی درخواستوں '
              'میں صرف کرنسی یا اثاثے کی علامتیں ہوتی ہیں، کبھی آپ کا ذاتی یا '
              'مالی ڈیٹا نہیں۔ ہر فراہم کنندہ ڈیٹا کو صرف سروس میں اپنا حصہ '
              'فراہم کرنے کے لیے پروسیس کرتا ہے۔',
        ),
        const LegalSection(
          'سیکیورٹی',
          'ہماری سروسز سے کنکشن خفیہ کاری شدہ (HTTPS) ہوتے ہیں۔ ہمارے ڈیٹا '
              'بیس میں ہر صارف کے ریکارڈ اس طرح الگ ہیں کہ ایک اکاؤنٹ کبھی دوسرے '
              'کا ریکارڈ نہیں پڑھ سکتا۔ سرور کلیدیں کبھی ایپ تک نہیں پہنچتیں، '
              'ادائیگی کی اطلاعات کچھ بدلنے سے پہلے تصدیق کی جاتی ہیں، اور آپ '
              'اپنی ڈیوائس پر ایپ لاک (PIN یا فنگر پرنٹ) لگا سکتے ہیں۔',
        ),
        const LegalSection(
          'ہم کیا نہیں کرتے',
          'ہم آپ کا ڈیٹا نہ بیچتے ہیں نہ کرائے پر دیتے ہیں، نہ اشتہارات '
              'دکھاتے ہیں، اور نہ آپ کی مالی سرگرمی پر رویے کی ٹریکنگ یا تجزیات '
              'چلاتے ہیں۔',
        ),
        // Only trips are counted, so only with SmartTrip.
        if (AppEnv.smartTrip)
          const LegalSection(
            'گمنام شمار',
            'جب آپ کوئی سفر بناتے ہیں تو ایپ صرف یہ الفاظ بھیجتی ہے «ایک سفر '
                'بنایا گیا»، اور ہمارا سرور اس دن کے مجموعے میں ایک کا اضافہ کرتا '
                'ہے۔ اس کے ساتھ کچھ اور نہ بھیجا جاتا ہے نہ رکھا جاتا ہے — نہ '
                'اکاؤنٹ، نہ ڈیوائس، نہ منزل، نہ رقم — اس لیے یہ مجموعے آپ سے جوڑے '
                'نہیں جا سکتے۔ ہم انہیں صرف یہ جاننے کے لیے استعمال کرتے ہیں کہ ایپ'
                ' کتنی استعمال ہوتی ہے اور شراکت داروں کو مجموعی اعداد دکھانے کے '
                'لیے۔ آپ اسے سیٹنگز میں، رازداری کے حصے سے بند کر سکتے ہیں۔',
          ),
        const LegalSection(
          'ہم ڈیٹا کب تک رکھتے ہیں',
          'آپ کی ڈیوائس پر ڈیٹا تب تک رہتا ہے جب تک آپ اسے حذف نہ کریں یا '
              'ایپ نہ ہٹائیں۔ آپ کا اکاؤنٹ، ہم آہنگ ڈیٹا، استعمال کی گنتی اور '
              'درخواستوں کا میٹا ڈیٹا اس وقت تک رکھا جاتا ہے جب تک آپ کا اکاؤنٹ '
              'موجود ہو — صرف سروس چلانے اور آپ کے پلان کی حدیں لاگو کرنے کے '
              'لیے — اور اکاؤنٹ حذف کرنے پر مستقل طور پر مٹا دیا جاتا ہے۔ Whop '
              'اور PayPal وہ بلنگ ریکارڈ رکھتے ہیں جو قانوناً رکھنا ضروری ہیں۔',
        ),
        LegalSection(
          'آپ کے حقوق اور اختیارات',
          'آپ کسی بھی وقت ایپ میں اپنا ڈیٹا دیکھ اور درست کر سکتے ہیں، مکمل '
              'بیک اپ ایکسپورٹ کر سکتے ہیں، ہم آہنگی بند کر سکتے ہیں، سائن آؤٹ کر'
              ' سکتے ہیں، اور اپنا اکاؤنٹ اس کے تمام ڈیٹا سمیت حذف کر سکتے ہیں '
              '(نیچے دیکھیں)۔ آپ کسی بھی وقت ادا شدہ سبسکرپشن منسوخ کر سکتے ہیں '
              '(شرائط دیکھیں)۔ اپنے ذاتی ڈیٹا کے بارے میں کسی بھی دوسری درخواست '
              'کے لیے — بشمول رسائی، درستی، حذف یا اعتراض — ہم سے $_reachUr رابطہ'
              ' کریں اور ہم فوراً جواب دیں گے۔',
        ),
        const LegalSection(
          'اپنا اکاؤنٹ اور ڈیٹا حذف کرنا',
          'ایپ یا ویب ورژن میں، کسی بھی ڈیوائس پر، سیٹنگز کھولیں، پھر اکاؤنٹ،'
              ' پھر "میرا اکاؤنٹ حذف کریں"۔ یہ آپ کا اکاؤنٹ اور ہمارے سرورز پر اس'
              ' کے لیے محفوظ ہر چیز (پروفائل، ہم آہنگ ڈیٹا، سبسکرپشن ریکارڈ اور '
              'استعمال کی گنتی) مستقل طور پر حذف کرتا ہے، اور اس ڈیوائس پر آپ کا '
              'ڈیٹا مٹا دیتا ہے۔ پہلے کوئی بھی ادا شدہ سبسکرپشن منسوخ کریں۔ حذف '
              'کرنا واپس نہیں ہو سکتا، اس لیے اگر بعد میں ڈیٹا کی ضرورت پڑ سکتی '
              'ہے تو پہلے بیک اپ ایکسپورٹ کر لیں۔',
        ),
        LegalSection(
          'عمر',
          '$_app 16 سال اور اس سے زیادہ عمر کے افراد کے لیے ہے۔ ہم جان بوجھ '
              'کر کم عمر بچوں سے ڈیٹا جمع نہیں کرتے؛ اگر آپ کو لگتا ہے کہ کسی بچے'
              ' نے اکاؤنٹ بنایا ہے تو ہم سے $_reachUr رابطہ کریں اور ہم اسے حذف '
              'کر دیں گے۔',
        ),
        LegalSection(
          'تبدیلیاں اور رابطہ',
          'ہم اس پالیسی کو اپ ڈیٹ کر سکتے ہیں؛ اوپر دکھائی گئی تاریخ تازہ '
              'ترین ورژن کی عکاسی کرتی ہے۔ پرائیویسی کے سوالات کے لیے ہم سے '
              '$_reachUr رابطہ کریں۔',
        ),
      ];

  // ---- Terms (Urdu) ----
  static List<LegalSection> get _termsUr => <LegalSection>[
        LegalSection(
          'قبولیت',
          '$_app استعمال کر کے آپ ان شرائط سے اتفاق کرتے ہیں۔ اگر آپ متفق '
              'نہیں تو براہ کرم ایپ استعمال نہ کریں۔',
        ),
        LegalSection(
          'کون استعمال کر سکتا ہے',
          '$_app استعمال کرنے کے لیے آپ کی عمر کم از کم 16 سال ہونی چاہیے۔ '
              'اگر آپ اکاؤنٹ بنائیں تو اپنی سائن ان تفصیلات محفوظ رکھیں؛ آپ اپنے '
              'اکاؤنٹ کی سرگرمی کے ذمہ دار ہیں۔',
        ),
        const LegalSection(
          'یہ سروس کیا ہے',
          'آمدنی، اخراجات، بجٹ، اہداف اور متعلقہ جائزوں کا حساب رکھنے کے لیے '
              'ایک ذاتی بجٹ اور منصوبہ بندی کا ٹول، اختیاری AI مدد، رسید اسکیننگ،'
              ' ڈیوائسز کے درمیان ہم آہنگی اور ادا شدہ پلانز کے ساتھ۔',
        ),
        const LegalSection(
          'منصوبہ بندی کے ٹولز، پیشہ ورانہ مشورہ نہیں',
          'بجٹ، تخمینے، زکوٰۃ کا حساب اور DGOTIX AI کے جوابات فیصلہ کرنے میں '
              'مدد کے لیے منصوبہ بندی کے ٹولز ہیں۔ یہ پیشہ ورانہ مالی، ٹیکس یا '
              'مذہبی مشورہ نہیں۔ زکوٰۃ جیسی مذہبی ذمہ داریوں کے لیے کسی مستند '
              'عالم سے تصدیق کریں؛ بڑے مالی فیصلوں کے لیے کسی مستند مشیر سے رجوع '
              'کریں۔',
        ),
        const LegalSection(
          'AI فیچرز',
          'DGOTIX AI اور کلاؤڈ رسید اسکیننگ آپ کا وقت بچانے کے لیے خودکار '
              'نتائج دیتے ہیں؛ عمل سے پہلے اہم اعداد کا جائزہ لیں۔ یہ فیچرز آپ کے'
              ' پلان پر منحصر منصفانہ استعمال کی حدوں میں شامل ہیں، اور سب کے لیے'
              ' سروس کو تیز اور قابلِ اعتماد رکھنے کے لیے ان میں تبدیلی ہو سکتی '
              'ہے۔',
        ),
        const LegalSection(
          'سبسکرپشنز، بلنگ اور تجدید',
          'بنیادی ایپ مفت ہے۔ ادا شدہ پلانز (Pro) ایپ میں دکھائی '
              'گئی قیمتوں پر زیادہ حدیں اور اضافی فیچرز کھولتے ہیں۔ ادا شدہ '
              'پلان ہر بلنگ مدت (ماہانہ یا سالانہ) پر خود بخود تجدید ہوتا ہے جب '
              'تک آپ منسوخ نہ کریں۔ ادائیگیاں ہمارے ادائیگی فراہم کنندہ Whop '
              '(یا آپ کی پسند پر PayPal) کے ذریعے پروسیس ہوتی ہیں؛ قابلِ اطلاق '
              'ٹیکس شامل ہو سکتے ہیں اور ادائیگی سے پہلے ہمیشہ دکھائے جاتے ہیں۔ '
              'آپ کسی بھی وقت منسوخ کر سکتے ہیں اور ادا شدہ مدت کے اختتام تک '
              'رسائی برقرار رکھ سکتے ہیں۔ اگر قیمتیں یا پلان کے فیچرز بدلیں تو '
              'موجودہ شرائط ہمیشہ سبسکرائب کرنے سے پہلے دکھائی جاتی ہیں۔',
        ),
        const LegalSection(
          'ہمارا ادائیگی فراہم کنندہ: Whop',
          'SmartBudget کو DGOTIX فروخت کرتا ہے۔ ادائیگی اور بلنگ Whop '
              '(whop.com) سنبھالتا ہے، جو اپنے محفوظ صفحے پر ادائیگی پروسیس '
              'کرتا ہے، ادائیگی سے پہلے ٹیکس سمیت پوری قیمت دکھاتا ہے اور آپ کو '
              'رسید بھیجتا ہے۔ آپ اپنی سبسکرپشن ایپ سے منظم یا منسوخ کر سکتے '
              'ہیں (پلانز ← منظم کریں)۔',
        ),
        LegalSection(
          'رقم کی واپسی کی پالیسی',
          'سوائے اس کے کہ قانون تقاضا کرے، بلنگ مدت شروع ہونے کے بعد '
              'ادائیگیاں عموماً ناقابلِ واپسی ہیں، کیونکہ اس کے اختتام تک آپ کی '
              'رسائی برقرار رہتی ہے۔ آئندہ تجدید روکنے کے لیے آپ کسی بھی وقت '
              'منسوخ کر سکتے ہیں۔ رقم کی واپسی کی درخواست یا کسی ادائیگی کے '
              'بارے میں سوال کے لیے ہم سے $_reachUr رابطہ کریں: ہم ہر درخواست '
              'کو قابلِ اطلاق صارف قانون کے تحت دیکھتے ہیں اور منظور شدہ رقم '
              'Whop (یا PayPal) کے ذریعے واپس کرتے ہیں۔',
        ),
        const LegalSection(
          'پروموشنل کوڈز',
          'کوپن اور رعایتی کوڈز اختیاری ہیں اور صرف ادائیگی کی قیمت بدلتے ہیں'
              ' (یا آزمائشی مدت دیتے ہیں)۔ ہر کوڈ کی اپنی شرائط ہیں (مدتِ اعتبار،'
              ' استعمال کی حدیں، فی صارف ایک) اور اسے واپس لیا جا سکتا ہے یا اس '
              'کی میعاد ختم ہو سکتی ہے۔ ان کی کوئی نقد قیمت نہیں اور بیان کیے '
              'بغیر انہیں ملایا نہیں جا سکتا۔',
        ),
        const LegalSection(
          'آپ کا ڈیٹا اور بیک اپ',
          'آپ اپنے درج کردہ ڈیٹا کی درستی کے ذمہ دار ہیں۔ ڈیوائسز میں اپنا '
              'ڈیٹا محفوظ رکھنے کے لیے اسے ہم آہنگ کرنے کے لیے سائن ان کریں، یا '
              'سیٹنگز سے باقاعدگی سے بیک اپ ایکسپورٹ کریں۔',
        ),
        LegalSection(
          'دستیابی',
          'ہم $_app کو دستیاب اور قابلِ اعتماد رکھنے کے لیے کام کرتے ہیں۔ '
              'قانون کی اجازت کی حد تک ایپ کسی بھی قسم کی ضمانت کے بغیر "جیسی ہے"'
              ' کی بنیاد پر فراہم کی جاتی ہے۔ لائیو مارکیٹ ڈیٹا، AI اور ادائیگیاں'
              ' تیسرے فریق کی سروسز پر منحصر ہیں اور کبھی کبھار تاخیر یا عدم '
              'دستیابی ہو سکتی ہے؛ ایسی رکاوٹ آپ کو بجٹ کے بنیادی ٹولز استعمال '
              'کرنے سے کبھی نہیں روکتی، جو آف لائن بھی کام کرتے ہیں۔ فیچرز وقت کے'
              ' ساتھ بدل سکتے ہیں۔',
        ),
        const LegalSection(
          'ذمہ داری کی حد',
          'قانون کی اجازت کی حد تک ہم بالواسطہ یا نتیجتاً ہونے والے نقصانات، '
              'یا ایپ کے اعداد کی بنیاد پر آپ کے فیصلوں کے ذمہ دار نہیں۔ ان شرائط'
              ' میں کچھ بھی صارف قانون کے تحت آپ کے ان حقوق کو محدود نہیں کرتا جن'
              ' سے دستبردار نہیں ہوا جا سکتا۔',
        ),
        const LegalSection(
          'قابلِ قبول استعمال',
          'سروس کا غلط استعمال نہ کریں، اس کی سیکیورٹی یا پلان کی حدوں کو '
              'توڑنے یا ان سے بچنے کی کوشش نہ کریں، اور اسے کسی غیر قانونی مقصد '
              'کے لیے استعمال نہ کریں۔',
        ),
        LegalSection(
          'استعمال ختم کرنا',
          'آپ کسی بھی وقت $_app کا استعمال بند کر کے اپنا اکاؤنٹ حذف کر سکتے '
              'ہیں۔ ہم ایسا اکاؤنٹ معطل کر سکتے ہیں جو ان شرائط کی خلاف ورزی کرے '
              'یا سروس یا دوسرے صارفین کو خطرے میں ڈالے۔',
        ),
        LegalSection(
          'برانڈ اور ملکیت',
          '$_app کا نام، $_brand برانڈ، اور ایپ کا ڈیزائن اور کوڈ اپنے مالک '
              'کی ملکیت رہتے ہیں۔ آپ کا ڈیٹا آپ کا رہتا ہے۔',
        ),
        LegalSection(
          'تبدیلیاں اور رابطہ',
          'ہم ان شرائط کو اپ ڈیٹ کر سکتے ہیں اور تازہ ترین ورژن کی تاریخ دکھا'
              ' سکتے ہیں؛ اپ ڈیٹ کے بعد استعمال جاری رکھنے کا مطلب ہے کہ آپ '
              'نظرثانی شدہ شرائط قبول کرتے ہیں۔ سوالات کے لیے ہم سے $_reachUr '
              'رابطہ کریں۔',
        ),
      ];
}
