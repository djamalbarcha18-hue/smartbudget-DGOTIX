import 'package:smartbudget/core/config/app_config.dart';
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
  static const String lastUpdated = '2026-10-12';

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

  static List<LegalSection> sections(LegalDoc doc, {required AppLang lang}) =>
      switch (doc) {
        LegalDoc.privacy => lang.pick(_privacyAr, _privacyEn, _privacyFr),
        LegalDoc.terms => lang.pick(_termsAr, _termsEn, _termsFr),
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
              'recurring transactions, seasonal budgets and daret groups — '
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
          'Paid plans are optional. Orders are processed by Paddle.com, our '
              'online reseller and Merchant of Record, which lets you pay by '
              'card, PayPal, Apple Pay or Google Pay. Paddle collects the billing'
              ' details it needs (such as your name, email, country and payment '
              'method) under its own privacy policy; we never see or store your '
              'full card details. We keep your plan, subscription status, renewal'
              ' date and Paddle\'s subscription identifiers so we can give you '
              'the right access, plus a record of any promotional code you '
              'redeem.',
        ),
        const LegalSection(
          'Service providers',
          'Depending on the features you use: Supabase (accounts, sync and '
              'our server functions); Paddle (payments); Brevo (account emails); '
              'Cloudflare Turnstile (the human check at sign-in); GitHub Pages '
              '(hosting of our website and web app); Google, OpenAI and Anthropic'
              ' (DGOTIX AI and cloud receipt scanning); and public market-data '
              'sources for live figures — currency rates (open.er-api.com) and '
              'crypto prices (CoinGecko) — whose requests contain only currency '
              'or asset symbols, never your personal or financial data. Each '
              'provider processes data only to deliver its part of the service.',
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
        const LegalSection(
          'How long we keep data',
          'Data on your device stays until you delete it or remove the app. '
              'Your account, synced data, usage counts and request metadata are '
              'kept while your account exists — only to run the service and apply'
              ' your plan\'s limits — and are permanently erased when you delete '
              'it. Paddle keeps the billing records it is legally required to '
              'keep.',
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
              'والدارت — مبالغ وتواريخ فقط، دون الأوصاف أو الملاحظات أو الأسماء '
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
          'الباقات المدفوعة اختيارية. تُعالَج الطلبات عبر Paddle.com، موزّعنا'
              ' المعتمد عبر الإنترنت والبائع المسجَّل (Merchant of Record)، الذي '
              'يتيح الدفع بالبطاقة أو PayPal أو Apple Pay أو Google Pay. ويجمع '
              'Paddle بيانات الفوترة التي يحتاجها (مثل اسمك وبريدك وبلدك ووسيلة '
              'الدفع) وفق سياسة خصوصيته؛ ولا نرى ولا نخزّن بيانات بطاقتك الكاملة.'
              ' ونحتفظ بباقتك وحالة اشتراكك وتاريخ التجديد ومعرّفات الاشتراك لدى '
              'Paddle لنمنحك الوصول الصحيح، إضافةً إلى سجلّ بأي كود ترويجي '
              'تستخدمه.',
        ),
        const LegalSection(
          'مزوّدو الخدمات',
          'حسب الميزات التي تستخدمها: Supabase (الحسابات والمزامنة ودوال '
              'خادمنا)؛ وPaddle (المدفوعات)؛ وBrevo (رسائل الحساب)؛ وCloudflare '
              'Turnstile (التحقّق البشري عند الدخول)؛ وGitHub Pages (استضافة '
              'موقعنا وتطبيق الويب)؛ وGoogle وOpenAI وAnthropic (DGOTIX AI ومسح '
              'الإيصالات السحابي)؛ ومصادر بيانات سوق عامة للقيم الحيّة — أسعار '
              'العملات (open.er-api.com) وأسعار العملات الرقمية (CoinGecko) — '
              'وطلباتها تحتوي على رموز العملات أو الأصول فقط، لا أي بيانات شخصية '
              'أو مالية. ويعالج كل مزوّد البيانات فقط لتقديم الجزء الخاص به من '
              'الخدمة.',
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
        const LegalSection(
          'مدة الاحتفاظ بالبيانات',
          'تبقى البيانات على جهازك حتى تحذفها أو تُزيل التطبيق. ويُحتفظ '
              'بحسابك وبياناتك المتزامنة وعدّادات الاستخدام والبيانات الوصفية '
              'للطلبات ما دام حسابك قائماً — لتشغيل الخدمة وتطبيق حدود باقتك فقط '
              '— وتُمحى نهائياً عند حذفه. ويحتفظ Paddle بسجلّات الفوترة التي '
              'يُلزمه القانون بالاحتفاظ بها.',
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
          'The core app is free. Paid plans (Basic and Pro) unlock higher '
              'limits and extra features at the prices shown in the app. A paid '
              'plan renews automatically each billing period (monthly or yearly) '
              'until you cancel. Payments are processed by our online reseller '
              'Paddle; applicable taxes may be added and are handled by Paddle as'
              ' the merchant of record. You can cancel at any time and keep '
              'access until the end of the period you already paid for. If prices'
              ' or plan features change, the current terms are always shown '
              'before you subscribe.',
        ),
        const LegalSection(
          'Our reseller: Paddle',
          'Our order process is conducted by our online reseller Paddle.com. '
              'Paddle.com is the Merchant of Record for all our orders. Paddle '
              'provides all customer service inquiries and handles returns.',
        ),
        LegalSection(
          'Refund policy',
          'Except where required by law, payments are generally non-'
              'refundable once a billing period has started, since you keep '
              'access until its end. You can cancel at any time to stop future '
              'renewals. Refund requests are handled by Paddle under its buyer '
              'terms and applicable consumer law (you can reach Paddle at '
              'paddle.net); you can also contact us $_reachEn and we will help.',
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
          'التطبيق الأساسي مجاني. وتفتح الباقات المدفوعة (الأساسية '
              'والاحترافية) حدوداً أعلى وميزات إضافية بالأسعار المعروضة في '
              'التطبيق. وتتجدّد الباقة المدفوعة تلقائياً في كل فترة فوترة (شهرياً'
              ' أو سنوياً) حتى تُلغيها. تُعالَج المدفوعات عبر موزّعنا المعتمد عبر'
              ' الإنترنت Paddle؛ وقد تُضاف ضرائب مطبّقة يتولّاها Paddle بصفته '
              'البائع المسجَّل. ويمكنك الإلغاء في أي وقت مع الاحتفاظ بالوصول حتى '
              'نهاية الفترة المدفوعة. وإذا تغيّرت الأسعار أو ميزات الباقات '
              'فستُعرض الشروط الحالية دائماً قبل اشتراكك.',
        ),
        const LegalSection(
          'موزّعنا المعتمد: Paddle',
          'تتم عملية الطلب لدينا عبر موزّعنا المعتمد عبر الإنترنت Paddle.com.'
              ' وPaddle.com هو البائع المسجَّل (Merchant of Record) لجميع '
              'طلباتنا، ويتولّى Paddle جميع استفسارات خدمة العملاء ويعالج طلبات '
              'الاسترجاع.',
        ),
        LegalSection(
          'سياسة الاسترجاع',
          'باستثناء ما يوجبه القانون، تكون المدفوعات عادةً غير قابلة '
              'للاسترداد بعد بدء فترة الفوترة، لأنك تحتفظ بالوصول حتى نهايتها. '
              'ويمكنك الإلغاء في أي وقت لإيقاف التجديدات القادمة. يتولّى Paddle '
              'طلبات الاسترداد وفق شروط المشتري لديه وقانون حماية المستهلك '
              'المطبّق (يمكنك التواصل مع Paddle عبر paddle.net)؛ ويمكنك أيضاً '
              'التواصل معنا $_reachAr وسنساعدك.',
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
          'Les formules payantes sont facultatives. Les commandes sont '
              'traitées par Paddle.com, notre revendeur en ligne et marchand '
              'officiel (Merchant of Record), qui vous permet de payer par carte,'
              ' PayPal, Apple Pay ou Google Pay. Paddle collecte les informations'
              ' de facturation dont il a besoin (comme votre nom, votre e-mail, '
              'votre pays et votre moyen de paiement) selon sa propre politique '
              'de confidentialité ; nous ne voyons ni ne conservons jamais les '
              'détails complets de votre carte. Nous conservons votre formule, '
              'l\'état de votre abonnement, sa date de renouvellement et les '
              'identifiants d\'abonnement de Paddle pour vous donner le bon '
              'accès, ainsi qu\'une trace des codes promo que vous utilisez.',
        ),
        const LegalSection(
          'Prestataires de services',
          'Selon les fonctionnalités que vous utilisez : Supabase (comptes, '
              'synchronisation et fonctions de notre serveur) ; Paddle '
              '(paiements) ; Brevo (e-mails liés au compte) ; Cloudflare '
              'Turnstile (la vérification humaine à la connexion) ; GitHub Pages '
              '(hébergement de notre site et de l\'application web) ; Google, '
              'OpenAI et Anthropic (DGOTIX AI et scan des tickets dans le '
              'cloud) ; et des sources publiques de données de marché pour les '
              'chiffres en direct : taux de change (open.er-api.com) et cours des'
              ' cryptomonnaies (CoinGecko), dont les requêtes ne contiennent que '
              'des symboles de devises ou d\'actifs, jamais vos données '
              'personnelles ou financières. Chaque prestataire ne traite les '
              'données que pour fournir sa part du service.',
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
        const LegalSection(
          'Durée de conservation',
          'Les données sur votre appareil y restent jusqu\'à ce que vous les '
              'supprimiez ou désinstalliez l\'application. Votre compte, vos '
              'données synchronisées, vos compteurs d\'utilisation et les '
              'métadonnées des requêtes sont conservés tant que votre compte '
              'existe, uniquement pour faire fonctionner le service et appliquer '
              'les limites de votre formule, et sont définitivement effacés '
              'lorsque vous le supprimez. Paddle conserve les justificatifs de '
              'facturation qu\'il est légalement tenu de conserver.',
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
          'L\'application de base est gratuite. Les formules payantes (Basic '
              'et Pro) débloquent des limites plus élevées et des fonctionnalités'
              ' supplémentaires aux prix affichés dans l\'application. Une '
              'formule payante se renouvelle automatiquement à chaque période de '
              'facturation (mensuelle ou annuelle) jusqu\'à sa résiliation. Les '
              'paiements sont traités par notre revendeur en ligne Paddle ; les '
              'taxes applicables peuvent s\'ajouter et sont gérées par Paddle en '
              'tant que marchand officiel. Vous pouvez résilier à tout moment et '
              'conserver l\'accès jusqu\'à la fin de la période déjà payée. Si '
              'les prix ou les fonctionnalités changent, les conditions en '
              'vigueur sont toujours affichées avant votre abonnement.',
        ),
        const LegalSection(
          'Notre revendeur : Paddle',
          'Notre processus de commande est assuré par notre revendeur en '
              'ligne Paddle.com. Paddle.com est le marchand officiel (Merchant of'
              ' Record) de toutes nos commandes. Paddle traite toutes les '
              'demandes du service client et gère les retours.',
        ),
        LegalSection(
          'Politique de remboursement',
          'Sauf lorsque la loi l\'exige, les paiements ne sont en général pas'
              ' remboursables une fois qu\'une période de facturation a commencé,'
              ' puisque vous conservez l\'accès jusqu\'à sa fin. Vous pouvez '
              'résilier à tout moment pour arrêter les renouvellements futurs. '
              'Les demandes de remboursement sont traitées par Paddle selon ses '
              'conditions d\'achat et le droit de la consommation applicable '
              '(vous pouvez joindre Paddle sur paddle.net) ; vous pouvez aussi '
              'nous contacter $_reachFr et nous vous aiderons.',
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
}
