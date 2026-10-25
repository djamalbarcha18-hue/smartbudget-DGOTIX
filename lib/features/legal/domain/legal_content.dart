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

  static String get _reachDe => AppConfig.hasSupportEmail
      ? 'unter ${AppConfig.supportEmail}'
      : 'über die Seite Hilfe & Support in der App';

  static String get _reachPt => AppConfig.hasSupportEmail
      ? 'pelo e-mail ${AppConfig.supportEmail}'
      : 'pela página Ajuda e suporte do app';

  static String get _reachIt => AppConfig.hasSupportEmail
      ? 'all\'indirizzo ${AppConfig.supportEmail}'
      : 'dalla pagina Aiuto e supporto dell\'app';

  static String get _reachNl => AppConfig.hasSupportEmail
      ? 'via ${AppConfig.supportEmail}'
      : 'via de pagina Hulp en support in de app';

  static String get _reachBs => AppConfig.hasSupportEmail
      ? 'na ${AppConfig.supportEmail}'
      : 'preko stranice Pomoć i podrška u aplikaciji';

  static String get _reachSq => AppConfig.hasSupportEmail
      ? 'në ${AppConfig.supportEmail}'
      : 'nga faqja Ndihmë dhe mbështetje në aplikacion';

  static String get _reachRu => AppConfig.hasSupportEmail
      ? 'по адресу ${AppConfig.supportEmail}'
      : 'через страницу «Помощь и поддержка» в приложении';

  static String get _reachSw => AppConfig.hasSupportEmail
      ? 'kupitia ${AppConfig.supportEmail}'
      : 'kupitia ukurasa wa Msaada kwenye programu';

  static String get _reachHa => AppConfig.hasSupportEmail
      ? 'ta ${AppConfig.supportEmail}'
      : 'ta shafin Taimako a cikin manhajar';

  static String get _reachAf => AppConfig.hasSupportEmail
      ? 'via ${AppConfig.supportEmail}'
      : 'via die Hulp en ondersteuning-bladsy in die app';

  static String get _reachFa => AppConfig.hasSupportEmail
      ? 'از طریق ${AppConfig.supportEmail}'
      : 'از طریق صفحه راهنما و پشتیبانی در برنامه';

  static String get _reachHi => AppConfig.hasSupportEmail
      ? '${AppConfig.supportEmail} पर'
      : 'ऐप के मदद और सहायता पेज से';

  static String get _reachZh => AppConfig.hasSupportEmail
      ? '通过 ${AppConfig.supportEmail} '
      : '通过应用的“帮助与支持”页面';

  static List<LegalSection> sections(LegalDoc doc, {required AppLang lang}) =>
      switch (doc) {
        LegalDoc.privacy => lang.pick(_privacyAr, _privacyEn,
            fr: _privacyFr, id: _privacyId, es: _privacyEs,
            tr: _privacyTr, ms: _privacyMs, ur: _privacyUr, de: _privacyDe,
            pt: _privacyPt, it: _privacyIt, nl: _privacyNl,
            bs: _privacyBs, sq: _privacySq, ru: _privacyRu,
            sw: _privacySw, ha: _privacyHa, af: _privacyAf,
            fa: _privacyFa,
            hi: _privacyHi,
            zh: _privacyZh),
        LegalDoc.terms => lang.pick(_termsAr, _termsEn,
            fr: _termsFr, id: _termsId, es: _termsEs,
            tr: _termsTr, ms: _termsMs, ur: _termsUr, de: _termsDe,
            pt: _termsPt, it: _termsIt, nl: _termsNl,
            bs: _termsBs, sq: _termsSq, ru: _termsRu,
            sw: _termsSw, ha: _termsHa, af: _termsAf,
            fa: _termsFa,
            hi: _termsHi,
            zh: _termsZh),
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
        // Only while the totals are on (and trips are only in SmartTrip).
        if (AppEnv.anonStats && AppEnv.smartTrip)
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
        // Only while the totals are on (and trips are only in SmartTrip).
        if (AppEnv.anonStats && AppEnv.smartTrip)
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
        // Only while the totals are on (and trips are only in SmartTrip).
        if (AppEnv.anonStats && AppEnv.smartTrip)
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
        // Only while the totals are on (and trips are only in SmartTrip).
        if (AppEnv.anonStats && AppEnv.smartTrip)
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
        // Only while the totals are on (and trips are only in SmartTrip).
        if (AppEnv.anonStats && AppEnv.smartTrip)
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
        // Only while the totals are on (and trips are only in SmartTrip).
        if (AppEnv.anonStats && AppEnv.smartTrip)
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
        // Only while the totals are on (and trips are only in SmartTrip).
        if (AppEnv.anonStats && AppEnv.smartTrip)
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
        // Only while the totals are on (and trips are only in SmartTrip).
        if (AppEnv.anonStats && AppEnv.smartTrip)
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

  // ---- Privacy (German) ----
  static List<LegalSection> get _privacyDe => <LegalSection>[
        LegalSection(
          'Überblick',
          'Diese Erklärung beschreibt, was $_app speichert, wo es gespeichert '
              'wird und welche Wahl du hast. Kurz gesagt: Deine Finanzdaten '
              'gehören dir, sie werden zuerst auf deinem Gerät gespeichert, und '
              'wir verkaufen sie nie, zeigen dir keine Werbung und verfolgen dich '
              'nicht. Einige optionale Funktionen (Anmeldung und Synchronisierung,'
              ' DGOTIX AI, Belegscan in der Cloud und bezahlte Tarife) senden '
              'bestimmte Daten nur dann an einen Dienst, wenn du sie nutzt, wie '
              'unten beschrieben.',
        ),
        const LegalSection(
          'Was wir speichern',
          'Die Angaben, die du selbst eingibst: Einnahmen, Ausgaben, Budgets, '
              'Ziele, Schulden, Geldbörsen, eigene Kategorien und deine '
              'Anzeigeeinstellungen (Design, Sprache, Basiswährung). Wenn du ein '
              'Konto erstellst, speichern wir zusätzlich deine E-Mail-Adresse, '
              'deinen Tarif und Abo-Status sowie Nutzungszähler pro Zeitraum für '
              'DGOTIX AI und den Belegscan in der Cloud – nur, um die Limits '
              'deines Tarifs anzuwenden. Wir speichern weder deine Fragen an '
              'DGOTIX AI noch deine Belegbilder; wenn du eine KI-Antwort meldest, '
              'speichern wir diese Antwort und deine optionale Notiz, um sie zu '
              'prüfen.',
        ),
        const LegalSection(
          'Wo deine Daten liegen',
          'Alles wird zuerst auf deinem Gerät gespeichert (in der App oder, in'
              ' der Webversion, in deinem Browser), sodass die App auch ohne Konto'
              ' oder Verbindung funktioniert. Wenn du dich anmeldest, werden deine'
              ' Daten außerdem automatisch zwischen deinen Geräten synchronisiert:'
              ' Eine Kopie liegt in unserer Datenbank (gehostet von Supabase), ist'
              ' mit deinem Konto verknüpft und so abgeschottet, dass nur du sie '
              'lesen kannst. Du kannst die Synchronisierung in den Einstellungen '
              'ausschalten; dann bleiben deine Daten nur auf diesem Gerät.',
        ),
        const LegalSection(
          'Dein Konto und E-Mails',
          'Deine E-Mail-Adresse dient der Anmeldung und dem Versand von '
              'Konto-E-Mails, etwa zur Bestätigung der Adresse oder zum '
              'Zurücksetzen des Passworts (versendet über Brevo). Sie wird nie '
              'für Werbung verwendet oder zu Marketingzwecken weitergegeben. Bei '
              'Registrierung und Anmeldung hält eine kurze Prüfung, ob du ein '
              'Mensch bist (Cloudflare Turnstile), automatisierten Missbrauch fern.',
        ),
        const LegalSection(
          'DGOTIX AI',
          'DGOTIX AI ist optional. Wenn du eine Frage stellst, werden der Text '
              'der Frage und eine Zusammenfassung deiner Zahlen (Summen nach Monat'
              ' und Kategorie für bis zu 12 Monate, Budgets, Stände der '
              'Geldbörsen, Ziele, wiederkehrende Buchungen, Saisonbudgets und '
              'Sparrunden – nur Beträge und Daten, nie Beschreibungen, Notizen '
              'oder die Namen, die du vergibst) über unseren sicheren Server an '
              'einen KI-Anbieter (Google Gemini, OpenAI oder Anthropic) gesendet, '
              'um die Antwort zu erzeugen. Unser Server nutzt unsere eigenen '
              'Anbieterschlüssel und speichert nur Nutzungsmetadaten, nie deine '
              'Frage oder deine Zahlen. Wir nutzen deine Daten nicht zum Trainieren'
              ' von Modellen. Antworten werden automatisch erzeugt; prüfe wichtige'
              ' Zahlen, bevor du danach handelst.',
        ),
        const LegalSection(
          'Belegscan',
          'Unter Android können Belege vollständig auf deinem Gerät gelesen '
              'werden. Beim Scan in der Cloud wird das Belegbild über unseren '
              'sicheren Server an einen KI-Anbieter gesendet, nur um Händler, '
              'Datum, Betrag, Positionen und Kategorie zu lesen; das Bild wird '
              'nicht gespeichert.',
        ),
        const LegalSection(
          'Zahlungen und Abos',
          'Bezahlte Tarife sind optional. Du zahlst über den sicheren '
              'Bezahlvorgang von Whop (whop.com), unserem Zahlungsanbieter, oder '
              'mit PayPal, wenn du das wählst. Sie erheben die nötigen '
              'Rechnungsdaten (etwa Name, E-Mail, Land und Zahlungsart) nach ihren'
              ' eigenen Datenschutzbestimmungen; wir sehen oder speichern nie '
              'deine vollständigen Kartendaten. Wir speichern deinen Tarif, den '
              'Abo-Status, das Verlängerungsdatum und die Abo-Kennungen des '
              'Zahlungsanbieters, um dir den richtigen Zugang zu geben, sowie '
              'einen Nachweis über eingelöste Aktionscodes.',
        ),
        const LegalSection(
          'Dienstleister',
          'Je nach genutzten Funktionen: Supabase (Konten, Synchronisierung und'
              ' unsere Serverfunktionen); Whop und PayPal (Zahlungen); Brevo '
              '(Konto-E-Mails); Cloudflare Turnstile (die Prüfung bei der '
              'Anmeldung); GitHub Pages (Hosting unserer Website und Web-App); '
              'Google, OpenAI und Anthropic (DGOTIX AI und Belegscan in der '
              'Cloud); sowie öffentliche Marktdatenquellen für aktuelle Werte – '
              'Wechselkurse (open.er-api.com) und Kryptopreise (CoinGecko) –, '
              'deren Anfragen nur Währungs- oder Anlagesymbole enthalten, nie '
              'deine persönlichen oder finanziellen Daten. Jeder Anbieter '
              'verarbeitet Daten nur, um seinen Teil des Dienstes zu erbringen.',
        ),
        const LegalSection(
          'Sicherheit',
          'Verbindungen zu unseren Diensten sind verschlüsselt (HTTPS). In '
              'unserer Datenbank sind die Einträge jedes Nutzers so abgeschottet,'
              ' dass ein Konto nie die eines anderen lesen kann. Serverschlüssel '
              'gelangen nie in die App, Zahlungsbenachrichtigungen werden geprüft,'
              ' bevor sie etwas ändern, und du kannst auf deinem Gerät eine '
              'App-Sperre (PIN oder Fingerabdruck) einrichten.',
        ),
        const LegalSection(
          'Was wir nicht tun',
          'Wir verkaufen oder vermieten deine Daten nicht, zeigen keine Werbung'
              ' und betreiben kein Verhaltens-Tracking und keine Analysen deiner '
              'finanziellen Aktivitäten.',
        ),
        // Only while the totals are on (and trips are only in SmartTrip).
        if (AppEnv.anonStats && AppEnv.smartTrip)
          const LegalSection(
            'Anonyme Zählungen',
            'Wenn du eine Reise anlegst, sendet die App nur die Worte „eine '
                'Reise wurde geplant“, und unser Server erhöht die Summe dieses '
                'Tages um eins. Sonst wird nichts gesendet oder dazu gespeichert –'
                ' kein Konto, kein Gerät, kein Reiseziel, kein Betrag –, sodass '
                'die Summen nicht mit dir verknüpft werden können. Wir nutzen sie '
                'nur, um zu wissen, wie viel die App genutzt wird, und um Partnern'
                ' Gesamtzahlen zu zeigen. Du kannst das in den Einstellungen unter'
                ' Privatsphäre ausschalten.',
          ),
        const LegalSection(
          'Wie lange wir Daten aufbewahren',
          'Daten auf deinem Gerät bleiben, bis du sie löschst oder die App '
              'entfernst. Dein Konto, synchronisierte Daten, Nutzungszähler und '
              'Anfrage-Metadaten werden aufbewahrt, solange dein Konto besteht – '
              'nur, um den Dienst zu betreiben und die Limits deines Tarifs '
              'anzuwenden –, und endgültig gelöscht, wenn du es löschst. Whop und'
              ' PayPal bewahren die Abrechnungsunterlagen auf, die sie gesetzlich '
              'aufbewahren müssen.',
        ),
        LegalSection(
          'Deine Rechte und Einstellungen',
          'Du kannst deine Daten jederzeit in der App ansehen und korrigieren, '
              'eine vollständige Sicherung exportieren, die Synchronisierung '
              'ausschalten, dich abmelden und dein Konto mit allen Daten löschen '
              '(siehe unten). Ein bezahltes Abo kannst du jederzeit kündigen '
              '(siehe Nutzungsbedingungen). Für jedes andere Anliegen zu deinen '
              'personenbezogenen Daten – darunter Auskunft, Berichtigung, Löschung'
              ' oder Widerspruch – kontaktiere uns $_reachDe, und wir antworten '
              'zeitnah.',
        ),
        const LegalSection(
          'Konto und Daten löschen',
          'Öffne in der App oder der Webversion, auf jedem Gerät, die '
              'Einstellungen, dann Konto und dann „Mein Konto löschen“. Damit '
              'werden dein Konto und alles, was dafür auf unseren Servern '
              'gespeichert ist (Profil, synchronisierte Daten, Abo-Eintrag und '
              'Nutzungszähler), endgültig gelöscht und deine Daten auf diesem '
              'Gerät entfernt. Kündige vorher ein bezahltes Abo. Die Löschung kann'
              ' nicht rückgängig gemacht werden – exportiere also vorher eine '
              'Sicherung, falls du deine Daten später noch brauchst.',
        ),
        LegalSection(
          'Alter',
          '$_app richtet sich an Personen ab 16 Jahren. Wir erheben nicht '
              'wissentlich Daten von jüngeren Kindern; wenn du glaubst, dass ein '
              'Kind ein Konto erstellt hat, kontaktiere uns $_reachDe, und wir '
              'löschen es.',
        ),
        LegalSection(
          'Änderungen und Kontakt',
          'Wir können diese Erklärung aktualisieren; das oben angezeigte Datum '
              'nennt die neueste Fassung. Bei Fragen zum Datenschutz kontaktiere '
              'uns $_reachDe.',
        ),
      ];

  // ---- Terms (German) ----
  static List<LegalSection> get _termsDe => <LegalSection>[
        LegalSection(
          'Zustimmung',
          'Mit der Nutzung von $_app stimmst du diesen Bedingungen zu. Wenn du '
              'nicht zustimmst, nutze die App bitte nicht.',
        ),
        LegalSection(
          'Wer sie nutzen darf',
          'Du musst mindestens 16 Jahre alt sein, um $_app zu nutzen. Wenn du '
              'ein Konto erstellst, bewahre deine Anmeldedaten sicher auf; du '
              'bist für die Aktivitäten in deinem Konto verantwortlich.',
        ),
        const LegalSection(
          'Was der Dienst ist',
          'Ein persönliches Werkzeug für Budget und Planung, um Einnahmen, '
              'Ausgaben, Budgets, Ziele und zugehörige Einblicke zu verfolgen, mit'
              ' optionaler KI-Hilfe, Belegscan, Synchronisierung zwischen Geräten '
              'und bezahlten Tarifen.',
        ),
        const LegalSection(
          'Planungswerkzeuge, keine fachliche Beratung',
          'Budgets, Prognosen, die Zakat-Berechnung und die Antworten von '
              'DGOTIX AI sind Planungswerkzeuge, die dir bei Entscheidungen helfen.'
              ' Sie sind keine fachliche Finanz-, Steuer- oder religiöse Beratung.'
              ' Lass religiöse Pflichten wie die Zakat von einem qualifizierten '
              'Gelehrten bestätigen; bei großen finanziellen Entscheidungen wende '
              'dich an eine qualifizierte Beratung.',
        ),
        const LegalSection(
          'KI-Funktionen',
          'DGOTIX AI und der Belegscan in der Cloud liefern automatische '
              'Ergebnisse, um dir Zeit zu sparen; prüfe wichtige Zahlen, bevor du '
              'danach handelst. Diese Funktionen sind innerhalb von '
              'Fair-Use-Grenzen enthalten, die von deinem Tarif abhängen, und '
              'können angepasst werden, damit der Dienst für alle schnell und '
              'zuverlässig bleibt.',
        ),
        const LegalSection(
          'Abos, Abrechnung und Verlängerung',
          'Die Kern-App ist kostenlos. Bezahlte Tarife (Pro) schalten höhere '
              'Limits und zusätzliche Funktionen zu den in der App angezeigten '
              'Preisen frei. Ein bezahlter Tarif verlängert sich automatisch um '
              'jeden Abrechnungszeitraum (monatlich oder jährlich), bis du '
              'kündigst. Zahlungen wickelt Whop ab, unser Zahlungsanbieter (oder '
              'PayPal, wenn du das wählst); anfallende Steuern können hinzukommen '
              'und werden vor dem Bezahlen immer angezeigt. Du kannst jederzeit '
              'kündigen und behältst den Zugang bis zum Ende des bereits bezahlten'
              ' Zeitraums. Wenn sich Preise oder Leistungen ändern, werden dir die'
              ' aktuellen Bedingungen immer vor dem Abschluss angezeigt.',
        ),
        const LegalSection(
          'Unser Zahlungsanbieter: Whop',
          'SmartBudget wird von DGOTIX verkauft. Bezahlvorgang und Abrechnung '
              'übernimmt Whop (whop.com): Whop wickelt die Zahlung über den '
              'eigenen sicheren Bezahlvorgang ab, zeigt vor dem Bezahlen den '
              'vollen Preis einschließlich Steuern und sendet dir die Quittung. '
              'Du kannst dein Abo in der App verwalten oder kündigen (Tarife → '
              'Verwalten).',
        ),
        LegalSection(
          'Erstattungen',
          'Soweit gesetzlich nicht anders vorgeschrieben, werden Zahlungen nach'
              ' Beginn eines Abrechnungszeitraums grundsätzlich nicht erstattet, '
              'da du den Zugang bis zu dessen Ende behältst. Du kannst jederzeit '
              'kündigen, um künftige Verlängerungen zu stoppen. Für einen '
              'Erstattungswunsch oder Fragen zu einer Abbuchung kontaktiere uns '
              '$_reachDe: Wir prüfen jede Anfrage nach geltendem '
              'Verbraucherrecht und erstatten genehmigte Beträge über Whop (oder '
              'PayPal).',
        ),
        const LegalSection(
          'Aktionscodes',
          'Gutscheine und Rabattcodes sind optional und ändern nur den Preis '
              'eines Bezahlvorgangs (oder gewähren eine Testphase). Jeder Code hat'
              ' eigene Bedingungen (Gültigkeitszeitraum, Nutzungsgrenzen, einer '
              'pro Kunde) und kann zurückgezogen werden oder ablaufen. Sie haben '
              'keinen Barwert und lassen sich nur kombinieren, wenn das angegeben '
              'ist.',
        ),
        const LegalSection(
          'Deine Daten und Sicherungen',
          'Du bist für die Richtigkeit der eingegebenen Daten verantwortlich. '
              'Um deine Daten geräteübergreifend zu schützen, melde dich an, um '
              'sie zu synchronisieren, oder exportiere regelmäßig eine Sicherung '
              'in den Einstellungen.',
        ),
        LegalSection(
          'Verfügbarkeit',
          'Wir arbeiten daran, dass $_app verfügbar und zuverlässig bleibt. '
              'Soweit gesetzlich zulässig, wird die App „wie besehen“ und ohne '
              'Gewährleistung jeglicher Art bereitgestellt. Aktuelle Marktdaten, '
              'KI und Zahlungen hängen von Diensten Dritter ab und können '
              'gelegentlich verzögert oder nicht verfügbar sein; eine solche '
              'Unterbrechung hindert dich nie an der Nutzung der grundlegenden '
              'Budgetwerkzeuge, die auch offline funktionieren. Funktionen können '
              'sich mit der Zeit weiterentwickeln.',
        ),
        const LegalSection(
          'Haftungsbeschränkung',
          'Soweit gesetzlich zulässig, haften wir nicht für mittelbare Schäden '
              'oder Folgeschäden oder für Entscheidungen, die du auf Grundlage der'
              ' Zahlen der App triffst. Nichts in diesen Bedingungen schränkt '
              'Rechte ein, die dir nach zwingendem Verbraucherrecht zustehen.',
        ),
        const LegalSection(
          'Zulässige Nutzung',
          'Missbrauche den Dienst nicht, versuche nicht, seine Sicherheit oder '
              'die Tarifgrenzen zu umgehen oder zu brechen, und nutze ihn nicht '
              'für rechtswidrige Zwecke.',
        ),
        LegalSection(
          'Ende der Nutzung',
          'Du kannst $_app jederzeit nicht mehr nutzen und dein Konto löschen. '
              'Wir können ein Konto sperren, das gegen diese Bedingungen verstößt '
              'oder den Dienst oder andere Nutzer gefährdet.',
        ),
        LegalSection(
          'Marke und Eigentum',
          'Der Name $_app, die Marke $_brand sowie Design und Code der App '
              'bleiben Eigentum ihres Inhabers. Deine Daten bleiben deine.',
        ),
        LegalSection(
          'Änderungen und Kontakt',
          'Wir können diese Bedingungen aktualisieren und das Datum der '
              'neuesten Fassung anzeigen; wenn du die App nach einer '
              'Aktualisierung weiter nutzt, akzeptierst du die geänderten '
              'Bedingungen. Bei Fragen kontaktiere uns $_reachDe.',
        ),
      ];

  // ---- Privacy (Portuguese) ----
  static List<LegalSection> get _privacyPt => <LegalSection>[
        LegalSection(
          'Visão geral',
          'Esta política explica o que o $_app guarda, onde guarda e quais '
              'escolhas você tem. Em resumo: seus dados financeiros são seus, '
              'ficam primeiro no seu aparelho, e nunca os vendemos, nunca '
              'mostramos anúncios nem rastreamos você. Alguns recursos opcionais '
              '(login e sincronização, DGOTIX AI, leitura de recibos na nuvem e '
              'planos pagos) enviam dados específicos a um serviço só quando você'
              ' os usa, como descrito abaixo.',
        ),
        const LegalSection(
          'O que guardamos',
          'As informações que você mesmo informa: receitas, despesas, '
              'orçamentos, metas, dívidas, carteiras, categorias personalizadas e'
              ' suas preferências de exibição (tema, idioma, moeda base). Se você'
              ' cria uma conta, também guardamos seu e-mail, seu plano e a '
              'situação da assinatura, além de contadores de uso por período da '
              'DGOTIX AI e da leitura de recibos na nuvem — usados só para '
              'aplicar os limites do seu plano. Não guardamos suas perguntas à '
              'DGOTIX AI nem as imagens dos seus recibos; se você denunciar uma '
              'resposta da IA, guardamos essa resposta e sua observação opcional '
              'para analisá-la.',
        ),
        const LegalSection(
          'Onde seus dados ficam',
          'Tudo é salvo primeiro no seu aparelho (no app ou, na versão web, no'
              ' seu navegador), então o app funciona mesmo sem conta ou conexão. '
              'Se você entra na sua conta, seus dados também são sincronizados '
              'automaticamente entre seus aparelhos: uma cópia fica no nosso '
              'banco de dados (hospedado pela Supabase), ligada à sua conta e '
              'isolada para que só você possa lê-la. Você pode desativar a '
              'sincronização em Configurações; aí seus dados ficam só neste '
              'aparelho.',
        ),
        const LegalSection(
          'Sua conta e e-mails',
          'Seu e-mail é usado para você entrar na conta e para enviar e-mails '
              'da conta, como confirmação do endereço e redefinição de senha '
              '(enviados pela Brevo). Ele nunca é usado para publicidade nem '
              'compartilhado para marketing. Ao se cadastrar ou entrar, uma '
              'verificação rápida de que você é uma pessoa (Cloudflare Turnstile)'
              ' impede abusos automatizados.',
        ),
        const LegalSection(
          'DGOTIX AI',
          'A DGOTIX AI é opcional. Quando você faz uma pergunta, o texto dela e'
              ' um resumo dos seus números (totais por mês e categoria de até 12 '
              'meses, orçamentos, saldos das carteiras, metas, transações '
              'recorrentes, orçamentos de temporada e círculos de poupança — só '
              'valores e datas, nunca descrições, observações ou os nomes que '
              'você dá às coisas) são enviados pelo nosso servidor seguro a um '
              'provedor de IA (Google Gemini, OpenAI ou Anthropic) para gerar a '
              'resposta. Nosso servidor usa nossas próprias chaves de provedor e '
              'registra só metadados de uso, nunca sua pergunta ou seus números. '
              'Não usamos seus dados para treinar nenhum modelo. As respostas são'
              ' geradas automaticamente, então confira os números importantes '
              'antes de agir.',
        ),
        const LegalSection(
          'Leitura de recibos',
          'No Android, os recibos podem ser lidos inteiramente no seu '
              'aparelho. A leitura na nuvem envia a imagem do recibo pelo nosso '
              'servidor seguro a um provedor de IA só para ler o estabelecimento,'
              ' a data, o valor, os itens e a categoria; a imagem não é guardada.',
        ),
        const LegalSection(
          'Pagamentos e assinaturas',
          'Os planos pagos são opcionais. Você paga no checkout seguro da Whop '
              '(whop.com), nosso provedor de pagamentos, ou com PayPal, se '
              'preferir. Eles coletam os dados de cobrança de que precisam (como '
              'nome, e-mail, país e forma de pagamento) segundo as próprias '
              'políticas de privacidade; nunca vemos nem guardamos os dados '
              'completos do seu cartão. Guardamos seu plano, a situação da '
              'assinatura, a data de renovação e os identificadores de assinatura'
              ' do provedor de pagamento para dar a você o acesso certo, além do '
              'registro de qualquer código promocional que você use.',
        ),
        const LegalSection(
          'Prestadores de serviço',
          'Conforme os recursos que você usa: Supabase (contas, sincronização e'
              ' nossas funções de servidor); Whop e PayPal (pagamentos); Brevo '
              '(e-mails da conta); Cloudflare Turnstile (a verificação no login);'
              ' GitHub Pages (hospedagem do nosso site e do app web); Google, '
              'OpenAI e Anthropic (DGOTIX AI e leitura de recibos na nuvem); e '
              'fontes públicas de dados de mercado para valores ao vivo — '
              'câmbio (open.er-api.com) e preços de cripto (CoinGecko) —, cujas '
              'solicitações contêm só símbolos de moedas ou ativos, nunca seus '
              'dados pessoais ou financeiros. Cada prestador trata os dados só '
              'para entregar sua parte do serviço.',
        ),
        const LegalSection(
          'Segurança',
          'As conexões com nossos serviços são criptografadas (HTTPS). No nosso'
              ' banco de dados, os registros de cada usuário são isolados para '
              'que uma conta nunca leia os de outra. As chaves do servidor nunca '
              'chegam ao app, as notificações de pagamento são verificadas antes '
              'de mudar qualquer coisa, e você pode ativar um bloqueio do app (PIN'
              ' ou digital) no seu aparelho.',
        ),
        const LegalSection(
          'O que não fazemos',
          'Não vendemos nem alugamos seus dados, não mostramos anúncios e não '
              'fazemos rastreamento de comportamento nem análises da sua '
              'atividade financeira.',
        ),
        // Only while the totals are on (and trips are only in SmartTrip).
        if (AppEnv.anonStats && AppEnv.smartTrip)
          const LegalSection(
            'Contagens anônimas',
            'Quando você cria uma viagem, o app envia só as palavras “uma '
                'viagem foi planejada”, e nosso servidor soma um ao total '
                'daquele dia. Nada mais é enviado nem guardado junto — nem conta,'
                ' nem aparelho, nem destino, nem valor —, então os totais não '
                'podem ser ligados a você. Usamos esses totais só para saber '
                'quanto o app é usado e para mostrar números gerais a parceiros. '
                'Você pode desativar isso em Configurações, em Privacidade.',
          ),
        const LegalSection(
          'Por quanto tempo guardamos os dados',
          'Os dados no seu aparelho ficam até você apagá-los ou remover o app. '
              'Sua conta, os dados sincronizados, os contadores de uso e os '
              'metadados das solicitações são mantidos enquanto sua conta existir'
              ' — só para operar o serviço e aplicar os limites do seu plano — e '
              'são apagados de vez quando você a exclui. A Whop e o PayPal '
              'guardam os registros de cobrança que a lei os obriga a manter.',
        ),
        LegalSection(
          'Seus direitos e controles',
          'Você pode ver e corrigir seus dados no app a qualquer momento, '
              'exportar um backup completo, desativar a sincronização, sair e '
              'excluir sua conta com todos os dados (veja abaixo). Você pode '
              'cancelar uma assinatura paga a qualquer momento (veja os Termos). '
              'Para qualquer outro pedido sobre seus dados pessoais — incluindo '
              'acesso, correção, exclusão ou oposição — fale conosco $_reachPt, '
              'e responderemos rapidamente.',
        ),
        const LegalSection(
          'Excluir sua conta e seus dados',
          'No app ou na versão web, em qualquer aparelho, abra Configurações, '
              'depois Conta e depois “Excluir minha conta”. Isso exclui de vez '
              'sua conta e tudo o que está guardado para ela nos nossos '
              'servidores (perfil, dados sincronizados, registro da assinatura e '
              'contadores de uso) e apaga seus dados naquele aparelho. Cancele '
              'antes qualquer assinatura paga. A exclusão não pode ser desfeita, '
              'então exporte um backup antes se puder querer seus dados depois.',
        ),
        LegalSection(
          'Idade',
          'O $_app é destinado a pessoas com 16 anos ou mais. Não coletamos '
              'conscientemente dados de crianças mais novas; se você acha que '
              'uma criança criou uma conta, fale conosco $_reachPt e nós a '
              'excluiremos.',
        ),
        LegalSection(
          'Alterações e contato',
          'Podemos atualizar esta política; a data mostrada acima indica a '
              'versão mais recente. Para dúvidas sobre privacidade, fale conosco '
              '$_reachPt.',
        ),
      ];

  // ---- Terms (Portuguese) ----
  static List<LegalSection> get _termsPt => <LegalSection>[
        LegalSection(
          'Aceitação',
          'Ao usar o $_app, você concorda com estes termos. Se não concordar, '
              'não use o app.',
        ),
        LegalSection(
          'Quem pode usar',
          'Você precisa ter pelo menos 16 anos para usar o $_app. Se criar uma '
              'conta, mantenha seus dados de acesso em segurança; você é '
              'responsável pela atividade na sua conta.',
        ),
        const LegalSection(
          'O que é o serviço',
          'Uma ferramenta pessoal de orçamento e planejamento para acompanhar '
              'receitas, despesas, orçamentos, metas e análises relacionadas, com'
              ' ajuda opcional de IA, leitura de recibos, sincronização entre '
              'aparelhos e planos pagos.',
        ),
        const LegalSection(
          'Ferramentas de planejamento, não aconselhamento profissional',
          'Orçamentos, projeções, o cálculo do Zakat e as respostas da DGOTIX '
              'AI são ferramentas de planejamento para ajudar você a decidir. Não'
              ' são aconselhamento profissional financeiro, tributário ou '
              'religioso. Para obrigações religiosas como o Zakat, confirme com '
              'um estudioso qualificado; para decisões financeiras importantes, '
              'consulte um profissional qualificado.',
        ),
        const LegalSection(
          'Recursos de IA',
          'A DGOTIX AI e a leitura de recibos na nuvem geram resultados '
              'automáticos para poupar seu tempo; confira os números importantes '
              'antes de agir. Esses recursos estão incluídos dentro de limites de'
              ' uso justo que dependem do seu plano e podem ser ajustados para '
              'manter o serviço rápido e confiável para todos.',
        ),
        const LegalSection(
          'Assinaturas, cobrança e renovação',
          'O app básico é gratuito. Os planos pagos (Pro) liberam limites '
              'maiores e recursos extras pelos preços mostrados no app. Um plano '
              'pago renova automaticamente a cada período de cobrança (mensal ou '
              'anual) até você cancelar. Os pagamentos são processados pela Whop,'
              ' nosso provedor de pagamentos (ou pelo PayPal, se você escolher); '
              'impostos aplicáveis podem ser acrescentados e sempre aparecem no '
              'checkout antes de você pagar. Você pode cancelar a qualquer momento'
              ' e manter o acesso até o fim do período já pago. Se os preços ou '
              'os recursos do plano mudarem, os termos atuais sempre aparecem '
              'antes de você assinar.',
        ),
        const LegalSection(
          'Nosso provedor de pagamentos: Whop',
          'O SmartBudget é vendido pela DGOTIX. O checkout e a cobrança são '
              'feitos pela Whop (whop.com), que processa o pagamento no próprio '
              'checkout seguro, mostra o preço completo com impostos antes de '
              'você pagar e envia seu recibo. Você pode gerenciar ou cancelar sua'
              ' assinatura no app (Planos → Gerenciar).',
        ),
        LegalSection(
          'Política de reembolso',
          'Salvo quando a lei exigir, os pagamentos em geral não são '
              'reembolsáveis depois que um período de cobrança começa, já que '
              'você mantém o acesso até o fim dele. Você pode cancelar a qualquer'
              ' momento para interromper as renovações futuras. Para pedir '
              'reembolso ou tirar dúvidas sobre uma cobrança, fale conosco '
              '$_reachPt: analisamos cada pedido conforme a lei do consumidor '
              'aplicável e fazemos os reembolsos aprovados pela Whop (ou pelo '
              'PayPal).',
        ),
        const LegalSection(
          'Códigos promocionais',
          'Cupons e códigos de desconto são opcionais e mudam só o preço de um'
              ' checkout (ou concedem um período de teste). Cada código tem suas '
              'próprias condições (validade, limites de uso, um por cliente) e '
              'pode ser retirado ou expirar. Eles não têm valor em dinheiro e não'
              ' podem ser combinados, salvo indicação.',
        ),
        const LegalSection(
          'Seus dados e backups',
          'Você é responsável pela exatidão dos dados que informa. Para manter'
              ' seus dados seguros entre aparelhos, entre na sua conta para '
              'sincronizá-los ou exporte um backup regularmente em Configurações.',
        ),
        LegalSection(
          'Disponibilidade',
          'Trabalhamos para manter o $_app disponível e confiável. Na medida '
              'permitida pela lei, o app é fornecido “no estado em que se '
              'encontra”, sem garantias de qualquer tipo. Dados de mercado ao '
              'vivo, IA e pagamentos dependem de serviços de terceiros e podem '
              'atrasar ou ficar indisponíveis de vez em quando; essa interrupção '
              'nunca impede você de usar as ferramentas básicas de orçamento, que'
              ' também funcionam offline. Os recursos podem evoluir com o tempo.',
        ),
        const LegalSection(
          'Limitação de responsabilidade',
          'Na medida permitida pela lei, não respondemos por perdas indiretas '
              'ou consequentes, nem por decisões que você tome com base nos '
              'números do app. Nada nestes termos limita direitos que você tem '
              'pela lei do consumidor e que não podem ser renunciados.',
        ),
        const LegalSection(
          'Uso aceitável',
          'Não faça mau uso do serviço, não tente quebrar ou contornar a '
              'segurança ou os limites dos planos, nem use o serviço para fins '
              'ilegais.',
        ),
        LegalSection(
          'Encerrar o uso',
          'Você pode parar de usar o $_app e excluir sua conta a qualquer '
              'momento. Podemos suspender uma conta que viole estes termos ou '
              'coloque em risco o serviço ou outros usuários.',
        ),
        LegalSection(
          'Marca e propriedade',
          'O nome $_app, a marca $_brand e o design e o código do app '
              'continuam sendo propriedade do seu titular. Seus dados continuam '
              'sendo seus.',
        ),
        LegalSection(
          'Alterações e contato',
          'Podemos atualizar estes termos e mostrar a data da versão mais '
              'recente; continuar usando o app depois de uma atualização '
              'significa aceitar os termos revisados. Para dúvidas, fale conosco '
              '$_reachPt.',
        ),
      ];

  // ---- Privacy (Italian) ----
  static List<LegalSection> get _privacyIt => <LegalSection>[
        LegalSection(
          'Panoramica',
          'Questa informativa spiega cosa salva $_app, dove lo salva e quali '
              'scelte hai. In breve: i tuoi dati finanziari sono tuoi, vengono '
              'salvati prima sul tuo dispositivo e non li vendiamo mai, non ti '
              'mostriamo pubblicità e non ti tracciamo. Alcune funzioni '
              'facoltative (accesso e sincronizzazione, DGOTIX AI, scansione '
              'degli scontrini nel cloud e piani a pagamento) inviano dati '
              'specifici a un servizio solo quando le usi, come descritto sotto.',
        ),
        const LegalSection(
          'Cosa salviamo',
          'Le informazioni che inserisci tu: entrate, spese, budget, obiettivi,'
              ' debiti, portafogli, categorie personalizzate e le tue preferenze '
              'di visualizzazione (tema, lingua, valuta base). Se crei un '
              'account, conserviamo anche il tuo indirizzo email, il piano e lo '
              'stato dell\'abbonamento, e i contatori di utilizzo per periodo di '
              'DGOTIX AI e della scansione cloud degli scontrini, usati solo per '
              'applicare i limiti del tuo piano. Non conserviamo le tue domande a'
              ' DGOTIX AI né le immagini degli scontrini; se segnali una risposta'
              ' dell\'IA, conserviamo quella risposta e la tua nota facoltativa '
              'per esaminarla.',
        ),
        const LegalSection(
          'Dove si trovano i tuoi dati',
          'Tutto viene salvato prima sul tuo dispositivo (nell\'app o, per la '
              'versione web, nel browser), così l\'app funziona anche senza '
              'account o connessione. Se accedi, i tuoi dati vengono anche '
              'sincronizzati automaticamente tra i tuoi dispositivi: una copia è '
              'conservata nel nostro database (ospitato da Supabase), legata al '
              'tuo account e isolata in modo che solo tu possa leggerla. Puoi '
              'disattivare la sincronizzazione nelle Impostazioni; allora i dati '
              'restano solo su questo dispositivo.',
        ),
        const LegalSection(
          'Il tuo account e le email',
          'Il tuo indirizzo email serve per l\'accesso e per inviarti email '
              'dell\'account, come la conferma dell\'indirizzo e la '
              'reimpostazione della password (inviate tramite Brevo). Non viene '
              'mai usato per pubblicità né condiviso per marketing. Alla '
              'registrazione e all\'accesso, un rapido controllo che tu sia una '
              'persona (Cloudflare Turnstile) tiene lontani gli abusi '
              'automatizzati.',
        ),
        const LegalSection(
          'DGOTIX AI',
          'DGOTIX AI è facoltativo. Quando fai una domanda, il testo della '
              'domanda e un riepilogo delle tue cifre (totali per mese e '
              'categoria fino a 12 mesi, budget, saldi dei portafogli, obiettivi,'
              ' transazioni ricorrenti, budget stagionali e giri di risparmio: '
              'solo importi e date, mai descrizioni, note o i nomi che dai alle '
              'cose) vengono inviati tramite il nostro server sicuro a un '
              'fornitore di IA (Google Gemini, OpenAI o Anthropic) per generare '
              'la risposta. Il nostro server usa le nostre chiavi e registra solo'
              ' metadati di utilizzo, mai la tua domanda o le tue cifre. Non '
              'usiamo i tuoi dati per addestrare alcun modello. Le risposte sono '
              'generate automaticamente, quindi verifica le cifre importanti '
              'prima di agire.',
        ),
        const LegalSection(
          'Scansione degli scontrini',
          'Su Android, gli scontrini possono essere letti interamente sul tuo '
              'dispositivo. La scansione nel cloud invia l\'immagine dello '
              'scontrino tramite il nostro server sicuro a un fornitore di IA '
              'solo per leggere esercente, data, importo, articoli e categoria; '
              'l\'immagine non viene conservata.',
        ),
        const LegalSection(
          'Pagamenti e abbonamenti',
          'I piani a pagamento sono facoltativi. Paghi sul checkout sicuro di '
              'Whop (whop.com), il nostro fornitore di pagamenti, o con PayPal se'
              ' lo scegli. Raccolgono i dati di fatturazione necessari (come '
              'nome, email, paese e metodo di pagamento) secondo le proprie '
              'informative; non vediamo né conserviamo mai i dati completi della'
              ' tua carta. Conserviamo il tuo piano, lo stato dell\'abbonamento, '
              'la data di rinnovo e gli identificativi dell\'abbonamento del '
              'fornitore per darti l\'accesso corretto, oltre alla traccia di '
              'eventuali codici promozionali utilizzati.',
        ),
        const LegalSection(
          'Fornitori di servizi',
          'A seconda delle funzioni che usi: Supabase (account, '
              'sincronizzazione e funzioni del nostro server); Whop e PayPal '
              '(pagamenti); Brevo (email dell\'account); Cloudflare Turnstile (il'
              ' controllo all\'accesso); GitHub Pages (hosting del sito e della '
              'web app); Google, OpenAI e Anthropic (DGOTIX AI e scansione cloud '
              'degli scontrini); e fonti pubbliche di dati di mercato per i '
              'valori in tempo reale, cioè cambi (open.er-api.com) e prezzi delle'
              ' cripto (CoinGecko), le cui richieste contengono solo simboli di '
              'valute o attività, mai i tuoi dati personali o finanziari. Ogni '
              'fornitore tratta i dati solo per fornire la propria parte del '
              'servizio.',
        ),
        const LegalSection(
          'Sicurezza',
          'Le connessioni ai nostri servizi sono cifrate (HTTPS). Nel nostro '
              'database i dati di ogni utente sono isolati, così un account non '
              'può mai leggere quelli di un altro. Le chiavi del server non '
              'arrivano mai all\'app, le notifiche di pagamento vengono '
              'verificate prima di cambiare qualsiasi cosa e puoi aggiungere un '
              'blocco app (PIN o impronta) sul tuo dispositivo.',
        ),
        const LegalSection(
          'Cosa non facciamo',
          'Non vendiamo né affittiamo i tuoi dati, non mostriamo pubblicità e '
              'non effettuiamo tracciamento comportamentale né analisi sulla tua '
              'attività finanziaria.',
        ),
        // Only while the totals are on (and trips are only in SmartTrip).
        if (AppEnv.anonStats && AppEnv.smartTrip)
          const LegalSection(
            'Conteggi anonimi',
            'Quando crei un viaggio, l\'app invia solo le parole “è stato '
                'pianificato un viaggio” e il nostro server aggiunge uno al '
                'totale di quel giorno. Nient\'altro viene inviato o conservato '
                'insieme (nessun account, dispositivo, destinazione o importo), '
                'quindi i totali non possono essere collegati a te. Li usiamo solo'
                ' per sapere quanto viene usata l\'app e per mostrare cifre '
                'complessive ai partner. Puoi disattivarlo nelle Impostazioni, '
                'alla voce Privacy.',
          ),
        const LegalSection(
          'Per quanto tempo conserviamo i dati',
          'I dati sul tuo dispositivo restano finché non li elimini o rimuovi '
              'l\'app. Il tuo account, i dati sincronizzati, i contatori di '
              'utilizzo e i metadati delle richieste sono conservati finché '
              'l\'account esiste, solo per far funzionare il servizio e applicare'
              ' i limiti del tuo piano, e vengono cancellati definitivamente '
              'quando lo elimini. Whop e PayPal conservano i documenti di '
              'fatturazione che la legge impone loro di conservare.',
        ),
        LegalSection(
          'I tuoi diritti e controlli',
          'Puoi vedere e correggere i tuoi dati nell\'app in qualsiasi momento,'
              ' esportare un backup completo, disattivare la sincronizzazione, '
              'uscire ed eliminare l\'account con tutti i dati (vedi sotto). Puoi'
              ' annullare un abbonamento a pagamento in qualsiasi momento (vedi i'
              ' Termini). Per qualsiasi altra richiesta sui tuoi dati personali, '
              'compresi accesso, rettifica, cancellazione od opposizione, '
              'contattaci $_reachIt e ti risponderemo rapidamente.',
        ),
        const LegalSection(
          'Eliminare l\'account e i dati',
          'Nell\'app o nella versione web, su qualsiasi dispositivo, apri '
              'Impostazioni, poi Account, poi “Elimina il mio account”. Questo '
              'elimina definitivamente il tuo account e tutto ciò che è salvato '
              'per esso sui nostri server (profilo, dati sincronizzati, '
              'abbonamento e contatori di utilizzo) e cancella i tuoi dati su quel'
              ' dispositivo. Annulla prima qualsiasi abbonamento a pagamento. '
              'L\'eliminazione non si può annullare, quindi esporta prima un '
              'backup se potresti volere i tuoi dati in futuro.',
        ),
        LegalSection(
          'Età',
          '$_app è destinata a persone dai 16 anni in su. Non raccogliamo '
              'consapevolmente dati di minori più giovani; se ritieni che un '
              'minore abbia creato un account, contattaci $_reachIt e lo '
              'elimineremo.',
        ),
        LegalSection(
          'Modifiche e contatti',
          'Possiamo aggiornare questa informativa; la data indicata sopra '
              'corrisponde all\'ultima versione. Per domande sulla privacy, '
              'contattaci $_reachIt.',
        ),
      ];

  // ---- Terms (Italian) ----
  static List<LegalSection> get _termsIt => <LegalSection>[
        LegalSection(
          'Accettazione',
          'Usando $_app accetti questi termini. Se non li accetti, non usare '
              'l\'app.',
        ),
        LegalSection(
          'Chi può usarla',
          'Devi avere almeno 16 anni per usare $_app. Se crei un account, '
              'custodisci i dati di accesso; sei responsabile dell\'attività sul '
              'tuo account.',
        ),
        const LegalSection(
          'Cos\'è il servizio',
          'Uno strumento personale di budget e pianificazione per seguire '
              'entrate, spese, budget, obiettivi e relative analisi, con aiuto '
              'facoltativo dell\'IA, scansione degli scontrini, sincronizzazione '
              'tra dispositivi e piani a pagamento.',
        ),
        const LegalSection(
          'Strumenti di pianificazione, non consulenza professionale',
          'Budget, proiezioni, il calcolo della Zakat e le risposte di DGOTIX '
              'AI sono strumenti di pianificazione per aiutarti a decidere. Non '
              'sono consulenza professionale finanziaria, fiscale o religiosa. '
              'Per gli obblighi religiosi come la Zakat, verifica con un sapiente'
              ' qualificato; per le decisioni finanziarie importanti, rivolgiti a'
              ' un consulente qualificato.',
        ),
        const LegalSection(
          'Funzioni di IA',
          'DGOTIX AI e la scansione cloud degli scontrini producono risultati '
              'automatici per farti risparmiare tempo; verifica le cifre '
              'importanti prima di agire. Queste funzioni sono incluse entro '
              'limiti di uso corretto che dipendono dal tuo piano e possono essere'
              ' adeguati per mantenere il servizio veloce e affidabile per tutti.',
        ),
        const LegalSection(
          'Abbonamenti, fatturazione e rinnovi',
          'L\'app di base è gratuita. I piani a pagamento (Pro) sbloccano '
              'limiti più alti e funzioni extra ai prezzi indicati nell\'app. Un'
              ' piano a pagamento si rinnova automaticamente a ogni periodo di '
              'fatturazione (mensile o annuale) finché non lo annulli. I '
              'pagamenti sono gestiti da Whop, il nostro fornitore di pagamenti '
              '(o da PayPal se lo scegli); eventuali imposte applicabili possono '
              'essere aggiunte e sono sempre mostrate al checkout prima di '
              'pagare. Puoi annullare in qualsiasi momento e mantenere l\'accesso'
              ' fino alla fine del periodo già pagato. Se prezzi o funzioni del '
              'piano cambiano, i termini aggiornati sono sempre mostrati prima '
              'dell\'abbonamento.',
        ),
        const LegalSection(
          'Il nostro fornitore di pagamenti: Whop',
          'SmartBudget è venduto da DGOTIX. Checkout e fatturazione sono '
              'gestiti da Whop (whop.com), che elabora il pagamento sul proprio '
              'checkout sicuro, mostra il prezzo completo di imposte prima del '
              'pagamento e invia la ricevuta. Puoi gestire o annullare '
              'l\'abbonamento dall\'app (Piani → Gestisci).',
        ),
        LegalSection(
          'Politica di rimborso',
          'Salvo quanto previsto dalla legge, i pagamenti in genere non sono '
              'rimborsabili una volta iniziato un periodo di fatturazione, perché'
              ' mantieni l\'accesso fino alla sua fine. Puoi annullare in '
              'qualsiasi momento per fermare i rinnovi futuri. Per una richiesta '
              'di rimborso o domande su un addebito, contattaci $_reachIt: '
              'esaminiamo ogni richiesta secondo la normativa sui consumatori '
              'applicabile ed effettuiamo i rimborsi approvati tramite Whop (o '
              'PayPal).',
        ),
        const LegalSection(
          'Codici promozionali',
          'Coupon e codici sconto sono facoltativi e cambiano solo il prezzo di'
              ' un checkout (o danno un periodo di prova). Ogni codice ha le sue '
              'condizioni (validità, limiti di utilizzo, uno per cliente) e può '
              'essere ritirato o scadere. Non hanno valore in denaro e non sono '
              'cumulabili, salvo diversa indicazione.',
        ),
        const LegalSection(
          'I tuoi dati e i backup',
          'Sei responsabile dell\'esattezza dei dati che inserisci. Per '
              'mantenere i tuoi dati al sicuro tra dispositivi, accedi per '
              'sincronizzarli o esporta regolarmente un backup dalle '
              'Impostazioni.',
        ),
        LegalSection(
          'Disponibilità',
          'Lavoriamo per mantenere $_app disponibile e affidabile. Nei limiti '
              'consentiti dalla legge, l\'app è fornita “così com\'è”, senza '
              'garanzie di alcun tipo. Dati di mercato in tempo reale, IA e '
              'pagamenti dipendono da servizi di terzi e possono a volte essere '
              'in ritardo o non disponibili; un\'interruzione del genere non ti '
              'impedisce mai di usare gli strumenti di budget di base, che '
              'funzionano anche offline. Le funzioni possono evolvere nel tempo.',
        ),
        const LegalSection(
          'Limitazione di responsabilità',
          'Nei limiti consentiti dalla legge, non rispondiamo di perdite '
              'indirette o consequenziali, né delle decisioni che prendi in base '
              'alle cifre dell\'app. Nulla in questi termini limita i diritti che'
              ' ti spettano per legge come consumatore e a cui non si può '
              'rinunciare.',
        ),
        const LegalSection(
          'Uso consentito',
          'Non abusare del servizio, non tentare di violarne o aggirarne la '
              'sicurezza o i limiti dei piani e non usarlo per scopi illeciti.',
        ),
        LegalSection(
          'Fine dell\'utilizzo',
          'Puoi smettere di usare $_app ed eliminare il tuo account in '
              'qualsiasi momento. Possiamo sospendere un account che viola questi'
              ' termini o mette a rischio il servizio o altri utenti.',
        ),
        LegalSection(
          'Marchio e proprietà',
          'Il nome $_app, il marchio $_brand, il design e il codice dell\'app '
              'restano di proprietà del loro titolare. I tuoi dati restano tuoi.',
        ),
        LegalSection(
          'Modifiche e contatti',
          'Possiamo aggiornare questi termini e mostrare la data dell\'ultima '
              'versione; continuare a usare l\'app dopo un aggiornamento significa'
              ' accettare i termini rivisti. Per domande, contattaci $_reachIt.',
        ),
      ];

  // ---- Privacy (Dutch) ----
  static List<LegalSection> get _privacyNl => <LegalSection>[
        LegalSection(
          'Overzicht',
          'Dit beleid legt uit wat $_app opslaat, waar het wordt opgeslagen en '
              'welke keuzes je hebt. Kort gezegd: je financiële gegevens zijn van'
              ' jou, ze worden eerst op je apparaat opgeslagen, en we verkopen ze'
              ' nooit, tonen je geen advertenties en volgen je niet. Een paar '
              'optionele functies (inloggen en synchroniseren, DGOTIX AI, bonnen '
              'scannen in de cloud en betaalde abonnementen) sturen bepaalde '
              'gegevens alleen naar een dienst als je ze gebruikt, zoals '
              'hieronder beschreven.',
        ),
        const LegalSection(
          'Wat we opslaan',
          'De informatie die je zelf invult: inkomsten, uitgaven, budgetten, '
              'doelen, schulden, portemonnees, eigen categorieën en je '
              'weergavevoorkeuren (thema, taal, basisvaluta). Als je een account '
              'aanmaakt, bewaren we ook je e-mailadres, je abonnement en de '
              'status ervan, en gebruikstellers per periode voor DGOTIX AI en het'
              ' scannen van bonnen in de cloud — alleen om de limieten van je '
              'abonnement toe te passen. We bewaren je vragen aan DGOTIX AI en je'
              ' bonfoto\'s niet; als je een AI-antwoord meldt, bewaren we dat '
              'antwoord en je optionele notitie om het te bekijken.',
        ),
        const LegalSection(
          'Waar je gegevens staan',
          'Alles wordt eerst op je apparaat opgeslagen (in de app, of voor de '
              'webversie in je browser), zodat de app ook zonder account of '
              'verbinding werkt. Als je inlogt, worden je gegevens ook '
              'automatisch tussen je apparaten gesynchroniseerd: een kopie staat '
              'in onze database (gehost door Supabase), gekoppeld aan je account '
              'en zo afgeschermd dat alleen jij hem kunt lezen. Je kunt '
              'synchronisatie uitzetten in Instellingen; dan blijven je gegevens '
              'alleen op dit apparaat.',
        ),
        const LegalSection(
          'Je account en e-mails',
          'Je e-mailadres wordt gebruikt om je in te loggen en om '
              'accountmails te sturen, zoals de bevestiging van je adres en het '
              'opnieuw instellen van je wachtwoord (verstuurd via Brevo). Het '
              'wordt nooit gebruikt voor advertenties of gedeeld voor marketing. '
              'Bij registreren en inloggen houdt een korte controle of je een '
              'mens bent (Cloudflare Turnstile) geautomatiseerd misbruik buiten '
              'de deur.',
        ),
        const LegalSection(
          'DGOTIX AI',
          'DGOTIX AI is optioneel. Als je een vraag stelt, worden de tekst van '
              'die vraag en een samenvatting van je cijfers (totalen per maand en'
              ' categorie tot 12 maanden, budgetten, saldi van portemonnees, '
              'doelen, terugkerende transacties, seizoensbudgetten en spaarkringen'
              ' — alleen bedragen en datums, nooit omschrijvingen, notities of de'
              ' namen die je dingen geeft) via onze beveiligde server naar een '
              'AI-aanbieder (Google Gemini, OpenAI of Anthropic) gestuurd om het '
              'antwoord te maken. Onze server gebruikt onze eigen sleutels en '
              'registreert alleen gebruiksmetadata, nooit je vraag of je cijfers.'
              ' We gebruiken je gegevens niet om modellen te trainen. Antwoorden '
              'worden automatisch gemaakt, dus controleer belangrijke cijfers '
              'voordat je ernaar handelt.',
        ),
        const LegalSection(
          'Bonnen scannen',
          'Op Android kunnen bonnen volledig op je apparaat worden gelezen. '
              'Scannen in de cloud stuurt de foto van de bon via onze beveiligde '
              'server naar een AI-aanbieder, alleen om de winkel, datum, het '
              'bedrag, de artikelen en de categorie te lezen; de foto wordt niet '
              'bewaard.',
        ),
        const LegalSection(
          'Betalingen en abonnementen',
          'Betaalde abonnementen zijn optioneel. Je betaalt via de beveiligde '
              'checkout van Whop (whop.com), onze betaalpartner, of met PayPal als'
              ' je dat kiest. Zij verzamelen de factuurgegevens die ze nodig '
              'hebben (zoals naam, e-mail, land en betaalmethode) volgens hun '
              'eigen privacybeleid; wij zien of bewaren nooit je volledige '
              'kaartgegevens. We bewaren je abonnement, de status ervan, de '
              'verlengingsdatum en de abonnementskenmerken van de betaalpartner '
              'om je de juiste toegang te geven, plus een registratie van '
              'kortingscodes die je gebruikt.',
        ),
        const LegalSection(
          'Dienstverleners',
          'Afhankelijk van de functies die je gebruikt: Supabase (accounts, '
              'synchronisatie en onze serverfuncties); Whop en PayPal '
              '(betalingen); Brevo (accountmails); Cloudflare Turnstile (de '
              'controle bij het inloggen); GitHub Pages (hosting van onze website'
              ' en web-app); Google, OpenAI en Anthropic (DGOTIX AI en bonnen '
              'scannen in de cloud); en openbare bronnen voor marktgegevens voor '
              'actuele cijfers — wisselkoersen (open.er-api.com) en cryptoprijzen'
              ' (CoinGecko) — waarvan de verzoeken alleen valuta- of '
              'activasymbolen bevatten, nooit je persoonlijke of financiële '
              'gegevens. Elke dienstverlener verwerkt gegevens alleen om zijn '
              'deel van de dienst te leveren.',
        ),
        const LegalSection(
          'Beveiliging',
          'Verbindingen met onze diensten zijn versleuteld (HTTPS). In onze '
              'database zijn de gegevens van elke gebruiker zo afgeschermd dat het'
              ' ene account nooit die van een ander kan lezen. Serversleutels '
              'komen nooit in de app, betaalmeldingen worden gecontroleerd voordat'
              ' ze iets veranderen, en je kunt op je apparaat een '
              'app-vergrendeling instellen (pincode of vingerafdruk).',
        ),
        const LegalSection(
          'Wat we niet doen',
          'We verkopen of verhuren je gegevens niet, tonen geen advertenties en '
              'doen niet aan gedragstracking of analyses van je financiële '
              'activiteit.',
        ),
        // Only while the totals are on (and trips are only in SmartTrip).
        if (AppEnv.anonStats && AppEnv.smartTrip)
          const LegalSection(
            'Anonieme tellingen',
            'Als je een reis aanmaakt, stuurt de app alleen de woorden “er is '
                'een reis gepland”, en onze server telt één op bij het totaal van'
                ' die dag. Er wordt verder niets mee verstuurd of bewaard — geen '
                'account, apparaat, bestemming of bedrag — dus de totalen kunnen '
                'niet aan jou worden gekoppeld. We gebruiken ze alleen om te weten'
                ' hoeveel de app wordt gebruikt en om partners totaalcijfers te '
                'laten zien. Je kunt dit uitzetten in Instellingen, onder '
                'Privacy.',
          ),
        const LegalSection(
          'Hoe lang we gegevens bewaren',
          'Gegevens op je apparaat blijven tot je ze verwijdert of de app '
              'verwijdert. Je account, gesynchroniseerde gegevens, gebruikstellers'
              ' en metadata van verzoeken worden bewaard zolang je account bestaat'
              ' — alleen om de dienst te laten werken en de limieten van je '
              'abonnement toe te passen — en definitief gewist als je het '
              'verwijdert. Whop en PayPal bewaren de factuurgegevens die ze '
              'wettelijk moeten bewaren.',
        ),
        LegalSection(
          'Je rechten en instellingen',
          'Je kunt je gegevens altijd in de app bekijken en corrigeren, een '
              'volledige back-up exporteren, synchronisatie uitzetten, uitloggen '
              'en je account met alle gegevens verwijderen (zie hieronder). Je '
              'kunt een betaald abonnement op elk moment opzeggen (zie de '
              'Voorwaarden). Voor elk ander verzoek over je persoonsgegevens — '
              'zoals inzage, correctie, verwijdering of bezwaar — neem contact op'
              ' $_reachNl en we antwoorden snel.',
        ),
        const LegalSection(
          'Je account en gegevens verwijderen',
          'Open in de app of de webversie, op elk apparaat, Instellingen, dan '
              'Account, dan “Mijn account verwijderen”. Dit verwijdert je account '
              'en alles wat ervoor op onze servers staat (profiel, '
              'gesynchroniseerde gegevens, abonnementsgegevens en gebruikstellers)'
              ' definitief, en wist je gegevens op dat apparaat. Zeg eerst een '
              'betaald abonnement op. Verwijderen kan niet ongedaan worden '
              'gemaakt, dus exporteer vooraf een back-up als je je gegevens later'
              ' misschien wilt hebben.',
        ),
        LegalSection(
          'Leeftijd',
          '$_app is bedoeld voor mensen van 16 jaar en ouder. We verzamelen niet'
              ' bewust gegevens van jongere kinderen; als je denkt dat een kind '
              'een account heeft aangemaakt, neem contact op $_reachNl en we '
              'verwijderen het.',
        ),
        LegalSection(
          'Wijzigingen en contact',
          'We kunnen dit beleid bijwerken; de datum hierboven is die van de '
              'nieuwste versie. Neem voor vragen over privacy contact op '
              '$_reachNl.',
        ),
      ];

  // ---- Terms (Dutch) ----
  static List<LegalSection> get _termsNl => <LegalSection>[
        LegalSection(
          'Aanvaarding',
          'Door $_app te gebruiken ga je akkoord met deze voorwaarden. Als je '
              'niet akkoord gaat, gebruik de app dan niet.',
        ),
        LegalSection(
          'Wie het mag gebruiken',
          'Je moet minstens 16 jaar oud zijn om $_app te gebruiken. Als je een '
              'account aanmaakt, houd je inloggegevens veilig; je bent '
              'verantwoordelijk voor wat er met je account gebeurt.',
        ),
        const LegalSection(
          'Wat de dienst is',
          'Een persoonlijk hulpmiddel voor budget en planning om inkomsten, '
              'uitgaven, budgetten, doelen en bijbehorende inzichten bij te houden,'
              ' met optionele AI-hulp, bonnen scannen, synchronisatie tussen '
              'apparaten en betaalde abonnementen.',
        ),
        const LegalSection(
          'Planningshulpmiddelen, geen professioneel advies',
          'Budgetten, prognoses, de zakat-berekening en de antwoorden van '
              'DGOTIX AI zijn planningshulpmiddelen die je helpen beslissen. Ze '
              'zijn geen professioneel financieel, fiscaal of religieus advies. '
              'Laat religieuze verplichtingen zoals zakat bevestigen door een '
              'bevoegde geleerde; raadpleeg voor grote financiële beslissingen '
              'een bevoegde adviseur.',
        ),
        const LegalSection(
          'AI-functies',
          'DGOTIX AI en het scannen van bonnen in de cloud geven automatische '
              'resultaten om je tijd te besparen; controleer belangrijke cijfers '
              'voordat je ernaar handelt. Deze functies zijn inbegrepen binnen '
              'redelijke gebruiksgrenzen die van je abonnement afhangen, en '
              'kunnen worden aangepast om de dienst snel en betrouwbaar te houden '
              'voor iedereen.',
        ),
        const LegalSection(
          'Abonnementen, facturering en verlenging',
          'De basisapp is gratis. Betaalde abonnementen (Pro) ontgrendelen '
              'hogere limieten en extra functies tegen de prijzen die in de app '
              'staan. Een betaald abonnement wordt elke factuurperiode (maandelijks'
              ' of jaarlijks) automatisch verlengd tot je opzegt. Betalingen '
              'worden verwerkt door Whop, onze betaalpartner (of door PayPal als '
              'je dat kiest); eventuele belastingen kunnen worden toegevoegd en '
              'worden altijd bij het afrekenen getoond voordat je betaalt. Je kunt'
              ' op elk moment opzeggen en houdt toegang tot het einde van de '
              'periode die je al betaald hebt. Als prijzen of functies '
              'veranderen, worden de actuele voorwaarden altijd getoond voordat '
              'je je abonneert.',
        ),
        const LegalSection(
          'Onze betaalpartner: Whop',
          'SmartBudget wordt verkocht door DGOTIX. Afrekenen en facturering '
              'worden verzorgd door Whop (whop.com), dat de betaling via de eigen '
              'beveiligde checkout verwerkt, vóór het betalen de volledige prijs '
              'inclusief belastingen toont en je de kwitantie stuurt. Je kunt je '
              'abonnement in de app beheren of opzeggen (Abonnementen → '
              'Beheren).',
        ),
        LegalSection(
          'Terugbetalingsbeleid',
          'Behalve waar de wet dat vereist, worden betalingen in principe niet '
              'terugbetaald zodra een factuurperiode is begonnen, omdat je toegang'
              ' houdt tot het einde ervan. Je kunt op elk moment opzeggen om '
              'toekomstige verlengingen te stoppen. Voor een terugbetalingsverzoek'
              ' of een vraag over een afschrijving neem je contact op $_reachNl: '
              'we beoordelen elk verzoek volgens het geldende consumentenrecht en '
              'betalen goedgekeurde bedragen terug via Whop (of PayPal).',
        ),
        const LegalSection(
          'Kortingscodes',
          'Kortingscodes zijn optioneel en veranderen alleen de prijs bij het '
              'afrekenen (of geven een proefperiode). Elke code heeft eigen '
              'voorwaarden (geldigheid, gebruikslimieten, één per klant) en kan '
              'worden ingetrokken of verlopen. Ze hebben geen geldwaarde en zijn '
              'niet te combineren, tenzij anders vermeld.',
        ),
        const LegalSection(
          'Je gegevens en back-ups',
          'Je bent verantwoordelijk voor de juistheid van de gegevens die je '
              'invult. Om je gegevens veilig te houden tussen apparaten, log je in'
              ' om ze te synchroniseren, of exporteer je regelmatig een back-up '
              'via Instellingen.',
        ),
        LegalSection(
          'Beschikbaarheid',
          'We werken eraan om $_app beschikbaar en betrouwbaar te houden. Voor '
              'zover de wet dat toestaat, wordt de app geleverd “zoals hij is”, '
              'zonder garanties van welke aard ook. Actuele marktgegevens, AI en '
              'betalingen hangen af van diensten van derden en kunnen soms '
              'vertraagd of niet beschikbaar zijn; zo\'n onderbreking houdt je '
              'nooit tegen bij het gebruik van de basisbudgettools, die ook '
              'offline werken. Functies kunnen in de loop van de tijd '
              'veranderen.',
        ),
        const LegalSection(
          'Beperking van aansprakelijkheid',
          'Voor zover de wet dat toestaat, zijn we niet aansprakelijk voor '
              'indirecte schade of gevolgschade, of voor beslissingen die je '
              'neemt op basis van de cijfers in de app. Niets in deze voorwaarden'
              ' beperkt rechten die je als consument hebt en waarvan niet kan '
              'worden afgeweken.',
        ),
        const LegalSection(
          'Toegestaan gebruik',
          'Misbruik de dienst niet, probeer de beveiliging of '
              'abonnementslimieten niet te breken of te omzeilen, en gebruik hem '
              'niet voor onwettige doeleinden.',
        ),
        LegalSection(
          'Stoppen met gebruik',
          'Je kunt op elk moment stoppen met $_app en je account verwijderen. '
              'We kunnen een account schorsen dat deze voorwaarden schendt of de '
              'dienst of andere gebruikers in gevaar brengt.',
        ),
        LegalSection(
          'Merk en eigendom',
          'De naam $_app, het merk $_brand en het ontwerp en de code van de app '
              'blijven eigendom van hun eigenaar. Je gegevens blijven van jou.',
        ),
        LegalSection(
          'Wijzigingen en contact',
          'We kunnen deze voorwaarden bijwerken en de datum van de nieuwste '
              'versie tonen; als je de app na een update blijft gebruiken, ga je '
              'akkoord met de herziene voorwaarden. Neem voor vragen contact op '
              '$_reachNl.',
        ),
      ];

  // ---- Privacy (Bosnian) ----
  static List<LegalSection> get _privacyBs => <LegalSection>[
        LegalSection(
          'Pregled',
          'Ova politika objašnjava šta $_app čuva, gdje se čuva i kakve izbore '
              'imaš. Ukratko: tvoji finansijski podaci su tvoji, prvo se čuvaju '
              'na tvom uređaju, a mi ih nikad ne prodajemo, ne prikazujemo ti '
              'reklame i ne pratimo te. Nekoliko opcionalnih funkcija (prijava i'
              ' sinhronizacija, DGOTIX AI, skeniranje računa u oblaku i plaćeni '
              'paketi) šalju određene podatke nekoj usluzi samo kad ih koristiš, '
              'kako je opisano ispod.',
        ),
        const LegalSection(
          'Šta čuvamo',
          'Podatke koje sam uneseš: prihode, troškove, budžete, ciljeve, '
              'dugove, novčanike, vlastite kategorije i postavke prikaza (tema, '
              'jezik, osnovna valuta). Ako napraviš račun, čuvamo i tvoju e-mail'
              ' adresu, paket i status pretplate te brojače korištenja po '
              'periodima za DGOTIX AI i skeniranje računa u oblaku — samo da '
              'primijenimo ograničenja tvog paketa. Ne čuvamo tvoja pitanja za '
              'DGOTIX AI niti slike računa; ako prijaviš AI odgovor, čuvamo taj '
              'odgovor i tvoju opcionalnu bilješku da ga pregledamo.',
        ),
        const LegalSection(
          'Gdje su tvoji podaci',
          'Sve se prvo čuva na tvom uređaju (u aplikaciji ili, za web verziju,'
              ' u pregledniku), pa aplikacija radi i bez računa ili veze. Ako se '
              'prijaviš, tvoji podaci se i automatski sinhronizuju između tvojih '
              'uređaja: kopija se čuva u našoj bazi podataka (koju hostuje '
              'Supabase), vezana za tvoj račun i odvojena tako da je samo ti '
              'možeš čitati. Sinhronizaciju možeš isključiti u Postavkama; tada '
              'podaci ostaju samo na ovom uređaju.',
        ),
        const LegalSection(
          'Tvoj račun i e-mailovi',
          'Tvoja e-mail adresa služi za prijavu i slanje e-mailova o računu, '
              'kao što su potvrda adrese i resetovanje lozinke (šalju se preko '
              'Breva). Nikad se ne koristi za reklame niti dijeli u marketinške '
              'svrhe. Pri registraciji i prijavi kratka provjera da si osoba '
              '(Cloudflare Turnstile) sprečava automatizovane zloupotrebe.',
        ),
        const LegalSection(
          'DGOTIX AI',
          'DGOTIX AI je opcionalan. Kad postaviš pitanje, tekst pitanja i '
              'sažetak tvojih brojki (zbirovi po mjesecu i kategoriji za najviše '
              '12 mjeseci, budžeti, stanja novčanika, ciljevi, ponavljajuće '
              'transakcije, sezonski budžeti i krugovi štednje — samo iznosi i '
              'datumi, nikad opisi, bilješke ili nazivi koje daješ stvarima) '
              'šalju se preko našeg sigurnog servera AI pružaocu (Google Gemini, '
              'OpenAI ili Anthropic) da napravi odgovor. Naš server koristi naše '
              'ključeve i bilježi samo metapodatke o korištenju, nikad tvoje '
              'pitanje ili brojke. Tvoje podatke ne koristimo za treniranje '
              'modela. Odgovori se prave automatski, pa provjeri važne brojke '
              'prije nego što djeluješ.',
        ),
        const LegalSection(
          'Skeniranje računa',
          'Na Androidu se računi mogu pročitati u potpunosti na tvom uređaju. '
              'Skeniranje u oblaku šalje sliku računa preko našeg sigurnog '
              'servera AI pružaocu samo da pročita trgovca, datum, iznos, stavke '
              'i kategoriju; slika se ne čuva.',
        ),
        const LegalSection(
          'Plaćanja i pretplate',
          'Plaćeni paketi su opcionalni. Plaćaš na sigurnoj naplati Whopa '
              '(whop.com), našeg pružaoca plaćanja, ili PayPalom ako to izabereš.'
              ' Oni prikupljaju potrebne podatke za naplatu (npr. ime, e-mail, '
              'zemlju i način plaćanja) prema svojim politikama privatnosti; mi '
              'nikad ne vidimo niti čuvamo pune podatke tvoje kartice. Čuvamo '
              'tvoj paket, status pretplate, datum obnove i identifikatore '
              'pretplate pružaoca plaćanja da ti damo pravi pristup, kao i '
              'zapis o iskorištenim promotivnim kodovima.',
        ),
        const LegalSection(
          'Pružaoci usluga',
          'Zavisno od funkcija koje koristiš: Supabase (računi, sinhronizacija'
              ' i naše serverske funkcije); Whop i PayPal (plaćanja); Brevo '
              '(e-mailovi o računu); Cloudflare Turnstile (provjera pri prijavi);'
              ' GitHub Pages (hosting naše web stranice i web aplikacije); '
              'Google, OpenAI i Anthropic (DGOTIX AI i skeniranje računa u '
              'oblaku); te javni izvori tržišnih podataka za aktuelne brojke — '
              'kursevi (open.er-api.com) i cijene kripta (CoinGecko) — čiji '
              'zahtjevi sadrže samo oznake valuta ili imovine, nikad tvoje lične '
              'ili finansijske podatke. Svaki pružalac obrađuje podatke samo da '
              'pruži svoj dio usluge.',
        ),
        const LegalSection(
          'Sigurnost',
          'Veze s našim uslugama su šifrovane (HTTPS). U našoj bazi podataka '
              'zapisi svakog korisnika su odvojeni tako da jedan račun nikad ne '
              'može čitati tuđe. Serverski ključevi nikad ne dolaze do '
              'aplikacije, obavještenja o plaćanju se provjeravaju prije nego što'
              ' išta promijene, a na uređaju možeš uključiti zaključavanje '
              'aplikacije (PIN ili otisak prsta).',
        ),
        const LegalSection(
          'Šta ne radimo',
          'Ne prodajemo niti iznajmljujemo tvoje podatke, ne prikazujemo '
              'reklame i ne pratimo ponašanje niti analiziramo tvoju finansijsku '
              'aktivnost.',
        ),
        // Only while the totals are on (and trips are only in SmartTrip).
        if (AppEnv.anonStats && AppEnv.smartTrip)
          const LegalSection(
            'Anonimno brojanje',
            'Kad napraviš putovanje, aplikacija šalje samo riječi „isplanirano '
                'je putovanje“, a naš server dodaje jedan zbiru za taj dan. Ništa '
                'drugo se ne šalje niti čuva uz to — ni račun, ni uređaj, ni '
                'destinacija, ni iznos — pa se zbirovi ne mogu povezati s tobom. '
                'Koristimo ih samo da znamo koliko se aplikacija koristi i da '
                'partnerima pokažemo ukupne brojke. Ovo možeš isključiti u '
                'Postavkama, pod Privatnost.',
          ),
        const LegalSection(
          'Koliko dugo čuvamo podatke',
          'Podaci na tvom uređaju ostaju dok ih ne obrišeš ili ne ukloniš '
              'aplikaciju. Tvoj račun, sinhronizovani podaci, brojači korištenja '
              'i metapodaci zahtjeva čuvaju se dok račun postoji — samo da '
              'usluga radi i da se primijene ograničenja paketa — i trajno se '
              'brišu kad ga obrišeš. Whop i PayPal čuvaju zapise o naplati koje '
              'su zakonom dužni čuvati.',
        ),
        LegalSection(
          'Tvoja prava i kontrole',
          'Svoje podatke možeš u aplikaciji vidjeti i ispraviti u bilo kojem '
              'trenutku, izvesti puni backup, isključiti sinhronizaciju, odjaviti'
              ' se i obrisati račun sa svim podacima (vidi ispod). Plaćenu '
              'pretplatu možeš otkazati bilo kada (vidi Uslove). Za svaki drugi '
              'zahtjev o tvojim ličnim podacima — uključujući pristup, ispravku, '
              'brisanje ili prigovor — kontaktiraj nas $_reachBs i brzo ćemo '
              'odgovoriti.',
        ),
        const LegalSection(
          'Brisanje računa i podataka',
          'U aplikaciji ili web verziji, na bilo kojem uređaju, otvori '
              'Postavke, pa Račun, pa „Obriši moj račun“. Time se trajno briše '
              'tvoj račun i sve što je za njega sačuvano na našim serverima '
              '(profil, sinhronizovani podaci, zapis o pretplati i brojači '
              'korištenja), a brišu se i tvoji podaci na tom uređaju. Prvo '
              'otkaži plaćenu pretplatu. Brisanje se ne može poništiti, pa prije'
              ' izvezi backup ako bi ti podaci mogli trebati kasnije.',
        ),
        LegalSection(
          'Starost',
          '$_app je namijenjen osobama od 16 i više godina. Svjesno ne '
              'prikupljamo podatke mlađe djece; ako misliš da je dijete '
              'napravilo račun, kontaktiraj nas $_reachBs i obrisat ćemo ga.',
        ),
        LegalSection(
          'Izmjene i kontakt',
          'Ovu politiku možemo ažurirati; datum iznad pokazuje najnoviju '
              'verziju. Za pitanja o privatnosti kontaktiraj nas $_reachBs.',
        ),
      ];

  // ---- Terms (Bosnian) ----
  static List<LegalSection> get _termsBs => <LegalSection>[
        LegalSection(
          'Prihvatanje',
          'Korištenjem aplikacije $_app prihvataš ove uslove. Ako se ne slažeš,'
              ' nemoj koristiti aplikaciju.',
        ),
        LegalSection(
          'Ko je može koristiti',
          'Moraš imati najmanje 16 godina da koristiš $_app. Ako napraviš '
              'račun, čuvaj podatke za prijavu; odgovoran si za aktivnosti na '
              'svom računu.',
        ),
        const LegalSection(
          'Šta je usluga',
          'Lični alat za budžet i planiranje za praćenje prihoda, troškova, '
              'budžeta, ciljeva i povezanih uvida, uz opcionalnu pomoć AI-a, '
              'skeniranje računa, sinhronizaciju između uređaja i plaćene pakete.',
        ),
        const LegalSection(
          'Alati za planiranje, ne stručni savjet',
          'Budžeti, projekcije, izračun zekata i odgovori DGOTIX AI su alati za'
              ' planiranje koji ti pomažu da odlučiš. Nisu stručni finansijski, '
              'poreski niti vjerski savjet. Za vjerske obaveze poput zekata '
              'provjeri s kvalifikovanim alimom; za velike finansijske odluke '
              'obrati se kvalifikovanom savjetniku.',
        ),
        const LegalSection(
          'AI funkcije',
          'DGOTIX AI i skeniranje računa u oblaku daju automatske rezultate da '
              'ti uštede vrijeme; provjeri važne brojke prije nego što djeluješ. '
              'Ove funkcije su uključene u granicama razumnog korištenja koje '
              'zavise od tvog paketa i mogu se prilagoditi da usluga ostane brza '
              'i pouzdana za sve.',
        ),
        const LegalSection(
          'Pretplate, naplata i obnove',
          'Osnovna aplikacija je besplatna. Plaćeni paketi (Pro) otključavaju '
              'veća ograničenja i dodatne funkcije po cijenama prikazanim u '
              'aplikaciji. Plaćeni paket se automatski obnavlja svakog perioda '
              'naplate (mjesečno ili godišnje) dok ga ne otkažeš. Plaćanja '
              'obrađuje Whop, naš pružalac plaćanja (ili PayPal ako ga '
              'izabereš); mogući porezi se mogu dodati i uvijek se prikazuju pri '
              'naplati prije plaćanja. Možeš otkazati bilo kada i zadržati '
              'pristup do kraja već plaćenog perioda. Ako se cijene ili funkcije '
              'paketa promijene, aktuelni uslovi se uvijek prikazuju prije '
              'pretplate.',
        ),
        const LegalSection(
          'Naš pružalac plaćanja: Whop',
          'SmartBudget prodaje DGOTIX. Naplatu i fakturisanje obavlja Whop '
              '(whop.com), koji obrađuje plaćanje na svojoj sigurnoj naplati, '
              'prije plaćanja prikazuje punu cijenu s porezima i šalje ti '
              'potvrdu. Pretplatom možeš upravljati ili je otkazati u aplikaciji '
              '(Paketi → Upravljaj).',
        ),
        LegalSection(
          'Politika povrata novca',
          'Osim kad zakon nalaže drugačije, uplate se u pravilu ne vraćaju '
              'nakon što period naplate počne, jer zadržavaš pristup do njegovog '
              'kraja. Možeš otkazati bilo kada da zaustaviš buduće obnove. Za '
              'zahtjev za povrat ili pitanje o naplati kontaktiraj nas $_reachBs:'
              ' svaki zahtjev razmatramo prema važećem zakonu o zaštiti '
              'potrošača, a odobrene povrate vršimo preko Whopa (ili PayPala).',
        ),
        const LegalSection(
          'Promotivni kodovi',
          'Kuponi i kodovi za popust su opcionalni i mijenjaju samo cijenu '
              'pri naplati (ili daju probni period). Svaki kod ima vlastite '
              'uslove (rok važenja, ograničenja korištenja, jedan po kupcu) i '
              'može biti povučen ili isteći. Nemaju novčanu vrijednost i ne mogu '
              'se kombinovati, osim ako je navedeno.',
        ),
        const LegalSection(
          'Tvoji podaci i backup',
          'Odgovoran si za tačnost podataka koje uneseš. Da tvoji podaci budu '
              'sigurni na svim uređajima, prijavi se da ih sinhronizuješ ili '
              'redovno izvozi backup iz Postavki.',
        ),
        LegalSection(
          'Dostupnost',
          'Radimo na tome da $_app bude dostupan i pouzdan. U mjeri koju '
              'zakon dozvoljava, aplikacija se pruža „kakva jeste“, bez ikakvih '
              'garancija. Tržišni podaci uživo, AI i plaćanja zavise od usluga '
              'trećih strana i ponekad mogu kasniti ili biti nedostupni; takav '
              'prekid te nikad ne sprečava da koristiš osnovne alate za budžet, '
              'koji rade i bez interneta. Funkcije se vremenom mogu mijenjati.',
        ),
        const LegalSection(
          'Ograničenje odgovornosti',
          'U mjeri koju zakon dozvoljava, ne odgovaramo za indirektne ili '
              'posljedične gubitke, niti za odluke koje doneseš na osnovu brojki '
              'u aplikaciji. Ništa u ovim uslovima ne ograničava prava koja imaš '
              'kao potrošač i kojih se ne možeš odreći.',
        ),
        const LegalSection(
          'Dozvoljeno korištenje',
          'Ne zloupotrebljavaj uslugu, ne pokušavaj probiti ili zaobići njenu '
              'sigurnost ili ograničenja paketa i ne koristi je u nezakonite '
              'svrhe.',
        ),
        LegalSection(
          'Prestanak korištenja',
          'Možeš prestati koristiti $_app i obrisati račun bilo kada. Možemo '
              'suspendovati račun koji krši ove uslove ili ugrožava uslugu ili '
              'druge korisnike.',
        ),
        LegalSection(
          'Brend i vlasništvo',
          'Naziv $_app, brend $_brand te dizajn i kod aplikacije ostaju '
              'vlasništvo njihovog vlasnika. Tvoji podaci ostaju tvoji.',
        ),
        LegalSection(
          'Izmjene i kontakt',
          'Ove uslove možemo ažurirati i prikazati datum najnovije verzije; '
              'nastavak korištenja nakon ažuriranja znači da prihvataš izmijenjene'
              ' uslove. Za pitanja kontaktiraj nas $_reachBs.',
        ),
      ];

  // ---- Privacy (Albanian) ----
  static List<LegalSection> get _privacySq => <LegalSection>[
        LegalSection(
          'Përmbledhje',
          'Kjo politikë shpjegon çfarë ruan $_app, ku e ruan dhe çfarë '
              'zgjedhjesh ke. Shkurt: të dhënat e tua financiare janë të tuat, '
              'ruhen fillimisht në pajisjen tënde dhe ne nuk i shesim kurrë, nuk '
              'të shfaqim reklama dhe nuk të ndjekim. Disa funksione opsionale '
              '(hyrja dhe sinkronizimi, DGOTIX AI, skanimi i faturave në cloud '
              'dhe paketat me pagesë) i dërgojnë të dhëna të caktuara një '
              'shërbimi vetëm kur i përdor, siç përshkruhet më poshtë.',
        ),
        const LegalSection(
          'Çfarë ruajmë',
          'Informacionin që fut vetë: të ardhurat, shpenzimet, buxhetet, '
              'qëllimet, borxhet, portofolat, kategoritë e tua dhe preferencat e'
              ' shfaqjes (tema, gjuha, monedha bazë). Nëse krijon llogari, '
              'ruajmë gjithashtu email-in, paketën dhe statusin e abonimit, si '
              'dhe numëruesit e përdorimit për periudhë për DGOTIX AI dhe '
              'skanimin e faturave në cloud — vetëm për të zbatuar kufijtë e '
              'paketës. Nuk ruajmë pyetjet e tua për DGOTIX AI as imazhet e '
              'faturave; nëse raporton një përgjigje të AI, ruajmë atë përgjigje '
              'dhe shënimin tënd opsional për ta shqyrtuar.',
        ),
        const LegalSection(
          'Ku ndodhen të dhënat e tua',
          'Gjithçka ruhet fillimisht në pajisjen tënde (në aplikacion ose, për'
              ' versionin web, në shfletues), ndaj aplikacioni funksionon edhe '
              'pa llogari apo lidhje. Nëse hyn në llogari, të dhënat '
              'sinkronizohen gjithashtu automatikisht mes pajisjeve: një kopje '
              'ruhet në bazën tonë të të dhënave (e pritur nga Supabase), e '
              'lidhur me llogarinë tënde dhe e izoluar që vetëm ti ta lexosh. '
              'Mund ta çaktivizosh sinkronizimin te Cilësimet; atëherë të dhënat '
              'qëndrojnë vetëm në këtë pajisje.',
        ),
        const LegalSection(
          'Llogaria jote dhe email-et',
          'Email-i yt përdoret për hyrjen dhe për email-e të llogarisë, si '
              'konfirmimi i adresës dhe rivendosja e fjalëkalimit (dërgohen '
              'përmes Brevo). Nuk përdoret kurrë për reklama dhe nuk ndahet për '
              'marketing. Gjatë regjistrimit dhe hyrjes, një kontroll i shpejtë '
              'që je person (Cloudflare Turnstile) parandalon abuzimet e '
              'automatizuara.',
        ),
        const LegalSection(
          'DGOTIX AI',
          'DGOTIX AI është opsional. Kur bën një pyetje, teksti i saj dhe një '
              'përmbledhje e shifrave të tua (totale sipas muajit dhe kategorisë '
              'deri në 12 muaj, buxhete, gjendje portofolash, qëllime, '
              'transaksione periodike, buxhete sezonale dhe rrethe kursimi — '
              'vetëm shuma dhe data, kurrë përshkrime, shënime apo emrat që u '
              'vë gjërave) dërgohen përmes serverit tonë të sigurt te një ofrues '
              'AI (Google Gemini, OpenAI ose Anthropic) për të krijuar '
              'përgjigjen. Serveri ynë përdor çelësat tanë dhe regjistron vetëm '
              'meta të dhëna përdorimi, kurrë pyetjen apo shifrat e tua. Nuk i '
              'përdorim të dhënat e tua për të trajnuar modele. Përgjigjet '
              'krijohen automatikisht, ndaj kontrollo shifrat e rëndësishme para'
              ' se të veprosh.',
        ),
        const LegalSection(
          'Skanimi i faturave',
          'Në Android, faturat mund të lexohen plotësisht në pajisjen tënde. '
              'Skanimi në cloud e dërgon imazhin e faturës përmes serverit tonë '
              'të sigurt te një ofrues AI vetëm për të lexuar tregtarin, datën, '
              'shumën, artikujt dhe kategorinë; imazhi nuk ruhet.',
        ),
        const LegalSection(
          'Pagesat dhe abonimet',
          'Paketat me pagesë janë opsionale. Paguan në arkën e sigurt të Whop '
              '(whop.com), ofruesit tonë të pagesave, ose me PayPal nëse e '
              'zgjedh. Ata mbledhin të dhënat e faturimit që u nevojiten (si '
              'emri, email-i, shteti dhe mënyra e pagesës) sipas politikave të '
              'tyre të privatësisë; ne nuk i shohim dhe nuk i ruajmë kurrë të '
              'dhënat e plota të kartës. Ruajmë paketën, statusin e abonimit, '
              'datën e rinovimit dhe identifikuesit e abonimit të ofruesit për të'
              ' të dhënë aksesin e duhur, si dhe një regjistër të kodeve '
              'promocionale që përdor.',
        ),
        const LegalSection(
          'Ofruesit e shërbimeve',
          'Sipas funksioneve që përdor: Supabase (llogaritë, sinkronizimi dhe '
              'funksionet e serverit); Whop dhe PayPal (pagesat); Brevo (email-et'
              ' e llogarisë); Cloudflare Turnstile (kontrolli në hyrje); GitHub '
              'Pages (pritja e faqes dhe aplikacionit web); Google, OpenAI dhe '
              'Anthropic (DGOTIX AI dhe skanimi i faturave në cloud); dhe burime '
              'publike të dhënash tregu për shifra në kohë reale — kurse këmbimi '
              '(open.er-api.com) dhe çmime kripto (CoinGecko) — kërkesat e të '
              'cilave përmbajnë vetëm simbole monedhash ose aktivesh, kurrë të '
              'dhënat e tua personale apo financiare. Çdo ofrues i përpunon të '
              'dhënat vetëm për të ofruar pjesën e vet të shërbimit.',
        ),
        const LegalSection(
          'Siguria',
          'Lidhjet me shërbimet tona janë të enkriptuara (HTTPS). Në bazën tonë'
              ' të të dhënave, regjistrimet e çdo përdoruesi janë të izoluara që '
              'një llogari të mos lexojë kurrë ato të një tjetre. Çelësat e '
              'serverit nuk arrijnë kurrë në aplikacion, njoftimet e pagesave '
              'verifikohen para se të ndryshojnë diçka dhe mund të aktivizosh '
              'kyçjen e aplikacionit (PIN ose gjurmë gishti) në pajisjen tënde.',
        ),
        const LegalSection(
          'Çfarë nuk bëjmë',
          'Nuk i shesim dhe nuk i japim me qira të dhënat e tua, nuk shfaqim '
              'reklama dhe nuk bëjmë ndjekje të sjelljes apo analiza të '
              'aktivitetit tënd financiar.',
        ),
        // Only while the totals are on (and trips are only in SmartTrip).
        if (AppEnv.anonStats && AppEnv.smartTrip)
          const LegalSection(
            'Numërime anonime',
            'Kur krijon një udhëtim, aplikacioni dërgon vetëm fjalët “u '
                'planifikua një udhëtim” dhe serveri ynë shton një te totali i '
                'asaj dite. Asgjë tjetër nuk dërgohet apo ruhet bashkë me të — '
                'as llogari, as pajisje, as destinacion, as shumë — ndaj totalet '
                'nuk mund të lidhen me ty. I përdorim vetëm për të ditur sa '
                'përdoret aplikacioni dhe për t\'u treguar partnerëve shifra të '
                'përgjithshme. Mund ta çaktivizosh te Cilësimet, nën Privatësia.',
          ),
        const LegalSection(
          'Sa kohë i ruajmë të dhënat',
          'Të dhënat në pajisjen tënde qëndrojnë derisa t\'i fshish ose të '
              'heqësh aplikacionin. Llogaria, të dhënat e sinkronizuara, '
              'numëruesit e përdorimit dhe meta të dhënat e kërkesave ruhen sa '
              'kohë ekziston llogaria — vetëm për të funksionuar shërbimi dhe '
              'për të zbatuar kufijtë e paketës — dhe fshihen përgjithmonë kur e'
              ' fshin. Whop dhe PayPal ruajnë regjistrat e faturimit që ligji i '
              'detyron t\'i ruajnë.',
        ),
        LegalSection(
          'Të drejtat dhe kontrollet e tua',
          'Mund t\'i shohësh dhe t\'i korrigjosh të dhënat në aplikacion në '
              'çdo kohë, të eksportosh një kopje të plotë rezervë, të çaktivizosh'
              ' sinkronizimin, të dalësh dhe të fshish llogarinë me të gjitha të'
              ' dhënat (shih më poshtë). Mund ta anulosh një abonim me pagesë në'
              ' çdo kohë (shih Kushtet). Për çdo kërkesë tjetër për të dhënat e '
              'tua personale — përfshirë aksesin, korrigjimin, fshirjen ose '
              'kundërshtimin — na kontakto $_reachSq dhe do të përgjigjemi '
              'shpejt.',
        ),
        const LegalSection(
          'Fshirja e llogarisë dhe e të dhënave',
          'Në aplikacion ose në versionin web, në çdo pajisje, hap Cilësimet, '
              'pastaj Llogaria, pastaj “Fshi llogarinë time”. Kjo fshin '
              'përgjithmonë llogarinë dhe gjithçka të ruajtur për të në '
              'serverat tanë (profili, të dhënat e sinkronizuara, regjistri i '
              'abonimit dhe numëruesit e përdorimit) dhe fshin të dhënat në atë '
              'pajisje. Anulo më parë çdo abonim me pagesë. Fshirja nuk mund të '
              'zhbëhet, ndaj eksporto një kopje rezervë nëse mund t\'i duash të '
              'dhënat më vonë.',
        ),
        LegalSection(
          'Mosha',
          '$_app është menduar për persona 16 vjeç e lart. Nuk mbledhim '
              'qëllimisht të dhëna nga fëmijë më të vegjël; nëse mendon se një '
              'fëmijë ka krijuar llogari, na kontakto $_reachSq dhe do ta '
              'fshijmë.',
        ),
        LegalSection(
          'Ndryshimet dhe kontakti',
          'Mund ta përditësojmë këtë politikë; data e shfaqur më sipër është '
              'ajo e versionit më të fundit. Për pyetje për privatësinë, na '
              'kontakto $_reachSq.',
        ),
      ];

  // ---- Terms (Albanian) ----
  static List<LegalSection> get _termsSq => <LegalSection>[
        LegalSection(
          'Pranimi',
          'Duke përdorur $_app, pranon këto kushte. Nëse nuk pajtohesh, mos e '
              'përdor aplikacionin.',
        ),
        LegalSection(
          'Kush mund ta përdorë',
          'Duhet të jesh të paktën 16 vjeç për të përdorur $_app. Nëse krijon '
              'llogari, mbaji të sigurta të dhënat e hyrjes; je përgjegjës për '
              'aktivitetin në llogarinë tënde.',
        ),
        const LegalSection(
          'Çfarë është shërbimi',
          'Një mjet personal buxheti dhe planifikimi për të ndjekur të ardhurat,'
              ' shpenzimet, buxhetet, qëllimet dhe vështrimet përkatëse, me '
              'ndihmë opsionale nga AI, skanim faturash, sinkronizim mes '
              'pajisjeve dhe paketa me pagesë.',
        ),
        const LegalSection(
          'Mjete planifikimi, jo këshillë profesionale',
          'Buxhetet, parashikimet, llogaritja e zekatit dhe përgjigjet e DGOTIX'
              ' AI janë mjete planifikimi që të ndihmojnë të vendosësh. Nuk janë '
              'këshillë profesionale financiare, tatimore apo fetare. Për '
              'detyrime fetare si zekati, konfirmo me një dijetar të kualifikuar;'
              ' për vendime të mëdha financiare, konsultohu me një këshilltar të '
              'kualifikuar.',
        ),
        const LegalSection(
          'Funksionet AI',
          'DGOTIX AI dhe skanimi i faturave në cloud japin rezultate automatike'
              ' për të të kursyer kohë; kontrollo shifrat e rëndësishme para se '
              'të veprosh. Këto funksione përfshihen brenda kufijve të përdorimit'
              ' të arsyeshëm që varen nga paketa jote dhe mund të përshtaten për '
              'ta mbajtur shërbimin të shpejtë dhe të besueshëm për të gjithë.',
        ),
        const LegalSection(
          'Abonimet, faturimi dhe rinovimet',
          'Aplikacioni bazë është falas. Paketat me pagesë (Pro) zhbllokojnë '
              'kufij më të lartë dhe funksione shtesë me çmimet e shfaqura në '
              'aplikacion. Një paketë me pagesë rinovohet automatikisht çdo '
              'periudhë faturimi (mujore ose vjetore) derisa ta anulosh. Pagesat '
              'përpunohen nga Whop, ofruesi ynë i pagesave (ose nga PayPal nëse e'
              ' zgjedh); taksat e zbatueshme mund të shtohen dhe shfaqen gjithmonë'
              ' në arkë para se të paguash. Mund ta anulosh në çdo kohë dhe e '
              'mban aksesin deri në fund të periudhës së paguar. Nëse çmimet ose '
              'funksionet e paketës ndryshojnë, kushtet aktuale shfaqen gjithmonë'
              ' para se të abonohesh.',
        ),
        const LegalSection(
          'Ofruesi ynë i pagesave: Whop',
          'SmartBudget shitet nga DGOTIX. Arka dhe faturimi kryhen nga Whop '
              '(whop.com), i cili e përpunon pagesën në arkën e vet të sigurt, '
              'shfaq çmimin e plotë me taksat para pagesës dhe të dërgon '
              'faturën. Mund ta menaxhosh ose ta anulosh abonimin nga '
              'aplikacioni (Paketat → Menaxho).',
        ),
        LegalSection(
          'Politika e rimbursimit',
          'Përveç kur e kërkon ligji, pagesat në përgjithësi nuk rimbursohen '
              'pasi të ketë nisur një periudhë faturimi, sepse e mban aksesin '
              'deri në fund të saj. Mund ta anulosh në çdo kohë për të ndaluar '
              'rinovimet e ardhshme. Për një kërkesë rimbursimi ose pyetje për '
              'një tarifim, na kontakto $_reachSq: e shqyrtojmë çdo kërkesë sipas'
              ' ligjit të zbatueshëm për mbrojtjen e konsumatorit dhe i bëjmë '
              'rimbursimet e miratuara përmes Whop (ose PayPal).',
        ),
        const LegalSection(
          'Kodet promocionale',
          'Kuponët dhe kodet e zbritjes janë opsionale dhe ndryshojnë vetëm '
              'çmimin në arkë (ose japin një periudhë prove). Çdo kod ka kushtet e'
              ' veta (vlefshmëria, kufijtë e përdorimit, një për klient) dhe mund '
              'të tërhiqet ose të skadojë. Nuk kanë vlerë në para dhe nuk mund të'
              ' kombinohen, përveç kur thuhet ndryshe.',
        ),
        const LegalSection(
          'Të dhënat dhe kopjet rezervë',
          'Je përgjegjës për saktësinë e të dhënave që fut. Për t\'i mbajtur të'
              ' sigurta mes pajisjeve, hyr për t\'i sinkronizuar ose eksporto '
              'rregullisht një kopje rezervë nga Cilësimet.',
        ),
        LegalSection(
          'Disponueshmëria',
          'Punojmë që $_app të jetë i disponueshëm dhe i besueshëm. Në masën që'
              ' e lejon ligji, aplikacioni ofrohet “siç është”, pa garanci të '
              'asnjë lloji. Të dhënat e tregut në kohë reale, AI dhe pagesat '
              'varen nga shërbime të palëve të treta dhe ndonjëherë mund të '
              'vonohen ose të mos jenë të disponueshme; një ndërprerje e tillë '
              'nuk të pengon kurrë të përdorësh mjetet bazë të buxhetit, që '
              'funksionojnë edhe offline. Funksionet mund të ndryshojnë me kohën.',
        ),
        const LegalSection(
          'Kufizimi i përgjegjësisë',
          'Në masën që e lejon ligji, nuk mbajmë përgjegjësi për humbje '
              'indirekte ose pasuese, as për vendimet që merr bazuar në shifrat e'
              ' aplikacionit. Asgjë në këto kushte nuk kufizon të drejtat që ke '
              'si konsumator dhe që nuk mund t\'i heqësh dorë.',
        ),
        const LegalSection(
          'Përdorimi i lejuar',
          'Mos e keqpërdor shërbimin, mos provo të thyesh apo të anashkalosh '
              'sigurinë ose kufijtë e paketave dhe mos e përdor për qëllime të '
              'paligjshme.',
        ),
        LegalSection(
          'Ndërprerja e përdorimit',
          'Mund ta ndalosh përdorimin e $_app dhe ta fshish llogarinë në çdo '
              'kohë. Mund ta pezullojmë një llogari që shkel këto kushte ose që '
              'rrezikon shërbimin apo përdoruesit e tjerë.',
        ),
        LegalSection(
          'Marka dhe pronësia',
          'Emri $_app, marka $_brand, si dhe dizajni dhe kodi i aplikacionit '
              'mbeten pronë e zotëruesit të tyre. Të dhënat e tua mbeten të '
              'tuat.',
        ),
        LegalSection(
          'Ndryshimet dhe kontakti',
          'Mund t\'i përditësojmë këto kushte dhe të shfaqim datën e versionit '
              'më të fundit; përdorimi i vazhduar pas një përditësimi do të thotë'
              ' se pranon kushtet e rishikuara. Për pyetje, na kontakto $_reachSq.',
        ),
      ];

  // ---- Privacy (Russian) ----
  static List<LegalSection> get _privacyRu => <LegalSection>[
        LegalSection(
          'Обзор',
          'Эта политика объясняет, что хранит $_app, где это хранится и какой '
              'у вас есть выбор. Коротко: ваши финансовые данные принадлежат вам,'
              ' они сначала сохраняются на вашем устройстве, и мы никогда их не '
              'продаём, не показываем вам рекламу и не отслеживаем вас. Несколько'
              ' необязательных функций (вход и синхронизация, DGOTIX AI, облачное'
              ' сканирование чеков и платные тарифы) отправляют определённые '
              'данные в сервис только тогда, когда вы ими пользуетесь, как '
              'описано ниже.',
        ),
        const LegalSection(
          'Что мы храним',
          'Сведения, которые вы вводите сами: доходы, расходы, бюджеты, цели, '
              'долги, кошельки, свои категории и настройки отображения (тема, '
              'язык, основная валюта). Если вы создаёте аккаунт, мы также храним '
              'ваш адрес e-mail, ваш тариф и статус подписки, а также счётчики '
              'использования DGOTIX AI и облачного сканирования чеков за период —'
              ' только чтобы применять лимиты вашего тарифа. Мы не храним ваши '
              'вопросы к DGOTIX AI и изображения чеков; если вы пожалуетесь на '
              'ответ ИИ, мы сохраним этот ответ и ваш необязательный комментарий, '
              'чтобы его проверить.',
        ),
        const LegalSection(
          'Где хранятся ваши данные',
          'Всё сначала сохраняется на вашем устройстве (в приложении или в '
              'браузере для веб-версии), поэтому приложение работает даже без '
              'аккаунта и подключения. Если вы входите в аккаунт, ваши данные '
              'также автоматически синхронизируются между вашими устройствами: '
              'их копия хранится в нашей базе данных (размещённой у Supabase), '
              'привязана к вашему аккаунту и изолирована так, что прочитать её '
              'можете только вы. Синхронизацию можно выключить в настройках; '
              'тогда данные остаются только на этом устройстве.',
        ),
        const LegalSection(
          'Ваш аккаунт и письма',
          'Ваш адрес e-mail используется для входа и для писем об аккаунте, '
              'например подтверждения адреса и сброса пароля (отправляются через '
              'Brevo). Он никогда не используется для рекламы и не передаётся '
              'для маркетинга. При регистрации и входе быстрая проверка на '
              'человека (Cloudflare Turnstile) защищает от автоматических '
              'злоупотреблений.',
        ),
        const LegalSection(
          'DGOTIX AI',
          'DGOTIX AI — необязательная функция. Когда вы задаёте вопрос, текст '
              'вопроса и сводка ваших цифр (итоги по месяцам и категориям до 12 '
              'месяцев, бюджеты, остатки кошельков, цели, повторяющиеся '
              'операции, сезонные бюджеты и круги накоплений — только суммы и '
              'даты, без описаний, заметок и названий, которые вы даёте) '
              'отправляются через наш защищённый сервер поставщику ИИ (Google '
              'Gemini, OpenAI или Anthropic) для создания ответа. Наш сервер '
              'использует наши собственные ключи поставщиков и записывает только '
              'метаданные использования, но не ваш вопрос и не ваши цифры. Мы не'
              ' используем ваши данные для обучения каких-либо моделей. Ответы '
              'создаются автоматически, поэтому проверяйте важные цифры, прежде '
              'чем действовать.',
        ),
        const LegalSection(
          'Сканирование чеков',
          'На Android чеки можно распознавать полностью на устройстве. '
              'Облачное сканирование отправляет изображение чека через наш '
              'защищённый сервер поставщику ИИ только для того, чтобы прочитать '
              'продавца, дату, сумму, позиции и категорию; изображение не '
              'сохраняется.',
        ),
        const LegalSection(
          'Платежи и подписки',
          'Платные тарифы необязательны. Вы оплачиваете на защищённой странице '
              'оплаты Whop (whop.com), нашего платёжного провайдера, или через '
              'PayPal, если выберете его. Они собирают нужные им платёжные '
              'данные (например, имя, e-mail, страну и способ оплаты) по своим '
              'политикам конфиденциальности; мы никогда не видим и не храним '
              'полные данные вашей карты. Мы храним ваш тариф, статус подписки, '
              'дату продления и идентификаторы подписки у платёжного провайдера, '
              'чтобы предоставить вам правильный доступ, а также запись о любом '
              'использованном вами промокоде.',
        ),
        const LegalSection(
          'Поставщики услуг',
          'В зависимости от функций, которыми вы пользуетесь: Supabase '
              '(аккаунты, синхронизация и функции нашего сервера); Whop и PayPal '
              '(платежи); Brevo (письма об аккаунте); Cloudflare Turnstile '
              '(проверка на человека при входе); GitHub Pages (размещение нашего '
              'сайта и веб-приложения); Google, OpenAI и Anthropic (DGOTIX AI и '
              'облачное сканирование чеков); а также открытые источники рыночных '
              'данных для актуальных значений — курсы валют (open.er-api.com) и '
              'цены криптовалют (CoinGecko), — запросы к которым содержат только '
              'символы валют или активов и никогда не содержат ваших личных или '
              'финансовых данных. Каждый поставщик обрабатывает данные только для'
              ' выполнения своей части сервиса.',
        ),
        const LegalSection(
          'Безопасность',
          'Соединения с нашими сервисами зашифрованы (HTTPS). В нашей базе '
              'данных записи каждого пользователя изолированы, так что один '
              'аккаунт никогда не может прочитать данные другого. Ключи сервера '
              'никогда не попадают в приложение, уведомления о платежах '
              'проверяются, прежде чем что-либо изменить, а на своём устройстве '
              'вы можете включить блокировку приложения (PIN-код или отпечаток).',
        ),
        const LegalSection(
          'Чего мы не делаем',
          'Мы не продаём и не сдаём в аренду ваши данные, не показываем рекламу'
              ' и не ведём поведенческое отслеживание или аналитику вашей '
              'финансовой активности.',
        ),
        // Only while the totals are on (and trips are only in SmartTrip).
        if (AppEnv.anonStats && AppEnv.smartTrip)
          const LegalSection(
            'Анонимные подсчёты',
            'Когда вы создаёте поездку, приложение отправляет только слова '
                '«поездка запланирована», а наш сервер прибавляет единицу к итогу'
                ' этого дня. Больше ничего не отправляется и не хранится — ни '
                'аккаунт, ни устройство, ни направление, ни сумма, — поэтому '
                'итоги нельзя связать с вами. Мы используем их только чтобы '
                'понимать, насколько активно используется приложение, и '
                'показывать партнёрам общие цифры. Это можно выключить в '
                'настройках, в разделе «Конфиденциальность».',
          ),
        const LegalSection(
          'Как долго мы храним данные',
          'Данные на вашем устройстве хранятся, пока вы их не удалите или не '
              'удалите приложение. Ваш аккаунт, синхронизированные данные, '
              'счётчики использования и метаданные запросов хранятся, пока '
              'существует ваш аккаунт, — только для работы сервиса и применения '
              'лимитов тарифа — и безвозвратно удаляются при его удалении. Whop '
              'и PayPal хранят платёжные записи, которые обязаны хранить по '
              'закону.',
        ),
        LegalSection(
          'Ваши права и возможности',
          'Вы можете в любой момент просматривать и исправлять свои данные в '
              'приложении, экспортировать полную резервную копию, выключить '
              'синхронизацию, выйти из аккаунта и удалить аккаунт со всеми '
              'данными (см. ниже). Платную подписку можно отменить в любой '
              'момент (см. Условия). По любому другому вопросу о ваших '
              'персональных данных — включая доступ, исправление, удаление или '
              'возражение — свяжитесь с нами $_reachRu, и мы быстро ответим.',
        ),
        const LegalSection(
          'Удаление аккаунта и данных',
          'В приложении или веб-версии, на любом устройстве, откройте '
              '«Настройки», затем «Аккаунт», затем «Удалить мой аккаунт». Это '
              'безвозвратно удалит ваш аккаунт и всё, что хранится для него на '
              'наших серверах (профиль, синхронизированные данные, запись о '
              'подписке и счётчики использования), и сотрёт ваши данные на этом '
              'устройстве. Сначала отмените платную подписку. Удаление нельзя '
              'отменить, поэтому заранее экспортируйте резервную копию, если '
              'данные могут понадобиться.',
        ),
        LegalSection(
          'Возраст',
          '$_app предназначено для лиц от 16 лет. Мы сознательно не собираем '
              'данные детей младшего возраста; если вы считаете, что ребёнок '
              'создал аккаунт, свяжитесь с нами $_reachRu, и мы его удалим.',
        ),
        LegalSection(
          'Изменения и контакты',
          'Мы можем обновлять эту политику; дата выше соответствует последней '
              'версии. По вопросам конфиденциальности свяжитесь с нами '
              '$_reachRu.',
        ),
      ];

  // ---- Terms (Russian) ----
  static List<LegalSection> get _termsRu => <LegalSection>[
        LegalSection(
          'Принятие условий',
          'Пользуясь $_app, вы соглашаетесь с этими условиями. Если вы не '
              'согласны, пожалуйста, не пользуйтесь приложением.',
        ),
        LegalSection(
          'Кто может пользоваться',
          'Чтобы пользоваться $_app, вам должно быть не менее 16 лет. Если вы '
              'создаёте аккаунт, храните данные для входа в безопасности; вы '
              'отвечаете за действия в своём аккаунте.',
        ),
        const LegalSection(
          'Что представляет собой сервис',
          'Инструмент личного бюджета и планирования для учёта доходов, '
              'расходов, бюджетов, целей и связанной аналитики, с '
              'необязательной помощью ИИ, сканированием чеков, синхронизацией '
              'между устройствами и платными тарифами.',
        ),
        const LegalSection(
          'Инструменты планирования, а не профессиональный совет',
          'Бюджеты, прогнозы, расчёт закята и ответы DGOTIX AI — это '
              'инструменты планирования, помогающие принимать решения. Они не '
              'являются профессиональной финансовой, налоговой или религиозной '
              'консультацией. Религиозные обязанности, такие как закят, '
              'уточняйте у знающего учёного; по крупным финансовым решениям '
              'консультируйтесь с квалифицированным специалистом.',
        ),
        const LegalSection(
          'Функции ИИ',
          'DGOTIX AI и облачное сканирование чеков дают автоматические '
              'результаты, чтобы сэкономить ваше время; проверяйте важные цифры, '
              'прежде чем действовать. Эти функции доступны в пределах '
              'разумного использования, которые зависят от вашего тарифа и могут'
              ' меняться, чтобы сервис оставался быстрым и надёжным для всех.',
        ),
        const LegalSection(
          'Подписки, оплата и продление',
          'Основное приложение бесплатно. Платные тарифы (Pro) открывают более '
              'высокие лимиты и дополнительные функции по ценам, указанным в '
              'приложении. Платный тариф автоматически продлевается каждый '
              'расчётный период (месяц или год), пока вы его не отмените. '
              'Платежи обрабатывает Whop, наш платёжный провайдер (или PayPal, '
              'если вы выберете его); могут добавляться применимые налоги, и они'
              ' всегда показываются на странице оплаты до платежа. Вы можете '
              'отменить подписку в любой момент и сохранить доступ до конца уже '
              'оплаченного периода. Если цены или состав тарифов меняются, '
              'актуальные условия всегда показываются до оформления подписки.',
        ),
        const LegalSection(
          'Наш платёжный провайдер: Whop',
          'SmartBudget продаёт DGOTIX. Оплату и выставление счетов '
              'обеспечивает Whop (whop.com): он проводит платёж на своей '
              'защищённой странице, показывает полную цену с учётом налогов до '
              'оплаты и отправляет вам чек. Управлять подпиской или отменить её '
              'можно в приложении («Тарифы» → «Управление»).',
        ),
        LegalSection(
          'Политика возврата',
          'Кроме случаев, предусмотренных законом, платежи, как правило, не '
              'возвращаются после начала расчётного периода, поскольку доступ '
              'сохраняется до его окончания. Вы можете отменить подписку в любой '
              'момент, чтобы остановить будущие продления. По вопросу возврата '
              'или любого списания свяжитесь с нами $_reachRu: мы рассматриваем '
              'каждый запрос в соответствии с применимым законодательством о '
              'защите прав потребителей и проводим одобренные возвраты через '
              'Whop (или PayPal).',
        ),
        const LegalSection(
          'Промокоды',
          'Купоны и коды скидок необязательны и меняют только цену оплаты (или'
              ' дают пробный период). У каждого кода свои условия (срок действия,'
              ' лимит использований, один на клиента), и он может быть отозван '
              'или истечь. Они не имеют денежной стоимости и не суммируются, '
              'если не указано иное.',
        ),
        const LegalSection(
          'Ваши данные и резервные копии',
          'Вы отвечаете за точность вводимых данных. Чтобы данные были в '
              'безопасности на всех устройствах, войдите в аккаунт для '
              'синхронизации или регулярно экспортируйте резервную копию в '
              'настройках.',
        ),
        LegalSection(
          'Доступность',
          'Мы стараемся, чтобы $_app было доступным и надёжным. В пределах, '
              'допускаемых законом, приложение предоставляется «как есть», без '
              'каких-либо гарантий. Актуальные рыночные данные, ИИ и платежи '
              'зависят от сторонних сервисов и иногда могут задерживаться или '
              'быть недоступны; такой перебой никогда не мешает пользоваться '
              'основными инструментами бюджета, которые работают и без сети. '
              'Функции могут со временем меняться.',
        ),
        const LegalSection(
          'Ограничение ответственности',
          'В пределах, допускаемых законом, мы не несём ответственности за '
              'косвенные убытки или за решения, принятые вами на основе цифр '
              'приложения. Ничто в этих условиях не ограничивает права, которые '
              'дают вам законы о защите прав потребителей и от которых нельзя '
              'отказаться.',
        ),
        const LegalSection(
          'Допустимое использование',
          'Не злоупотребляйте сервисом, не пытайтесь взломать или обойти его '
              'защиту или лимиты тарифов и не используйте его в незаконных '
              'целях.',
        ),
        LegalSection(
          'Прекращение использования',
          'Вы можете перестать пользоваться $_app и удалить аккаунт в любой '
              'момент. Мы можем приостановить аккаунт, который нарушает эти '
              'условия или подвергает риску сервис или других пользователей.',
        ),
        LegalSection(
          'Бренд и права',
          'Название $_app, бренд $_brand, а также дизайн и код приложения '
              'остаются собственностью их владельца. Ваши данные остаются '
              'вашими.',
        ),
        LegalSection(
          'Изменения и контакты',
          'Мы можем обновлять эти условия и указывать дату последней версии; '
              'продолжение использования после обновления означает согласие с '
              'новыми условиями. По вопросам свяжитесь с нами $_reachRu.',
        ),
      ];

  // ---- Privacy (Swahili) ----
  static List<LegalSection> get _privacySw => <LegalSection>[
        LegalSection(
          'Muhtasari',
          'Sera hii inaeleza $_app inahifadhi nini, inahifadhiwa wapi na '
              'chaguo ulizonazo. Kwa ufupi: data yako ya fedha ni yako, '
              'inahifadhiwa kwanza kwenye kifaa chako, na hatuiuzi kamwe, '
              'hatukuonyeshi matangazo wala kukufuatilia. Vipengele vichache vya '
              'hiari (kuingia na kulinganisha, DGOTIX AI, uchanganuzi wa risiti '
              'mtandaoni na vifurushi vya kulipia) vinatuma data maalum kwa '
              'huduma fulani pale tu unapovitumia, kama ilivyoelezwa hapa chini.',
        ),
        const LegalSection(
          'Tunachohifadhi',
          'Taarifa unazoandika mwenyewe: mapato, matumizi, bajeti, malengo, '
              'madeni, pochi, kategoria zako na mapendeleo ya mwonekano '
              '(mandhari, lugha, sarafu kuu). Ukifungua akaunti tunahifadhi pia '
              'barua pepe yako, kifurushi chako na hali ya usajili, na idadi ya '
              'matumizi ya DGOTIX AI na uchanganuzi wa risiti mtandaoni kwa kila '
              'kipindi — kwa ajili ya kutumia vikomo vya kifurushi chako tu. '
              'Hatuhifadhi maswali yako kwa DGOTIX AI wala picha za risiti zako; '
              'ukiripoti jibu la AI, tunahifadhi jibu hilo na dokezo lako la '
              'hiari ili tulikague.',
        ),
        const LegalSection(
          'Data yako inakaa wapi',
          'Kila kitu kinahifadhiwa kwanza kwenye kifaa chako (kwenye programu, '
              'au kwenye kivinjari chako kwa toleo la wavuti), kwa hiyo programu '
              'inafanya kazi hata bila akaunti au mtandao. Ukiingia, data yako '
              'pia inalinganishwa yenyewe kati ya vifaa vyako: nakala '
              'inahifadhiwa kwenye hifadhidata yetu (inayohifadhiwa na Supabase),'
              ' imefungwa kwenye akaunti yako na kutengwa ili ni wewe tu '
              'unayeweza kuisoma. Unaweza kuzima ulinganishaji kwenye Mipangilio;'
              ' data yako basi inabaki kwenye kifaa hiki tu.',
        ),
        const LegalSection(
          'Akaunti yako na barua pepe',
          'Barua pepe yako inatumika kukuingiza na kutuma barua za akaunti, '
              'kama uthibitisho wa anwani na kuweka upya nenosiri (zinatumwa '
              'kupitia Brevo). Haitumiki kamwe kwa matangazo wala kushirikiwa kwa'
              ' masoko. Unapojisajili au kuingia, ukaguzi mfupi wa binadamu '
              '(Cloudflare Turnstile) unazuia matumizi mabaya ya kiotomatiki.',
        ),
        const LegalSection(
          'DGOTIX AI',
          'DGOTIX AI ni ya hiari. Unapouliza swali, maandishi ya swali hilo na '
              'muhtasari wa tarakimu zako (jumla kwa mwezi na kategoria hadi '
              'miezi 12, bajeti, salio la pochi, malengo, miamala inayojirudia, '
              'bajeti za misimu na mizunguko ya akiba — viasi na tarehe tu, kamwe '
              'si maelezo, madokezo au majina unayovipa vitu) vinatumwa kupitia '
              'seva yetu salama kwa mtoa huduma wa AI (Google Gemini, OpenAI au '
              'Anthropic) ili kutengeneza jibu. Seva yetu inatumia funguo zetu '
              'wenyewe na inarekodi data ya matumizi tu, kamwe si swali lako wala'
              ' tarakimu zako. Hatutumii data yako kufundisha modeli yoyote. '
              'Majibu yanatengenezwa kiotomatiki, kwa hiyo kagua tarakimu muhimu '
              'kabla ya kuchukua hatua.',
        ),
        const LegalSection(
          'Uchanganuzi wa risiti',
          'Kwenye Android, risiti zinaweza kusomwa kabisa kwenye kifaa chako. '
              'Uchanganuzi wa mtandaoni unatuma picha ya risiti kupitia seva yetu '
              'salama kwa mtoa huduma wa AI kwa ajili ya kusoma mfanyabiashara, '
              'tarehe, kiasi, bidhaa na kategoria tu; picha haihifadhiwi.',
        ),
        const LegalSection(
          'Malipo na usajili',
          'Vifurushi vya kulipia ni vya hiari. Unalipa kwenye ukurasa salama wa '
              'malipo wa Whop (whop.com), mtoa huduma wetu wa malipo, au kwa '
              'PayPal ukiichagua. Wanakusanya taarifa za malipo wanazohitaji '
              '(kama jina, barua pepe, nchi na njia ya malipo) chini ya sera zao '
              'za faragha; hatuoni wala kuhifadhi taarifa kamili za kadi yako. '
              'Tunahifadhi kifurushi chako, hali ya usajili, tarehe ya kujirudia '
              'na vitambulisho vya usajili vya mtoa huduma wa malipo ili tukupe '
              'ufikiaji sahihi, pamoja na rekodi ya msimbo wowote wa ofa '
              'unaoutumia.',
        ),
        const LegalSection(
          'Watoa huduma',
          'Kulingana na vipengele unavyotumia: Supabase (akaunti, ulinganishaji '
              'na kazi za seva yetu); Whop na PayPal (malipo); Brevo (barua za '
              'akaunti); Cloudflare Turnstile (ukaguzi wa binadamu wakati wa '
              'kuingia); GitHub Pages (kuhifadhi tovuti yetu na programu ya '
              'wavuti); Google, OpenAI na Anthropic (DGOTIX AI na uchanganuzi wa '
              'risiti mtandaoni); na vyanzo vya umma vya data za soko kwa '
              'thamani za sasa — viwango vya sarafu (open.er-api.com) na bei za '
              'crypto (CoinGecko) — ambavyo maombi yake yana alama za sarafu au '
              'mali tu, kamwe si data yako binafsi au ya fedha. Kila mtoa huduma '
              'anashughulikia data kwa ajili ya kutoa sehemu yake ya huduma tu.',
        ),
        const LegalSection(
          'Usalama',
          'Miunganisho kwenye huduma zetu imesimbwa (HTTPS). Kwenye hifadhidata '
              'yetu, rekodi za kila mtumiaji zimetengwa ili akaunti moja isiweze '
              'kamwe kusoma ya nyingine. Funguo za seva hazifiki kamwe kwenye '
              'programu, arifa za malipo zinathibitishwa kabla ya kubadilisha '
              'chochote, na unaweza kuongeza kufuli ya programu (PIN au alama ya '
              'kidole) kwenye kifaa chako.',
        ),
        const LegalSection(
          'Tusichofanya',
          'Hatuuzi wala kukodisha data yako, hatuonyeshi matangazo, wala '
              'hatufuatilii tabia au kuchambua shughuli zako za fedha.',
        ),
        // Only while the totals are on (and trips are only in SmartTrip).
        if (AppEnv.anonStats && AppEnv.smartTrip)
          const LegalSection(
            'Hesabu zisizo na utambulisho',
            'Unapounda safari, programu inatuma maneno “safari imepangwa” tu, '
                'na seva yetu inaongeza moja kwenye jumla ya siku hiyo. Hakuna '
                'kingine kinachotumwa wala kuhifadhiwa nayo — hakuna akaunti, '
                'kifaa, mahali wala kiasi — kwa hiyo jumla haziwezi kuhusishwa '
                'nawe. Tunazitumia tu kujua programu inatumika kiasi gani na '
                'kuwaonyesha washirika takwimu za jumla. Unaweza kuzima hili '
                'kwenye Mipangilio, chini ya Faragha.',
          ),
        const LegalSection(
          'Tunahifadhi data kwa muda gani',
          'Data kwenye kifaa chako inabaki hadi uifute au uondoe programu. '
              'Akaunti yako, data iliyolinganishwa, idadi ya matumizi na data ya '
              'maombi vinahifadhiwa wakati akaunti yako ipo — kwa ajili ya '
              'kuendesha huduma na kutumia vikomo vya kifurushi chako tu — na '
              'vinafutwa kabisa unapoifuta. Whop na PayPal wanahifadhi rekodi za '
              'malipo wanazotakiwa kisheria kuhifadhi.',
        ),
        LegalSection(
          'Haki zako na udhibiti',
          'Unaweza kuona na kusahihisha data yako kwenye programu wakati wowote,'
              ' kuchukua nakala kamili, kuzima ulinganishaji, kutoka, na kufuta '
              'akaunti yako pamoja na data yake yote (tazama hapa chini). Unaweza'
              ' kughairi usajili wa kulipia wakati wowote (tazama Masharti). Kwa '
              'ombi lingine lolote kuhusu data yako binafsi — ikiwemo kuiona, '
              'kuisahihisha, kuifuta au kupinga — wasiliana nasi $_reachSw na '
              'tutajibu haraka.',
        ),
        const LegalSection(
          'Kufuta akaunti yako na data',
          'Kwenye programu au toleo la wavuti, kwenye kifaa chochote, fungua '
              'Mipangilio, kisha Akaunti, kisha "Futa akaunti yangu". Hii inafuta '
              'kabisa akaunti yako na kila kitu kilichohifadhiwa kwa ajili yake '
              'kwenye seva zetu (wasifu, data iliyolinganishwa, rekodi ya usajili '
              'na idadi ya matumizi), na inafuta data yako kwenye kifaa hicho. '
              'Ghairi usajili wowote wa kulipia kwanza. Kufuta hakuwezi '
              'kutenduliwa, kwa hiyo chukua nakala kabla ikiwa huenda ukahitaji '
              'data yako baadaye.',
        ),
        LegalSection(
          'Umri',
          '$_app imekusudiwa watu wenye umri wa miaka 16 na zaidi. Hatukusanyi '
              'kwa makusudi data ya watoto wadogo zaidi; ukiamini mtoto amefungua'
              ' akaunti, wasiliana nasi $_reachSw na tutaifuta.',
        ),
        LegalSection(
          'Mabadiliko na mawasiliano',
          'Tunaweza kusasisha sera hii; tarehe iliyo hapo juu inaonyesha toleo '
              'la karibuni. Kwa maswali ya faragha, wasiliana nasi $_reachSw.',
        ),
      ];

  // ---- Terms (Swahili) ----
  static List<LegalSection> get _termsSw => <LegalSection>[
        LegalSection(
          'Kukubali',
          'Kwa kutumia $_app unakubali masharti haya. Ikiwa hukubali, tafadhali '
              'usitumie programu.',
        ),
        LegalSection(
          'Nani anaweza kuitumia',
          'Lazima uwe na umri wa angalau miaka 16 kutumia $_app. Ukifungua '
              'akaunti, linda taarifa zako za kuingia; unawajibika kwa shughuli '
              'kwenye akaunti yako.',
        ),
        const LegalSection(
          'Huduma ni nini',
          'Zana ya bajeti binafsi na upangaji kwa kufuatilia mapato, matumizi, '
              'bajeti, malengo na maarifa yanayohusiana, pamoja na msaada wa AI '
              'wa hiari, uchanganuzi wa risiti, ulinganishaji kati ya vifaa na '
              'vifurushi vya kulipia.',
        ),
        const LegalSection(
          'Zana za kupanga, si ushauri wa kitaalamu',
          'Bajeti, makadirio, kukokotoa Zaka na majibu ya DGOTIX AI ni zana za '
              'kupanga zinazokusaidia kuamua. Si ushauri wa kitaalamu wa fedha, '
              'kodi au dini. Kwa wajibu wa kidini kama Zaka, thibitisha na '
              'mwanazuoni mwenye sifa; kwa maamuzi makubwa ya fedha, shauriana na'
              ' mshauri mwenye sifa.',
        ),
        const LegalSection(
          'Vipengele vya AI',
          'DGOTIX AI na uchanganuzi wa risiti mtandaoni vinatoa matokeo ya '
              'kiotomatiki ili kukuokolea muda; kagua tarakimu muhimu kabla ya '
              'kuchukua hatua. Vipengele hivi vimejumuishwa ndani ya vikomo vya '
              'matumizi ya haki vinavyotegemea kifurushi chako, na vinaweza '
              'kurekebishwa ili huduma ibaki ya haraka na ya kuaminika kwa wote.',
        ),
        const LegalSection(
          'Usajili, malipo na kujirudia',
          'Programu ya msingi ni bure. Vifurushi vya kulipia (Pro) vinafungua '
              'vikomo vikubwa zaidi na vipengele vya ziada kwa bei zinazoonyeshwa'
              ' kwenye programu. Kifurushi cha kulipia kinajirudia chenyewe kila '
              'kipindi (mwezi au mwaka) hadi ukighairi. Malipo yanashughulikiwa '
              'na Whop, mtoa huduma wetu wa malipo (au PayPal ukiichagua); kodi '
              'zinazohusika zinaweza kuongezwa na zinaonyeshwa daima kwenye '
              'ukurasa wa malipo kabla ya kulipa. Unaweza kughairi wakati wowote '
              'na kubaki na ufikiaji hadi mwisho wa kipindi ulichokwisha lipia. '
              'Bei au vipengele vya vifurushi vikibadilika, masharti ya sasa '
              'yanaonyeshwa daima kabla ya kujisajili.',
        ),
        const LegalSection(
          'Mtoa huduma wetu wa malipo: Whop',
          'SmartBudget inauzwa na DGOTIX. Malipo na ankara yanashughulikiwa na '
              'Whop (whop.com), inayoshughulikia malipo kwenye ukurasa wake salama,'
              ' inaonyesha bei kamili pamoja na kodi kabla ya kulipa, na kukutumia'
              ' risiti. Unaweza kusimamia au kughairi usajili wako kutoka kwenye '
              'programu (Vifurushi → Simamia).',
        ),
        LegalSection(
          'Sera ya kurejesha pesa',
          'Isipokuwa pale sheria inapotaka, malipo kwa kawaida hayarejeshwi '
              'kipindi kikishaanza, kwa kuwa unabaki na ufikiaji hadi mwisho wake.'
              ' Unaweza kughairi wakati wowote kusimamisha marudio yajayo. Kwa '
              'ombi la kurejeshewa pesa au swali lolote kuhusu malipo, wasiliana '
              'nasi $_reachSw: tunakagua kila ombi chini ya sheria ya walaji '
              'inayohusika na kurejesha pesa zilizoidhinishwa kupitia Whop (au '
              'PayPal).',
        ),
        const LegalSection(
          'Misimbo ya ofa',
          'Kuponi na misimbo ya punguzo ni za hiari na zinabadilisha bei ya '
              'malipo tu (au kutoa kipindi cha majaribio). Kila msimbo una '
              'masharti yake (muda wa uhalali, vikomo vya matumizi, mmoja kwa kila'
              ' mteja) na unaweza kuondolewa au kuisha muda. Hazina thamani ya '
              'pesa taslimu na haziwezi kuunganishwa isipokuwa imeelezwa.',
        ),
        const LegalSection(
          'Data yako na nakala',
          'Unawajibika kwa usahihi wa data unayoandika. Ili kuweka data yako '
              'salama kwenye vifaa vyote, ingia ili kuilinganisha, au chukua '
              'nakala mara kwa mara kutoka Mipangilio.',
        ),
        LegalSection(
          'Upatikanaji',
          'Tunajitahidi kuweka $_app ikipatikana na ya kuaminika. Kwa kiwango '
              'kinachoruhusiwa na sheria, programu inatolewa "kama ilivyo", bila '
              'dhamana za aina yoyote. Data za soko za sasa, AI na malipo '
              'vinategemea huduma za wahusika wengine na mara chache vinaweza '
              'kuchelewa au kutopatikana; usumbufu kama huo hautakuzuia kamwe '
              'kutumia zana za msingi za bajeti, ambazo pia zinafanya kazi bila '
              'mtandao. Vipengele vinaweza kubadilika kadiri muda unavyokwenda.',
        ),
        const LegalSection(
          'Ukomo wa dhima',
          'Kwa kiwango kinachoruhusiwa na sheria, hatuwajibiki kwa hasara '
              'zisizo za moja kwa moja au zinazotokana, wala kwa maamuzi '
              'unayofanya kulingana na tarakimu za programu. Hakuna chochote '
              'katika masharti haya kinachopunguza haki ulizonazo chini ya sheria'
              ' ya walaji ambazo haziwezi kuondolewa.',
        ),
        const LegalSection(
          'Matumizi yanayokubalika',
          'Usitumie huduma vibaya, usijaribu kuvunja au kukwepa usalama wake au '
              'vikomo vya vifurushi, wala kuitumia kwa madhumuni yoyote '
              'yasiyo halali.',
        ),
        LegalSection(
          'Kuacha kutumia',
          'Unaweza kuacha kutumia $_app na kufuta akaunti yako wakati wowote. '
              'Tunaweza kusimamisha akaunti inayovunja masharti haya au '
              'inayohatarisha huduma au watumiaji wengine.',
        ),
        LegalSection(
          'Chapa na umiliki',
          'Jina la $_app, chapa ya $_brand, pamoja na muundo na msimbo wa '
              'programu vinabaki mali ya mmiliki wake. Data yako inabaki kuwa '
              'yako.',
        ),
        LegalSection(
          'Mabadiliko na mawasiliano',
          'Tunaweza kusasisha masharti haya na kuonyesha tarehe ya toleo la '
              'karibuni; kuendelea kutumia baada ya sasisho kunamaanisha '
              'unakubali masharti yaliyorekebishwa. Kwa maswali, wasiliana nasi '
              '$_reachSw.',
        ),
      ];

  // ---- Privacy (Hausa) ----
  static List<LegalSection> get _privacyHa => <LegalSection>[
        LegalSection(
          'Taƙaitawa',
          'Wannan manufa tana bayyana abin da $_app ke ajiyewa, inda ake '
              'ajiye shi, da zaɓuɓɓukan da kake da su. A taƙaice: bayanan '
              'kuɗinka naka ne, ana ajiye su a na\'urarka da farko, kuma ba mu '
              'taɓa sayar da su ba, ba ma nuna maka talla ko bin diddiginka. '
              'Wasu fasaloli na zaɓi (shiga da daidaitawa, DGOTIX AI, karatun '
              'rasit a intanet da tsare-tsaren biya) suna aika takamaiman '
              'bayanai zuwa wani sabis ne kawai lokacin da ka yi amfani da su, '
              'kamar yadda aka bayyana a ƙasa.',
        ),
        const LegalSection(
          'Abin da muke ajiyewa',
          'Bayanan da kake rubutawa da kanka: kuɗin shiga, kashe kuɗi, kasafi, '
              'buri, basussuka, jakunkuna, rukunonin naka da zaɓin kamanni (jigo,'
              ' harshe, babban kuɗi). Idan ka buɗe asusu muna kuma ajiye imel '
              'ɗinka, tsarinka da matsayin biyan kuɗinka, da ƙididdigar amfani da '
              'DGOTIX AI da karatun rasit a intanet a kowane lokaci — don aiwatar '
              'da iyakokin tsarinka kawai. Ba ma ajiye tambayoyinka ga DGOTIX AI '
              'ko hotunan rasit ɗinka; idan ka kai rahoton amsar AI, muna ajiye '
              'amsar da bayaninka na zaɓi don mu duba ta.',
        ),
        const LegalSection(
          'Inda bayananka suke',
          'Ana ajiye komai a na\'urarka da farko (a cikin manhajar, ko a mai '
              'binciken ka don sigar yanar gizo), don haka manhajar tana aiki ko '
              'ba tare da asusu ko intanet ba. Idan ka shiga, bayananka ana '
              'daidaita su kai tsaye tsakanin na\'urorinka: ana ajiye kwafi a '
              'ma\'ajiyarmu (wadda Supabase ke ɗauka), an haɗa shi da asusunka '
              'kuma an keɓe shi ta yadda kai kaɗai za ka iya karanta shi. Za ka '
              'iya kashe daidaitawa a Saituna; bayananka za su zauna a wannan '
              'na\'ura kawai.',
        ),
        const LegalSection(
          'Asusunka da imel',
          'Ana amfani da imel ɗinka don shigar da kai da aika saƙonnin asusu, '
              'kamar tabbatar da adireshi da sake saita kalmar sirri (ana aika su'
              ' ta Brevo). Ba a taɓa amfani da shi don talla ko raba shi don '
              'kasuwanci ba. Lokacin da ka yi rajista ko ka shiga, gajeren '
              'binciken mutum (Cloudflare Turnstile) yana hana cin zarafi na '
              'na\'ura.',
        ),
        const LegalSection(
          'DGOTIX AI',
          'DGOTIX AI zaɓi ce. Lokacin da ka yi tambaya, rubutun tambayar da '
              'taƙaitaccen lambobinka (jimilla bisa wata da rukuni har zuwa watanni'
              ' 12, kasafi, ma\'aunin jakunkuna, buri, ma\'amaloli masu '
              'maimaituwa, kasafin lokuta da adashe — adadi da kwanan wata kawai,'
              ' ba bayanai, bayanan kula ko sunayen da ka ba abubuwa ba) ana aika'
              ' su ta sabarmu mai tsaro zuwa mai ba da sabis na AI (Google '
              'Gemini, OpenAI ko Anthropic) don ƙirƙirar amsar. Sabarmu tana '
              'amfani da maɓallanmu kuma tana rubuta bayanan amfani kawai, ba '
              'tambayarka ko lambobinka ba. Ba ma amfani da bayananka don horar '
              'da kowane samfuri. Ana ƙirƙirar amsoshi kai tsaye, don haka duba '
              'muhimman lambobi kafin ka ɗauki mataki.',
        ),
        const LegalSection(
          'Karatun rasit',
          'A Android, ana iya karanta rasit gaba ɗaya a na\'urarka. Karatu a '
              'intanet yana aika hoton rasit ta sabarmu mai tsaro zuwa mai ba da '
              'sabis na AI don karanta sunan mai sayarwa, kwanan wata, adadi, '
              'kayayyaki da rukuni kawai; ba a ajiye hoton.',
        ),
        const LegalSection(
          'Biya da biyan kuɗi na lokaci',
          'Tsare-tsaren biya zaɓi ne. Kana biya a shafin biya mai tsaro na '
              'Whop (whop.com), mai ba mu sabis na biya, ko da PayPal idan ka '
              'zaɓe shi. Suna tattara bayanan biya da suke buƙata (kamar suna, '
              'imel, ƙasa da hanyar biya) ƙarƙashin manufofin sirrinsu; ba mu '
              'taɓa gani ko ajiye cikakkun bayanan katinka ba. Muna ajiye '
              'tsarinka, matsayin biyan kuɗi, ranar sabuntawa da lambobin '
              'shaidar biyan kuɗi na mai ba da sabis na biya don ba ka damar da '
              'ta dace, tare da rikodin kowace lambar tayi da ka yi amfani da ita.',
        ),
        const LegalSection(
          'Masu ba da sabis',
          'Bisa fasalolin da kake amfani da su: Supabase (asusu, daidaitawa da '
              'ayyukan sabarmu); Whop da PayPal (biya); Brevo (saƙonnin asusu); '
              'Cloudflare Turnstile (binciken mutum lokacin shiga); GitHub Pages '
              '(ɗaukar shafinmu da manhajar yanar gizo); Google, OpenAI da '
              'Anthropic (DGOTIX AI da karatun rasit a intanet); da majiyoyin '
              'jama\'a na bayanan kasuwa don ƙimomin yanzu — farashin kuɗaɗe '
              '(open.er-api.com) da farashin crypto (CoinGecko) — waɗanda '
              'buƙatunsu ke ƙunshe da alamomin kuɗi ko kadara kawai, ba bayananka'
              ' na sirri ko na kuɗi ba. Kowane mai ba da sabis yana sarrafa '
              'bayanai ne kawai don isar da ɓangarensa na sabis.',
        ),
        const LegalSection(
          'Tsaro',
          'Haɗin kai da ayyukanmu an ɓoye shi (HTTPS). A ma\'ajiyarmu, bayanan '
              'kowane mai amfani an keɓe su ta yadda wani asusu ba zai taɓa '
              'karanta na wani ba. Maɓallan sabar ba sa taɓa kaiwa ga manhajar, '
              'ana tabbatar da sanarwar biya kafin su canza komai, kuma za ka iya'
              ' ƙara kullen manhaja (PIN ko zanen yatsa) a na\'urarka.',
        ),
        const LegalSection(
          'Abin da ba ma yi',
          'Ba ma sayar ko ba da hayar bayananka, ba ma nuna talla, kuma ba ma '
              'bin ɗabi\'unka ko nazarin ayyukanka na kuɗi.',
        ),
        // Only while the totals are on (and trips are only in SmartTrip).
        if (AppEnv.anonStats && AppEnv.smartTrip)
          const LegalSection(
            'Ƙididdiga ba tare da suna ba',
            'Lokacin da ka ƙirƙiri tafiya, manhajar tana aika kalmomin “an '
                'tsara tafiya” kawai, kuma sabarmu tana ƙara ɗaya ga jimillar '
                'ranar. Ba a aika ko ajiye wani abu tare da shi — babu asusu, '
                'na\'ura, wuri ko adadi — don haka ba za a iya haɗa jimillar da '
                'kai ba. Muna amfani da su ne kawai don sanin yawan amfani da '
                'manhajar da nuna wa abokan hulɗa lambobin gaba ɗaya. Za ka iya '
                'kashe wannan a Saituna, ƙarƙashin Sirri.',
          ),
        const LegalSection(
          'Tsawon lokacin ajiye bayanai',
          'Bayanai a na\'urarka suna nan har sai ka share su ko ka cire '
              'manhajar. Asusunka, bayanan da aka daidaita, ƙididdigar amfani da '
              'bayanan buƙatu ana ajiye su muddin asusunka yana nan — don gudanar'
              ' da sabis da aiwatar da iyakokin tsarinka kawai — kuma ana goge su'
              ' gaba ɗaya idan ka share shi. Whop da PayPal suna ajiye bayanan '
              'biya da doka ta tilasta musu ajiyewa.',
        ),
        LegalSection(
          'Haƙƙoƙinka da iko',
          'Za ka iya gani da gyara bayananka a manhajar a kowane lokaci, fitar '
              'da cikakken kwafi, kashe daidaitawa, fita, da share asusunka tare '
              'da duk bayanansa (duba ƙasa). Za ka iya soke biyan kuɗi a kowane '
              'lokaci (duba Sharuɗɗa). Don kowace buƙata game da bayananka na '
              'sirri — har da gani, gyara, share ko ƙin amincewa — tuntuɓe mu '
              '$_reachHa kuma za mu amsa da sauri.',
        ),
        const LegalSection(
          'Share asusunka da bayanai',
          'A manhajar ko sigar yanar gizo, a kowace na\'ura, buɗe Saituna, sannan'
              ' Asusu, sannan "Share asusuna". Wannan yana share asusunka gaba '
              'ɗaya da duk abin da aka ajiye masa a sabobinmu (bayanin martaba, '
              'bayanan da aka daidaita, rikodin biyan kuɗi da ƙididdigar amfani), '
              'kuma yana goge bayananka a wannan na\'ura. Soke duk wani biyan '
              'kuɗi tukuna. Ba za a iya soke share ba, don haka ka fitar da kwafi '
              'tukuna idan za ka iya buƙatar bayananka daga baya.',
        ),
        LegalSection(
          'Shekaru',
          '$_app an yi ta ne don mutane masu shekaru 16 zuwa sama. Ba mu da '
              'niyyar tattara bayanan ƙananan yara; idan kana ganin yaro ya buɗe '
              'asusu, tuntuɓe mu $_reachHa kuma za mu share shi.',
        ),
        LegalSection(
          'Canje-canje da tuntuɓa',
          'Za mu iya sabunta wannan manufa; kwanan watan da ke sama yana nuna '
              'sigar ƙarshe. Don tambayoyi game da sirri, tuntuɓe mu $_reachHa.',
        ),
      ];

  // ---- Terms (Hausa) ----
  static List<LegalSection> get _termsHa => <LegalSection>[
        LegalSection(
          'Amincewa',
          'Ta amfani da $_app ka amince da waɗannan sharuɗɗa. Idan ba ka '
              'amince ba, da fatan kada ka yi amfani da manhajar.',
        ),
        LegalSection(
          'Wa zai iya amfani da ita',
          'Dole ka kasance aƙalla shekaru 16 don amfani da $_app. Idan ka buɗe '
              'asusu, kare bayanan shigarka; kai ne ke da alhakin ayyuka a '
              'asusunka.',
        ),
        const LegalSection(
          'Menene sabis ɗin',
          'Kayan aikin kasafi da tsari na kai don bin kuɗin shiga, kashe kuɗi, '
              'kasafi, buri da bayanai masu alaƙa, tare da taimakon AI na zaɓi, '
              'karatun rasit, daidaitawa tsakanin na\'urori da tsare-tsaren biya.',
        ),
        const LegalSection(
          'Kayan aikin tsari, ba shawarar ƙwararru ba',
          'Kasafi, hasashe, lissafin Zakka da amsoshin DGOTIX AI kayan aikin '
              'tsari ne don taimaka maka yanke shawara. Ba shawarar ƙwararru ta '
              'kuɗi, haraji ko addini ba ne. Don wajibai na addini kamar Zakka, '
              'tabbatar da malami mai ilimi; don manyan shawarwarin kuɗi, '
              'tuntuɓi ƙwararren mai ba da shawara.',
        ),
        const LegalSection(
          'Fasalolin AI',
          'DGOTIX AI da karatun rasit a intanet suna ba da sakamako kai tsaye '
              'don adana maka lokaci; duba muhimman lambobi kafin ka ɗauki mataki.'
              ' Waɗannan fasaloli suna cikin iyakokin amfani na adalci da suka '
              'dogara da tsarinka, kuma ana iya daidaita su don sabis ya kasance '
              'mai sauri da aminci ga kowa.',
        ),
        const LegalSection(
          'Biyan kuɗi, biya da sabuntawa',
          'Manhajar asali kyauta ce. Tsare-tsaren biya (Pro) suna buɗe iyakoki '
              'mafi girma da ƙarin fasaloli a farashin da aka nuna a manhajar. '
              'Tsarin biya yana sabunta kansa a kowane lokaci (wata ko shekara) '
              'har sai ka soke shi. Whop ne ke sarrafa biya, mai ba mu sabis na '
              'biya (ko PayPal idan ka zaɓe shi); ana iya ƙara harajin da ya '
              'dace kuma ana nuna shi koyaushe a shafin biya kafin ka biya. Za ka'
              ' iya soke a kowane lokaci ka ci gaba da samun dama har ƙarshen '
              'lokacin da ka riga ka biya. Idan farashi ko fasalolin tsari sun '
              'canza, ana nuna sharuɗɗan yanzu koyaushe kafin ka yi rajista.',
        ),
        const LegalSection(
          'Mai ba mu sabis na biya: Whop',
          'DGOTIX ne ke sayar da SmartBudget. Whop (whop.com) ne ke kula da biya '
              'da takardun kuɗi: yana sarrafa biya a shafinsa mai tsaro, yana '
              'nuna cikakken farashi tare da haraji kafin ka biya, kuma yana aiko'
              ' maka da rasit. Za ka iya sarrafa ko soke biyan kuɗinka daga '
              'manhajar (Tsare-tsare → Sarrafa).',
        ),
        LegalSection(
          'Manufar mayar da kuɗi',
          'Sai dai inda doka ta buƙata, yawanci ba a mayar da kuɗi bayan lokacin'
              ' biya ya fara, tunda kana da dama har ƙarshensa. Za ka iya soke a '
              'kowane lokaci don dakatar da sabuntawa na gaba. Don buƙatar mayar '
              'da kuɗi ko kowace tambaya game da cire kuɗi, tuntuɓe mu $_reachHa:'
              ' muna duba kowace buƙata bisa dokar masu sayayya da ta dace kuma '
              'muna mayar da kuɗin da aka amince ta Whop (ko PayPal).',
        ),
        const LegalSection(
          'Lambobin tayi',
          'Kuponi da lambobin rangwame zaɓi ne kuma suna canza farashin biya '
              'kawai (ko ba da lokacin gwaji). Kowace lamba tana da sharuɗɗanta '
              '(wa\'adin aiki, iyakar amfani, ɗaya ga kowane abokin ciniki) kuma '
              'ana iya janye ta ko wa\'adinta ya ƙare. Ba su da ƙimar tsabar kuɗi '
              'kuma ba za a haɗa su ba sai an faɗa.',
        ),
        const LegalSection(
          'Bayananka da kwafi',
          'Kai ne ke da alhakin daidaiton bayanan da kake rubutawa. Don kiyaye '
              'bayananka a duk na\'urori, shiga don daidaita su, ko ka riƙa '
              'fitar da kwafi daga Saituna.',
        ),
        LegalSection(
          'Samuwa',
          'Muna ƙoƙari don $_app ta kasance a samu kuma mai aminci. Gwargwadon '
              'yadda doka ta ba da dama, ana ba da manhajar "yadda take", ba '
              'tare da kowace irin garanti ba. Bayanan kasuwa na yanzu, AI da '
              'biya sun dogara da ayyukan wasu kuma lokaci-lokaci suna iya '
              'jinkiri ko rashin samuwa; irin wannan katsewa ba ta taɓa hana ka '
              'amfani da kayan aikin kasafi na asali, waɗanda ke aiki ko ba '
              'intanet. Fasaloli na iya canzawa a tsawon lokaci.',
        ),
        const LegalSection(
          'Iyakance alhaki',
          'Gwargwadon yadda doka ta ba da dama, ba mu da alhakin asarar da ba '
              'kai tsaye ba ko wadda ta biyo baya, ko shawarwarin da ka yanke '
              'bisa lambobin manhajar. Babu wani abu a waɗannan sharuɗɗa da ke '
              'iyakance haƙƙoƙin da kake da su ƙarƙashin dokar masu sayayya da '
              'ba za a iya yafe su ba.',
        ),
        const LegalSection(
          'Amfani mai karɓuwa',
          'Kada ka yi amfani da sabis ba daidai ba, kada ka yi ƙoƙarin karya ko '
              'tsallake tsaronsa ko iyakokin tsare-tsare, ko amfani da shi don '
              'wata manufa da ta saɓa wa doka.',
        ),
        LegalSection(
          'Daina amfani',
          'Za ka iya daina amfani da $_app ka share asusunka a kowane lokaci. '
              'Za mu iya dakatar da asusun da ya karya waɗannan sharuɗɗa ko ya '
              'jefa sabis ko sauran masu amfani cikin haɗari.',
        ),
        LegalSection(
          'Alama da mallaka',
          'Sunan $_app, alamar $_brand, da ƙira da lambar manhajar suna zama '
              'mallakar mai su. Bayananka suna zama naka.',
        ),
        LegalSection(
          'Canje-canje da tuntuɓa',
          'Za mu iya sabunta waɗannan sharuɗɗa mu nuna kwanan watan sigar '
              'ƙarshe; ci gaba da amfani bayan sabuntawa yana nufin ka amince da '
              'sharuɗɗan da aka gyara. Don tambayoyi, tuntuɓe mu $_reachHa.',
        ),
      ];

  // ---- Privacy (Afrikaans) ----
  static List<LegalSection> get _privacyAf => <LegalSection>[
        LegalSection(
          'Oorsig',
          'Hierdie beleid verduidelik wat $_app stoor, waar dit gestoor word en '
              'watter keuses jy het. Kortliks: jou finansiële data is joune, dit '
              'word eers op jou toestel gestoor, en ons verkoop dit nooit, wys vir'
              ' jou geen advertensies nie en volg jou nie. \'n Paar opsionele '
              'funksies (aanmelding en sinchronisasie, DGOTIX AI, '
              'strokie-skandering in die wolk en betaalde planne) stuur sekere '
              'data na \'n diens slegs wanneer jy hulle gebruik, soos hieronder '
              'beskryf.',
        ),
        const LegalSection(
          'Wat ons stoor',
          'Die inligting wat jy self invoer: inkomste, uitgawes, begrotings, '
              'doelwitte, skuld, beursies, eie kategorieë en jou '
              'vertoonvoorkeure (tema, taal, basisgeldeenheid). As jy \'n rekening '
              'skep, hou ons ook jou e-posadres, jou plan en sy status, en '
              'gebruikstellers per tydperk vir DGOTIX AI en strokie-skandering in '
              'die wolk — slegs om jou plan se perke toe te pas. Ons hou nie jou '
              'vrae aan DGOTIX AI of jou strokiefoto\'s nie; as jy \'n KI-antwoord '
              'rapporteer, hou ons daardie antwoord en jou opsionele nota om dit '
              'na te gaan.',
        ),
        const LegalSection(
          'Waar jou data is',
          'Alles word eers op jou toestel gestoor (in die app, of vir die '
              'webweergawe in jou blaaier), sodat die app ook sonder \'n rekening '
              'of verbinding werk. As jy aanmeld, word jou data ook outomaties '
              'tussen jou toestelle gesinchroniseer: \'n kopie is in ons databasis '
              '(aangebied deur Supabase), gekoppel aan jou rekening en so '
              'afgeskerm dat net jy dit kan lees. Jy kan sinchronisasie in '
              'Instellings afskakel; dan bly jou data net op hierdie toestel.',
        ),
        const LegalSection(
          'Jou rekening en e-posse',
          'Jou e-posadres word gebruik om jou aan te meld en om '
              'rekening-e-posse te stuur, soos die bevestiging van jou adres en '
              'die terugstel van jou wagwoord (gestuur via Brevo). Dit word nooit '
              'vir advertensies gebruik of vir bemarking gedeel nie. By '
              'registrasie en aanmelding hou \'n kort toets of jy \'n mens is '
              '(Cloudflare Turnstile) outomatiese misbruik uit.',
        ),
        const LegalSection(
          'DGOTIX AI',
          'DGOTIX AI is opsioneel. Wanneer jy \'n vraag vra, word die teks van '
              'daardie vraag en \'n opsomming van jou syfers (totale per maand en '
              'kategorie tot 12 maande, begrotings, beursiesaldo\'s, doelwitte, '
              'herhalende transaksies, seisoenbegrotings en spaarkringe — slegs '
              'bedrae en datums, nooit beskrywings, notas of die name wat jy '
              'dinge gee nie) via ons beveiligde bediener na \'n KI-verskaffer '
              '(Google Gemini, OpenAI of Anthropic) gestuur om die antwoord te '
              'maak. Ons bediener gebruik ons eie sleutels en teken slegs '
              'gebruiksmetadata aan, nooit jou vraag of jou syfers nie. Ons '
              'gebruik nie jou data om modelle op te lei nie. Antwoorde word '
              'outomaties gemaak, dus kontroleer belangrike syfers voordat jy '
              'daarvolgens optree.',
        ),
        const LegalSection(
          'Strokie-skandering',
          'Op Android kan strokies heeltemal op jou toestel gelees word. '
              'Skandering in die wolk stuur die foto van die strokie via ons '
              'beveiligde bediener na \'n KI-verskaffer, slegs om die winkel, '
              'datum, bedrag, items en kategorie te lees; die foto word nie '
              'gehou nie.',
        ),
        const LegalSection(
          'Betalings en intekeninge',
          'Betaalde planne is opsioneel. Jy betaal via die beveiligde '
              'betaalblad van Whop (whop.com), ons betaalvennoot, of met PayPal as'
              ' jy dit kies. Hulle versamel die faktuurbesonderhede wat hulle '
              'nodig het (soos naam, e-pos, land en betaalmetode) volgens hul eie '
              'privaatheidsbeleid; ons sien of stoor nooit jou volle '
              'kaartbesonderhede nie. Ons hou jou plan, sy status, die '
              'hernuwingsdatum en die betaalvennoot se intekeningsverwysings om '
              'jou die regte toegang te gee, plus \'n rekord van koepons wat jy '
              'gebruik.',
        ),
        const LegalSection(
          'Diensverskaffers',
          'Afhangende van die funksies wat jy gebruik: Supabase (rekeninge, '
              'sinchronisasie en ons bedienerfunksies); Whop en PayPal '
              '(betalings); Brevo (rekening-e-posse); Cloudflare Turnstile (die '
              'toets by aanmelding); GitHub Pages (aanbieding van ons webwerf en '
              'web-app); Google, OpenAI en Anthropic (DGOTIX AI en '
              'strokie-skandering in die wolk); en openbare bronne vir markdata '
              'vir lewendige syfers — wisselkoerse (open.er-api.com) en '
              'kriptopryse (CoinGecko) — waarvan die versoeke slegs geldeenheid- '
              'of batesimbole bevat, nooit jou persoonlike of finansiële data '
              'nie. Elke verskaffer verwerk data slegs om sy deel van die diens '
              'te lewer.',
        ),
        const LegalSection(
          'Sekuriteit',
          'Verbindings met ons dienste is geïnkripteer (HTTPS). In ons databasis '
              'is elke gebruiker se data so afgeskerm dat een rekening nooit \'n '
              'ander s\'n kan lees nie. Bedienersleutels kom nooit in die app nie, '
              'betaalkennisgewings word nagegaan voordat hulle iets verander, en '
              'jy kan \'n appslot op jou toestel opstel (PIN of vingerafdruk).',
        ),
        const LegalSection(
          'Wat ons nie doen nie',
          'Ons verkoop of verhuur nie jou data nie, wys geen advertensies nie en '
              'doen nie gedragsopsporing of ontledings van jou finansiële '
              'aktiwiteit nie.',
        ),
        // Only while the totals are on (and trips are only in SmartTrip).
        if (AppEnv.anonStats && AppEnv.smartTrip)
          const LegalSection(
            'Anonieme tellings',
            'Wanneer jy \'n reis skep, stuur die app slegs die woorde “\'n reis '
                'is beplan”, en ons bediener tel een by daardie dag se totaal. '
                'Niks anders word saam gestuur of gehou nie — geen rekening, '
                'toestel, bestemming of bedrag nie — dus kan die totale nie aan '
                'jou gekoppel word nie. Ons gebruik hulle slegs om te weet hoeveel'
                ' die app gebruik word en om vennote totale syfers te wys. Jy kan '
                'dit in Instellings, onder Privaatheid, afskakel.',
          ),
        const LegalSection(
          'Hoe lank ons data hou',
          'Data op jou toestel bly totdat jy dit skrap of die app verwyder. Jou '
              'rekening, gesinchroniseerde data, gebruikstellers en '
              'versoekmetadata word gehou solank jou rekening bestaan — slegs om '
              'die diens te laat werk en jou plan se perke toe te pas — en vir '
              'altyd uitgevee wanneer jy dit skrap. Whop en PayPal hou die '
              'faktuurrekords wat hulle wetlik moet hou.',
        ),
        LegalSection(
          'Jou regte en instellings',
          'Jy kan jou data altyd in die app bekyk en regstel, \'n volledige '
              'rugsteun uitvoer, sinchronisasie afskakel, afmeld en jou rekening '
              'met al sy data skrap (sien hieronder). Jy kan \'n betaalde plan '
              'enige tyd kanselleer (sien die Diensbepalings). Vir enige ander '
              'versoek oor jou persoonlike data — soos insae, regstelling, '
              'skrapping of beswaar — kontak ons $_reachAf en ons antwoord '
              'vinnig.',
        ),
        const LegalSection(
          'Skrap jou rekening en data',
          'Maak in die app of die webweergawe, op enige toestel, Instellings '
              'oop, dan Rekening, dan “Skrap my rekening”. Dit skrap jou rekening '
              'en alles wat daarvoor op ons bedieners is (profiel, '
              'gesinchroniseerde data, intekeningsrekords en gebruikstellers) vir '
              'altyd, en vee jou data op daardie toestel uit. Kanselleer eers '
              '\'n betaalde plan. Skrapping kan nie ontdoen word nie, dus voer '
              'vooraf \'n rugsteun uit as jy jou data later dalk wil hê.',
        ),
        LegalSection(
          'Ouderdom',
          '$_app is bedoel vir mense van 16 jaar en ouer. Ons versamel nie '
              'doelbewus data van jonger kinders nie; as jy dink \'n kind het \'n '
              'rekening geskep, kontak ons $_reachAf en ons skrap dit.',
        ),
        LegalSection(
          'Veranderinge en kontak',
          'Ons kan hierdie beleid bywerk; die datum hierbo is dié van die '
              'nuutste weergawe. Kontak ons vir vrae oor privaatheid $_reachAf.',
        ),
      ];

  // ---- Terms (Afrikaans) ----
  static List<LegalSection> get _termsAf => <LegalSection>[
        LegalSection(
          'Aanvaarding',
          'Deur $_app te gebruik, stem jy in tot hierdie bepalings. As jy nie '
              'instem nie, moet asseblief nie die app gebruik nie.',
        ),
        LegalSection(
          'Wie dit mag gebruik',
          'Jy moet ten minste 16 jaar oud wees om $_app te gebruik. As jy \'n '
              'rekening skep, hou jou aanmeldbesonderhede veilig; jy is '
              'verantwoordelik vir wat met jou rekening gebeur.',
        ),
        const LegalSection(
          'Wat die diens is',
          '\'n Persoonlike hulpmiddel vir begroting en beplanning om inkomste, '
              'uitgawes, begrotings, doelwitte en verwante insigte te volg, met '
              'opsionele KI-hulp, strokie-skandering, sinchronisasie tussen '
              'toestelle en betaalde planne.',
        ),
        const LegalSection(
          'Beplanningshulpmiddels, nie professionele advies nie',
          'Begrotings, vooruitskattings, die zakat-berekening en die antwoorde '
              'van DGOTIX AI is beplanningshulpmiddels om jou te help besluit. '
              'Hulle is nie professionele finansiële, belasting- of godsdienstige '
              'advies nie. Laat godsdienstige verpligtinge soos zakat deur \'n '
              'gekwalifiseerde geleerde bevestig; raadpleeg \'n gekwalifiseerde '
              'adviseur vir groot finansiële besluite.',
        ),
        const LegalSection(
          'KI-funksies',
          'DGOTIX AI en strokie-skandering in die wolk gee outomatiese '
              'resultate om jou tyd te spaar; kontroleer belangrike syfers voordat'
              ' jy daarvolgens optree. Hierdie funksies is ingesluit binne '
              'redelike gebruiksperke wat van jou plan afhang, en kan aangepas '
              'word om die diens vinnig en betroubaar vir almal te hou.',
        ),
        const LegalSection(
          'Planne, fakturering en hernuwing',
          'Die basiese app is gratis. Betaalde planne (Pro) ontsluit hoër perke '
              'en ekstra funksies teen die pryse wat in die app gewys word. \'n '
              'Betaalde plan hernu outomaties elke faktuurtydperk (maandeliks of '
              'jaarliks) totdat jy kanselleer. Betalings word verwerk deur Whop, '
              'ons betaalvennoot (of deur PayPal as jy dit kies); enige toepaslike'
              ' belasting kan bygevoeg word en word altyd by die betaalblad gewys '
              'voordat jy betaal. Jy kan enige tyd kanselleer en behou toegang '
              'tot die einde van die tydperk wat jy reeds betaal het. As pryse of '
              'funksies verander, word die huidige bepalings altyd gewys voordat '
              'jy inteken.',
        ),
        const LegalSection(
          'Ons betaalvennoot: Whop',
          'SmartBudget word deur DGOTIX verkoop. Betaling en fakturering word '
              'deur Whop (whop.com) hanteer, wat die betaling via sy eie '
              'beveiligde betaalblad verwerk, die volle prys insluitend belasting '
              'wys voordat jy betaal, en vir jou die kwitansie stuur. Jy kan jou '
              'intekening in die app bestuur of kanselleer (Planne → Bestuur).',
        ),
        LegalSection(
          'Terugbetalingsbeleid',
          'Behalwe waar die wet dit vereis, word betalings in beginsel nie '
              'terugbetaal sodra \'n faktuurtydperk begin het nie, omdat jy '
              'toegang tot die einde daarvan behou. Jy kan enige tyd kanselleer om'
              ' toekomstige hernuwings te stop. Vir \'n terugbetalingsversoek of '
              '\'n vraag oor \'n heffing, kontak ons $_reachAf: ons oorweeg elke '
              'versoek volgens die toepaslike verbruikersreg en betaal goedgekeurde'
              ' bedrae terug via Whop (of PayPal).',
        ),
        const LegalSection(
          'Koepons',
          'Koepons is opsioneel en verander slegs die prys by betaling (of gee '
              '\'n proeftydperk). Elke kode het sy eie voorwaardes (geldigheid, '
              'gebruiksperke, een per klant) en kan teruggetrek word of verval. '
              'Hulle het geen kontantwaarde nie en kan nie gekombineer word nie, '
              'tensy anders vermeld.',
        ),
        const LegalSection(
          'Jou data en rugsteun',
          'Jy is verantwoordelik vir die akkuraatheid van die data wat jy '
              'invoer. Om jou data veilig tussen toestelle te hou, meld aan om dit'
              ' te sinchroniseer, of voer gereeld \'n rugsteun vanuit Instellings '
              'uit.',
        ),
        LegalSection(
          'Beskikbaarheid',
          'Ons werk daaraan om $_app beskikbaar en betroubaar te hou. Sover die '
              'wet dit toelaat, word die app “soos dit is” verskaf, sonder enige '
              'waarborge. Lewendige markdata, KI en betalings hang af van dienste '
              'van derde partye en kan soms vertraag of onbeskikbaar wees; so \'n '
              'onderbreking keer jou nooit om die basiese begrotingshulpmiddels '
              'te gebruik nie, wat ook vanlyn werk. Funksies kan mettertyd '
              'verander.',
        ),
        const LegalSection(
          'Beperking van aanspreeklikheid',
          'Sover die wet dit toelaat, is ons nie aanspreeklik vir indirekte of '
              'gevolglike skade nie, of vir besluite wat jy neem op grond van die '
              'syfers in die app nie. Niks in hierdie bepalings beperk regte wat '
              'jy as verbruiker het en waarvan nie afgewyk kan word nie.',
        ),
        const LegalSection(
          'Aanvaarbare gebruik',
          'Moenie die diens misbruik nie, moenie probeer om die sekuriteit of '
              'planperke te breek of te omseil nie, en moenie dit vir onwettige '
              'doeleindes gebruik nie.',
        ),
        LegalSection(
          'Ophou gebruik',
          'Jy kan enige tyd ophou om $_app te gebruik en jou rekening skrap. Ons'
              ' kan \'n rekening opskort wat hierdie bepalings oortree of die diens'
              ' of ander gebruikers in gevaar stel.',
        ),
        LegalSection(
          'Handelsmerk en eiendom',
          'Die naam $_app, die handelsmerk $_brand en die app se ontwerp en kode '
              'bly die eiendom van hul eienaar. Jou data bly joune.',
        ),
        LegalSection(
          'Veranderinge en kontak',
          'Ons kan hierdie bepalings bywerk en die datum van die nuutste '
              'weergawe wys; as jy die app ná \'n bywerking aanhou gebruik, stem '
              'jy in tot die hersiene bepalings. Kontak ons vir vrae $_reachAf.',
        ),
      ];

  // ---- Privacy (Persian) ----
  static List<LegalSection> get _privacyFa => <LegalSection>[
        LegalSection(
          'نمای کلی',
          'این سیاست توضیح می‌دهد $_app چه چیزی را، کجا ذخیره می‌کند و چه '
              'انتخاب‌هایی دارید. خلاصه: داده‌های مالی شما مال شماست، ابتدا '
              'روی دستگاه خودتان ذخیره می‌شود و ما هرگز آن را نمی‌فروشیم، به شما'
              ' تبلیغ نشان نمی‌دهیم و شما را ردیابی نمی‌کنیم. چند امکان اختیاری '
              '(ورود و همگام‌سازی، DGOTIX AI، اسکن ابری رسید و طرح‌های پولی) فقط '
              'وقتی از آن‌ها استفاده کنید داده‌های مشخصی را به یک سرویس می‌فرستند،'
              ' چنان‌که در ادامه آمده است.',
        ),
        const LegalSection(
          'آنچه ذخیره می‌کنیم',
          'اطلاعاتی که خودتان وارد می‌کنید: درآمد، هزینه، بودجه، اهداف، بدهی‌ها،'
              ' کیف‌پول‌ها، دسته‌های شخصی و ترجیحات نمایش (پوسته، زبان، ارز پایه).'
              ' اگر حساب بسازید، ایمیل، طرح و وضعیت آن، و شمارنده‌های مصرف هر دوره'
              ' برای DGOTIX AI و اسکن ابری رسید را هم نگه می‌داریم؛ فقط برای اعمال'
              ' محدودیت‌های طرح شما. پرسش‌های شما از DGOTIX AI و عکس رسیدها را نگه'
              ' نمی‌داریم؛ اگر پاسخی از هوش مصنوعی را گزارش کنید، آن پاسخ و یادداشت'
              ' اختیاری شما را برای بررسی نگه می‌داریم.',
        ),
        const LegalSection(
          'داده‌های شما کجاست',
          'همه چیز ابتدا روی دستگاه شما ذخیره می‌شود (در برنامه، یا در نسخه وب'
              ' در مرورگر)، تا برنامه بدون حساب یا اتصال هم کار کند. اگر وارد '
              'شوید، داده‌ها خودکار بین دستگاه‌هایتان همگام می‌شوند: یک نسخه در '
              'پایگاه داده ما (میزبانی Supabase) است که به حساب شما وصل است و '
              'طوری جدا شده که فقط شما بتوانید آن را بخوانید. می‌توانید همگام‌سازی'
              ' را در تنظیمات خاموش کنید؛ آنگاه داده‌ها فقط روی این دستگاه '
              'می‌مانند.',
        ),
        const LegalSection(
          'حساب و ایمیل‌های شما',
          'ایمیل شما برای ورود و فرستادن ایمیل‌های حساب، مانند تأیید نشانی و '
              'بازنشانی رمز (از طریق Brevo)، به کار می‌رود. هرگز برای تبلیغ '
              'استفاده یا برای بازاریابی به اشتراک گذاشته نمی‌شود. هنگام ثبت‌نام و'
              ' ورود، یک بررسی کوتاه انسان بودن (Cloudflare Turnstile) جلوی سوءاستفاده'
              ' خودکار را می‌گیرد.',
        ),
        const LegalSection(
          'DGOTIX AI',
          'DGOTIX AI اختیاری است. وقتی پرسشی می‌کنید، متن آن پرسش و خلاصه‌ای از '
              'ارقام شما (جمع هر ماه و هر دسته تا 12 ماه، بودجه‌ها، موجودی '
              'کیف‌پول‌ها، اهداف، تراکنش‌های تکراری، بودجه مناسبت‌ها و صندوق‌ها؛ '
              'فقط مبلغ و تاریخ، هرگز توضیح، یادداشت یا نام‌هایی که می‌گذارید) از '
              'طریق سرور امن ما به یک ارائه‌دهنده هوش مصنوعی (Google Gemini، OpenAI'
              ' یا Anthropic) فرستاده می‌شود تا پاسخ ساخته شود. سرور ما از '
              'کلیدهای خودمان استفاده می‌کند و فقط فراداده مصرف را ثبت می‌کند، هرگز'
              ' پرسش یا ارقام شما را. از داده‌های شما برای آموزش مدل‌ها استفاده '
              'نمی‌کنیم. پاسخ‌ها خودکار ساخته می‌شوند، پس پیش از عمل ارقام مهم را'
              ' بررسی کنید.',
        ),
        const LegalSection(
          'اسکن رسید',
          'روی اندروید، رسیدها می‌توانند کاملاً روی دستگاه شما خوانده شوند. اسکن'
              ' ابری عکس رسید را از طریق سرور امن ما به یک ارائه‌دهنده هوش مصنوعی '
              'می‌فرستد، فقط برای خواندن فروشنده، تاریخ، مبلغ، اقلام و دسته؛ عکس '
              'نگه داشته نمی‌شود.',
        ),
        const LegalSection(
          'پرداخت‌ها و اشتراک‌ها',
          'طرح‌های پولی اختیاری‌اند. پرداخت از طریق صفحه پرداخت امن Whop '
              '(whop.com)، همکار پرداخت ما، یا با PayPal اگر آن را انتخاب کنید، '
              'انجام می‌شود. آن‌ها جزئیات صورت‌حسابی را که لازم دارند (مانند نام، '
              'ایمیل، کشور و روش پرداخت) طبق سیاست حریم خصوصی خودشان گردآوری '
              'می‌کنند؛ ما هرگز جزئیات کامل کارت شما را نمی‌بینیم و ذخیره نمی‌کنیم.'
              ' طرح، وضعیت آن، تاریخ تمدید و شناسه‌های اشتراک همکار پرداخت را برای'
              ' دادن دسترسی درست نگه می‌داریم، به‌علاوه سابقه کدهای تخفیفی که '
              'استفاده می‌کنید.',
        ),
        const LegalSection(
          'ارائه‌دهندگان خدمات',
          'بسته به امکاناتی که استفاده می‌کنید: Supabase (حساب‌ها، همگام‌سازی و '
              'توابع سرور ما)؛ Whop و PayPal (پرداخت‌ها)؛ Brevo (ایمیل‌های حساب)؛ '
              'Cloudflare Turnstile (بررسی هنگام ورود)؛ GitHub Pages (میزبانی وب‌سایت'
              ' و برنامه وب)؛ Google، OpenAI و Anthropic (DGOTIX AI و اسکن ابری '
              'رسید)؛ و منابع عمومی داده بازار برای ارقام زنده، یعنی نرخ ارز '
              '(open.er-api.com) و قیمت رمزارز (CoinGecko)، که درخواست‌هایشان فقط '
              'نماد ارز یا دارایی دارد، هرگز داده شخصی یا مالی شما. هر ارائه‌دهنده'
              ' فقط برای انجام بخش خود از سرویس داده‌ها را پردازش می‌کند.',
        ),
        const LegalSection(
          'امنیت',
          'اتصال به سرویس‌های ما رمزگذاری شده است (HTTPS). در پایگاه داده ما، '
              'داده‌های هر کاربر طوری جدا شده که هیچ حسابی نتواند داده حساب دیگری '
              'را بخواند. کلیدهای سرور هرگز در برنامه نیستند، اعلان‌های پرداخت '
              'پیش از هر تغییری بررسی می‌شوند و می‌توانید روی دستگاه خود قفل '
              'برنامه (رمز یا اثر انگشت) بگذارید.',
        ),
        const LegalSection(
          'آنچه انجام نمی‌دهیم',
          'داده‌های شما را نمی‌فروشیم و اجاره نمی‌دهیم، تبلیغ نشان نمی‌دهیم و '
              'ردیابی رفتاری یا تحلیل فعالیت مالی شما انجام نمی‌دهیم.',
        ),
        // Only while the totals are on (and trips are only in SmartTrip).
        if (AppEnv.anonStats && AppEnv.smartTrip)
          const LegalSection(
            'شمارش‌های ناشناس',
            'وقتی سفری می‌سازید، برنامه فقط عبارت «یک سفر برنامه‌ریزی شد» را '
                'می‌فرستد و سرور ما یکی به جمع آن روز اضافه می‌کند. هیچ چیز دیگری '
                'همراهش فرستاده یا نگه داشته نمی‌شود؛ نه حساب، نه دستگاه، نه مقصد و'
                ' نه مبلغ؛ پس جمع‌ها به شما ربط داده نمی‌شوند. فقط برای دانستن '
                'میزان استفاده از برنامه و نشان دادن ارقام کلی به همکاران از آن‌ها'
                ' استفاده می‌کنیم. می‌توانید در تنظیمات، بخش حریم خصوصی، خاموشش '
                'کنید.',
          ),
        const LegalSection(
          'مدت نگهداری داده‌ها',
          'داده‌های روی دستگاه شما تا وقتی حذفشان کنید یا برنامه را پاک کنید '
              'می‌مانند. حساب، داده‌های همگام‌شده، شمارنده‌های مصرف و فراداده '
              'درخواست‌ها تا وقتی حساب شما وجود دارد نگه داشته می‌شوند؛ فقط برای '
              'کار کردن سرویس و اعمال محدودیت‌های طرح؛ و با حذف حساب برای همیشه '
              'پاک می‌شوند. Whop و PayPal سوابق صورت‌حسابی را که قانوناً باید نگه '
              'دارند نگه می‌دارند.',
        ),
        LegalSection(
          'حقوق و تنظیمات شما',
          'همیشه می‌توانید داده‌های خود را در برنامه ببینید و اصلاح کنید، یک '
              'پشتیبان کامل بگیرید، همگام‌سازی را خاموش کنید، خارج شوید و حساب را '
              'با همه داده‌هایش حذف کنید (پایین را ببینید). هر زمان می‌توانید طرح '
              'پولی را لغو کنید (شرایط استفاده را ببینید). برای هر درخواست دیگری '
              'درباره داده‌های شخصی‌تان، مانند دسترسی، اصلاح، حذف یا اعتراض، '
              '$_reachFa با ما تماس بگیرید تا سریع پاسخ دهیم.',
        ),
        const LegalSection(
          'حذف حساب و داده‌ها',
          'در برنامه یا نسخه وب، روی هر دستگاهی، تنظیمات، سپس حساب، سپس «حذف حساب'
              ' من» را باز کنید. این کار حساب شما و هر آنچه برای آن روی سرورهای ما'
              ' است (نمایه، داده‌های همگام‌شده، سوابق اشتراک و شمارنده‌های مصرف) را'
              ' برای همیشه حذف می‌کند و داده‌های شما روی آن دستگاه را پاک می‌کند. '
              'ابتدا طرح پولی را لغو کنید. حذف قابل بازگشت نیست، پس اگر ممکن است '
              'بعداً داده‌ها را بخواهید، از قبل پشتیبان بگیرید.',
        ),
        LegalSection(
          'سن',
          '$_app برای افراد 16 سال و بالاتر است. آگاهانه از کودکان کوچک‌تر داده '
              'گردآوری نمی‌کنیم؛ اگر فکر می‌کنید کودکی حساب ساخته، $_reachFa با '
              'ما تماس بگیرید تا حذفش کنیم.',
        ),
        LegalSection(
          'تغییرات و تماس',
          'ممکن است این سیاست را به‌روز کنیم؛ تاریخ بالا مربوط به آخرین نسخه '
              'است. برای پرسش درباره حریم خصوصی $_reachFa با ما تماس بگیرید.',
        ),
      ];

  // ---- Terms (Persian) ----
  static List<LegalSection> get _termsFa => <LegalSection>[
        LegalSection(
          'پذیرش',
          'با استفاده از $_app این شرایط را می‌پذیرید. اگر نمی‌پذیرید، لطفاً از '
              'برنامه استفاده نکنید.',
        ),
        LegalSection(
          'چه کسی می‌تواند استفاده کند',
          'برای استفاده از $_app باید دست‌کم 16 سال داشته باشید. اگر حساب '
              'می‌سازید، اطلاعات ورود را امن نگه دارید؛ شما مسئول آنچه در حسابتان '
              'رخ می‌دهد هستید.',
        ),
        const LegalSection(
          'سرویس چیست',
          'ابزاری شخصی برای بودجه‌بندی و برنامه‌ریزی، برای پیگیری درآمد، هزینه، '
              'بودجه، اهداف و بینش‌های مرتبط، همراه با کمک اختیاری هوش مصنوعی، اسکن'
              ' رسید، همگام‌سازی بین دستگاه‌ها و طرح‌های پولی.',
        ),
        const LegalSection(
          'ابزار برنامه‌ریزی، نه مشاوره حرفه‌ای',
          'بودجه‌ها، پیش‌بینی‌ها، محاسبه زکات و پاسخ‌های DGOTIX AI ابزارهای '
              'برنامه‌ریزی برای کمک به تصمیم‌گیری شما هستند. مشاوره حرفه‌ای مالی، '
              'مالیاتی یا دینی نیستند. تکالیف دینی مانند زکات را با یک عالم آگاه '
              'تأیید کنید و برای تصمیم‌های مالی بزرگ با یک مشاور واجد شرایط مشورت '
              'کنید.',
        ),
        const LegalSection(
          'امکانات هوش مصنوعی',
          'DGOTIX AI و اسکن ابری رسید نتایج خودکار می‌دهند تا در وقت شما صرفه‌جویی'
              ' شود؛ پیش از عمل ارقام مهم را بررسی کنید. این امکانات در محدوده '
              'مصرف معقولی که به طرح شما بستگی دارد گنجانده شده‌اند و ممکن است برای'
              ' سریع و قابل اعتماد ماندن سرویس برای همه تنظیم شوند.',
        ),
        const LegalSection(
          'طرح‌ها، صورت‌حساب و تمدید',
          'برنامه پایه رایگان است. طرح‌های پولی (Pro) محدودیت‌های بالاتر و '
              'امکانات بیشتر را با قیمت‌های نمایش‌داده‌شده در برنامه باز می‌کنند. '
              'طرح پولی هر دوره صورت‌حساب (ماهانه یا سالانه) خودکار تمدید می‌شود '
              'تا وقتی لغوش کنید. پرداخت‌ها توسط Whop، همکار پرداخت ما (یا PayPal '
              'اگر انتخابش کنید)، پردازش می‌شوند؛ مالیات مربوط ممکن است اضافه شود '
              'و همیشه پیش از پرداخت در صفحه پرداخت نمایش داده می‌شود. هر زمان '
              'می‌توانید لغو کنید و تا پایان دوره‌ای که پرداخته‌اید دسترسی دارید. '
              'اگر قیمت‌ها یا امکانات تغییر کنند، شرایط فعلی همیشه پیش از اشتراک '
              'نمایش داده می‌شود.',
        ),
        const LegalSection(
          'همکار پرداخت ما: Whop',
          'SmartBudget را DGOTIX می‌فروشد. پرداخت و صورت‌حساب را Whop (whop.com)'
              ' انجام می‌دهد که پرداخت را از طریق صفحه امن خودش پردازش می‌کند، قیمت'
              ' کامل با مالیات را پیش از پرداخت نشان می‌دهد و رسید را برایتان '
              'می‌فرستد. می‌توانید اشتراک را در برنامه مدیریت یا لغو کنید (طرح‌ها '
              '← مدیریت).',
        ),
        LegalSection(
          'سیاست بازپرداخت',
          'جز جایی که قانون الزام کند، پرداخت‌ها پس از شروع یک دوره صورت‌حساب '
              'اصولاً بازپرداخت نمی‌شوند، چون تا پایان آن دسترسی دارید. هر زمان '
              'می‌توانید برای توقف تمدیدهای بعدی لغو کنید. برای درخواست بازپرداخت '
              'یا پرسش درباره یک کسر مبلغ، $_reachFa با ما تماس بگیرید: هر درخواست'
              ' را طبق قانون حمایت از مصرف‌کننده مربوط بررسی و مبالغ تأییدشده را از'
              ' طریق Whop (یا PayPal) بازپرداخت می‌کنیم.',
        ),
        const LegalSection(
          'کدهای تخفیف',
          'کدهای تخفیف اختیاری‌اند و فقط قیمت پرداخت را تغییر می‌دهند (یا دوره '
              'آزمایشی می‌دهند). هر کد شرایط خود را دارد (اعتبار، سقف استفاده، یکی'
              ' برای هر مشتری) و ممکن است لغو یا منقضی شود. ارزش نقدی ندارند و جز '
              'در صورت ذکر، قابل ترکیب نیستند.',
        ),
        const LegalSection(
          'داده‌ها و پشتیبان شما',
          'درستی داده‌هایی که وارد می‌کنید با شماست. برای امن ماندن داده‌ها بین '
              'دستگاه‌ها وارد شوید تا همگام شوند، یا به‌طور منظم از تنظیمات پشتیبان'
              ' بگیرید.',
        ),
        LegalSection(
          'دسترس‌پذیری',
          'می‌کوشیم $_app در دسترس و قابل اعتماد بماند. تا جایی که قانون اجازه '
              'دهد، برنامه «همان‌گونه که هست» و بدون هیچ ضمانتی ارائه می‌شود. داده '
              'زنده بازار، هوش مصنوعی و پرداخت‌ها به سرویس‌های اشخاص ثالث بستگی '
              'دارند و ممکن است گاهی با تأخیر یا در دسترس نباشند؛ چنین وقفه‌ای هرگز'
              ' مانع استفاده از ابزارهای پایه بودجه نمی‌شود که آفلاین هم کار '
              'می‌کنند. امکانات ممکن است با گذشت زمان تغییر کنند.',
        ),
        const LegalSection(
          'محدودیت مسئولیت',
          'تا جایی که قانون اجازه دهد، مسئول خسارت غیرمستقیم یا تبعی، یا '
              'تصمیم‌هایی که بر اساس ارقام برنامه می‌گیرید، نیستیم. هیچ چیز در این'
              ' شرایط حقوقی را که به‌عنوان مصرف‌کننده دارید و قابل سلب نیست محدود '
              'نمی‌کند.',
        ),
        const LegalSection(
          'استفاده مجاز',
          'از سرویس سوءاستفاده نکنید، برای شکستن یا دور زدن امنیت یا محدودیت‌های'
              ' طرح تلاش نکنید و از آن برای مقاصد غیرقانونی استفاده نکنید.',
        ),
        LegalSection(
          'توقف استفاده',
          'هر زمان می‌توانید استفاده از $_app را متوقف و حساب خود را حذف کنید. '
              'ممکن است حسابی را که این شرایط را نقض کند یا سرویس یا کاربران دیگر '
              'را به خطر بیندازد تعلیق کنیم.',
        ),
        LegalSection(
          'نشان تجاری و مالکیت',
          'نام $_app، نشان $_brand و طراحی و کد برنامه متعلق به مالک آن‌ها '
              'می‌ماند. داده‌های شما مال شما می‌ماند.',
        ),
        LegalSection(
          'تغییرات و تماس',
          'ممکن است این شرایط را به‌روز کنیم و تاریخ آخرین نسخه را نشان دهیم؛ '
              'اگر پس از به‌روزرسانی به استفاده ادامه دهید، شرایط بازبینی‌شده را '
              'می‌پذیرید. برای پرسش $_reachFa با ما تماس بگیرید.',
        ),
      ];

  // ---- Privacy (Hindi) ----
  static List<LegalSection> get _privacyHi => <LegalSection>[
        LegalSection(
          'सारांश',
          'यह नीति बताती है कि $_app क्या सहेजता है, कहाँ सहेजता है और आपके '
              'पास क्या विकल्प हैं। संक्षेप में: आपका वित्तीय डेटा आपका है, यह '
              'पहले आपके डिवाइस पर सहेजा जाता है, और हम इसे कभी नहीं बेचते, '
              'आपको विज्ञापन नहीं दिखाते और आपको ट्रैक नहीं करते। कुछ वैकल्पिक '
              'सुविधाएँ (साइन इन और सिंक, DGOTIX AI, क्लाउड रसीद स्कैन और भुगतान'
              ' वाले प्लान) सिर्फ़ तब किसी सेवा को तय डेटा भेजती हैं जब आप उनका '
              'इस्तेमाल करते हैं, जैसा नीचे बताया गया है।',
        ),
        const LegalSection(
          'हम क्या सहेजते हैं',
          'वह जानकारी जो आप ख़ुद लिखते हैं: आमदनी, ख़र्च, बजट, लक्ष्य, क़र्ज़, '
              'वॉलेट, अपनी श्रेणियाँ और दिखावट की पसंद (थीम, भाषा, मूल मुद्रा)। '
              'अगर आप खाता बनाते हैं, तो हम आपका ईमेल, आपका प्लान और उसकी '
              'स्थिति, और DGOTIX AI व क्लाउड रसीद स्कैन के लिए हर अवधि के '
              'इस्तेमाल के काउंटर भी रखते हैं — सिर्फ़ आपके प्लान की सीमाएँ लागू '
              'करने के लिए। हम DGOTIX AI से आपके सवाल और आपकी रसीदों की फ़ोटो नहीं'
              ' रखते; अगर आप किसी AI जवाब की शिकायत करते हैं, तो जाँच के लिए वह '
              'जवाब और आपका वैकल्पिक नोट रखते हैं।',
        ),
        const LegalSection(
          'आपका डेटा कहाँ रहता है',
          'सब कुछ पहले आपके डिवाइस पर सहेजा जाता है (ऐप में, या वेब संस्करण '
              'के लिए आपके ब्राउज़र में), ताकि ऐप बिना खाते या कनेक्शन के भी '
              'चले। साइन इन करने पर आपका डेटा आपके डिवाइसों के बीच अपने आप सिंक '
              'होता है: इसकी एक कॉपी हमारे डेटाबेस (Supabase पर होस्ट) में रहती है,'
              ' आपके खाते से जुड़ी और ऐसे अलग रखी गई कि सिर्फ़ आप उसे पढ़ सकें। आप'
              ' सेटिंग्स में सिंक बंद कर सकते हैं; तब आपका डेटा सिर्फ़ इसी डिवाइस '
              'पर रहता है।',
        ),
        const LegalSection(
          'आपका खाता और ईमेल',
          'आपका ईमेल आपको साइन इन कराने और खाते से जुड़े ईमेल भेजने के लिए '
              'इस्तेमाल होता है, जैसे पते की पुष्टि और पासवर्ड रीसेट (Brevo के '
              'ज़रिए)। इसे कभी विज्ञापन के लिए इस्तेमाल या मार्केटिंग के लिए साझा'
              ' नहीं किया जाता। साइन अप और साइन इन के समय एक छोटी इंसानी जाँच '
              '(Cloudflare Turnstile) स्वचालित दुरुपयोग रोकती है।',
        ),
        const LegalSection(
          'DGOTIX AI',
          'DGOTIX AI वैकल्पिक है। जब आप सवाल पूछते हैं, तो उस सवाल का टेक्स्ट और'
              ' आपके अंकों का एक सारांश (12 महीनों तक महीने और श्रेणी के हिसाब से '
              'कुल, बजट, वॉलेट बैलेंस, लक्ष्य, दोहराने वाले लेन-देन, मौसमी बजट और'
              ' बचत कमेटियाँ — सिर्फ़ रक़में और तारीख़ें, कभी विवरण, नोट या आपके '
              'दिए नाम नहीं) हमारे सुरक्षित सर्वर से एक AI प्रदाता (Google Gemini, '
              'OpenAI या Anthropic) को जवाब बनाने के लिए भेजा जाता है। हमारा सर्वर '
              'हमारी अपनी कुंजियाँ इस्तेमाल करता है और सिर्फ़ इस्तेमाल का मेटाडेटा '
              'दर्ज करता है, कभी आपका सवाल या आपके अंक नहीं। हम मॉडल प्रशिक्षित '
              'करने के लिए आपका डेटा इस्तेमाल नहीं करते। जवाब अपने आप बनते हैं, '
              'इसलिए उन पर अमल से पहले ज़रूरी अंक जाँचें।',
        ),
        const LegalSection(
          'रसीद स्कैन',
          'Android पर रसीदें पूरी तरह आपके डिवाइस पर पढ़ी जा सकती हैं। क्लाउड '
              'स्कैन रसीद की फ़ोटो हमारे सुरक्षित सर्वर से एक AI प्रदाता को सिर्फ़ '
              'दुकान, तारीख़, रक़म, सामान और श्रेणी पढ़ने के लिए भेजता है; फ़ोटो '
              'रखी नहीं जाती।',
        ),
        const LegalSection(
          'भुगतान और सदस्यताएँ',
          'भुगतान वाले प्लान वैकल्पिक हैं। आप Whop (whop.com), हमारे भुगतान '
              'साझेदार, के सुरक्षित चेकआउट से भुगतान करते हैं, या चाहें तो PayPal '
              'से। वे अपनी गोपनीयता नीति के अनुसार ज़रूरी बिलिंग विवरण (जैसे नाम, '
              'ईमेल, देश और भुगतान का तरीक़ा) लेते हैं; हम कभी आपके कार्ड का पूरा '
              'विवरण नहीं देखते न रखते। सही पहुँच देने के लिए हम आपका प्लान, उसकी'
              ' स्थिति, नवीनीकरण की तारीख़ और भुगतान साझेदार के सदस्यता पहचानकर्ता'
              ' रखते हैं, साथ ही आपके इस्तेमाल किए कूपन का रिकॉर्ड।',
        ),
        const LegalSection(
          'सेवा प्रदाता',
          'आपकी इस्तेमाल की गई सुविधाओं के अनुसार: Supabase (खाते, सिंक और हमारे'
              ' सर्वर फ़ंक्शन); Whop और PayPal (भुगतान); Brevo (खाते के ईमेल); '
              'Cloudflare Turnstile (साइन इन जाँच); GitHub Pages (हमारी वेबसाइट और '
              'वेब ऐप की होस्टिंग); Google, OpenAI और Anthropic (DGOTIX AI और क्लाउड'
              ' रसीद स्कैन); और लाइव अंकों के लिए सार्वजनिक बाज़ार-डेटा स्रोत — '
              'विनिमय दरें (open.er-api.com) और क्रिप्टो दाम (CoinGecko) — जिनके '
              'अनुरोधों में सिर्फ़ मुद्रा या संपत्ति के चिह्न होते हैं, कभी आपका '
              'व्यक्तिगत या वित्तीय डेटा नहीं। हर प्रदाता डेटा को सिर्फ़ सेवा का '
              'अपना हिस्सा देने के लिए प्रोसेस करता है।',
        ),
        const LegalSection(
          'सुरक्षा',
          'हमारी सेवाओं से कनेक्शन एन्क्रिप्टेड हैं (HTTPS)। हमारे डेटाबेस में '
              'हर उपयोगकर्ता का डेटा ऐसे अलग है कि कोई खाता दूसरे का डेटा नहीं पढ़ '
              'सकता। सर्वर कुंजियाँ कभी ऐप में नहीं जातीं, भुगतान सूचनाएँ कुछ भी '
              'बदलने से पहले जाँची जाती हैं, और आप अपने डिवाइस पर ऐप लॉक (PIN या '
              'फ़िंगरप्रिंट) लगा सकते हैं।',
        ),
        const LegalSection(
          'हम क्या नहीं करते',
          'हम आपका डेटा न बेचते हैं न किराये पर देते हैं, विज्ञापन नहीं दिखाते,'
              ' और आपकी वित्तीय गतिविधि की व्यवहार-ट्रैकिंग या एनालिटिक्स नहीं '
              'करते।',
        ),
        // Only while the totals are on (and trips are only in SmartTrip).
        if (AppEnv.anonStats && AppEnv.smartTrip)
          const LegalSection(
            'गुमनाम गिनती',
            'जब आप यात्रा बनाते हैं, ऐप सिर्फ़ “एक यात्रा की योजना बनी” भेजता '
                'है, और हमारा सर्वर उस दिन के कुल में एक जोड़ता है। इसके साथ और '
                'कुछ नहीं भेजा या रखा जाता — न खाता, न डिवाइस, न जगह, न रक़म — '
                'इसलिए कुल को आपसे नहीं जोड़ा जा सकता। हम इन्हें सिर्फ़ यह जानने के'
                ' लिए इस्तेमाल करते हैं कि ऐप कितना चलता है और साझेदारों को कुल '
                'अंक दिखाने के लिए। आप इसे सेटिंग्स में, गोपनीयता के अंदर, बंद कर '
                'सकते हैं।',
          ),
        const LegalSection(
          'हम डेटा कितने समय रखते हैं',
          'आपके डिवाइस का डेटा तब तक रहता है जब तक आप उसे हटाएँ या ऐप '
              'अनइंस्टॉल करें। आपका खाता, सिंक डेटा, इस्तेमाल के काउंटर और अनुरोधों'
              ' का मेटाडेटा तब तक रखा जाता है जब तक आपका खाता है — सिर्फ़ सेवा '
              'चलाने और आपके प्लान की सीमाएँ लागू करने के लिए — और खाता हटाने पर '
              'हमेशा के लिए मिटा दिया जाता है। Whop और PayPal वे बिलिंग रिकॉर्ड '
              'रखते हैं जो उन्हें क़ानूनन रखने होते हैं।',
        ),
        LegalSection(
          'आपके अधिकार और विकल्प',
          'आप कभी भी ऐप में अपना डेटा देख और ठीक कर सकते हैं, पूरा बैकअप निकाल '
              'सकते हैं, सिंक बंद कर सकते हैं, साइन आउट कर सकते हैं और अपना खाता '
              'उसके सारे डेटा के साथ हटा सकते हैं (नीचे देखें)। भुगतान वाला प्लान '
              'कभी भी रद्द कर सकते हैं (शर्तें देखें)। अपने व्यक्तिगत डेटा के '
              'किसी और अनुरोध के लिए — जैसे पहुँच, सुधार, हटाना या आपत्ति — '
              '$_reachHi हमसे संपर्क करें और हम जल्दी जवाब देंगे।',
        ),
        const LegalSection(
          'अपना खाता और डेटा हटाना',
          'ऐप या वेब संस्करण में, किसी भी डिवाइस पर, सेटिंग्स, फिर खाता, फिर '
              '“मेरा खाता हटाएँ” खोलें। इससे आपका खाता और हमारे सर्वर पर उसके लिए '
              'रखा सब कुछ (प्रोफ़ाइल, सिंक डेटा, सदस्यता रिकॉर्ड और इस्तेमाल के '
              'काउंटर) हमेशा के लिए हट जाता है, और उस डिवाइस पर आपका डेटा मिट जाता'
              ' है। पहले भुगतान वाला प्लान रद्द करें। हटाना वापस नहीं हो सकता, '
              'इसलिए अगर बाद में डेटा चाहिए हो तो पहले बैकअप निकालें।',
        ),
        LegalSection(
          'उम्र',
          '$_app 16 साल और उससे ज़्यादा उम्र के लोगों के लिए है। हम जानबूझकर '
              'छोटे बच्चों का डेटा नहीं लेते; अगर आपको लगता है कि किसी बच्चे ने '
              'खाता बनाया है, तो $_reachHi हमसे संपर्क करें और हम उसे हटा देंगे।',
        ),
        LegalSection(
          'बदलाव और संपर्क',
          'हम यह नीति अपडेट कर सकते हैं; ऊपर की तारीख़ नवीनतम संस्करण की है। '
              'गोपनीयता से जुड़े सवालों के लिए $_reachHi हमसे संपर्क करें।',
        ),
      ];

  // ---- Terms (Hindi) ----
  static List<LegalSection> get _termsHi => <LegalSection>[
        LegalSection(
          'स्वीकृति',
          '$_app इस्तेमाल करके आप इन शर्तों से सहमत होते हैं। अगर सहमत नहीं हैं,'
              ' तो कृपया ऐप इस्तेमाल न करें।',
        ),
        LegalSection(
          'कौन इस्तेमाल कर सकता है',
          '$_app इस्तेमाल करने के लिए आपकी उम्र कम से कम 16 साल होनी चाहिए। अगर '
              'आप खाता बनाते हैं, तो अपनी साइन-इन जानकारी सुरक्षित रखें; आपके खाते'
              ' में जो होता है उसकी ज़िम्मेदारी आपकी है।',
        ),
        const LegalSection(
          'सेवा क्या है',
          'आमदनी, ख़र्च, बजट, लक्ष्य और उनसे जुड़ी जानकारी ट्रैक करने का एक '
              'व्यक्तिगत बजट और योजना उपकरण, वैकल्पिक AI मदद, रसीद स्कैन, '
              'डिवाइसों के बीच सिंक और भुगतान वाले प्लान के साथ।',
        ),
        const LegalSection(
          'योजना के उपकरण, पेशेवर सलाह नहीं',
          'बजट, पूर्वानुमान, ज़कात की गणना और DGOTIX AI के जवाब आपको फ़ैसला '
              'करने में मदद के लिए योजना के उपकरण हैं। ये पेशेवर वित्तीय, टैक्स या'
              ' धार्मिक सलाह नहीं हैं। ज़कात जैसे धार्मिक दायित्व किसी योग्य आलिम '
              'से पुष्ट करें; बड़े वित्तीय फ़ैसलों के लिए किसी योग्य सलाहकार से '
              'सलाह लें।',
        ),
        const LegalSection(
          'AI सुविधाएँ',
          'DGOTIX AI और क्लाउड रसीद स्कैन आपका समय बचाने के लिए स्वचालित नतीजे '
              'देते हैं; उन पर अमल से पहले ज़रूरी अंक जाँचें। ये सुविधाएँ आपके '
              'प्लान पर निर्भर उचित इस्तेमाल की सीमाओं में शामिल हैं, और सेवा को '
              'सबके लिए तेज़ और भरोसेमंद रखने के लिए बदली जा सकती हैं।',
        ),
        const LegalSection(
          'प्लान, बिलिंग और नवीनीकरण',
          'बुनियादी ऐप मुफ़्त है। भुगतान वाले प्लान (Pro) ऐप में दिखाए दामों पर '
              'ऊँची सीमाएँ और अतिरिक्त सुविधाएँ खोलते हैं। भुगतान वाला प्लान हर '
              'बिलिंग अवधि (मासिक या वार्षिक) में अपने आप नवीनीकृत होता है जब तक आप'
              ' रद्द न करें। भुगतान Whop, हमारे भुगतान साझेदार (या चुनने पर '
              'PayPal), द्वारा प्रोसेस होते हैं; लागू टैक्स जुड़ सकते हैं और भुगतान'
              ' से पहले चेकआउट पर हमेशा दिखते हैं। आप कभी भी रद्द कर सकते हैं और '
              'जिस अवधि का भुगतान कर चुके हैं उसके अंत तक पहुँच बनी रहती है। अगर '
              'दाम या सुविधाएँ बदलती हैं, तो सदस्यता से पहले मौजूदा शर्तें हमेशा '
              'दिखाई जाती हैं।',
        ),
        const LegalSection(
          'हमारा भुगतान साझेदार: Whop',
          'SmartBudget को DGOTIX बेचता है। चेकआउट और बिलिंग Whop (whop.com) संभालता'
              ' है, जो अपने सुरक्षित चेकआउट से भुगतान प्रोसेस करता है, भुगतान से '
              'पहले टैक्स सहित पूरा दाम दिखाता है और आपको रसीद भेजता है। आप ऐप में'
              ' सदस्यता प्रबंधित या रद्द कर सकते हैं (प्लान → प्रबंधन)।',
        ),
        LegalSection(
          'रिफ़ंड नीति',
          'जहाँ क़ानून ज़रूरी न बनाए, वहाँ बिलिंग अवधि शुरू होने के बाद भुगतान '
              'आमतौर पर वापस नहीं होते, क्योंकि उसके अंत तक आपकी पहुँच बनी रहती है।'
              ' आगे के नवीनीकरण रोकने के लिए कभी भी रद्द कर सकते हैं। रिफ़ंड के '
              'अनुरोध या किसी कटौती के सवाल के लिए $_reachHi हमसे संपर्क करें: हम '
              'हर अनुरोध लागू उपभोक्ता क़ानून के अनुसार देखते हैं और स्वीकृत रक़में '
              'Whop (या PayPal) से लौटाते हैं।',
        ),
        const LegalSection(
          'कूपन',
          'कूपन वैकल्पिक हैं और सिर्फ़ चेकआउट का दाम बदलते हैं (या ट्रायल देते '
              'हैं)। हर कोड की अपनी शर्तें होती हैं (वैधता, इस्तेमाल की सीमा, हर '
              'ग्राहक के लिए एक) और वापस लिया या समाप्त हो सकता है। इनका कोई नक़द '
              'मूल्य नहीं और अलग से न कहा जाए तो जोड़े नहीं जा सकते।',
        ),
        const LegalSection(
          'आपका डेटा और बैकअप',
          'आप जो डेटा लिखते हैं उसकी सटीकता की ज़िम्मेदारी आपकी है। डिवाइसों के '
              'बीच डेटा सुरक्षित रखने के लिए साइन इन करके सिंक करें, या सेटिंग्स से'
              ' नियमित बैकअप निकालें।',
        ),
        LegalSection(
          'उपलब्धता',
          'हम $_app को उपलब्ध और भरोसेमंद रखने की कोशिश करते हैं। क़ानून जितनी '
              'अनुमति दे, ऐप “जैसा है” बिना किसी तरह की वारंटी के दिया जाता है। '
              'लाइव बाज़ार डेटा, AI और भुगतान तीसरे पक्ष की सेवाओं पर निर्भर हैं और'
              ' कभी देर से या अनुपलब्ध हो सकते हैं; ऐसी रुकावट आपको बुनियादी बजट '
              'उपकरण इस्तेमाल करने से कभी नहीं रोकती, जो ऑफ़लाइन भी चलते हैं। '
              'सुविधाएँ समय के साथ बदल सकती हैं।',
        ),
        const LegalSection(
          'दायित्व की सीमा',
          'क़ानून जितनी अनुमति दे, हम अप्रत्यक्ष या परिणामी नुक़सान के लिए, या ऐप'
              ' के अंकों के आधार पर लिए आपके फ़ैसलों के लिए ज़िम्मेदार नहीं हैं। इन'
              ' शर्तों में कुछ भी उपभोक्ता के रूप में आपके उन अधिकारों को सीमित नहीं'
              ' करता जिन्हें छोड़ा नहीं जा सकता।',
        ),
        const LegalSection(
          'स्वीकार्य इस्तेमाल',
          'सेवा का दुरुपयोग न करें, सुरक्षा या प्लान की सीमाएँ तोड़ने या उनसे बचने'
              ' की कोशिश न करें, और इसे ग़ैरक़ानूनी कामों के लिए इस्तेमाल न करें।',
        ),
        LegalSection(
          'इस्तेमाल बंद करना',
          'आप कभी भी $_app इस्तेमाल करना बंद करके अपना खाता हटा सकते हैं। हम ऐसा'
              ' खाता निलंबित कर सकते हैं जो इन शर्तों को तोड़े या सेवा या दूसरे '
              'उपयोगकर्ताओं को ख़तरे में डाले।',
        ),
        LegalSection(
          'ब्रांड और स्वामित्व',
          '$_app नाम, $_brand ब्रांड और ऐप का डिज़ाइन और कोड उनके मालिक के रहते '
              'हैं। आपका डेटा आपका रहता है।',
        ),
        LegalSection(
          'बदलाव और संपर्क',
          'हम ये शर्तें अपडेट कर सकते हैं और नवीनतम संस्करण की तारीख़ दिखाएँगे; '
              'अपडेट के बाद ऐप इस्तेमाल करते रहने पर आप संशोधित शर्तों से सहमत होते'
              ' हैं। सवालों के लिए $_reachHi हमसे संपर्क करें।',
        ),
      ];
  // ---- Privacy (Chinese) ----
  static List<LegalSection> get _privacyZh => <LegalSection>[
        LegalSection(
          '摘要',
          '本政策说明 $_app 保存什么、保存在哪里，以及你有哪些选'
              '择。简而言之：你的财务数据属于你，它首先保存在你的设备上，我'
              '们绝不出售它、不向你展示广告，也不追踪你。部分可选功能（登录'
              '与同步、DGOTIX AI、云端收据扫描和付费方案）只有在你'
              '使用时，才会把限定的数据发送给某项服务，详见下文。',
        ),
        const LegalSection(
          '我们保存什么',
          '你自己输入的信息：收入、支出、预算、目标、借款、钱包、你自己'
              '的类别以及外观偏好（主题、语言、基础货币）。如果你创建账户，'
              '我们还会保存你的邮箱、你的方案及其状态，以及 DGOTIX '
              'AI 和云端收据扫描在每个周期的使用计数——仅用于执行你方案'
              '的额度。我们不保存你向 DGOTIX AI 提出的问题或你的'
              '收据照片；如果你举报某个 AI 回答，我们会保存该回答和你的'
              '可选备注以便审核。',
        ),
        const LegalSection(
          '你的数据存在哪里',
          '所有内容首先保存在你的设备上（应用内，或网页版在你的浏览器中），'
              '因此没有账户或网络时应用也能使用。登录后，你的数据会在你的设'
              '备之间自动同步：一份副本保存在我们的数据库中（托管于 '
              'Supabase），与你的账户关联，并且相互隔离，只有你能读'
              '取。你可以在设置中关闭同步；之后你的数据只保存在这台设备上。',
        ),
        const LegalSection(
          '你的账户和邮箱',
          '你的邮箱用于让你登录，并发送与账户相关的邮件，例如地址确认和'
              '密码重置（通过 Brevo）。它绝不会用于广告，也不会为营销'
              '而共享。注册和登录时，一个简短的真人验证（'
              'Cloudflare Turnstile）用于阻止自动化滥用。',
        ),
        const LegalSection(
          'DGOTIX AI',
          'DGOTIX AI 是可选的。当你提问时，问题的文字和你数字'
              '的摘要（最多 12 个月按月份和类别的合计、预算、钱包余额、'
              '目标、定期交易、节日预算和储蓄互助会——只有金额和日期，绝不'
              '包含描述、备注或你起的名字）会从我们的安全服务器发送给一家 '
              'AI 服务商（Google Gemini、OpenAI 或 '
              'Anthropic）来生成回答。我们的服务器使用我们自己的密'
              '钥，只记录使用元数据，绝不记录你的问题或你的数字。我们不会用'
              '你的数据训练模型。回答是自动生成的，因此在据此行动前请核对重'
              '要数字。',
        ),
        const LegalSection(
          '收据扫描',
          '在安卓上，收据可以完全在你的设备上读取。云端扫描会把收据照片'
              '从我们的安全服务器发送给一家 AI 服务商，仅用于读取商家、'
              '日期、金额、商品和类别；照片不会被保存。',
        ),
        const LegalSection(
          '付款与订阅',
          '付费方案是可选的。你通过我们的支付合作伙伴 Whop（'
              'whop.com）的安全结账页面付款，也可以选择 '
              'PayPal。他们按照各自的隐私政策收集必要的账单信息（如姓'
              '名、邮箱、国家和付款方式）；我们从不查看或保存你的完整卡号信'
              '息。为了提供正确的权限，我们保存你的方案、其状态、续订日期和'
              '支付合作伙伴的订阅标识，以及你使用过的优惠码记录。',
        ),
        const LegalSection(
          '服务提供商',
          '视你使用的功能而定：Supabase（账户、同步和我们的服务'
              '器函数）；Whop 和 PayPal（付款）；Brevo（账'
              '户邮件）；Cloudflare Turnstile（登录验证）；'
              'GitHub Pages（托管我们的网站和网页应用）；'
              'Google、OpenAI 和 Anthropic（'
              'DGOTIX AI 和云端收据扫描）；以及用于实时数字的公开'
              '市场数据源——汇率（open.er-api.com）和加密货'
              '币价格（CoinGecko）——这些请求只包含货币或资产代码，'
              '绝不包含你的个人或财务数据。每个提供商只为提供其负责的那部分'
              '服务而处理数据。',
        ),
        const LegalSection(
          '安全',
          '与我们服务的连接都经过加密（HTTPS）。在我们的数据库中，'
              '每个用户的数据相互隔离，任何账户都无法读取其他账户的数据。服'
              '务器密钥绝不会进入应用，付款通知在做任何更改前都会经过验证，'
              '你还可以在设备上设置应用锁（PIN 或指纹）。',
        ),
        const LegalSection(
          '我们不做什么',
          '我们不出售也不出租你的数据，不展示广告，也不对你的财务活动进'
              '行行为追踪或分析。',
        ),
        // Only while the totals are on (and trips are only in SmartTrip).
        if (AppEnv.anonStats && AppEnv.smartTrip)
          const LegalSection(
            '匿名计数',
            '当你创建一次旅行时，应用只发送“规划了一次旅行”，我们的服务'
                '器会在当天的总数上加一。除此之外不发送也不保存任何内容——没'
                '有账户、设备、地点或金额——因此总数无法与你关联。我们只用这'
                '些数字了解应用的使用量，并向合作伙伴展示总体数字。你可以在设'
                '置的“隐私”中关闭此功能。',
          ),
        const LegalSection(
          '我们保存数据多久',
          '你设备上的数据会一直保留，直到你删除它或卸载应用。你的账户、'
              '同步数据、使用计数和请求元数据会在你的账户存在期间保留——仅'
              '用于运行服务和执行你方案的额度——并在账户删除时永久清除。'
              'Whop 和 PayPal 会保留法律要求他们保留的账单记录。',
        ),
        LegalSection(
          '你的权利和选择',
          '你可以随时在应用中查看和更正你的数据、导出完整备份、关闭同步、'
              '退出登录，以及连同所有数据一起删除你的账户（见下文）。你可以'
              '随时取消付费方案（见条款）。关于你个人数据的任何其他请求——'
              '如访问、更正、删除或反对——请$_reachZh联系我们，我'
              '们会尽快回复。',
        ),
        const LegalSection(
          '删除你的账户和数据',
          '在应用或网页版中，在任意设备上打开“设置”，然后“账户”，再'
              '点“删除我的账户”。这会永久删除你的账户以及我们服务器上为其'
              '保存的所有内容（资料、同步数据、订阅记录和使用计数），并清除'
              '该设备上你的数据。请先取消付费方案。删除无法撤销，所以如果以'
              '后可能需要数据，请先导出备份。',
        ),
        LegalSection(
          '年龄',
          '$_app 面向 16 岁及以上的人士。我们不会有意收集儿童'
              '的数据；如果你认为有儿童创建了账户，请'
              '$_reachZh联系我们，我们会将其删除。',
        ),
        LegalSection(
          '变更与联系',
          '我们可能会更新本政策；上方的日期对应最新版本。如有隐私相关问'
              '题，请$_reachZh联系我们。',
        ),
      ];

  // ---- Terms (Chinese) ----
  static List<LegalSection> get _termsZh => <LegalSection>[
        LegalSection(
          '接受条款',
          '使用 $_app 即表示你同意这些条款。如果你不同意，请不要'
              '使用本应用。',
        ),
        LegalSection(
          '谁可以使用',
          '你必须年满 16 岁才能使用 $_app。如果你创建账户，请'
              '妥善保管你的登录信息；你需要对账户中发生的一切负责。',
        ),
        const LegalSection(
          '服务内容',
          '一款个人预算和规划工具，用于跟踪收入、支出、预算、目标及相关'
              '信息，并提供可选的 AI 帮助、收据扫描、多设备同步和付费方'
              '案。',
        ),
        const LegalSection(
          '规划工具，而非专业建议',
          '预算、预测、天课计算和 DGOTIX AI 的回答都是帮助你'
              '做决定的规划工具。它们不是专业的财务、税务或宗教建议。天课等'
              '宗教义务请向合格的学者确认；重大财务决定请咨询合格的顾问。',
        ),
        const LegalSection(
          'AI 功能',
          'DGOTIX AI 和云端收据扫描提供自动化结果来节省你的时'
              '间；在据此行动前请核对重要数字。这些功能受你方案的合理使用额'
              '度限制，并可能为了让服务对所有人保持快速可靠而调整。',
        ),
        const LegalSection(
          '方案、计费与续订',
          '基础应用是免费的。付费方案（Pro）按应用中显示的价格解锁更'
              '高额度和更多功能。付费方案会在每个计费周期（每月或每年）自动'
              '续订，直到你取消为止。付款由我们的支付合作伙伴 Whop（或'
              '你选择的 PayPal）处理；可能会加收适用的税费，并且在付'
              '款前总会在结账页面显示。你可以随时取消，并在已付款周期结束前'
              '继续使用。如果价格或功能发生变化，订阅前总会显示当前条款。',
        ),
        const LegalSection(
          '我们的支付合作伙伴：Whop',
          'SmartBudget 由 DGOTIX 销售。结账和计费由'
              ' Whop（whop.com）处理，它通过自己的安全结账页面'
              '处理付款，在付款前显示含税的完整价格，并向你发送收据。你可以'
              '在应用中管理或取消订阅（方案 → 管理）。',
        ),
        LegalSection(
          '退款政策',
          '除法律另有要求外，计费周期开始后付款通常不予退还，因为你在周'
              '期结束前仍可继续使用。你可以随时取消以停止之后的续订。如需申'
              '请退款或对某笔扣款有疑问，请$_reachZh联系我们：我们'
              '会依照适用的消费者法律处理每一项请求，并通过 Whop（或 '
              'PayPal）退还获批的金额。',
        ),
        const LegalSection(
          '优惠码',
          '优惠码是可选的，只改变结账价格（或提供试用）。每个优惠码都有'
              '自己的条件（有效期、使用次数上限、每位客户限用一次），并可能'
              '被撤回或过期。优惠码没有现金价值，除非另有说明，不能叠加使用。',
        ),
        const LegalSection(
          '你的数据和备份',
          '你需要对你输入的数据的准确性负责。为了在多台设备之间保护数据，'
              '请登录并同步，或定期在设置中导出备份。',
        ),
        LegalSection(
          '可用性',
          '我们努力让 $_app 保持可用和可靠。在法律允许的范围内，'
              '应用按“现状”提供，不附带任何形式的保证。实时市场数据、'
              'AI 和付款依赖第三方服务，有时可能延迟或不可用；这类中断绝'
              '不会妨碍你使用离线也能运行的基础预算工具。功能可能会随时间变'
              '化。',
        ),
        const LegalSection(
          '责任限制',
          '在法律允许的范围内，我们不对间接或后果性损失负责，也不对你根'
              '据应用中的数字所做的决定负责。这些条款中的任何内容都不会限制'
              '你作为消费者不可放弃的权利。',
        ),
        const LegalSection(
          '可接受的使用',
          '不得滥用服务，不得试图破坏或绕过安全措施或方案额度，也不得将'
              '其用于非法活动。',
        ),
        LegalSection(
          '停止使用',
          '你可以随时停止使用 $_app 并删除你的账户。对于违反这些'
              '条款或危及服务或其他用户的账户，我们可能会暂停其使用。',
        ),
        LegalSection(
          '品牌与所有权',
          '$_app 名称、$_brand 品牌以及应用的设计和代码归'
              '其所有者所有。你的数据仍然属于你。',
        ),
        LegalSection(
          '变更与联系',
          '我们可能会更新这些条款，并显示最新版本的日期；更新后继续使用'
              '应用即表示你同意修订后的条款。如有问题，请'
              '$_reachZh联系我们。',
        ),
      ];
}
