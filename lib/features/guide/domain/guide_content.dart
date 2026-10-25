/// User guide — how to use each part of SmartBudget.
///
/// Long-form prose lives here (like the legal pages) rather than in the ARB
/// files. Every topic points at a real route so the guide doubles as a map of
/// the platform. Describe only what the app actually does — no invented
/// buttons or promises.
library;

import 'package:smartbudget/core/l10n/app_lang.dart';

class GuideTopic {
  const GuideTopic({
    required this.route,
    required this.title,
    required this.summary,
    required this.steps,
  });

  /// The in-app route this topic opens.
  final String route;
  final String title;
  final String summary;
  final List<String> steps;
}

abstract final class GuideContent {
  static List<String> gettingStarted({required AppLang lang}) =>
      lang.pick(_startAr, _startEn,
          fr: _startFr, id: _startId, es: _startEs,
          tr: _startTr, ms: _startMs, ur: _startUr, de: _startDe,
          pt: _startPt, it: _startIt, nl: _startNl, bs: _startBs,
          sq: _startSq, ru: _startRu, sw: _startSw, ha: _startHa,
          af: _startAf, fa: _startFa, hi: _startHi, zh: _startZh, ja: _startJa);

  static List<GuideTopic> topics({required AppLang lang}) =>
      lang.pick(_topicsAr, _topicsEn,
          fr: _topicsFr, id: _topicsId, es: _topicsEs,
          tr: _topicsTr, ms: _topicsMs, ur: _topicsUr, de: _topicsDe,
          pt: _topicsPt, it: _topicsIt, nl: _topicsNl, bs: _topicsBs,
          sq: _topicsSq, ru: _topicsRu, sw: _topicsSw, ha: _topicsHa,
          af: _topicsAf, fa: _topicsFa, hi: _topicsHi, zh: _topicsZh, ja: _topicsJa);

  // ---- Getting started ----
  static const List<String> _startEn = <String>[
    'Open Settings and choose your language, theme and base currency — every '
        'total in the app is shown in that currency.',
    'Add your income and expenses (or scan a receipt) — everything else is '
        'calculated from them.',
    'Set a monthly budget so the app can tell you how much is left to spend.',
    'Check the Dashboard and Financial Health to see where you stand, then add '
        'goals and debts as you go.',
  ];

  static const List<String> _startAr = <String>[
    'افتح الإعدادات واختر اللغة والسمة والعملة الأساسية — كل المجاميع في '
        'التطبيق تُعرض بهذه العملة.',
    'أضف مداخيلك ومصاريفك (أو امسح إيصالاً) — كل شيء آخر يُحسب منها.',
    'حدّد ميزانية شهرية ليخبرك التطبيق بالمبلغ المتبقّي للصرف.',
    'راجع لوحة التحكم والصحة المالية لتعرف وضعك، ثم أضف الأهداف والديون '
        'تدريجياً.',
  ];

  // ---- Topics (English) ----
  static const List<GuideTopic> _topicsEn = <GuideTopic>[
    GuideTopic(
      route: '/dashboard',
      title: 'Dashboard',
      summary:
          'Your month at a glance: income, spending, savings and where the '
          'money went.',
      steps: <String>[
        'Tiles show this month\'s totals in your base currency.',
        'Tap a slice in the spending breakdown to highlight that category.',
        'Alerts point you to anything that needs attention, like an '
            'over-budget category or an urgent goal.',
        'With no data yet, tiles show "—" — nothing is ever made up.',
      ],
    ),
    GuideTopic(
      route: '/transactions',
      title: 'Income & expenses',
      summary: 'Record every movement of money — the base for every '
          'calculation in the app.',
      steps: <String>[
        'Use the quick-add button to record income or an expense with an '
            'amount, category, date and note.',
        'Income and Expenses each have their own screen; Transactions shows '
            'both together.',
        'Search the list to find any entry, and tap one to edit or delete it.',
      ],
    ),
    GuideTopic(
      route: '/recurring',
      title: 'Recurring transactions',
      summary: 'Salary, rent and subscriptions added automatically on their '
          'date.',
      steps: <String>[
        'When adding income or an expense, set "Repeat" to every week, '
            'month, 3 months, 6 months or year.',
        'For a bonus or a commission whose amount changes, turn on "The '
            'amount changes each time": on each date the app asks for the real '
            'amount instead of adding a guess.',
        'Each time it falls due, the app adds it as a normal transaction — '
            'even if you were away, it catches up when you next open the app.',
        'On the Recurring screen, pause, resume, change the amount or stop '
            'repeating. Transactions already added are never changed.',
      ],
    ),
    GuideTopic(
      route: '/expenses',
      title: 'Scan a receipt',
      summary: 'Turn a photo of a receipt into a ready-to-save expense.',
      steps: <String>[
        'On the Expenses screen, tap "Scan receipt" and take or choose a photo.',
        'The app fills in the merchant, date, amount and category — review '
            'them before saving.',
        'Cloud scanning depends on your plan; if a scan can\'t be read, enter '
            'the expense manually.',
      ],
    ),
    GuideTopic(
      route: '/budget',
      title: 'Monthly budget',
      summary: 'Plan how much you want to spend per category, month by month.',
      steps: <String>[
        'Pick the year and month at the top — one screen covers every month.',
        'Set a limit for each category you want to control.',
        'Progress bars fill as you spend; a category over its limit is '
            'flagged.',
        'On a paid plan, "Suggest a split" divides your income across '
            'categories from your own recent spending — review it, then apply.',
      ],
    ),
    GuideTopic(
      route: '/goals',
      title: 'Goals & savings',
      summary: 'Save toward something specific and see how close you are.',
      steps: <String>[
        'Create a goal with a target amount and, optionally, a deadline.',
        'Record contributions as you save; progress updates automatically.',
        'Goals near their deadline are highlighted on the Dashboard.',
      ],
    ),
    GuideTopic(
      route: '/debts',
      title: 'Debts & loans',
      summary: 'Keep track of what you owe and what others owe you.',
      steps: <String>[
        'Add each debt or loan with its amount and the person or party.',
        'Update the amount paid so far to see the remaining balance.',
        'Debts feed into your Financial Health score.',
      ],
    ),
    GuideTopic(
      route: '/portfolio',
      title: 'Projects portfolio',
      summary: 'Plan bigger projects in near, mid and long-term compartments.',
      steps: <String>[
        'Add projects and place each one in a time horizon.',
        'The funding engine fills compartments in order, so you see which '
            'projects your savings can cover first.',
      ],
    ),
    GuideTopic(
      route: '/health',
      title: 'Financial health',
      summary: 'A score that sums up how healthy your finances are, and why.',
      steps: <String>[
        'The score is computed on your device from your own data.',
        'Key factors show what is helping or hurting it — improve those first.',
      ],
    ),
    GuideTopic(
      route: '/reports',
      title: 'Reports & analytics',
      summary: 'See trends over the year and where your money goes.',
      steps: <String>[
        'Choose a year to compare income and expenses month by month.',
        'Use the breakdowns to spot categories that grow over time.',
      ],
    ),
    GuideTopic(
      route: '/zakat',
      title: 'Zakat',
      summary: 'Estimate the Zakat due on your wealth and track the Hawl.',
      steps: <String>[
        'Enter the assets that are subject to Zakat to get an estimate.',
        'Set the date your wealth reached the nisab to follow the lunar-year '
            'countdown, shown in Hijri.',
        'This is a planning aid — confirm your obligation with a qualified '
            'scholar.',
      ],
    ),
    GuideTopic(
      route: '/markets',
      title: 'Exchange rates & markets',
      summary: 'Live currency rates and crypto prices from public sources.',
      steps: <String>[
        'Rates are fetched live; each row shows how it was sourced.',
        'When a market has no reliable source it reads "unavailable" — never '
            'an invented number.',
      ],
    ),
    GuideTopic(
      route: '/assistant',
      title: 'DGOTIX AI assistant',
      summary: 'Ask questions about your finances in plain language.',
      steps: <String>[
        'Type a question or tap a suggestion; the assistant answers using a '
            'short summary of your figures.',
        'The number of answers depends on your plan; you\'ll see a note when '
            'you are close to the limit.',
        'Answers are generated automatically — double-check important '
            'decisions. Rule-based insights below the chat always work, even '
            'without AI.',
      ],
    ),
    GuideTopic(
      route: '/plans',
      title: 'Plans & subscription',
      summary: 'Compare Free and Pro, and manage your subscription.',
      steps: <String>[
        'The core budgeting tools are free forever.',
        'Paid plans raise the AI and cloud-scan limits and add extra features.',
        'If you subscribe, your current plan and renewal date appear at the '
            'top, with a button to manage or cancel.',
      ],
    ),
    GuideTopic(
      route: '/settings',
      title: 'Settings, data & backup',
      summary: 'Make the app yours and keep your data safe.',
      steps: <String>[
        'Language, theme and base currency are under Appearance and Region.',
        'Manage your own income and expense categories.',
        'Under Data & backup, export a full backup at any time; when signed '
            'in, your data syncs between your devices automatically (also '
            'after working offline), and you can turn that off.',
      ],
    ),
  ];

  // ---- Topics (Arabic) ----
  static const List<GuideTopic> _topicsAr = <GuideTopic>[
    GuideTopic(
      route: '/dashboard',
      title: 'لوحة التحكم',
      summary: 'شهرك في لمحة: المداخيل والمصاريف والادّخار وأين ذهب المال.',
      steps: <String>[
        'تعرض البطاقات مجاميع هذا الشهر بعملتك الأساسية.',
        'اضغط على جزء من توزيع المصاريف لإبراز تلك الفئة.',
        'تنبّهك التنبيهات إلى ما يحتاج انتباهاً، مثل فئة تجاوزت ميزانيتها أو '
            'هدف عاجل.',
        'قبل إدخال أي بيانات تعرض البطاقات "—" — لا شيء يُختلق أبداً.',
      ],
    ),
    GuideTopic(
      route: '/transactions',
      title: 'المداخيل والمصاريف',
      summary: 'سجّل كل حركة مالية — فهي أساس كل الحسابات في التطبيق.',
      steps: <String>[
        'استخدم زر الإضافة السريعة لتسجيل دخل أو مصروف بالمبلغ والفئة '
            'والتاريخ والملاحظة.',
        'للمداخيل وللمصاريف شاشة لكلٍّ منهما؛ وتعرض شاشة المعاملات الاثنين '
            'معاً.',
        'ابحث في القائمة لإيجاد أي عملية، واضغط عليها لتعديلها أو حذفها.',
      ],
    ),
    GuideTopic(
      route: '/recurring',
      title: 'المعاملات المتكرّرة',
      summary: 'الراتب والإيجار والاشتراكات تُضاف تلقائياً في موعدها.',
      steps: <String>[
        'عند إضافة دخل أو مصروف، اختر «التكرار»: كل أسبوع أو كل شهر أو كل 3 '
            'أشهر أو كل 6 أشهر أو كل سنة.',
        'للمردودية أو العمولات التي يتغيّر مبلغها، فعّل «المبلغ يتغيّر في كل '
            'مرة»: في كل موعد يطلب منك التطبيق المبلغ الحقيقي بدل أن يضيف '
            'مبلغاً تقديرياً.',
        'في كل موعد يضيفها التطبيق كمعاملة عادية — وإن غبت، يستدركها عند فتحك '
            'التطبيق في المرة القادمة.',
        'من صفحة المعاملات المتكرّرة يمكنك الإيقاف المؤقت أو الاستئناف أو '
            'تعديل المبلغ أو إيقاف التكرار. المعاملات المضافة سابقاً لا تتغيّر.',
      ],
    ),
    GuideTopic(
      route: '/expenses',
      title: 'مسح إيصال',
      summary: 'حوّل صورة إيصال إلى مصروف جاهز للحفظ.',
      steps: <String>[
        'في شاشة المصاريف اضغط "مسح إيصال" والتقط صورة أو اخترها.',
        'يملأ التطبيق اسم التاجر والتاريخ والمبلغ والفئة — راجعها قبل الحفظ.',
        'يعتمد المسح السحابي على باقتك؛ وإن تعذّرت قراءة الإيصال أدخل المصروف '
            'يدوياً.',
      ],
    ),
    GuideTopic(
      route: '/budget',
      title: 'الميزانية الشهرية',
      summary: 'خطّط لما تريد صرفه في كل فئة، شهراً بشهر.',
      steps: <String>[
        'اختر السنة والشهر في الأعلى — شاشة واحدة لكل الأشهر.',
        'حدّد سقفاً لكل فئة تريد ضبطها.',
        'تمتلئ أشرطة التقدّم مع الصرف، وتُميَّز الفئة التي تتجاوز سقفها.',
        'في الباقات المدفوعة، يقسّم زر "اقترح تقسيمًا" دخلك على الفئات بناءً '
            'على مصاريفك الأخيرة — راجعه ثم طبّقه.',
      ],
    ),
    GuideTopic(
      route: '/goals',
      title: 'الأهداف والادّخار',
      summary: 'ادّخر لهدف محدّد واعرف مدى اقترابك منه.',
      steps: <String>[
        'أنشئ هدفاً بمبلغ مستهدف وموعد نهائي اختياري.',
        'سجّل مساهماتك كلما ادّخرت، ويتحدّث التقدّم تلقائياً.',
        'تُبرز الأهداف القريبة من موعدها في لوحة التحكم.',
      ],
    ),
    GuideTopic(
      route: '/debts',
      title: 'الديون والقروض',
      summary: 'تابع ما عليك وما لك عند الآخرين.',
      steps: <String>[
        'أضف كل دين أو قرض بمبلغه والشخص أو الجهة المعنيّة.',
        'حدّث المبلغ المدفوع حتى الآن لترى الرصيد المتبقّي.',
        'تدخل الديون في حساب مؤشّر صحتك المالية.',
      ],
    ),
    GuideTopic(
      route: '/portfolio',
      title: 'محفظة المشاريع',
      summary: 'خطّط لمشاريعك الكبيرة في أقسام قريبة ومتوسطة وبعيدة المدى.',
      steps: <String>[
        'أضف مشاريعك وضع كلاً منها في أفقه الزمني.',
        'يموّل المحرّك الأقسام بالترتيب، فترى أيّ المشاريع تكفيها مدّخراتك '
            'أولاً.',
      ],
    ),
    GuideTopic(
      route: '/health',
      title: 'الصحة المالية',
      summary: 'مؤشّر يلخّص مدى سلامة وضعك المالي، ولماذا.',
      steps: <String>[
        'يُحسب المؤشّر على جهازك من بياناتك أنت.',
        'تُظهر العوامل الرئيسية ما يرفعه أو يخفضه — ابدأ بتحسينها.',
      ],
    ),
    GuideTopic(
      route: '/reports',
      title: 'التقارير والتحليلات',
      summary: 'شاهد اتجاهات السنة وأين يذهب مالك.',
      steps: <String>[
        'اختر سنة لمقارنة المداخيل والمصاريف شهراً بشهر.',
        'استخدم التوزيعات لاكتشاف الفئات التي تنمو مع الوقت.',
      ],
    ),
    GuideTopic(
      route: '/zakat',
      title: 'الزكاة',
      summary: 'قدّر الزكاة المستحقّة على مالك وتابع الحول.',
      steps: <String>[
        'أدخل الأموال الخاضعة للزكاة لتحصل على تقدير.',
        'حدّد تاريخ بلوغ مالك النصاب لمتابعة العدّ التنازلي للسنة القمرية '
            'بالتاريخ الهجري.',
        'هذه أداة للتخطيط — تحقّق من الواجب عليك مع عالم مؤهّل.',
      ],
    ),
    GuideTopic(
      route: '/markets',
      title: 'أسعار الصرف والأسواق',
      summary: 'أسعار عملات وعملات رقمية حيّة من مصادر عامة.',
      steps: <String>[
        'تُجلب الأسعار مباشرة، ويبيّن كل سطر مصدره.',
        'حين لا يوجد مصدر موثوق لسوقٍ ما يظهر "غير متاح" — ولا رقم مختلق أبداً.',
      ],
    ),
    GuideTopic(
      route: '/assistant',
      title: 'مساعد DGOTIX AI',
      summary: 'اسأل عن أموالك بلغة بسيطة.',
      steps: <String>[
        'اكتب سؤالك أو اضغط اقتراحاً؛ يجيب المساعد اعتماداً على ملخّص موجز '
            'لأرقامك.',
        'عدد الإجابات يعتمد على باقتك، وستظهر لك ملاحظة عند اقترابك من الحد.',
        'الإجابات مولّدة آلياً — راجع القرارات المهمة. والرؤى المبنيّة على '
            'القواعد أسفل المحادثة تعمل دائماً حتى دون ذكاء اصطناعي.',
      ],
    ),
    GuideTopic(
      route: '/plans',
      title: 'الباقات والاشتراك',
      summary: 'قارن بين المجانية والاحترافية، وأدِر اشتراكك.',
      steps: <String>[
        'أدوات الميزانية الأساسية مجانية دائماً.',
        'ترفع الباقات المدفوعة حدود الذكاء الاصطناعي والمسح السحابي وتضيف '
            'ميزات أخرى.',
        'إن اشتركت تظهر باقتك وتاريخ تجديدها في الأعلى، مع زر لإدارتها أو '
            'إلغائها.',
      ],
    ),
    GuideTopic(
      route: '/settings',
      title: 'الإعدادات والبيانات والنسخ الاحتياطي',
      summary: 'اجعل التطبيق على مقاسك واحفظ بياناتك بأمان.',
      steps: <String>[
        'اللغة والسمة والعملة الأساسية تجدها في المظهر والمنطقة.',
        'أدِر فئات المداخيل والمصاريف الخاصة بك.',
        'في البيانات والنسخ الاحتياطي صدّر نسخة كاملة في أي وقت؛ وعند تسجيل '
            'الدخول تُزامَن بياناتك بين أجهزتك تلقائياً (حتى بعد العمل دون '
            'إنترنت)، ويمكنك إيقاف ذلك.',
      ],
    ),
  ];

  // ---- Getting started (French) ----
  static const List<String> _startFr = <String>[
    'Ouvrez Paramètres et choisissez votre langue, votre thème et votre '
        'devise de base : tous les totaux de l\'application sont affichés dans '
        'cette devise.',
    'Ajoutez vos revenus et vos dépenses (ou scannez un ticket) : tout le '
        'reste est calculé à partir d\'eux.',
    'Fixez un budget mensuel pour que l\'application vous indique combien il '
        'vous reste à dépenser.',
    'Consultez le Tableau de bord et la Santé financière pour voir où vous en '
        'êtes, puis ajoutez des objectifs et des dettes au fil du temps.',
  ];

  // ---- Topics (French) ----
  static const List<GuideTopic> _topicsFr = <GuideTopic>[
    GuideTopic(
      route: '/dashboard',
      title: 'Tableau de bord',
      summary: 'Votre mois en un coup d\'œil : revenus, dépenses, épargne et '
          'où est passé l\'argent.',
      steps: <String>[
        'Les tuiles affichent les totaux du mois dans votre devise de base.',
        'Touchez une part du détail des dépenses pour mettre cette catégorie '
            'en évidence.',
        'Les alertes vous signalent ce qui demande votre attention, comme une '
            'catégorie hors budget ou un objectif urgent.',
        'Sans données, les tuiles affichent « — » : rien n\'est jamais '
            'inventé.',
      ],
    ),
    GuideTopic(
      route: '/transactions',
      title: 'Revenus et dépenses',
      summary: 'Enregistrez chaque mouvement d\'argent : c\'est la base de '
          'tous les calculs de l\'application.',
      steps: <String>[
        'Utilisez le bouton d\'ajout rapide pour enregistrer un revenu ou une '
            'dépense avec un montant, une catégorie, une date et une note.',
        'Revenus et Dépenses ont chacun leur écran ; Transactions affiche les '
            'deux ensemble.',
        'Recherchez dans la liste pour retrouver une saisie, et touchez-la pour '
            'la modifier ou la supprimer.',
      ],
    ),
    GuideTopic(
      route: '/recurring',
      title: 'Transactions récurrentes',
      summary: 'Salaire, loyer et abonnements ajoutés automatiquement à leur '
          'date.',
      steps: <String>[
        'En ajoutant un revenu ou une dépense, réglez « Répétition » sur '
            'chaque semaine, chaque mois, tous les 3 mois, tous les 6 mois ou '
            'chaque année.',
        'Pour une prime ou une commission dont le montant change, activez « Le '
            'montant change à chaque fois » : à chaque date, l\'application vous '
            'demande le montant réel au lieu d\'ajouter une estimation.',
        'À chaque échéance, l\'application l\'ajoute comme une transaction '
            'normale : même si vous étiez absent, elle rattrape le retard à la '
            'prochaine ouverture.',
        'Sur l\'écran Récurrents, mettez en pause, reprenez, changez le montant '
            'ou arrêtez la répétition. Les transactions déjà ajoutées ne sont '
            'jamais modifiées.',
      ],
    ),
    GuideTopic(
      route: '/expenses',
      title: 'Scanner un ticket',
      summary: 'Transformez la photo d\'un ticket en dépense prête à '
          'enregistrer.',
      steps: <String>[
        'Sur l\'écran Dépenses, touchez « Scanner un ticket » et prenez ou '
            'choisissez une photo.',
        'L\'application remplit le commerçant, la date, le montant et la '
            'catégorie : vérifiez-les avant d\'enregistrer.',
        'Le scan dans le cloud dépend de votre formule ; si un ticket ne peut '
            'pas être lu, saisissez la dépense à la main.',
      ],
    ),
    GuideTopic(
      route: '/budget',
      title: 'Budget mensuel',
      summary: 'Prévoyez combien vous voulez dépenser par catégorie, mois par '
          'mois.',
      steps: <String>[
        'Choisissez l\'année et le mois en haut : un seul écran couvre tous les '
            'mois.',
        'Fixez une limite pour chaque catégorie que vous voulez maîtriser.',
        'Les barres de progression se remplissent au fil des dépenses ; une '
            'catégorie qui dépasse sa limite est signalée.',
        'Avec une formule payante, « Proposer une répartition » répartit vos '
            'revenus entre les catégories d\'après vos propres dépenses '
            'récentes : vérifiez, puis appliquez.',
      ],
    ),
    GuideTopic(
      route: '/goals',
      title: 'Objectifs et épargne',
      summary: 'Épargnez pour un projet précis et voyez où vous en êtes.',
      steps: <String>[
        'Créez un objectif avec un montant cible et, si vous le souhaitez, une '
            'échéance.',
        'Enregistrez vos contributions au fur et à mesure ; la progression se '
            'met à jour automatiquement.',
        'Les objectifs proches de leur échéance sont mis en avant sur le '
            'Tableau de bord.',
      ],
    ),
    GuideTopic(
      route: '/debts',
      title: 'Dettes et prêts',
      summary: 'Suivez ce que vous devez et ce que l\'on vous doit.',
      steps: <String>[
        'Ajoutez chaque dette ou prêt avec son montant et la personne ou '
            'l\'organisme concerné.',
        'Mettez à jour le montant déjà payé pour voir le solde restant.',
        'Les dettes entrent dans le calcul de votre score de santé financière.',
      ],
    ),
    GuideTopic(
      route: '/portfolio',
      title: 'Portefeuille de projets',
      summary: 'Planifiez vos grands projets à court, moyen et long terme.',
      steps: <String>[
        'Ajoutez vos projets et placez chacun sur un horizon de temps.',
        'Le moteur de financement remplit les horizons dans l\'ordre : vous '
            'voyez quels projets votre épargne peut couvrir en premier.',
      ],
    ),
    GuideTopic(
      route: '/health',
      title: 'Santé financière',
      summary: 'Un score qui résume l\'état de vos finances, et pourquoi.',
      steps: <String>[
        'Le score est calculé sur votre appareil à partir de vos propres '
            'données.',
        'Les facteurs clés montrent ce qui l\'améliore ou le dégrade : '
            'commencez par ceux-là.',
      ],
    ),
    GuideTopic(
      route: '/reports',
      title: 'Rapports et analyses',
      summary: 'Voyez les tendances de l\'année et où va votre argent.',
      steps: <String>[
        'Choisissez une année pour comparer revenus et dépenses mois par mois.',
        'Utilisez les détails pour repérer les catégories qui augmentent avec '
            'le temps.',
      ],
    ),
    GuideTopic(
      route: '/zakat',
      title: 'Zakat',
      summary: 'Estimez la zakat due sur votre patrimoine et suivez le hawl.',
      steps: <String>[
        'Saisissez les biens soumis à la zakat pour obtenir une estimation.',
        'Indiquez la date à laquelle votre patrimoine a atteint le nisab pour '
            'suivre le compte à rebours de l\'année lunaire, affiché en '
            'calendrier hégirien.',
        'C\'est une aide à la planification : confirmez votre obligation auprès '
            'd\'un savant qualifié.',
      ],
    ),
    GuideTopic(
      route: '/markets',
      title: 'Taux de change et marchés',
      summary: 'Taux de change et cours des cryptomonnaies en direct, depuis '
          'des sources publiques.',
      steps: <String>[
        'Les taux sont récupérés en direct ; chaque ligne indique sa source.',
        'Quand un marché n\'a pas de source fiable, il est marqué « '
            'indisponible » : jamais un chiffre inventé.',
      ],
    ),
    GuideTopic(
      route: '/assistant',
      title: 'Assistant DGOTIX AI',
      summary: 'Posez vos questions sur vos finances en langage courant.',
      steps: <String>[
        'Tapez une question ou touchez une suggestion ; l\'assistant répond à '
            'partir d\'un court résumé de vos chiffres.',
        'Le nombre de réponses dépend de votre formule ; une note s\'affiche '
            'quand vous approchez de la limite.',
        'Les réponses sont générées automatiquement : vérifiez les décisions '
            'importantes. Les analyses à base de règles sous la discussion '
            'fonctionnent toujours, même sans IA.',
      ],
    ),
    GuideTopic(
      route: '/plans',
      title: 'Formules et abonnement',
      summary: 'Comparez Gratuit et Pro, et gérez votre abonnement.',
      steps: <String>[
        'Les outils de budget essentiels sont gratuits pour toujours.',
        'Les formules payantes relèvent les limites de l\'IA et du scan dans le '
            'cloud et ajoutent des fonctionnalités.',
        'Si vous vous abonnez, votre formule actuelle et sa date de '
            'renouvellement apparaissent en haut, avec un bouton pour la gérer '
            'ou la résilier.',
      ],
    ),
    GuideTopic(
      route: '/settings',
      title: 'Paramètres, données et sauvegarde',
      summary: 'Personnalisez l\'application et protégez vos données.',
      steps: <String>[
        'Langue, thème et devise de base se trouvent dans Apparence et Région.',
        'Gérez vos propres catégories de revenus et de dépenses.',
        'Dans Données et sauvegarde, exportez une sauvegarde complète à tout '
            'moment ; une fois connecté, vos données se synchronisent '
            'automatiquement entre vos appareils (y compris après un travail '
            'hors ligne), et vous pouvez désactiver cette option.',
      ],
    ),
  ];

  // ---- Getting started (Indonesian) ----
  static const List<String> _startId = <String>[
    'Buka Pengaturan dan pilih bahasa, tema, dan mata uang dasar — semua '
        'total di aplikasi ditampilkan dalam mata uang itu.',
    'Tambahkan pemasukan dan pengeluaran Anda (atau pindai struk) — semua '
        'hal lain dihitung dari situ.',
    'Atur anggaran bulanan agar aplikasi bisa memberi tahu berapa yang masih '
        'bisa dibelanjakan.',
    'Cek Dasbor dan Kesehatan Keuangan untuk melihat posisi Anda, lalu '
        'tambahkan target dan utang seiring waktu.',
  ];

  // ---- Topics (Indonesian) ----
  static const List<GuideTopic> _topicsId = <GuideTopic>[
    GuideTopic(
      route: '/dashboard',
      title: 'Dasbor',
      summary: 'Bulan Anda dalam sekali lihat: pemasukan, pengeluaran, '
          'tabungan, dan ke mana uangnya pergi.',
      steps: <String>[
        'Kotak-kotak menampilkan total bulan ini dalam mata uang dasar Anda.',
        'Ketuk bagian di rincian pengeluaran untuk menyorot kategori itu.',
        'Peringatan menunjukkan apa pun yang perlu perhatian, seperti kategori '
            'yang melebihi anggaran atau target yang mendesak.',
        'Jika belum ada data, kotak menampilkan "—" — tidak ada yang dikarang.',
      ],
    ),
    GuideTopic(
      route: '/transactions',
      title: 'Pemasukan & pengeluaran',
      summary: 'Catat setiap pergerakan uang — dasar semua perhitungan di '
          'aplikasi.',
      steps: <String>[
        'Gunakan tombol tambah cepat untuk mencatat pemasukan atau pengeluaran '
            'dengan jumlah, kategori, tanggal, dan catatan.',
        'Pemasukan dan Pengeluaran punya layar masing-masing; Transaksi '
            'menampilkan keduanya.',
        'Cari di daftar untuk menemukan catatan apa pun, dan ketuk untuk '
            'mengubah atau menghapusnya.',
      ],
    ),
    GuideTopic(
      route: '/recurring',
      title: 'Transaksi berulang',
      summary: 'Gaji, sewa, dan langganan ditambahkan otomatis pada '
          'tanggalnya.',
      steps: <String>[
        'Saat menambah pemasukan atau pengeluaran, atur "Ulangi" ke setiap '
            'minggu, bulan, 3 bulan, 6 bulan, atau tahun.',
        'Untuk bonus atau komisi yang jumlahnya berubah, aktifkan "Jumlahnya '
            'berubah-ubah": setiap jatuh tempo aplikasi menanyakan jumlah '
            'sebenarnya, bukan menebak.',
        'Setiap jatuh tempo, aplikasi menambahkannya sebagai transaksi biasa — '
            'meski Anda sedang tidak membuka aplikasi, semuanya disusulkan saat '
            'Anda membukanya lagi.',
        'Di layar Berulang, jeda, lanjutkan, ubah jumlah, atau hentikan '
            'pengulangan. Transaksi yang sudah ditambahkan tidak pernah diubah.',
      ],
    ),
    GuideTopic(
      route: '/expenses',
      title: 'Pindai struk',
      summary: 'Ubah foto struk menjadi pengeluaran yang siap disimpan.',
      steps: <String>[
        'Di layar Pengeluaran, ketuk "Pindai struk" lalu ambil atau pilih foto.',
        'Aplikasi mengisi nama toko, tanggal, jumlah, dan kategori — periksa '
            'sebelum menyimpan.',
        'Pemindaian cloud tergantung paket Anda; jika struk tidak terbaca, '
            'catat pengeluarannya secara manual.',
      ],
    ),
    GuideTopic(
      route: '/budget',
      title: 'Anggaran bulanan',
      summary: 'Rencanakan berapa yang ingin Anda belanjakan per kategori, '
          'bulan demi bulan.',
      steps: <String>[
        'Pilih tahun dan bulan di bagian atas — satu layar untuk semua bulan.',
        'Tetapkan batas untuk setiap kategori yang ingin Anda kendalikan.',
        'Bilah kemajuan terisi seiring pengeluaran; kategori yang melewati '
            'batas akan ditandai.',
        'Di paket berbayar, "Sarankan pembagian" membagi pemasukan Anda ke '
            'kategori berdasarkan pengeluaran Anda belakangan ini — periksa, '
            'lalu terapkan.',
      ],
    ),
    GuideTopic(
      route: '/goals',
      title: 'Target & tabungan',
      summary: 'Menabung untuk sesuatu yang spesifik dan lihat seberapa dekat '
          'Anda.',
      steps: <String>[
        'Buat target dengan jumlah tujuan dan, bila perlu, tenggat.',
        'Catat setoran setiap kali menabung; kemajuan diperbarui otomatis.',
        'Target yang mendekati tenggat disorot di Dasbor.',
      ],
    ),
    GuideTopic(
      route: '/debts',
      title: 'Utang & pinjaman',
      summary: 'Pantau apa yang Anda utangkan dan apa yang orang lain utangkan '
          'kepada Anda.',
      steps: <String>[
        'Tambahkan setiap utang atau pinjaman dengan jumlah dan orang atau '
            'pihaknya.',
        'Perbarui jumlah yang sudah dibayar untuk melihat sisa saldo.',
        'Utang ikut dihitung dalam skor Kesehatan Keuangan Anda.',
      ],
    ),
    GuideTopic(
      route: '/portfolio',
      title: 'Portofolio proyek',
      summary: 'Rencanakan proyek besar dalam kelompok jangka pendek, menengah, '
          'dan panjang.',
      steps: <String>[
        'Tambahkan proyek dan tempatkan masing-masing dalam jangka waktunya.',
        'Mesin pendanaan mengisi kelompok secara berurutan, sehingga Anda '
            'melihat proyek mana yang bisa ditutup tabungan lebih dulu.',
      ],
    ),
    GuideTopic(
      route: '/health',
      title: 'Kesehatan keuangan',
      summary: 'Skor yang merangkum seberapa sehat keuangan Anda, dan '
          'alasannya.',
      steps: <String>[
        'Skor dihitung di perangkat Anda dari data Anda sendiri.',
        'Faktor utama menunjukkan apa yang membantu atau merugikan — perbaiki '
            'itu lebih dulu.',
      ],
    ),
    GuideTopic(
      route: '/reports',
      title: 'Laporan & analisis',
      summary: 'Lihat tren sepanjang tahun dan ke mana uang Anda pergi.',
      steps: <String>[
        'Pilih tahun untuk membandingkan pemasukan dan pengeluaran per bulan.',
        'Gunakan rincian untuk menemukan kategori yang terus naik.',
      ],
    ),
    GuideTopic(
      route: '/zakat',
      title: 'Zakat',
      summary: 'Perkirakan zakat atas harta Anda dan pantau haulnya.',
      steps: <String>[
        'Masukkan harta yang wajib dizakati untuk mendapat perkiraan.',
        'Tetapkan tanggal harta Anda mencapai nisab untuk memantau hitung '
            'mundur tahun hijriah, ditampilkan dalam kalender Hijriah.',
        'Ini alat bantu perencanaan — pastikan kewajiban Anda kepada ulama '
            'yang berkompeten.',
      ],
    ),
    GuideTopic(
      route: '/markets',
      title: 'Kurs & pasar',
      summary: 'Kurs mata uang dan harga kripto langsung dari sumber publik.',
      steps: <String>[
        'Kurs diambil langsung; setiap baris menunjukkan sumbernya.',
        'Jika suatu pasar tidak punya sumber tepercaya, tertulis "tidak '
            'tersedia" — tidak pernah angka karangan.',
      ],
    ),
    GuideTopic(
      route: '/assistant',
      title: 'Asisten DGOTIX AI',
      summary: 'Tanyakan tentang keuangan Anda dengan bahasa sehari-hari.',
      steps: <String>[
        'Ketik pertanyaan atau ketuk saran; asisten menjawab memakai ringkasan '
            'singkat angka-angka Anda.',
        'Jumlah jawaban tergantung paket Anda; ada pemberitahuan saat Anda '
            'mendekati batas.',
        'Jawaban dibuat otomatis — periksa kembali keputusan penting. Wawasan '
            'berbasis aturan di bawah obrolan selalu jalan, bahkan tanpa AI.',
      ],
    ),
    GuideTopic(
      route: '/plans',
      title: 'Paket & langganan',
      summary: 'Bandingkan Gratis dan Pro, lalu kelola langganan Anda.',
      steps: <String>[
        'Fitur anggaran inti gratis selamanya.',
        'Paket berbayar menaikkan batas AI dan pemindaian cloud serta menambah '
            'fitur.',
        'Jika berlangganan, paket dan tanggal perpanjangan tampil di atas, '
            'dengan tombol untuk mengelola atau membatalkan.',
      ],
    ),
    GuideTopic(
      route: '/settings',
      title: 'Pengaturan, data & cadangan',
      summary: 'Sesuaikan aplikasi dan jaga data Anda tetap aman.',
      steps: <String>[
        'Bahasa, tema, dan mata uang dasar ada di Tampilan dan Wilayah.',
        'Kelola kategori pemasukan dan pengeluaran Anda sendiri.',
        'Di Data & cadangan, ekspor cadangan lengkap kapan saja; saat masuk, '
            'data Anda tersinkron otomatis antarperangkat (juga setelah bekerja '
            'offline), dan Anda bisa mematikannya.',
      ],
    ),
  ];

  // ---- Getting started (Spanish) ----
  static const List<String> _startEs = <String>[
    'Abre Ajustes y elige tu idioma, tu tema y tu moneda base: todos los '
        'totales de la app se muestran en esa moneda.',
    'Añade tus ingresos y gastos (o escanea un ticket): todo lo demás se '
        'calcula a partir de ellos.',
    'Fija un presupuesto mensual para que la app te diga cuánto te queda '
        'por gastar.',
    'Mira el Panel y la Salud financiera para ver dónde estás, y añade metas '
        'y deudas sobre la marcha.',
  ];

  // ---- Topics (Spanish) ----
  static const List<GuideTopic> _topicsEs = <GuideTopic>[
    GuideTopic(
      route: '/dashboard',
      title: 'Panel',
      summary: 'Tu mes de un vistazo: ingresos, gastos, ahorro y a dónde fue '
          'el dinero.',
      steps: <String>[
        'Las tarjetas muestran los totales del mes en tu moneda base.',
        'Toca una porción del desglose de gastos para resaltar esa categoría.',
        'Las alertas te señalan lo que necesita atención, como una categoría '
            'por encima del presupuesto o una meta urgente.',
        'Sin datos, las tarjetas muestran "—": nunca se inventa nada.',
      ],
    ),
    GuideTopic(
      route: '/transactions',
      title: 'Ingresos y gastos',
      summary: 'Registra cada movimiento de dinero: es la base de todos los '
          'cálculos de la app.',
      steps: <String>[
        'Usa el botón de añadir rápido para registrar un ingreso o un gasto '
            'con importe, categoría, fecha y nota.',
        'Ingresos y Gastos tienen su propia pantalla; Movimientos muestra '
            'ambos juntos.',
        'Busca en la lista para encontrar cualquier registro y tócalo para '
            'editarlo o eliminarlo.',
      ],
    ),
    GuideTopic(
      route: '/recurring',
      title: 'Movimientos recurrentes',
      summary: 'Sueldo, alquiler y suscripciones que se añaden solos en su '
          'fecha.',
      steps: <String>[
        'Al añadir un ingreso o un gasto, pon "Repetir" en cada semana, mes, '
            '3 meses, 6 meses o año.',
        'Para un bono o una comisión cuyo importe cambia, activa "El importe '
            'cambia cada vez": en cada fecha la app te pide el importe real '
            'en lugar de añadir una estimación.',
        'Cada vez que vence, la app lo añade como un movimiento normal: '
            'aunque no hayas abierto la app, se pone al día la próxima vez.',
        'En la pantalla Recurrentes, pausa, reanuda, cambia el importe o deja '
            'de repetir. Los movimientos ya añadidos nunca se modifican.',
      ],
    ),
    GuideTopic(
      route: '/expenses',
      title: 'Escanear un ticket',
      summary: 'Convierte la foto de un ticket en un gasto listo para guardar.',
      steps: <String>[
        'En la pantalla Gastos, toca "Escanear ticket" y haz o elige una foto.',
        'La app rellena el comercio, la fecha, el importe y la categoría: '
            'revísalos antes de guardar.',
        'El escaneo en la nube depende de tu plan; si un ticket no se puede '
            'leer, introduce el gasto a mano.',
      ],
    ),
    GuideTopic(
      route: '/budget',
      title: 'Presupuesto mensual',
      summary: 'Planifica cuánto quieres gastar por categoría, mes a mes.',
      steps: <String>[
        'Elige el año y el mes arriba: una sola pantalla cubre todos los '
            'meses.',
        'Fija un límite para cada categoría que quieras controlar.',
        'Las barras de progreso se llenan a medida que gastas; una categoría '
            'que supera su límite queda señalada.',
        'Con un plan de pago, "Sugerir un reparto" divide tus ingresos entre '
            'categorías según tu gasto reciente: revísalo y aplícalo.',
      ],
    ),
    GuideTopic(
      route: '/goals',
      title: 'Metas y ahorro',
      summary: 'Ahorra para algo concreto y mira cuánto te falta.',
      steps: <String>[
        'Crea una meta con un importe objetivo y, si quieres, una fecha '
            'límite.',
        'Registra tus aportes a medida que ahorras; el progreso se actualiza '
            'solo.',
        'Las metas cercanas a su fecha se destacan en el Panel.',
      ],
    ),
    GuideTopic(
      route: '/debts',
      title: 'Deudas y préstamos',
      summary: 'Lleva la cuenta de lo que debes y de lo que te deben.',
      steps: <String>[
        'Añade cada deuda o préstamo con su importe y la persona o entidad.',
        'Actualiza lo pagado hasta ahora para ver el saldo pendiente.',
        'Las deudas cuentan en tu puntuación de Salud financiera.',
      ],
    ),
    GuideTopic(
      route: '/portfolio',
      title: 'Cartera de proyectos',
      summary: 'Planifica proyectos grandes a corto, medio y largo plazo.',
      steps: <String>[
        'Añade proyectos y coloca cada uno en un horizonte de tiempo.',
        'El motor de financiación llena los horizontes en orden, así ves qué '
            'proyectos puede cubrir antes tu ahorro.',
      ],
    ),
    GuideTopic(
      route: '/health',
      title: 'Salud financiera',
      summary: 'Una puntuación que resume lo sanas que están tus finanzas, y '
          'por qué.',
      steps: <String>[
        'La puntuación se calcula en tu dispositivo con tus propios datos.',
        'Los factores clave muestran qué la mejora o la empeora: empieza por '
            'ellos.',
      ],
    ),
    GuideTopic(
      route: '/reports',
      title: 'Informes y análisis',
      summary: 'Ve la evolución del año y a dónde va tu dinero.',
      steps: <String>[
        'Elige un año para comparar ingresos y gastos mes a mes.',
        'Usa los desgloses para detectar categorías que crecen con el tiempo.',
      ],
    ),
    GuideTopic(
      route: '/zakat',
      title: 'Zakat',
      summary: 'Estima la zakat de tu patrimonio y sigue el hawl.',
      steps: <String>[
        'Introduce los bienes sujetos a zakat para obtener una estimación.',
        'Indica la fecha en que tu patrimonio alcanzó el nisab para seguir la '
            'cuenta atrás del año lunar, en calendario de la hégira.',
        'Es una ayuda para planificar: confirma tu obligación con un erudito '
            'cualificado.',
      ],
    ),
    GuideTopic(
      route: '/markets',
      title: 'Tipos de cambio y mercados',
      summary: 'Tipos de cambio y precios cripto en directo de fuentes '
          'públicas.',
      steps: <String>[
        'Los tipos se obtienen en directo; cada fila indica su origen.',
        'Cuando un mercado no tiene una fuente fiable, pone "no disponible": '
            'nunca un número inventado.',
      ],
    ),
    GuideTopic(
      route: '/assistant',
      title: 'Asistente DGOTIX AI',
      summary: 'Pregunta por tus finanzas con tus propias palabras.',
      steps: <String>[
        'Escribe una pregunta o toca una sugerencia; el asistente responde '
            'con un breve resumen de tus cifras.',
        'El número de respuestas depende de tu plan; verás un aviso cuando te '
            'acerques al límite.',
        'Las respuestas se generan automáticamente: revisa las decisiones '
            'importantes. Los análisis por reglas bajo el chat funcionan '
            'siempre, incluso sin IA.',
      ],
    ),
    GuideTopic(
      route: '/plans',
      title: 'Planes y suscripción',
      summary: 'Compara Gratis y Pro, y gestiona tu suscripción.',
      steps: <String>[
        'Las herramientas básicas de presupuesto son gratis para siempre.',
        'Los planes de pago suben los límites de IA y de escaneo en la nube y '
            'añaden funciones.',
        'Si te suscribes, tu plan actual y su fecha de renovación aparecen '
            'arriba, con un botón para gestionarlo o cancelarlo.',
      ],
    ),
    GuideTopic(
      route: '/settings',
      title: 'Ajustes, datos y copia de seguridad',
      summary: 'Haz tuya la app y mantén tus datos a salvo.',
      steps: <String>[
        'Idioma, tema y moneda base están en Apariencia y Región.',
        'Gestiona tus propias categorías de ingresos y gastos.',
        'En Datos y copia de seguridad, exporta una copia completa cuando '
            'quieras; con la sesión iniciada, tus datos se sincronizan solos '
            'entre tus dispositivos (también tras trabajar sin conexión), y '
            'puedes desactivarlo.',
      ],
    ),
  ];

  // ---- Getting started (Turkish) ----
  static const List<String> _startTr = <String>[
    'Ayarlar\'ı aç ve dilini, temanı ve ana para birimini seç — uygulamadaki '
        'her toplam o para biriminde gösterilir.',
    'Gelir ve giderlerini ekle (veya bir fiş tara) — geri kalan her şey '
        'bunlardan hesaplanır.',
    'Uygulamanın sana ne kadar harcayabileceğini söyleyebilmesi için aylık '
        'bir bütçe belirle.',
    'Nerede olduğunu görmek için Panel\'e ve Finansal sağlık\'a bak, sonra '
        'zamanla hedef ve borç ekle.',
  ];

  // ---- Topics (Turkish) ----
  static const List<GuideTopic> _topicsTr = <GuideTopic>[
    GuideTopic(
      route: '/dashboard',
      title: 'Panel',
      summary: 'Ayına bir bakışta: gelir, harcama, birikim ve paranın nereye '
          'gittiği.',
      steps: <String>[
        'Kutucuklar bu ayın toplamlarını ana para biriminde gösterir.',
        'O kategoriyi öne çıkarmak için harcama dağılımında bir dilime dokun.',
        'Uyarılar, bütçeyi aşan bir kategori veya acil bir hedef gibi dikkat '
            'gerektiren her şeyi gösterir.',
        'Henüz veri yoksa kutucuklarda "—" görünür — hiçbir şey uydurulmaz.',
      ],
    ),
    GuideTopic(
      route: '/transactions',
      title: 'Gelir ve giderler',
      summary: 'Her para hareketini kaydet — uygulamadaki her hesabın temeli.',
      steps: <String>[
        'Tutar, kategori, tarih ve notla bir gelir veya gider kaydetmek için '
            'hızlı ekle düğmesini kullan.',
        'Gelir ve Giderler\'in kendi ekranları var; İşlemler ikisini birlikte '
            'gösterir.',
        'Herhangi bir kaydı bulmak için listede ara; düzenlemek veya silmek '
            'için birine dokun.',
      ],
    ),
    GuideTopic(
      route: '/recurring',
      title: 'Tekrarlayan işlemler',
      summary: 'Maaş, kira ve abonelikler tarihlerinde otomatik eklenir.',
      steps: <String>[
        'Gelir veya gider eklerken "Tekrarla"yı her hafta, ay, 3 ay, 6 ay '
            'veya yıl olarak ayarla.',
        'Tutarı değişen bir prim veya komisyon için "Tutar her seferinde '
            'değişir"i aç: her tarihte uygulama tahmin eklemek yerine gerçek '
            'tutarı sorar.',
        'Her vadesi geldiğinde uygulama onu normal bir işlem olarak ekler — '
            'uzakta olsan bile, uygulamayı bir sonraki açışında eksikleri '
            'tamamlar.',
        'Tekrarlayanlar ekranında duraklat, devam ettir, tutarı değiştir veya '
            'tekrarı durdur. Zaten eklenen işlemler asla değişmez.',
      ],
    ),
    GuideTopic(
      route: '/expenses',
      title: 'Fiş tara',
      summary: 'Bir fiş fotoğrafını kaydetmeye hazır bir gidere dönüştür.',
      steps: <String>[
        'Giderler ekranında "Fiş tara"ya dokun ve bir fotoğraf çek veya seç.',
        'Uygulama işletmeyi, tarihi, tutarı ve kategoriyi doldurur — '
            'kaydetmeden önce gözden geçir.',
        'Bulutta tarama planına bağlıdır; bir tarama okunamazsa gideri elle '
            'gir.',
      ],
    ),
    GuideTopic(
      route: '/budget',
      title: 'Aylık bütçe',
      summary: 'Kategori başına ne kadar harcamak istediğini ay ay planla.',
      steps: <String>[
        'Üstten yılı ve ayı seç — tek ekran her ayı kapsar.',
        'Kontrol etmek istediğin her kategori için bir sınır belirle.',
        'Harcadıkça ilerleme çubukları dolar; sınırını aşan kategori '
            'işaretlenir.',
        'Ücretli bir planda "Paylaştırma öner", gelirini kendi son '
            'harcamalarına göre kategorilere böler — gözden geçir, sonra '
            'uygula.',
      ],
    ),
    GuideTopic(
      route: '/goals',
      title: 'Hedefler ve birikim',
      summary: 'Belirli bir şey için biriktir ve ne kadar yaklaştığını gör.',
      steps: <String>[
        'Hedef tutarı ve isteğe bağlı bir son tarihi olan bir hedef oluştur.',
        'Biriktirdikçe katkıları kaydet; ilerleme otomatik güncellenir.',
        'Son tarihi yaklaşan hedefler Panel\'de vurgulanır.',
      ],
    ),
    GuideTopic(
      route: '/debts',
      title: 'Borçlar ve krediler',
      summary: 'Borçlu olduklarını ve başkalarının sana borçlarını takip et.',
      steps: <String>[
        'Her borcu veya krediyi tutarı ve kişi ya da taraf ile ekle.',
        'Kalan bakiyeyi görmek için şimdiye kadar ödenen tutarı güncelle.',
        'Borçlar Finansal sağlık puanına katkıda bulunur.',
      ],
    ),
    GuideTopic(
      route: '/portfolio',
      title: 'Proje portföyü',
      summary: 'Büyük projeleri kısa, orta ve uzun vadeli bölmelerde planla.',
      steps: <String>[
        'Projeler ekle ve her birini bir vadeye yerleştir.',
        'Fonlama motoru bölmeleri sırayla doldurur; böylece birikimlerinin '
            'önce hangi projeleri karşılayabileceğini görürsün.',
      ],
    ),
    GuideTopic(
      route: '/health',
      title: 'Finansal sağlık',
      summary: 'Finanslarının ne kadar sağlıklı olduğunu ve nedenini '
          'özetleyen bir puan.',
      steps: <String>[
        'Puan, kendi verilerinden cihazında hesaplanır.',
        'Ana etkenler neyin yardımcı olduğunu veya zarar verdiğini gösterir — '
            'önce onları iyileştir.',
      ],
    ),
    GuideTopic(
      route: '/reports',
      title: 'Raporlar ve analizler',
      summary: 'Yıl boyunca eğilimleri ve paranın nereye gittiğini gör.',
      steps: <String>[
        'Gelir ve giderleri ay ay karşılaştırmak için bir yıl seç.',
        'Zamanla büyüyen kategorileri fark etmek için dökümleri kullan.',
      ],
    ),
    GuideTopic(
      route: '/zakat',
      title: 'Zekât',
      summary: 'Servetine düşen zekâtı tahmin et ve havlı takip et.',
      steps: <String>[
        'Tahmin almak için zekâta tabi varlıkları gir.',
        'Hicrî olarak gösterilen kamerî yıl geri sayımını izlemek için '
            'servetinin nisaba ulaştığı tarihi belirle.',
        'Bu bir planlama yardımıdır — yükümlülüğünü yetkin bir âlimle teyit '
            'et.',
      ],
    ),
    GuideTopic(
      route: '/markets',
      title: 'Döviz kurları ve piyasalar',
      summary: 'Herkese açık kaynaklardan canlı döviz kurları ve kripto '
          'fiyatları.',
      steps: <String>[
        'Kurlar canlı olarak alınır; her satır kaynağını gösterir.',
        'Bir piyasanın güvenilir kaynağı yoksa "veri yok" yazar — asla '
            'uydurma bir sayı değil.',
      ],
    ),
    GuideTopic(
      route: '/assistant',
      title: 'DGOTIX AI asistanı',
      summary: 'Finansların hakkında sade bir dille soru sor.',
      steps: <String>[
        'Bir soru yaz veya bir öneriye dokun; asistan rakamlarının kısa bir '
            'özetini kullanarak yanıtlar.',
        'Yanıt sayısı planına bağlıdır; sınıra yaklaştığında bir not görürsün.',
        'Yanıtlar otomatik üretilir — önemli kararları iki kez kontrol et. '
            'Sohbetin altındaki kurala dayalı içgörüler yapay zekâ olmadan da '
            'her zaman çalışır.',
      ],
    ),
    GuideTopic(
      route: '/plans',
      title: 'Planlar ve abonelik',
      summary: 'Free ve Pro\'yu karşılaştır ve aboneliğini yönet.',
      steps: <String>[
        'Temel bütçe araçları sonsuza dek ücretsiz.',
        'Ücretli planlar yapay zekâ ve bulut tarama sınırlarını yükseltir ve '
            'ek özellikler ekler.',
        'Abone olursan mevcut planın ve yenileme tarihin en üstte, yönetme '
            'veya iptal etme düğmesiyle görünür.',
      ],
    ),
    GuideTopic(
      route: '/settings',
      title: 'Ayarlar, veriler ve yedekleme',
      summary: 'Uygulamayı kendine göre ayarla ve verilerini güvende tut.',
      steps: <String>[
        'Dil, tema ve ana para birimi Görünüm ve Bölge altında.',
        'Kendi gelir ve gider kategorilerini yönet.',
        'Veriler ve yedekleme altında istediğin zaman tam bir yedek dışa '
            'aktar; giriş yaptığında verilerin cihazların arasında otomatik '
            'senkronize olur (çevrimdışı çalıştıktan sonra da) ve bunu '
            'kapatabilirsin.',
      ],
    ),
  ];

  // ---- Getting started (Malay) ----
  static const List<String> _startMs = <String>[
    'Buka Tetapan dan pilih bahasa, tema dan mata wang asas anda — setiap '
        'jumlah dalam aplikasi dipaparkan dalam mata wang itu.',
    'Tambah pendapatan dan perbelanjaan anda (atau imbas resit) — semua yang '
        'lain dikira daripadanya.',
    'Tetapkan bajet bulanan supaya aplikasi boleh memberitahu berapa baki '
        'yang boleh dibelanjakan.',
    'Semak Papan pemuka dan Kesihatan kewangan untuk melihat kedudukan anda, '
        'kemudian tambah matlamat dan hutang dari semasa ke semasa.',
  ];

  // ---- Topics (Malay) ----
  static const List<GuideTopic> _topicsMs = <GuideTopic>[
    GuideTopic(
      route: '/dashboard',
      title: 'Papan pemuka',
      summary: 'Bulan anda sepintas lalu: pendapatan, perbelanjaan, simpanan '
          'dan ke mana wang pergi.',
      steps: <String>[
        'Jubin menunjukkan jumlah bulan ini dalam mata wang asas anda.',
        'Ketik satu hirisan dalam pecahan perbelanjaan untuk menyerlahkan '
            'kategori itu.',
        'Amaran menunjukkan apa sahaja yang perlu perhatian, seperti kategori '
            'yang melebihi bajet atau matlamat yang mendesak.',
        'Tanpa data, jubin menunjukkan "—" — tiada yang direka.',
      ],
    ),
    GuideTopic(
      route: '/transactions',
      title: 'Pendapatan & perbelanjaan',
      summary: 'Rekod setiap pergerakan wang — asas setiap pengiraan dalam '
          'aplikasi.',
      steps: <String>[
        'Gunakan butang tambah pantas untuk merekod pendapatan atau '
            'perbelanjaan dengan jumlah, kategori, tarikh dan nota.',
        'Pendapatan dan Perbelanjaan masing-masing ada skrin sendiri; '
            'Transaksi menunjukkan kedua-duanya bersama.',
        'Cari dalam senarai untuk menemui sebarang catatan, dan ketik satu '
            'untuk menyunting atau memadamnya.',
      ],
    ),
    GuideTopic(
      route: '/recurring',
      title: 'Transaksi berulang',
      summary: 'Gaji, sewa dan langganan ditambah secara automatik pada '
          'tarikhnya.',
      steps: <String>[
        'Semasa menambah pendapatan atau perbelanjaan, tetapkan "Ulang" '
            'kepada setiap minggu, bulan, 3 bulan, 6 bulan atau tahun.',
        'Untuk bonus atau komisen yang jumlahnya berubah, hidupkan "Jumlah '
            'berubah setiap kali": pada setiap tarikh aplikasi meminta jumlah '
            'sebenar dan bukannya menambah anggaran.',
        'Setiap kali tiba tarikhnya, aplikasi menambahnya sebagai transaksi '
            'biasa — walaupun anda tiada, ia dikemas kini apabila anda '
            'membuka aplikasi kemudian.',
        'Pada skrin Berulang, jeda, sambung semula, tukar jumlah atau '
            'hentikan ulangan. Transaksi yang sudah ditambah tidak pernah '
            'diubah.',
      ],
    ),
    GuideTopic(
      route: '/expenses',
      title: 'Imbas resit',
      summary: 'Tukar foto resit menjadi perbelanjaan yang sedia untuk '
          'disimpan.',
      steps: <String>[
        'Pada skrin Perbelanjaan, ketik "Imbas resit" dan ambil atau pilih '
            'foto.',
        'Aplikasi mengisi peniaga, tarikh, jumlah dan kategori — semaknya '
            'sebelum menyimpan.',
        'Imbasan awan bergantung pada pelan anda; jika imbasan tidak dapat '
            'dibaca, masukkan perbelanjaan secara manual.',
      ],
    ),
    GuideTopic(
      route: '/budget',
      title: 'Bajet bulanan',
      summary: 'Rancang berapa banyak anda mahu belanja bagi setiap kategori, '
          'bulan demi bulan.',
      steps: <String>[
        'Pilih tahun dan bulan di bahagian atas — satu skrin merangkumi '
            'setiap bulan.',
        'Tetapkan had untuk setiap kategori yang ingin anda kawal.',
        'Bar kemajuan terisi semasa anda berbelanja; kategori yang melebihi '
            'had ditandakan.',
        'Pada pelan berbayar, "Cadangkan pembahagian" membahagikan pendapatan '
            'anda kepada kategori berdasarkan perbelanjaan terkini anda — '
            'semak, kemudian gunakan.',
      ],
    ),
    GuideTopic(
      route: '/goals',
      title: 'Matlamat & simpanan',
      summary: 'Simpan untuk sesuatu yang khusus dan lihat sejauh mana anda '
          'hampir.',
      steps: <String>[
        'Cipta matlamat dengan jumlah sasaran dan, secara pilihan, tarikh '
            'akhir.',
        'Rekod caruman semasa anda menyimpan; kemajuan dikemas kini secara '
            'automatik.',
        'Matlamat yang hampir tarikh akhir diserlahkan di Papan pemuka.',
      ],
    ),
    GuideTopic(
      route: '/debts',
      title: 'Hutang & pinjaman',
      summary: 'Jejak apa yang anda hutang dan apa yang orang lain hutang '
          'kepada anda.',
      steps: <String>[
        'Tambah setiap hutang atau pinjaman dengan jumlahnya dan orang atau '
            'pihak berkenaan.',
        'Kemas kini jumlah yang dibayar setakat ini untuk melihat baki.',
        'Hutang menyumbang kepada skor Kesihatan kewangan anda.',
      ],
    ),
    GuideTopic(
      route: '/portfolio',
      title: 'Portfolio projek',
      summary: 'Rancang projek besar dalam petak jangka pendek, sederhana dan '
          'panjang.',
      steps: <String>[
        'Tambah projek dan letakkan setiap satu dalam jangka masa.',
        'Enjin pembiayaan mengisi petak mengikut urutan, jadi anda nampak '
            'projek mana yang boleh ditampung oleh simpanan anda dahulu.',
      ],
    ),
    GuideTopic(
      route: '/health',
      title: 'Kesihatan kewangan',
      summary: 'Skor yang merumuskan sejauh mana sihat kewangan anda, dan '
          'sebabnya.',
      steps: <String>[
        'Skor dikira pada peranti anda daripada data anda sendiri.',
        'Faktor utama menunjukkan apa yang membantu atau menjejaskannya — '
            'perbaiki itu dahulu.',
      ],
    ),
    GuideTopic(
      route: '/reports',
      title: 'Laporan & analisis',
      summary: 'Lihat trend sepanjang tahun dan ke mana wang anda pergi.',
      steps: <String>[
        'Pilih tahun untuk membandingkan pendapatan dan perbelanjaan bulan '
            'demi bulan.',
        'Gunakan pecahan untuk mengesan kategori yang meningkat dari masa ke '
            'masa.',
      ],
    ),
    GuideTopic(
      route: '/zakat',
      title: 'Zakat',
      summary: 'Anggarkan zakat yang perlu dibayar atas harta anda dan jejak '
          'haul.',
      steps: <String>[
        'Masukkan aset yang dikenakan zakat untuk mendapat anggaran.',
        'Tetapkan tarikh harta anda mencapai nisab untuk mengikuti kiraan '
            'detik tahun qamariah, dipaparkan dalam Hijrah.',
        'Ini alat bantu perancangan — sahkan kewajipan anda dengan ilmuwan '
            'yang bertauliah.',
      ],
    ),
    GuideTopic(
      route: '/markets',
      title: 'Kadar pertukaran & pasaran',
      summary: 'Kadar mata wang dan harga kripto langsung daripada sumber '
          'awam.',
      steps: <String>[
        'Kadar diambil secara langsung; setiap baris menunjukkan sumbernya.',
        'Apabila pasaran tiada sumber yang boleh dipercayai, ia tertulis '
            '"tidak tersedia" — bukan nombor rekaan.',
      ],
    ),
    GuideTopic(
      route: '/assistant',
      title: 'Pembantu DGOTIX AI',
      summary: 'Tanya soalan tentang kewangan anda dalam bahasa mudah.',
      steps: <String>[
        'Taip soalan atau ketik cadangan; pembantu menjawab menggunakan '
            'ringkasan pendek angka anda.',
        'Bilangan jawapan bergantung pada pelan anda; anda akan nampak nota '
            'apabila hampir mencapai had.',
        'Jawapan dijana secara automatik — semak semula keputusan penting. '
            'Wawasan berasaskan peraturan di bawah sembang sentiasa '
            'berfungsi, walaupun tanpa AI.',
      ],
    ),
    GuideTopic(
      route: '/plans',
      title: 'Pelan & langganan',
      summary: 'Bandingkan Free dan Pro, dan urus langganan anda.',
      steps: <String>[
        'Alat bajet teras percuma selama-lamanya.',
        'Pelan berbayar menaikkan had AI dan imbasan awan serta menambah ciri '
            'tambahan.',
        'Jika anda melanggan, pelan semasa dan tarikh pembaharuan muncul di '
            'bahagian atas, dengan butang untuk mengurus atau membatalkan.',
      ],
    ),
    GuideTopic(
      route: '/settings',
      title: 'Tetapan, data & sandaran',
      summary: 'Jadikan aplikasi milik anda dan pastikan data anda selamat.',
      steps: <String>[
        'Bahasa, tema dan mata wang asas berada di bawah Penampilan dan '
            'Wilayah.',
        'Urus kategori pendapatan dan perbelanjaan anda sendiri.',
        'Di bawah Data & sandaran, eksport sandaran penuh pada bila-bila '
            'masa; apabila log masuk, data anda diselaraskan antara peranti '
            'secara automatik (juga selepas bekerja di luar talian), dan anda '
            'boleh mematikannya.',
      ],
    ),
  ];

  // ---- Getting started (Urdu) ----
  static const List<String> _startUr = <String>[
    'سیٹنگز کھولیں اور اپنی زبان، تھیم اور بنیادی کرنسی چنیں — ایپ کا ہر '
        'مجموعہ اسی کرنسی میں دکھایا جاتا ہے۔',
    'اپنی آمدنی اور اخراجات شامل کریں (یا رسید اسکین کریں) — باقی سب کچھ انہی '
        'سے حساب ہوتا ہے۔',
    'ماہانہ بجٹ مقرر کریں تاکہ ایپ بتا سکے کہ خرچ کے لیے کتنا باقی ہے۔',
    'اپنی صورتحال جاننے کے لیے ڈیش بورڈ اور مالی صحت دیکھیں، پھر وقت کے ساتھ '
        'اہداف اور قرض شامل کریں۔',
  ];

  // ---- Topics (Urdu) ----
  static const List<GuideTopic> _topicsUr = <GuideTopic>[
    GuideTopic(
      route: '/dashboard',
      title: 'ڈیش بورڈ',
      summary: 'آپ کا مہینہ ایک نظر میں: آمدنی، خرچ، بچت اور پیسہ کہاں گیا۔',
      steps: <String>[
        'ٹائلز اس مہینے کے مجموعے آپ کی بنیادی کرنسی میں دکھاتی ہیں۔',
        'کسی کیٹیگری کو نمایاں کرنے کے لیے خرچ کی تقسیم میں اس کے حصے پر ٹیپ '
            'کریں۔',
        'الرٹس ہر اس چیز کی طرف اشارہ کرتے ہیں جس پر توجہ درکار ہو، جیسے بجٹ '
            'سے بڑھی ہوئی کیٹیگری یا فوری ہدف۔',
        'ڈیٹا نہ ہونے پر ٹائلز "—" دکھاتی ہیں — کچھ بھی گھڑا نہیں جاتا۔',
      ],
    ),
    GuideTopic(
      route: '/transactions',
      title: 'آمدنی اور اخراجات',
      summary: 'پیسے کی ہر نقل و حرکت درج کریں — ایپ کے ہر حساب کی بنیاد۔',
      steps: <String>[
        'رقم، کیٹیگری، تاریخ اور نوٹ کے ساتھ آمدنی یا خرچ درج کرنے کے لیے '
            'فوری اندراج کا بٹن استعمال کریں۔',
        'آمدنی اور اخراجات کی اپنی اپنی اسکرین ہے؛ ٹرانزیکشنز دونوں کو ساتھ '
            'دکھاتی ہے۔',
        'کوئی بھی اندراج تلاش کرنے کے لیے فہرست میں تلاش کریں، اور ترمیم یا '
            'حذف کے لیے اس پر ٹیپ کریں۔',
      ],
    ),
    GuideTopic(
      route: '/recurring',
      title: 'بار بار ہونے والی ٹرانزیکشنز',
      summary: 'تنخواہ، کرایہ اور سبسکرپشنز اپنی تاریخ پر خود بخود شامل۔',
      steps: <String>[
        'آمدنی یا خرچ شامل کرتے وقت "دہرائیں" کو ہر ہفتے، مہینے، 3 مہینے، 6 '
            'مہینے یا سال پر سیٹ کریں۔',
        'بدلتی رقم والے بونس یا کمیشن کے لیے "رقم ہر بار بدلتی ہے" آن کریں: '
            'ہر تاریخ پر ایپ اندازہ شامل کرنے کی بجائے اصل رقم پوچھتی ہے۔',
        'ہر بار تاریخ آنے پر ایپ اسے عام ٹرانزیکشن کے طور پر شامل کرتی ہے — '
            'اگر آپ موجود نہ بھی ہوں تو اگلی بار ایپ کھولنے پر کمی پوری کر '
            'دیتی ہے۔',
        'بار بار ہونے والے کی اسکرین پر روکیں، دوبارہ شروع کریں، رقم بدلیں یا '
            'دہرانا بند کریں۔ پہلے سے شامل ٹرانزیکشنز کبھی نہیں بدلتیں۔',
      ],
    ),
    GuideTopic(
      route: '/expenses',
      title: 'رسید اسکین کریں',
      summary: 'رسید کی تصویر کو محفوظ کرنے کے لیے تیار خرچ میں بدلیں۔',
      steps: <String>[
        'اخراجات کی اسکرین پر "رسید اسکین کریں" پر ٹیپ کریں اور تصویر لیں یا '
            'چنیں۔',
        'ایپ دکان، تاریخ، رقم اور کیٹیگری بھر دیتی ہے — محفوظ کرنے سے پہلے '
            'انہیں دیکھ لیں۔',
        'کلاؤڈ اسکیننگ آپ کے پلان پر منحصر ہے؛ اگر اسکین پڑھا نہ جا سکے تو '
            'خرچ خود درج کریں۔',
      ],
    ),
    GuideTopic(
      route: '/budget',
      title: 'ماہانہ بجٹ',
      summary: 'ہر کیٹیگری میں کتنا خرچ کرنا ہے، مہینہ بہ مہینہ منصوبہ بنائیں۔',
      steps: <String>[
        'اوپر سے سال اور مہینہ چنیں — ایک ہی اسکرین ہر مہینے کا احاطہ کرتی ہے۔',
        'ہر اس کیٹیگری کی حد مقرر کریں جسے آپ قابو میں رکھنا چاہتے ہیں۔',
        'خرچ کے ساتھ پیش رفت کی بارز بھرتی ہیں؛ حد سے بڑھی ہوئی کیٹیگری نشان '
            'زد ہوتی ہے۔',
        'ادا شدہ پلان پر "تقسیم تجویز کریں" آپ کے حالیہ خرچ کی بنیاد پر آمدنی '
            'کو کیٹیگریز میں بانٹتا ہے — جائزہ لیں، پھر لاگو کریں۔',
      ],
    ),
    GuideTopic(
      route: '/goals',
      title: 'اہداف اور بچت',
      summary: 'کسی خاص چیز کے لیے بچت کریں اور دیکھیں کہ آپ کتنے قریب ہیں۔',
      steps: <String>[
        'ہدف کی رقم اور، چاہیں تو، آخری تاریخ کے ساتھ ہدف بنائیں۔',
        'بچت کے ساتھ رقم شامل کرتے جائیں؛ پیش رفت خود بخود اپ ڈیٹ ہوتی ہے۔',
        'آخری تاریخ کے قریب اہداف ڈیش بورڈ پر نمایاں ہوتے ہیں۔',
      ],
    ),
    GuideTopic(
      route: '/debts',
      title: 'قرض اور ادھار',
      summary: 'جو آپ کو دینا ہے اور جو دوسروں کو آپ کو دینا ہے، اس کا حساب '
          'رکھیں۔',
      steps: <String>[
        'ہر قرض یا ادھار اس کی رقم اور شخص یا فریق کے ساتھ شامل کریں۔',
        'باقی رقم دیکھنے کے لیے اب تک ادا شدہ رقم اپ ڈیٹ کریں۔',
        'قرض آپ کے مالی صحت کے اسکور میں شامل ہوتے ہیں۔',
      ],
    ),
    GuideTopic(
      route: '/portfolio',
      title: 'پروجیکٹس پورٹ فولیو',
      summary: 'بڑے پروجیکٹس کو قلیل، درمیانی اور طویل مدتی خانوں میں منصوبہ '
          'بند کریں۔',
      steps: <String>[
        'پروجیکٹس شامل کریں اور ہر ایک کو کسی مدت میں رکھیں۔',
        'فنڈنگ انجن خانوں کو ترتیب سے بھرتا ہے، تاکہ آپ دیکھ سکیں کہ آپ کی '
            'بچت پہلے کون سے پروجیکٹس پورے کر سکتی ہے۔',
      ],
    ),
    GuideTopic(
      route: '/health',
      title: 'مالی صحت',
      summary: 'ایک اسکور جو بتاتا ہے کہ آپ کے مالی معاملات کتنے صحت مند ہیں، '
          'اور کیوں۔',
      steps: <String>[
        'اسکور آپ کے اپنے ڈیٹا سے آپ کی ڈیوائس پر تیار ہوتا ہے۔',
        'اہم عوامل دکھاتے ہیں کہ کیا مدد کر رہا ہے یا نقصان پہنچا رہا ہے — '
            'پہلے انہیں بہتر کریں۔',
      ],
    ),
    GuideTopic(
      route: '/reports',
      title: 'رپورٹس اور تجزیہ',
      summary: 'سال بھر کے رجحانات اور آپ کا پیسہ کہاں جاتا ہے، دیکھیں۔',
      steps: <String>[
        'آمدنی اور اخراجات کا مہینہ بہ مہینہ موازنہ کرنے کے لیے سال چنیں۔',
        'وقت کے ساتھ بڑھنے والی کیٹیگریز پہچاننے کے لیے تفصیلات استعمال کریں۔',
      ],
    ),
    GuideTopic(
      route: '/zakat',
      title: 'زکوٰۃ',
      summary: 'اپنے مال پر واجب زکوٰۃ کا اندازہ لگائیں اور حول کا حساب رکھیں۔',
      steps: <String>[
        'اندازہ حاصل کرنے کے لیے قابلِ زکوٰۃ اثاثے درج کریں۔',
        'ہجری میں دکھائی جانے والی قمری سال کی الٹی گنتی کے لیے وہ تاریخ مقرر '
            'کریں جب آپ کا مال نصاب تک پہنچا۔',
        'یہ منصوبہ بندی میں مدد ہے — اپنی ذمہ داری کی تصدیق کسی مستند عالم سے '
            'کریں۔',
      ],
    ),
    GuideTopic(
      route: '/markets',
      title: 'ایکسچینج ریٹس اور مارکیٹیں',
      summary: 'عوامی ذرائع سے لائیو کرنسی ریٹس اور کرپٹو قیمتیں۔',
      steps: <String>[
        'ریٹس لائیو حاصل کیے جاتے ہیں؛ ہر قطار اپنا ذریعہ دکھاتی ہے۔',
        'جب کسی مارکیٹ کا قابلِ اعتماد ذریعہ نہ ہو تو "دستیاب نہیں" لکھا آتا '
            'ہے — کبھی گھڑا ہوا عدد نہیں۔',
      ],
    ),
    GuideTopic(
      route: '/assistant',
      title: 'DGOTIX AI اسسٹنٹ',
      summary: 'اپنے مالی معاملات کے بارے میں آسان زبان میں سوال پوچھیں۔',
      steps: <String>[
        'سوال لکھیں یا کسی تجویز پر ٹیپ کریں؛ اسسٹنٹ آپ کے اعداد کے مختصر '
            'خلاصے سے جواب دیتا ہے۔',
        'جوابات کی تعداد آپ کے پلان پر منحصر ہے؛ حد کے قریب پہنچنے پر آپ کو '
            'نوٹ نظر آئے گا۔',
        'جوابات خود بخود تیار ہوتے ہیں — اہم فیصلوں کی دوبارہ جانچ کریں۔ چیٹ '
            'کے نیچے قواعد پر مبنی جائزے AI کے بغیر بھی ہمیشہ کام کرتے ہیں۔',
      ],
    ),
    GuideTopic(
      route: '/plans',
      title: 'پلانز اور سبسکرپشن',
      summary: 'Free اور Pro کا موازنہ کریں اور اپنی سبسکرپشن کا '
          'انتظام کریں۔',
      steps: <String>[
        'بجٹ کے بنیادی ٹولز ہمیشہ کے لیے مفت ہیں۔',
        'ادا شدہ پلانز AI اور کلاؤڈ اسکین کی حدیں بڑھاتے ہیں اور اضافی فیچرز '
            'شامل کرتے ہیں۔',
        'اگر آپ سبسکرائب کریں تو آپ کا موجودہ پلان اور تجدید کی تاریخ سب سے '
            'اوپر نظر آتی ہے، ساتھ ہی انتظام یا منسوخی کا بٹن۔',
      ],
    ),
    GuideTopic(
      route: '/settings',
      title: 'سیٹنگز، ڈیٹا اور بیک اپ',
      summary: 'ایپ کو اپنے مطابق بنائیں اور اپنا ڈیٹا محفوظ رکھیں۔',
      steps: <String>[
        'زبان، تھیم اور بنیادی کرنسی ظاہری شکل اور علاقہ کے تحت ہیں۔',
        'آمدنی اور خرچ کی اپنی کیٹیگریز کا انتظام کریں۔',
        'ڈیٹا اور بیک اپ کے تحت کسی بھی وقت مکمل بیک اپ ایکسپورٹ کریں؛ سائن '
            'ان ہونے پر آپ کا ڈیٹا آپ کی ڈیوائسز میں خود بخود ہم آہنگ ہوتا ہے '
            '(آف لائن کام کے بعد بھی)، اور آپ اسے بند کر سکتے ہیں۔',
      ],
    ),
  ];

  // ---- Getting started (German) ----
  static const List<String> _startDe = <String>[
    'Öffne die Einstellungen und wähle Sprache, Design und Basiswährung – '
        'jede Summe in der App wird in dieser Währung angezeigt.',
    'Füge deine Einnahmen und Ausgaben hinzu (oder scanne einen Beleg) – alles '
        'andere wird daraus berechnet.',
    'Lege ein Monatsbudget fest, damit die App dir sagt, wie viel du noch '
        'ausgeben kannst.',
    'Sieh dir die Übersicht und die finanzielle Gesundheit an, um zu wissen, wo'
        ' du stehst, und füge dann nach und nach Ziele und Schulden hinzu.',
  ];

  // ---- Topics (German) ----
  static const List<GuideTopic> _topicsDe = <GuideTopic>[
    GuideTopic(
      route: '/dashboard',
      title: 'Übersicht',
      summary:
          'Dein Monat auf einen Blick: Einnahmen, Ausgaben, Ersparnisse und '
          'wohin das Geld gegangen ist.',
      steps: <String>[
        'Die Kacheln zeigen die Summen dieses Monats in deiner Basiswährung.',
        'Tippe auf ein Segment der Ausgabenaufteilung, um diese Kategorie '
            'hervorzuheben.',
        'Hinweise zeigen dir, was Aufmerksamkeit braucht, etwa eine Kategorie '
            'über dem Budget oder ein dringendes Ziel.',
        'Solange es noch keine Daten gibt, zeigen die Kacheln „—“ – es wird nie'
            ' etwas erfunden.',
      ],
    ),
    GuideTopic(
      route: '/transactions',
      title: 'Einnahmen & Ausgaben',
      summary: 'Erfasse jede Geldbewegung – die Grundlage jeder Berechnung in '
          'der App.',
      steps: <String>[
        'Mit der Schnell-hinzufügen-Schaltfläche erfasst du eine Einnahme oder '
            'Ausgabe mit Betrag, Kategorie, Datum und Notiz.',
        'Einnahmen und Ausgaben haben jeweils einen eigenen Bildschirm; '
            'Buchungen zeigt beide zusammen.',
        'Durchsuche die Liste, um jeden Eintrag zu finden, und tippe darauf, um'
            ' ihn zu bearbeiten oder zu löschen.',
      ],
    ),
    GuideTopic(
      route: '/recurring',
      title: 'Wiederkehrende Buchungen',
      summary: 'Gehalt, Miete und Abos werden automatisch an ihrem Datum '
          'hinzugefügt.',
      steps: <String>[
        'Stelle beim Hinzufügen einer Einnahme oder Ausgabe „Wiederholen“ auf '
            'jede Woche, jeden Monat, alle 3 Monate, alle 6 Monate oder jedes '
            'Jahr.',
        'Für einen Bonus oder eine Provision mit wechselndem Betrag schalte '
            '„Der Betrag ändert sich jedes Mal“ ein: An jedem Datum fragt die '
            'App nach dem echten Betrag, statt eine Schätzung hinzuzufügen.',
        'Bei jeder Fälligkeit fügt die App sie als normale Buchung hinzu – auch'
            ' wenn du weg warst, holt sie das beim nächsten Öffnen nach.',
        'Auf dem Bildschirm Wiederkehrend kannst du pausieren, fortsetzen, den '
            'Betrag ändern oder die Wiederholung beenden. Bereits hinzugefügte '
            'Buchungen werden nie geändert.',
      ],
    ),
    GuideTopic(
      route: '/expenses',
      title: 'Beleg scannen',
      summary: 'Mach aus dem Foto eines Belegs eine Ausgabe, die du nur noch '
          'speichern musst.',
      steps: <String>[
        'Tippe auf dem Bildschirm Ausgaben auf „Beleg scannen“ und nimm ein '
            'Foto auf oder wähle eines.',
        'Die App füllt Händler, Datum, Betrag und Kategorie aus – prüfe sie vor'
            ' dem Speichern.',
        'Der Scan in der Cloud hängt von deinem Tarif ab; lässt sich ein Beleg '
            'nicht lesen, gib die Ausgabe von Hand ein.',
      ],
    ),
    GuideTopic(
      route: '/budget',
      title: 'Monatsbudget',
      summary: 'Plane, wie viel du pro Kategorie ausgeben willst, Monat für '
          'Monat.',
      steps: <String>[
        'Wähle oben Jahr und Monat – ein Bildschirm deckt jeden Monat ab.',
        'Lege für jede Kategorie, die du im Griff haben willst, ein Limit fest.',
        'Fortschrittsbalken füllen sich, während du ausgibst; eine Kategorie '
            'über ihrem Limit wird markiert.',
        'In einem bezahlten Tarif verteilt „Aufteilung vorschlagen“ dein '
            'Einkommen anhand deiner eigenen letzten Ausgaben auf die Kategorien'
            ' – prüfe den Vorschlag und übernimm ihn dann.',
      ],
    ),
    GuideTopic(
      route: '/goals',
      title: 'Ziele & Sparen',
      summary: 'Spare auf etwas Bestimmtes hin und sieh, wie nah du dran bist.',
      steps: <String>[
        'Lege ein Ziel mit einem Zielbetrag und optional einer Frist an.',
        'Erfasse Einzahlungen, während du sparst; der Fortschritt wird '
            'automatisch aktualisiert.',
        'Ziele kurz vor ihrer Frist werden in der Übersicht hervorgehoben.',
      ],
    ),
    GuideTopic(
      route: '/debts',
      title: 'Schulden & Kredite',
      summary: 'Behalte im Blick, was du schuldest und was andere dir schulden.',
      steps: <String>[
        'Füge jede Schuld oder jeden Kredit mit Betrag und Person oder '
            'Gegenseite hinzu.',
        'Aktualisiere den bisher bezahlten Betrag, um den offenen Rest zu '
            'sehen.',
        'Schulden fließen in deinen Wert für die finanzielle Gesundheit ein.',
      ],
    ),
    GuideTopic(
      route: '/portfolio',
      title: 'Projektportfolio',
      summary: 'Plane größere Projekte in kurz-, mittel- und langfristigen '
          'Fächern.',
      steps: <String>[
        'Füge Projekte hinzu und ordne jedes einem Zeitrahmen zu.',
        'Die Finanzierung füllt die Fächer der Reihe nach, sodass du siehst, '
            'welche Projekte deine Ersparnisse zuerst abdecken können.',
      ],
    ),
    GuideTopic(
      route: '/health',
      title: 'Finanzielle Gesundheit',
      summary: 'Ein Wert, der zusammenfasst, wie gesund deine Finanzen sind, '
          'und warum.',
      steps: <String>[
        'Der Wert wird auf deinem Gerät aus deinen eigenen Daten berechnet.',
        'Die wichtigsten Faktoren zeigen, was hilft oder schadet – verbessere '
            'diese zuerst.',
      ],
    ),
    GuideTopic(
      route: '/reports',
      title: 'Berichte & Analysen',
      summary: 'Sieh Entwicklungen über das Jahr und wohin dein Geld geht.',
      steps: <String>[
        'Wähle ein Jahr, um Einnahmen und Ausgaben Monat für Monat zu '
            'vergleichen.',
        'Nutze die Aufschlüsselungen, um Kategorien zu erkennen, die mit der '
            'Zeit wachsen.',
      ],
    ),
    GuideTopic(
      route: '/zakat',
      title: 'Zakat',
      summary: 'Schätze die fällige Zakat auf dein Vermögen und verfolge den '
          'Hawl.',
      steps: <String>[
        'Gib das zakatpflichtige Vermögen ein, um eine Schätzung zu erhalten.',
        'Lege das Datum fest, an dem dein Vermögen den Nisab erreicht hat, um '
            'den Countdown des Mondjahres zu verfolgen, angezeigt im '
            'Hidschra-Kalender.',
        'Das ist eine Planungshilfe – lass deine Pflicht von einem '
            'qualifizierten Gelehrten bestätigen.',
      ],
    ),
    GuideTopic(
      route: '/markets',
      title: 'Wechselkurse & Märkte',
      summary: 'Aktuelle Wechselkurse und Kryptopreise aus öffentlichen '
          'Quellen.',
      steps: <String>[
        'Kurse werden live abgerufen; jede Zeile zeigt ihre Quelle.',
        'Hat ein Markt keine verlässliche Quelle, steht dort „nicht verfügbar“ '
            '– nie eine erfundene Zahl.',
      ],
    ),
    GuideTopic(
      route: '/assistant',
      title: 'KI-Assistent DGOTIX AI',
      summary: 'Stell Fragen zu deinen Finanzen in einfachen Worten.',
      steps: <String>[
        'Tippe eine Frage ein oder wähle einen Vorschlag; der Assistent '
            'antwortet anhand einer kurzen Übersicht deiner Zahlen.',
        'Die Zahl der Antworten hängt von deinem Tarif ab; du siehst einen '
            'Hinweis, wenn du nah am Limit bist.',
        'Antworten werden automatisch erzeugt – prüfe wichtige Entscheidungen '
            'noch einmal. Die regelbasierten Einblicke unter dem Chat '
            'funktionieren immer, auch ohne KI.',
      ],
    ),
    GuideTopic(
      route: '/plans',
      title: 'Tarife & Abo',
      summary: 'Vergleiche Kostenlos und Pro und verwalte dein Abo.',
      steps: <String>[
        'Die grundlegenden Budgetwerkzeuge sind für immer kostenlos.',
        'Bezahlte Tarife erhöhen die Limits für KI und Cloud-Scans und bieten '
            'zusätzliche Funktionen.',
        'Wenn du ein Abo abschließt, erscheinen oben dein aktueller Tarif und '
            'das Verlängerungsdatum, mit einer Schaltfläche zum Verwalten oder '
            'Kündigen.',
      ],
    ),
    GuideTopic(
      route: '/settings',
      title: 'Einstellungen, Daten & Sicherung',
      summary: 'Richte die App nach deinen Wünschen ein und schütze deine '
          'Daten.',
      steps: <String>[
        'Sprache, Design und Basiswährung findest du unter Darstellung und '
            'Region.',
        'Verwalte deine eigenen Einnahme- und Ausgabenkategorien.',
        'Unter Daten & Sicherung kannst du jederzeit eine vollständige '
            'Sicherung exportieren; wenn du angemeldet bist, werden deine Daten '
            'automatisch zwischen deinen Geräten synchronisiert (auch nach '
            'Offline-Arbeit), und du kannst das ausschalten.',
      ],
    ),
  ];

  // ---- Getting started (Portuguese) ----
  static const List<String> _startPt = <String>[
    'Abra Configurações e escolha o idioma, o tema e a moeda base — todos os '
        'totais do app aparecem nessa moeda.',
    'Adicione suas receitas e despesas (ou leia um recibo) — todo o resto é '
        'calculado a partir delas.',
    'Defina um orçamento mensal para o app dizer quanto ainda resta para '
        'gastar.',
    'Confira o Painel e a Saúde financeira para saber onde você está, depois '
        'adicione metas e dívidas aos poucos.',
  ];

  // ---- Topics (Portuguese) ----
  static const List<GuideTopic> _topicsPt = <GuideTopic>[
    GuideTopic(
      route: '/dashboard',
      title: 'Painel',
      summary:
          'Seu mês num relance: receitas, gastos, poupança e para onde foi o '
          'dinheiro.',
      steps: <String>[
        'Os blocos mostram os totais deste mês na sua moeda base.',
        'Toque numa fatia do detalhamento de gastos para destacar essa '
            'categoria.',
        'Os alertas apontam o que precisa de atenção, como uma categoria acima'
            ' do orçamento ou uma meta urgente.',
        'Sem dados ainda, os blocos mostram “—” — nada é inventado.',
      ],
    ),
    GuideTopic(
      route: '/transactions',
      title: 'Receitas e despesas',
      summary: 'Registre cada movimento de dinheiro — a base de todos os '
          'cálculos do app.',
      steps: <String>[
        'Use o botão de adição rápida para registrar uma receita ou despesa '
            'com valor, categoria, data e observação.',
        'Receitas e Despesas têm cada uma sua tela; Transações mostra as duas '
            'juntas.',
        'Busque na lista para achar qualquer lançamento e toque nele para '
            'editar ou excluir.',
      ],
    ),
    GuideTopic(
      route: '/recurring',
      title: 'Transações recorrentes',
      summary: 'Salário, aluguel e assinaturas adicionados automaticamente na '
          'data.',
      steps: <String>[
        'Ao adicionar uma receita ou despesa, defina “Repetir” como toda '
            'semana, todo mês, a cada 3 meses, a cada 6 meses ou todo ano.',
        'Para um bônus ou comissão de valor variável, ative “O valor muda a '
            'cada vez”: em cada data o app pergunta o valor real em vez de '
            'adicionar uma estimativa.',
        'A cada vencimento, o app adiciona como uma transação normal — mesmo '
            'que você tenha ficado fora, ele põe tudo em dia quando você abrir o'
            ' app de novo.',
        'Na tela Recorrentes, pause, retome, mude o valor ou pare de repetir. '
            'As transações já adicionadas nunca mudam.',
      ],
    ),
    GuideTopic(
      route: '/expenses',
      title: 'Ler um recibo',
      summary: 'Transforme a foto de um recibo numa despesa pronta para salvar.',
      steps: <String>[
        'Na tela Despesas, toque em “Ler recibo” e tire ou escolha uma foto.',
        'O app preenche o estabelecimento, a data, o valor e a categoria — '
            'revise antes de salvar.',
        'A leitura na nuvem depende do seu plano; se um recibo não puder ser '
            'lido, informe a despesa manualmente.',
      ],
    ),
    GuideTopic(
      route: '/budget',
      title: 'Orçamento mensal',
      summary: 'Planeje quanto quer gastar por categoria, mês a mês.',
      steps: <String>[
        'Escolha o ano e o mês no topo — uma tela cobre todos os meses.',
        'Defina um limite para cada categoria que você quer controlar.',
        'As barras de progresso enchem conforme você gasta; uma categoria '
            'acima do limite é sinalizada.',
        'Num plano pago, “Sugerir divisão” reparte sua renda entre as '
            'categorias com base nos seus próprios gastos recentes — revise e '
            'depois aplique.',
      ],
    ),
    GuideTopic(
      route: '/goals',
      title: 'Metas e poupança',
      summary: 'Guarde para algo específico e veja quanto falta.',
      steps: <String>[
        'Crie uma meta com um valor e, se quiser, um prazo.',
        'Registre os aportes conforme poupa; o progresso é atualizado '
            'automaticamente.',
        'Metas perto do prazo aparecem em destaque no Painel.',
      ],
    ),
    GuideTopic(
      route: '/debts',
      title: 'Dívidas e empréstimos',
      summary: 'Acompanhe o que você deve e o que devem a você.',
      steps: <String>[
        'Adicione cada dívida ou empréstimo com o valor e a pessoa ou parte.',
        'Atualize o valor já pago para ver o saldo restante.',
        'As dívidas entram na sua pontuação de Saúde financeira.',
      ],
    ),
    GuideTopic(
      route: '/portfolio',
      title: 'Carteira de projetos',
      summary: 'Planeje projetos maiores em compartimentos de curto, médio e '
          'longo prazo.',
      steps: <String>[
        'Adicione projetos e coloque cada um num prazo.',
        'O financiamento enche os compartimentos em ordem, para você ver quais'
            ' projetos sua poupança cobre primeiro.',
      ],
    ),
    GuideTopic(
      route: '/health',
      title: 'Saúde financeira',
      summary: 'Uma pontuação que resume quão saudáveis estão suas finanças, e '
          'por quê.',
      steps: <String>[
        'A pontuação é calculada no seu aparelho a partir dos seus próprios '
            'dados.',
        'Os fatores principais mostram o que ajuda ou atrapalha — melhore '
            'esses primeiro.',
      ],
    ),
    GuideTopic(
      route: '/reports',
      title: 'Relatórios e análises',
      summary: 'Veja a evolução ao longo do ano e para onde vai seu dinheiro.',
      steps: <String>[
        'Escolha um ano para comparar receitas e despesas mês a mês.',
        'Use os detalhamentos para identificar categorias que crescem com o '
            'tempo.',
      ],
    ),
    GuideTopic(
      route: '/zakat',
      title: 'Zakat',
      summary: 'Estime o Zakat devido sobre seu patrimônio e acompanhe o Hawl.',
      steps: <String>[
        'Informe os bens sujeitos ao Zakat para obter uma estimativa.',
        'Defina a data em que seu patrimônio atingiu o nisab para acompanhar a'
            ' contagem regressiva do ano lunar, mostrada no calendário hégira.',
        'Isto é uma ajuda de planejamento — confirme sua obrigação com um '
            'estudioso qualificado.',
      ],
    ),
    GuideTopic(
      route: '/markets',
      title: 'Câmbio e mercados',
      summary: 'Cotações e preços de cripto ao vivo, de fontes públicas.',
      steps: <String>[
        'As cotações são buscadas ao vivo; cada linha mostra de onde veio.',
        'Quando um mercado não tem fonte confiável, aparece “indisponível” — '
            'nunca um número inventado.',
      ],
    ),
    GuideTopic(
      route: '/assistant',
      title: 'Assistente DGOTIX AI',
      summary: 'Faça perguntas sobre suas finanças em linguagem simples.',
      steps: <String>[
        'Digite uma pergunta ou toque numa sugestão; o assistente responde com'
            ' base num breve resumo dos seus números.',
        'O número de respostas depende do seu plano; você verá um aviso quando'
            ' estiver perto do limite.',
        'As respostas são geradas automaticamente — confira as decisões '
            'importantes. As análises por regras abaixo do chat sempre '
            'funcionam, mesmo sem IA.',
      ],
    ),
    GuideTopic(
      route: '/plans',
      title: 'Planos e assinatura',
      summary: 'Compare Grátis e Pro e gerencie sua assinatura.',
      steps: <String>[
        'As ferramentas básicas de orçamento são gratuitas para sempre.',
        'Os planos pagos aumentam os limites de IA e de leitura na nuvem e '
            'trazem recursos extras.',
        'Se você assinar, seu plano atual e a data de renovação aparecem no '
            'topo, com um botão para gerenciar ou cancelar.',
      ],
    ),
    GuideTopic(
      route: '/settings',
      title: 'Configurações, dados e backup',
      summary: 'Deixe o app do seu jeito e mantenha seus dados seguros.',
      steps: <String>[
        'Idioma, tema e moeda base ficam em Aparência e Região.',
        'Gerencie suas próprias categorias de receita e despesa.',
        'Em Dados e backup, exporte um backup completo quando quiser; com a '
            'conta conectada, seus dados são sincronizados entre seus aparelhos '
            'automaticamente (também depois de usar offline), e você pode '
            'desativar isso.',
      ],
    ),
  ];

  // ---- Getting started (Italian) ----
  static const List<String> _startIt = <String>[
    'Apri le Impostazioni e scegli lingua, tema e valuta base: ogni totale '
        'dell\'app è mostrato in quella valuta.',
    'Aggiungi entrate e spese (o scansiona uno scontrino): tutto il resto si '
        'calcola da lì.',
    'Imposta un budget mensile, così l\'app ti dice quanto puoi ancora '
        'spendere.',
    'Guarda la Panoramica e la Salute finanziaria per capire a che punto sei, '
        'poi aggiungi obiettivi e debiti man mano.',
  ];

  // ---- Topics (Italian) ----
  static const List<GuideTopic> _topicsIt = <GuideTopic>[
    GuideTopic(
      route: '/dashboard',
      title: 'Panoramica',
      summary:
          'Il tuo mese a colpo d\'occhio: entrate, spese, risparmi e dove sono '
          'andati i soldi.',
      steps: <String>[
        'Le schede mostrano i totali di questo mese nella tua valuta base.',
        'Tocca una fetta del dettaglio spese per evidenziare quella categoria.',
        'Gli avvisi ti indicano ciò che richiede attenzione, come una categoria'
            ' oltre il budget o un obiettivo urgente.',
        'Senza dati, le schede mostrano “—”: nulla viene mai inventato.',
      ],
    ),
    GuideTopic(
      route: '/transactions',
      title: 'Entrate e spese',
      summary: 'Registra ogni movimento di denaro: la base di ogni calcolo '
          'dell\'app.',
      steps: <String>[
        'Usa il pulsante di aggiunta rapida per registrare un\'entrata o una '
            'spesa con importo, categoria, data e nota.',
        'Entrate e Spese hanno ciascuna la propria schermata; Transazioni le '
            'mostra insieme.',
        'Cerca nell\'elenco per trovare qualsiasi voce e toccala per '
            'modificarla o eliminarla.',
      ],
    ),
    GuideTopic(
      route: '/recurring',
      title: 'Transazioni ricorrenti',
      summary: 'Stipendio, affitto e abbonamenti aggiunti automaticamente alla '
          'loro data.',
      steps: <String>[
        'Quando aggiungi un\'entrata o una spesa, imposta “Ripeti” su ogni '
            'settimana, mese, 3 mesi, 6 mesi o anno.',
        'Per un premio o una provvigione che cambia, attiva “L\'importo cambia'
            ' ogni volta”: a ogni data l\'app chiede l\'importo reale invece di '
            'aggiungere una stima.',
        'A ogni scadenza l\'app la aggiunge come una transazione normale: anche'
            ' se sei stato via, recupera alla prossima apertura.',
        'Nella schermata Ricorrenti puoi mettere in pausa, riprendere, '
            'cambiare l\'importo o interrompere. Le transazioni già aggiunte non'
            ' cambiano mai.',
      ],
    ),
    GuideTopic(
      route: '/expenses',
      title: 'Scansiona uno scontrino',
      summary: 'Trasforma la foto di uno scontrino in una spesa pronta da '
          'salvare.',
      steps: <String>[
        'Nella schermata Spese, tocca “Scansiona scontrino” e scatta o scegli '
            'una foto.',
        'L\'app compila esercente, data, importo e categoria: controllali prima'
            ' di salvare.',
        'La scansione nel cloud dipende dal tuo piano; se uno scontrino non si '
            'legge, inserisci la spesa a mano.',
      ],
    ),
    GuideTopic(
      route: '/budget',
      title: 'Budget mensile',
      summary: 'Pianifica quanto vuoi spendere per categoria, mese per mese.',
      steps: <String>[
        'Scegli anno e mese in alto: una sola schermata copre ogni mese.',
        'Imposta un limite per ogni categoria che vuoi tenere sotto controllo.',
        'Le barre si riempiono man mano che spendi; una categoria oltre il '
            'limite viene segnalata.',
        'Con un piano a pagamento, “Suggerisci una ripartizione” divide le tue'
            ' entrate tra le categorie in base alle tue spese recenti: '
            'controlla e poi applica.',
      ],
    ),
    GuideTopic(
      route: '/goals',
      title: 'Obiettivi e risparmi',
      summary: 'Risparmia per qualcosa di preciso e vedi quanto ti manca.',
      steps: <String>[
        'Crea un obiettivo con un importo e, se vuoi, una scadenza.',
        'Registra i versamenti mentre risparmi; il progresso si aggiorna da '
            'solo.',
        'Gli obiettivi vicini alla scadenza sono evidenziati nella Panoramica.',
      ],
    ),
    GuideTopic(
      route: '/debts',
      title: 'Debiti e prestiti',
      summary: 'Tieni traccia di quanto devi e di quanto ti devono.',
      steps: <String>[
        'Aggiungi ogni debito o prestito con l\'importo e la persona o '
            'controparte.',
        'Aggiorna l\'importo già pagato per vedere il residuo.',
        'I debiti contano nel tuo punteggio di Salute finanziaria.',
      ],
    ),
    GuideTopic(
      route: '/portfolio',
      title: 'Portafoglio progetti',
      summary: 'Pianifica i progetti più grandi in comparti a breve, medio e '
          'lungo termine.',
      steps: <String>[
        'Aggiungi i progetti e colloca ciascuno in un orizzonte temporale.',
        'Il finanziamento riempie i comparti in ordine, così vedi quali '
            'progetti i tuoi risparmi coprono per primi.',
      ],
    ),
    GuideTopic(
      route: '/health',
      title: 'Salute finanziaria',
      summary: 'Un punteggio che riassume quanto sono sane le tue finanze, e '
          'perché.',
      steps: <String>[
        'Il punteggio è calcolato sul tuo dispositivo dai tuoi dati.',
        'I fattori principali mostrano cosa aiuta o pesa: migliora prima '
            'quelli.',
      ],
    ),
    GuideTopic(
      route: '/reports',
      title: 'Report e analisi',
      summary: 'Guarda l\'andamento dell\'anno e dove vanno i tuoi soldi.',
      steps: <String>[
        'Scegli un anno per confrontare entrate e spese mese per mese.',
        'Usa i dettagli per individuare le categorie che crescono nel tempo.',
      ],
    ),
    GuideTopic(
      route: '/zakat',
      title: 'Zakat',
      summary: 'Stima la Zakat dovuta sul tuo patrimonio e segui lo Hawl.',
      steps: <String>[
        'Inserisci i beni soggetti a Zakat per ottenere una stima.',
        'Imposta la data in cui il patrimonio ha raggiunto il nisab per '
            'seguire il conto alla rovescia dell\'anno lunare, mostrato secondo '
            'il calendario dell\'Egira.',
        'È un aiuto alla pianificazione: verifica il tuo obbligo con un '
            'sapiente qualificato.',
      ],
    ),
    GuideTopic(
      route: '/markets',
      title: 'Cambi e mercati',
      summary: 'Cambi valute e prezzi delle cripto in tempo reale da fonti '
          'pubbliche.',
      steps: <String>[
        'I cambi vengono scaricati in tempo reale; ogni riga indica la fonte.',
        'Quando un mercato non ha una fonte affidabile, si legge “non '
            'disponibile”: mai un numero inventato.',
      ],
    ),
    GuideTopic(
      route: '/assistant',
      title: 'Assistente DGOTIX AI',
      summary: 'Fai domande sulle tue finanze con parole semplici.',
      steps: <String>[
        'Scrivi una domanda o tocca un suggerimento; l\'assistente risponde in'
            ' base a un breve riepilogo delle tue cifre.',
        'Il numero di risposte dipende dal tuo piano; vedrai un avviso quando '
            'sei vicino al limite.',
        'Le risposte sono generate automaticamente: verifica le decisioni '
            'importanti. Le analisi basate su regole sotto la chat funzionano '
            'sempre, anche senza IA.',
      ],
    ),
    GuideTopic(
      route: '/plans',
      title: 'Piani e abbonamento',
      summary: 'Confronta Gratis e Pro e gestisci il tuo abbonamento.',
      steps: <String>[
        'Gli strumenti di budget di base sono gratuiti per sempre.',
        'I piani a pagamento alzano i limiti di IA e scansioni cloud e '
            'aggiungono funzioni extra.',
        'Se ti abboni, in alto compaiono il piano attuale e la data di '
            'rinnovo, con un pulsante per gestire o annullare.',
      ],
    ),
    GuideTopic(
      route: '/settings',
      title: 'Impostazioni, dati e backup',
      summary: 'Rendi l\'app tua e tieni al sicuro i tuoi dati.',
      steps: <String>[
        'Lingua, tema e valuta base si trovano in Aspetto e Regione.',
        'Gestisci le tue categorie di entrata e di spesa.',
        'In Dati e backup puoi esportare un backup completo quando vuoi; con '
            'l\'accesso, i dati si sincronizzano automaticamente tra i tuoi '
            'dispositivi (anche dopo aver lavorato offline), e puoi '
            'disattivarlo.',
      ],
    ),
  ];

  // ---- Getting started (Dutch) ----
  static const List<String> _startNl = <String>[
    'Open Instellingen en kies je taal, thema en basisvaluta — elk totaal in de'
        ' app wordt in die valuta getoond.',
    'Voeg je inkomsten en uitgaven toe (of scan een bon) — al het andere wordt '
        'daaruit berekend.',
    'Stel een maandbudget in, zodat de app je vertelt hoeveel je nog kunt '
        'uitgeven.',
    'Bekijk het Overzicht en je Financiële gezondheid om te zien waar je staat,'
        ' en voeg daarna gaandeweg doelen en schulden toe.',
  ];

  // ---- Topics (Dutch) ----
  static const List<GuideTopic> _topicsNl = <GuideTopic>[
    GuideTopic(
      route: '/dashboard',
      title: 'Overzicht',
      summary:
          'Je maand in één oogopslag: inkomsten, uitgaven, spaargeld en waar '
          'het geld naartoe ging.',
      steps: <String>[
        'De tegels tonen de totalen van deze maand in je basisvaluta.',
        'Tik op een deel van de uitgavenverdeling om die categorie te '
            'markeren.',
        'Meldingen wijzen je op wat aandacht nodig heeft, zoals een categorie '
            'boven budget of een dringend doel.',
        'Zonder gegevens tonen de tegels “—” — er wordt nooit iets verzonnen.',
      ],
    ),
    GuideTopic(
      route: '/transactions',
      title: 'Inkomsten en uitgaven',
      summary: 'Registreer elke geldbeweging — de basis van elke berekening in '
          'de app.',
      steps: <String>[
        'Gebruik de knop voor snel toevoegen om een inkomen of uitgave te '
            'registreren met bedrag, categorie, datum en notitie.',
        'Inkomsten en Uitgaven hebben elk een eigen scherm; Transacties toont '
            'ze samen.',
        'Doorzoek de lijst om een post te vinden, en tik erop om hem te '
            'bewerken of te verwijderen.',
      ],
    ),
    GuideTopic(
      route: '/recurring',
      title: 'Terugkerende transacties',
      summary: 'Salaris, huur en abonnementen automatisch toegevoegd op hun '
          'datum.',
      steps: <String>[
        'Zet bij het toevoegen van een inkomen of uitgave “Herhalen” op elke '
            'week, maand, 3 maanden, 6 maanden of elk jaar.',
        'Voor een bonus of provisie die wisselt, zet je “Het bedrag verandert '
            'elke keer” aan: op elke datum vraagt de app het echte bedrag in '
            'plaats van een schatting toe te voegen.',
        'Elke keer dat het verschuldigd is, voegt de app het toe als gewone '
            'transactie — ook als je weg was, haalt hij het in zodra je de app '
            'weer opent.',
        'Op het scherm Terugkerend kun je pauzeren, hervatten, het bedrag '
            'wijzigen of stoppen. Al toegevoegde transacties veranderen nooit.',
      ],
    ),
    GuideTopic(
      route: '/expenses',
      title: 'Een bon scannen',
      summary: 'Maak van een foto van een bon een uitgave die klaar is om op te'
          ' slaan.',
      steps: <String>[
        'Tik op het scherm Uitgaven op “Bon scannen” en maak of kies een foto.',
        'De app vult winkel, datum, bedrag en categorie in — controleer ze voor'
            ' het opslaan.',
        'Scannen in de cloud hangt af van je abonnement; als een bon niet te '
            'lezen is, vul de uitgave dan zelf in.',
      ],
    ),
    GuideTopic(
      route: '/budget',
      title: 'Maandbudget',
      summary: 'Plan hoeveel je per categorie wilt uitgeven, maand na maand.',
      steps: <String>[
        'Kies bovenaan het jaar en de maand — één scherm dekt elke maand.',
        'Stel een limiet in voor elke categorie die je in de hand wilt houden.',
        'Voortgangsbalken vullen zich als je uitgeeft; een categorie boven de '
            'limiet wordt gemarkeerd.',
        'Met een betaald abonnement verdeelt “Verdeling voorstellen” je inkomen'
            ' over de categorieën op basis van je eigen recente uitgaven — '
            'controleer het en pas het daarna toe.',
      ],
    ),
    GuideTopic(
      route: '/goals',
      title: 'Doelen en sparen',
      summary: 'Spaar voor iets specifieks en zie hoe dichtbij je bent.',
      steps: <String>[
        'Maak een doel aan met een bedrag en eventueel een deadline.',
        'Registreer inleggen terwijl je spaart; de voortgang wordt automatisch'
            ' bijgewerkt.',
        'Doelen vlak voor hun deadline worden gemarkeerd in het Overzicht.',
      ],
    ),
    GuideTopic(
      route: '/debts',
      title: 'Schulden en leningen',
      summary: 'Houd bij wat je verschuldigd bent en wat anderen jou schuldig '
          'zijn.',
      steps: <String>[
        'Voeg elke schuld of lening toe met het bedrag en de persoon of partij.',
        'Werk het al betaalde bedrag bij om het restant te zien.',
        'Schulden tellen mee in je score voor financiële gezondheid.',
      ],
    ),
    GuideTopic(
      route: '/portfolio',
      title: 'Projectportfolio',
      summary: 'Plan grotere projecten in vakken voor korte, middellange en '
          'lange termijn.',
      steps: <String>[
        'Voeg projecten toe en plaats elk project in een termijn.',
        'De financiering vult de vakken op volgorde, zodat je ziet welke '
            'projecten je spaargeld als eerste dekt.',
      ],
    ),
    GuideTopic(
      route: '/health',
      title: 'Financiële gezondheid',
      summary: 'Een score die samenvat hoe gezond je financiën zijn, en waarom.',
      steps: <String>[
        'De score wordt op je apparaat berekend uit je eigen gegevens.',
        'De belangrijkste factoren tonen wat helpt of schaadt — verbeter die '
            'eerst.',
      ],
    ),
    GuideTopic(
      route: '/reports',
      title: 'Rapporten en analyses',
      summary: 'Bekijk het verloop over het jaar en waar je geld naartoe gaat.',
      steps: <String>[
        'Kies een jaar om inkomsten en uitgaven per maand te vergelijken.',
        'Gebruik de uitsplitsingen om categorieën te zien die in de loop van de'
            ' tijd groeien.',
      ],
    ),
    GuideTopic(
      route: '/zakat',
      title: 'Zakat',
      summary: 'Schat de zakat over je vermogen en volg de hawl.',
      steps: <String>[
        'Vul het zakatplichtige vermogen in om een schatting te krijgen.',
        'Stel de datum in waarop je vermogen de nisab bereikte om het aftellen '
            'van het maanjaar te volgen, getoond in de Hijri-kalender.',
        'Dit is een planningshulpmiddel — laat je verplichting bevestigen door '
            'een bevoegde geleerde.',
      ],
    ),
    GuideTopic(
      route: '/markets',
      title: 'Wisselkoersen en markten',
      summary: 'Actuele wisselkoersen en cryptoprijzen uit openbare bronnen.',
      steps: <String>[
        'Koersen worden live opgehaald; elke regel toont de bron.',
        'Als een markt geen betrouwbare bron heeft, staat er “niet '
            'beschikbaar” — nooit een verzonnen getal.',
      ],
    ),
    GuideTopic(
      route: '/assistant',
      title: 'AI-assistent DGOTIX AI',
      summary: 'Stel vragen over je financiën in gewone taal.',
      steps: <String>[
        'Typ een vraag of tik op een suggestie; de assistent antwoordt op basis'
            ' van een korte samenvatting van je cijfers.',
        'Het aantal antwoorden hangt af van je abonnement; je ziet een melding '
            'als je dicht bij de limiet zit.',
        'Antwoorden worden automatisch gemaakt — controleer belangrijke '
            'beslissingen. De op regels gebaseerde inzichten onder de chat '
            'werken altijd, ook zonder AI.',
      ],
    ),
    GuideTopic(
      route: '/plans',
      title: 'Abonnementen',
      summary: 'Vergelijk Gratis en Pro, en beheer je abonnement.',
      steps: <String>[
        'De basisbudgettools zijn voor altijd gratis.',
        'Betaalde abonnementen verhogen de limieten voor AI en cloudscans en '
            'voegen extra functies toe.',
        'Als je een abonnement neemt, staan bovenaan je huidige abonnement en '
            'de verlengingsdatum, met een knop om te beheren of op te zeggen.',
      ],
    ),
    GuideTopic(
      route: '/settings',
      title: 'Instellingen, gegevens en back-up',
      summary: 'Maak de app van jou en houd je gegevens veilig.',
      steps: <String>[
        'Taal, thema en basisvaluta vind je onder Weergave en Regio.',
        'Beheer je eigen inkomsten- en uitgavencategorieën.',
        'Bij Gegevens en back-up exporteer je op elk moment een volledige '
            'back-up; als je bent ingelogd, worden je gegevens automatisch '
            'tussen je apparaten gesynchroniseerd (ook na offline werken), en '
            'dat kun je uitzetten.',
      ],
    ),
  ];

  // ---- Getting started (Bosnian) ----
  static const List<String> _startBs = <String>[
    'Otvori Postavke i izaberi jezik, temu i osnovnu valutu — svaki zbir u '
        'aplikaciji prikazuje se u toj valuti.',
    'Dodaj prihode i troškove (ili skeniraj račun) — sve ostalo se računa iz '
        'njih.',
    'Postavi mjesečni budžet da ti aplikacija kaže koliko još možeš potrošiti.',
    'Pogledaj Pregled i Finansijsko zdravlje da vidiš gdje si, pa postepeno '
        'dodaj ciljeve i dugove.',
  ];

  // ---- Topics (Bosnian) ----
  static const List<GuideTopic> _topicsBs = <GuideTopic>[
    GuideTopic(
      route: '/dashboard',
      title: 'Pregled',
      summary:
          'Tvoj mjesec na prvi pogled: prihodi, troškovi, štednja i gdje je '
          'novac otišao.',
      steps: <String>[
        'Pločice prikazuju zbirove ovog mjeseca u tvojoj osnovnoj valuti.',
        'Dodirni dio raščlambe troškova da istakneš tu kategoriju.',
        'Upozorenja te upućuju na ono što traži pažnju, npr. kategoriju preko '
            'budžeta ili hitan cilj.',
        'Bez podataka pločice prikazuju „—“ — ništa se nikad ne izmišlja.',
      ],
    ),
    GuideTopic(
      route: '/transactions',
      title: 'Prihodi i troškovi',
      summary: 'Bilježi svako kretanje novca — osnovu svakog izračuna u '
          'aplikaciji.',
      steps: <String>[
        'Dugmetom za brzo dodavanje zabilježi prihod ili trošak s iznosom, '
            'kategorijom, datumom i bilješkom.',
        'Prihodi i Troškovi imaju svaki svoj ekran; Transakcije prikazuju oboje'
            ' zajedno.',
        'Pretraži listu da nađeš bilo koji unos i dodirni ga da ga urediš ili '
            'obrišeš.',
      ],
    ),
    GuideTopic(
      route: '/recurring',
      title: 'Ponavljajuće transakcije',
      summary: 'Plata, kirija i pretplate dodaju se automatski na svoj datum.',
      steps: <String>[
        'Pri dodavanju prihoda ili troška postavi „Ponavljaj“ na svake sedmice,'
            ' mjeseca, 3 mjeseca, 6 mjeseci ili godine.',
        'Za bonus ili proviziju čiji se iznos mijenja uključi „Iznos se svaki '
            'put mijenja“: na svaki datum aplikacija pita za stvarni iznos umjesto'
            ' da doda procjenu.',
        'Svaki put kad dospije, aplikacija ga dodaje kao običnu transakciju — '
            'čak i ako te nije bilo, nadoknadi sve kad ponovo otvoriš aplikaciju.',
        'Na ekranu Ponavljajuće možeš pauzirati, nastaviti, promijeniti iznos '
            'ili prestati ponavljati. Već dodane transakcije se nikad ne mijenjaju.',
      ],
    ),
    GuideTopic(
      route: '/expenses',
      title: 'Skeniraj račun',
      summary: 'Pretvori fotografiju računa u trošak spreman za čuvanje.',
      steps: <String>[
        'Na ekranu Troškovi dodirni „Skeniraj račun“ i fotografiši ili izaberi '
            'sliku.',
        'Aplikacija popunjava trgovca, datum, iznos i kategoriju — pregledaj ih '
            'prije čuvanja.',
        'Skeniranje u oblaku zavisi od tvog paketa; ako se račun ne može '
            'pročitati, upiši trošak ručno.',
      ],
    ),
    GuideTopic(
      route: '/budget',
      title: 'Mjesečni budžet',
      summary: 'Planiraj koliko želiš potrošiti po kategoriji, mjesec po mjesec.',
      steps: <String>[
        'Izaberi godinu i mjesec na vrhu — jedan ekran pokriva svaki mjesec.',
        'Postavi granicu za svaku kategoriju koju želiš kontrolisati.',
        'Trake napretka se pune kako trošiš; kategorija preko granice se '
            'označava.',
        'U plaćenom paketu „Predloži raspodjelu“ dijeli tvoj prihod po '
            'kategorijama na osnovu tvoje nedavne potrošnje — pregledaj, pa '
            'primijeni.',
      ],
    ),
    GuideTopic(
      route: '/goals',
      title: 'Ciljevi i štednja',
      summary: 'Štedi za nešto određeno i vidi koliko ti je još ostalo.',
      steps: <String>[
        'Napravi cilj s iznosom i, po želji, rokom.',
        'Bilježi uplate dok štediš; napredak se ažurira automatski.',
        'Ciljevi blizu roka istaknuti su na Pregledu.',
      ],
    ),
    GuideTopic(
      route: '/debts',
      title: 'Dugovi i krediti',
      summary: 'Prati šta duguješ i šta drugi duguju tebi.',
      steps: <String>[
        'Dodaj svaki dug ili kredit s iznosom i osobom ili stranom.',
        'Ažuriraj dosad plaćeni iznos da vidiš preostalo.',
        'Dugovi utiču na tvoju ocjenu finansijskog zdravlja.',
      ],
    ),
    GuideTopic(
      route: '/portfolio',
      title: 'Portfolio projekata',
      summary: 'Planiraj veće projekte u kratkoročnim, srednjoročnim i '
          'dugoročnim pregradama.',
      steps: <String>[
        'Dodaj projekte i smjesti svaki u vremenski okvir.',
        'Finansiranje puni pregrade redom, pa vidiš koje projekte tvoja '
            'štednja pokriva prve.',
      ],
    ),
    GuideTopic(
      route: '/health',
      title: 'Finansijsko zdravlje',
      summary: 'Ocjena koja sažima koliko su zdrave tvoje finansije, i zašto.',
      steps: <String>[
        'Ocjena se računa na tvom uređaju iz tvojih podataka.',
        'Ključni faktori pokazuju šta pomaže, a šta odmaže — prvo poboljšaj '
            'njih.',
      ],
    ),
    GuideTopic(
      route: '/reports',
      title: 'Izvještaji i analize',
      summary: 'Pogledaj trendove kroz godinu i gdje ide tvoj novac.',
      steps: <String>[
        'Izaberi godinu da porediš prihode i troškove mjesec po mjesec.',
        'Koristi raščlambe da uočiš kategorije koje vremenom rastu.',
      ],
    ),
    GuideTopic(
      route: '/zakat',
      title: 'Zekat',
      summary: 'Procijeni zekat na svoju imovinu i prati hawl.',
      steps: <String>[
        'Upiši imovinu podložnu zekatu da dobiješ procjenu.',
        'Postavi datum kada je imovina dostigla nisab da pratiš odbrojavanje '
            'lunarne godine, prikazano po hidžretskom kalendaru.',
        'Ovo je pomoć za planiranje — svoju obavezu provjeri s kvalifikovanim '
            'alimom.',
      ],
    ),
    GuideTopic(
      route: '/markets',
      title: 'Kursevi i tržišta',
      summary: 'Aktuelni kursevi i cijene kripta iz javnih izvora.',
      steps: <String>[
        'Kursevi se preuzimaju uživo; svaki red pokazuje izvor.',
        'Kad tržište nema pouzdan izvor, piše „nije dostupno“ — nikad '
            'izmišljen broj.',
      ],
    ),
    GuideTopic(
      route: '/assistant',
      title: 'DGOTIX AI asistent',
      summary: 'Postavljaj pitanja o svojim finansijama običnim jezikom.',
      steps: <String>[
        'Upiši pitanje ili dodirni prijedlog; asistent odgovara na osnovu '
            'kratkog sažetka tvojih brojki.',
        'Broj odgovora zavisi od tvog paketa; vidjet ćeš napomenu kad se '
            'približiš granici.',
        'Odgovori se prave automatski — provjeri važne odluke. Uvidi zasnovani'
            ' na pravilima ispod razgovora uvijek rade, i bez AI-a.',
      ],
    ),
    GuideTopic(
      route: '/plans',
      title: 'Paketi i pretplata',
      summary: 'Uporedi Besplatno i Pro i upravljaj pretplatom.',
      steps: <String>[
        'Osnovni alati za budžet su zauvijek besplatni.',
        'Plaćeni paketi povećavaju ograničenja za AI i skeniranje u oblaku i '
            'dodaju funkcije.',
        'Ako se pretplatiš, trenutni paket i datum obnove pojavljuju se na '
            'vrhu, s dugmetom za upravljanje ili otkazivanje.',
      ],
    ),
    GuideTopic(
      route: '/settings',
      title: 'Postavke, podaci i backup',
      summary: 'Prilagodi aplikaciju sebi i čuvaj svoje podatke.',
      steps: <String>[
        'Jezik, tema i osnovna valuta su pod Izgled i Regija.',
        'Upravljaj vlastitim kategorijama prihoda i troškova.',
        'U Podaci i backup izvezi puni backup bilo kada; kad si prijavljen, '
            'podaci se automatski sinhronizuju između uređaja (i nakon rada bez '
            'mreže), a to možeš isključiti.',
      ],
    ),
  ];

  // ---- Getting started (Albanian) ----
  static const List<String> _startSq = <String>[
    'Hap Cilësimet dhe zgjidh gjuhën, temën dhe monedhën bazë — çdo total në '
        'aplikacion shfaqet në atë monedhë.',
    'Shto të ardhurat dhe shpenzimet (ose skano një faturë) — gjithçka tjetër '
        'llogaritet prej tyre.',
    'Vendos një buxhet mujor që aplikacioni të të tregojë sa të mbetet për të '
        'shpenzuar.',
    'Shiko Përmbledhjen dhe Shëndetin financiar për të ditur ku je, pastaj '
        'shto qëllime dhe borxhe gradualisht.',
  ];

  // ---- Topics (Albanian) ----
  static const List<GuideTopic> _topicsSq = <GuideTopic>[
    GuideTopic(
      route: '/dashboard',
      title: 'Përmbledhja',
      summary:
          'Muaji yt me një shikim: të ardhurat, shpenzimet, kursimet dhe ku '
          'shkuan paratë.',
      steps: <String>[
        'Pllakat tregojnë totalet e këtij muaji në monedhën tënde bazë.',
        'Prek një pjesë të ndarjes së shpenzimeve për të theksuar atë '
            'kategori.',
        'Njoftimet të tregojnë çfarë kërkon vëmendje, si një kategori mbi '
            'buxhet ose një qëllim urgjent.',
        'Pa të dhëna, pllakat tregojnë “—” — asgjë nuk shpiket kurrë.',
      ],
    ),
    GuideTopic(
      route: '/transactions',
      title: 'Të ardhurat dhe shpenzimet',
      summary: 'Regjistro çdo lëvizje parash — bazën e çdo llogaritjeje në '
          'aplikacion.',
      steps: <String>[
        'Përdor butonin e shtimit të shpejtë për të regjistruar një të ardhur '
            'ose shpenzim me shumë, kategori, datë dhe shënim.',
        'Të ardhurat dhe Shpenzimet kanë secila ekranin e vet; Transaksionet i'
            ' tregon të dyja bashkë.',
        'Kërko në listë për të gjetur çdo regjistrim dhe prek atë për ta '
            'ndryshuar ose fshirë.',
      ],
    ),
    GuideTopic(
      route: '/recurring',
      title: 'Transaksione periodike',
      summary: 'Rroga, qiraja dhe abonimet shtohen automatikisht në datën e '
          'tyre.',
      steps: <String>[
        'Kur shton një të ardhur ose shpenzim, vendos “Përsërit” çdo javë, '
            'muaj, 3 muaj, 6 muaj ose vit.',
        'Për një bonus ose komision me shumë të ndryshueshme, aktivizo “Shuma '
            'ndryshon çdo herë”: në çdo datë aplikacioni pyet për shumën reale '
            'në vend që të shtojë një vlerësim.',
        'Sa herë që skadon, aplikacioni e shton si transaksion të zakonshëm — '
            'edhe nëse ke munguar, i plotëson kur ta hapësh përsëri.',
        'Te ekrani Periodike mund të pezullosh, të vazhdosh, të ndryshosh '
            'shumën ose të ndalosh përsëritjen. Transaksionet e shtuara nuk '
            'ndryshojnë kurrë.',
      ],
    ),
    GuideTopic(
      route: '/expenses',
      title: 'Skano një faturë',
      summary: 'Ktheje foton e një fature në një shpenzim gati për t\'u ruajtur.',
      steps: <String>[
        'Te ekrani Shpenzimet, prek “Skano faturën” dhe bëj ose zgjidh një '
            'foto.',
        'Aplikacioni plotëson tregtarin, datën, shumën dhe kategorinë — '
            'rishikoji para se të ruash.',
        'Skanimi në cloud varet nga paketa; nëse një faturë nuk lexohet, '
            'shkruaje shpenzimin me dorë.',
      ],
    ),
    GuideTopic(
      route: '/budget',
      title: 'Buxheti mujor',
      summary: 'Planifiko sa do të shpenzosh për kategori, muaj pas muaji.',
      steps: <String>[
        'Zgjidh vitin dhe muajin lart — një ekran mbulon çdo muaj.',
        'Vendos një kufi për çdo kategori që do të kontrollosh.',
        'Shiritat e progresit mbushen ndërsa shpenzon; një kategori mbi kufi '
            'shënohet.',
        'Në një paketë me pagesë, “Sugjero ndarjen” i ndan të ardhurat mes '
            'kategorive bazuar në shpenzimet e tua të fundit — rishikoje, pastaj'
            ' apliko.',
      ],
    ),
    GuideTopic(
      route: '/goals',
      title: 'Qëllimet dhe kursimet',
      summary: 'Kurse për diçka të caktuar dhe shiko sa afër je.',
      steps: <String>[
        'Krijo një qëllim me një shumë dhe, nëse do, një afat.',
        'Regjistro kontributet ndërsa kursen; progresi përditësohet '
            'automatikisht.',
        'Qëllimet afër afatit theksohen te Përmbledhja.',
      ],
    ),
    GuideTopic(
      route: '/debts',
      title: 'Borxhet dhe huatë',
      summary: 'Ndiq sa detyrohesh dhe sa të detyrohen të tjerët.',
      steps: <String>[
        'Shto çdo borxh ose hua me shumën dhe personin ose palën.',
        'Përditëso shumën e paguar deri tani për të parë mbetjen.',
        'Borxhet ndikojnë në pikët e Shëndetit financiar.',
      ],
    ),
    GuideTopic(
      route: '/portfolio',
      title: 'Portofoli i projekteve',
      summary: 'Planifiko projektet më të mëdha në ndarje afatshkurtra, '
          'afatmesme dhe afatgjata.',
      steps: <String>[
        'Shto projekte dhe vendos secilin në një afat.',
        'Financimi i mbush ndarjet me radhë, kështu sheh cilat projekte i '
            'mbulojnë kursimet e tua të parat.',
      ],
    ),
    GuideTopic(
      route: '/health',
      title: 'Shëndeti financiar',
      summary: 'Një pikëzim që përmbledh sa të shëndetshme janë financat e '
          'tua, dhe pse.',
      steps: <String>[
        'Pikët llogariten në pajisjen tënde nga të dhënat e tua.',
        'Faktorët kryesorë tregojnë çfarë ndihmon apo dëmton — përmirëso ata '
            'të parët.',
      ],
    ),
    GuideTopic(
      route: '/reports',
      title: 'Raporte dhe analiza',
      summary: 'Shiko ecurinë gjatë vitit dhe ku shkojnë paratë.',
      steps: <String>[
        'Zgjidh një vit për të krahasuar të ardhurat dhe shpenzimet muaj pas '
            'muaji.',
        'Përdor ndarjet për të dalluar kategoritë që rriten me kohën.',
      ],
    ),
    GuideTopic(
      route: '/zakat',
      title: 'Zekati',
      summary: 'Vlerëso zekatin mbi pasurinë tënde dhe ndiq havlin.',
      steps: <String>[
        'Shkruaj pasuritë e zekatueshme për të marrë një vlerësim.',
        'Vendos datën kur pasuria arriti nisabin për të ndjekur numërimin '
            'mbrapsht të vitit hënor, në kalendarin hixhri.',
        'Kjo është ndihmë planifikimi — konfirmo detyrimin me një dijetar të '
            'kualifikuar.',
      ],
    ),
    GuideTopic(
      route: '/markets',
      title: 'Kurset dhe tregjet',
      summary: 'Kurse këmbimi dhe çmime kripto në kohë reale nga burime '
          'publike.',
      steps: <String>[
        'Kurset merren në kohë reale; çdo rresht tregon burimin.',
        'Kur një treg nuk ka burim të besueshëm, shkruhet “nuk është i '
            'disponueshëm” — kurrë një numër i shpikur.',
      ],
    ),
    GuideTopic(
      route: '/assistant',
      title: 'Asistenti DGOTIX AI',
      summary: 'Bëj pyetje për financat e tua me fjalë të thjeshta.',
      steps: <String>[
        'Shkruaj një pyetje ose prek një sugjerim; asistenti përgjigjet bazuar'
            ' në një përmbledhje të shkurtër të shifrave të tua.',
        'Numri i përgjigjeve varet nga paketa; do të shohësh një shënim kur je'
            ' afër kufirit.',
        'Përgjigjet krijohen automatikisht — kontrollo vendimet e rëndësishme.'
            ' Vështrimet me rregulla poshtë bisedës funksionojnë gjithmonë, edhe'
            ' pa AI.',
      ],
    ),
    GuideTopic(
      route: '/plans',
      title: 'Paketat dhe abonimi',
      summary: 'Krahaso Falas dhe Pro dhe menaxho abonimin.',
      steps: <String>[
        'Mjetet bazë të buxhetit janë falas përgjithmonë.',
        'Paketat me pagesë rrisin kufijtë e AI dhe skanimeve në cloud dhe '
            'shtojnë funksione.',
        'Nëse abonohesh, paketa aktuale dhe data e rinovimit shfaqen lart, me '
            'një buton për ta menaxhuar ose anuluar.',
      ],
    ),
    GuideTopic(
      route: '/settings',
      title: 'Cilësimet, të dhënat dhe kopja rezervë',
      summary: 'Bëje aplikacionin tëndin dhe mbaji të sigurta të dhënat.',
      steps: <String>[
        'Gjuha, tema dhe monedha bazë janë te Pamja dhe Rajoni.',
        'Menaxho kategoritë e tua të të ardhurave dhe shpenzimeve.',
        'Te Të dhënat dhe kopja rezervë, eksporto një kopje të plotë kur të '
            'duash; kur je i identifikuar, të dhënat sinkronizohen automatikisht'
            ' mes pajisjeve (edhe pas punës offline) dhe mund ta çaktivizosh.',
      ],
    ),
  ];

  // ---- Getting started (Russian) ----
  static const List<String> _startRu = <String>[
    'Откройте «Настройки» и выберите язык, тему и основную валюту — все '
        'итоги в приложении показываются в этой валюте.',
    'Добавьте доходы и расходы (или отсканируйте чек) — всё остальное '
        'рассчитывается из них.',
    'Задайте бюджет на месяц, чтобы приложение подсказывало, сколько ещё '
        'можно потратить.',
    'Загляните в «Обзор» и «Финансовое здоровье», чтобы понять, где вы '
        'находитесь, а затем постепенно добавляйте цели и долги.',
  ];

  // ---- Topics (Russian) ----
  static const List<GuideTopic> _topicsRu = <GuideTopic>[
    GuideTopic(
      route: '/dashboard',
      title: 'Обзор',
      summary:
          'Ваш месяц с первого взгляда: доходы, расходы, накопления и куда '
          'ушли деньги.',
      steps: <String>[
        'Плитки показывают итоги этого месяца в основной валюте.',
        'Нажмите на сектор в разбивке расходов, чтобы выделить эту категорию.',
        'Уведомления подсказывают, что требует внимания, например категорию '
            'сверх бюджета или срочную цель.',
        'Пока данных нет, плитки показывают «—» — ничего не выдумывается.',
      ],
    ),
    GuideTopic(
      route: '/transactions',
      title: 'Доходы и расходы',
      summary: 'Записывайте каждое движение денег — основу всех расчётов в '
          'приложении.',
      steps: <String>[
        'Кнопкой быстрого добавления записывайте доход или расход с суммой, '
            'категорией, датой и заметкой.',
        'У доходов и расходов свои экраны; «Операции» показывают их вместе.',
        'Ищите в списке любую запись и нажимайте на неё, чтобы изменить или '
            'удалить.',
      ],
    ),
    GuideTopic(
      route: '/recurring',
      title: 'Повторяющиеся операции',
      summary: 'Зарплата, аренда и подписки добавляются автоматически в свой '
          'день.',
      steps: <String>[
        'При добавлении дохода или расхода выберите «Повтор»: каждую неделю, '
            'месяц, 3 месяца, 6 месяцев или год.',
        'Для премии или комиссии с меняющейся суммой включите «Сумма каждый '
            'раз разная»: в каждую дату приложение спросит фактическую сумму, '
            'а не добавит примерную.',
        'Когда наступает срок, приложение добавляет обычную операцию — даже '
            'если вас не было, оно наверстает при следующем открытии.',
        'На экране «Повторяющиеся» можно приостановить, возобновить, изменить '
            'сумму или прекратить повтор. Уже добавленные операции не меняются.',
      ],
    ),
    GuideTopic(
      route: '/expenses',
      title: 'Сканирование чека',
      summary: 'Превратите фото чека в готовый к сохранению расход.',
      steps: <String>[
        'На экране «Расходы» нажмите «Сканировать чек» и сделайте или '
            'выберите фото.',
        'Приложение заполнит продавца, дату, сумму и категорию — проверьте '
            'их перед сохранением.',
        'Облачное сканирование зависит от тарифа; если чек не читается, '
            'введите расход вручную.',
      ],
    ),
    GuideTopic(
      route: '/budget',
      title: 'Бюджет на месяц',
      summary: 'Планируйте, сколько хотите тратить по каждой категории, месяц '
          'за месяцем.',
      steps: <String>[
        'Выберите год и месяц вверху — один экран охватывает все месяцы.',
        'Задайте лимит для каждой категории, которую хотите контролировать.',
        'Полосы прогресса заполняются по мере трат; категория сверх лимита '
            'помечается.',
        'В платном тарифе «Предложить распределение» делит доход между '
            'категориями по вашим недавним тратам — проверьте и примените.',
      ],
    ),
    GuideTopic(
      route: '/goals',
      title: 'Цели и накопления',
      summary: 'Копите на что-то конкретное и смотрите, сколько осталось.',
      steps: <String>[
        'Создайте цель с целевой суммой и, при желании, сроком.',
        'Записывайте пополнения по мере накопления; прогресс обновляется '
            'автоматически.',
        'Цели с близким сроком выделяются на «Обзоре».',
      ],
    ),
    GuideTopic(
      route: '/debts',
      title: 'Долги и займы',
      summary: 'Следите за тем, сколько должны вы и сколько должны вам.',
      steps: <String>[
        'Добавьте каждый долг или заём с суммой и человеком или стороной.',
        'Обновляйте выплаченную сумму, чтобы видеть остаток.',
        'Долги учитываются в оценке финансового здоровья.',
      ],
    ),
    GuideTopic(
      route: '/portfolio',
      title: 'Портфель проектов',
      summary: 'Планируйте крупные проекты в краткосрочном, среднесрочном и '
          'долгосрочном отсеках.',
      steps: <String>[
        'Добавляйте проекты и относите каждый к своему горизонту.',
        'Финансирование заполняет отсеки по порядку, поэтому видно, какие '
            'проекты ваши накопления покроют первыми.',
      ],
    ),
    GuideTopic(
      route: '/health',
      title: 'Финансовое здоровье',
      summary: 'Оценка, которая показывает, насколько здоровы ваши финансы, '
          'и почему.',
      steps: <String>[
        'Оценка рассчитывается на вашем устройстве по вашим собственным '
            'данным.',
        'Ключевые факторы показывают, что помогает и что мешает, — начните '
            'с них.',
      ],
    ),
    GuideTopic(
      route: '/reports',
      title: 'Отчёты и аналитика',
      summary: 'Смотрите динамику за год и куда уходят деньги.',
      steps: <String>[
        'Выберите год, чтобы сравнить доходы и расходы по месяцам.',
        'По разбивкам находите категории, которые со временем растут.',
      ],
    ),
    GuideTopic(
      route: '/zakat',
      title: 'Закят',
      summary: 'Оцените закят с вашего имущества и следите за хаулем.',
      steps: <String>[
        'Введите облагаемые закятом активы, чтобы получить оценку.',
        'Укажите дату, когда имущество достигло нисаба, чтобы следить за '
            'отсчётом лунного года по хиджре.',
        'Это помощь в планировании — уточните свою обязанность у знающего '
            'учёного.',
      ],
    ),
    GuideTopic(
      route: '/markets',
      title: 'Курсы и рынки',
      summary: 'Актуальные курсы валют и цены криптовалют из открытых '
          'источников.',
      steps: <String>[
        'Курсы загружаются в реальном времени; в каждой строке указан '
            'источник.',
        'Если для рынка нет надёжного источника, там написано «недоступно» — '
            'никогда не выдуманное число.',
      ],
    ),
    GuideTopic(
      route: '/assistant',
      title: 'Ассистент DGOTIX AI',
      summary: 'Задавайте вопросы о своих финансах простыми словами.',
      steps: <String>[
        'Напишите вопрос или нажмите на подсказку; ассистент отвечает по '
            'краткой сводке ваших цифр.',
        'Число ответов зависит от тарифа; вы увидите предупреждение, когда '
            'приблизитесь к лимиту.',
        'Ответы создаются автоматически — перепроверяйте важные решения. '
            'Подсказки по правилам под чатом работают всегда, даже без ИИ.',
      ],
    ),
    GuideTopic(
      route: '/plans',
      title: 'Тарифы и подписка',
      summary: 'Сравните Бесплатный и Pro и управляйте подпиской.',
      steps: <String>[
        'Основные инструменты бюджета бесплатны навсегда.',
        'Платные тарифы повышают лимиты ИИ и облачного сканирования и '
            'добавляют функции.',
        'Если вы подписаны, текущий тариф и дата продления показаны вверху, '
            'с кнопкой управления или отмены.',
      ],
    ),
    GuideTopic(
      route: '/settings',
      title: 'Настройки, данные и копии',
      summary: 'Настройте приложение под себя и сохраните данные в '
          'безопасности.',
      steps: <String>[
        'Язык, тема и основная валюта — в разделах «Внешний вид» и «Регион».',
        'Управляйте своими категориями доходов и расходов.',
        'В разделе «Данные и резервное копирование» в любой момент '
            'экспортируйте полную копию; после входа данные автоматически '
            'синхронизируются между устройствами (в том числе после работы без '
            'сети), и это можно выключить.',
      ],
    ),
  ];

  // ---- Getting started (Swahili) ----
  static const List<String> _startSw = <String>[
    'Fungua Mipangilio uchague lugha, mandhari na sarafu kuu — kila jumla '
        'kwenye programu inaonyeshwa kwa sarafu hiyo.',
    'Ongeza mapato na matumizi yako (au changanua risiti) — kila kitu kingine '
        'kinakokotolewa kutoka kwake.',
    'Weka bajeti ya mwezi ili programu ikuambie kiasi kilichobaki cha '
        'kutumia.',
    'Angalia Muhtasari na Afya ya kifedha ujue ulipo, kisha ongeza malengo na '
        'madeni taratibu.',
  ];

  // ---- Topics (Swahili) ----
  static const List<GuideTopic> _topicsSw = <GuideTopic>[
    GuideTopic(
      route: '/dashboard',
      title: 'Muhtasari',
      summary: 'Mwezi wako kwa mtazamo mmoja: mapato, matumizi, akiba na pesa '
          'zilikokwenda.',
      steps: <String>[
        'Vigae vinaonyesha jumla za mwezi huu kwa sarafu yako kuu.',
        'Gusa kipande kwenye uchambuzi wa matumizi kuangazia kategoria hiyo.',
        'Arifa zinakuonyesha kinachohitaji umakini, kama kategoria iliyozidi '
            'bajeti au lengo la haraka.',
        'Bila data bado, vigae vinaonyesha “—” — hakuna kinachobuniwa kamwe.',
      ],
    ),
    GuideTopic(
      route: '/transactions',
      title: 'Mapato na matumizi',
      summary: 'Rekodi kila mwendo wa pesa — msingi wa kila hesabu kwenye '
          'programu.',
      steps: <String>[
        'Tumia kitufe cha kuongeza haraka kurekodi mapato au matumizi kwa '
            'kiasi, kategoria, tarehe na dokezo.',
        'Mapato na Matumizi kila moja ina skrini yake; Miamala inaonyesha zote '
            'pamoja.',
        'Tafuta kwenye orodha kupata rekodi yoyote, na uiguse kuihariri au '
            'kuifuta.',
      ],
    ),
    GuideTopic(
      route: '/recurring',
      title: 'Miamala inayojirudia',
      summary: 'Mshahara, kodi ya nyumba na usajili vinaongezwa vyenyewe kwenye '
          'tarehe yake.',
      steps: <String>[
        'Unapoongeza mapato au matumizi, weka "Rudia" kila wiki, mwezi, miezi '
            '3, miezi 6 au mwaka.',
        'Kwa bonasi au kamisheni yenye kiasi kinachobadilika, washa "Kiasi '
            'kinabadilika kila mara": kila tarehe programu inauliza kiasi halisi '
            'badala ya kuongeza makisio.',
        'Kila tarehe inapofika, programu inaiongeza kama muamala wa kawaida — '
            'hata kama hukuwepo, inafidia utakapoifungua tena.',
        'Kwenye skrini ya Yanayojirudia, simamisha, endelea, badilisha kiasi '
            'au acha kurudia. Miamala iliyokwisha ongezwa haibadilishwi kamwe.',
      ],
    ),
    GuideTopic(
      route: '/expenses',
      title: 'Changanua risiti',
      summary: 'Geuza picha ya risiti kuwa matumizi tayari kuhifadhiwa.',
      steps: <String>[
        'Kwenye skrini ya Matumizi, gusa "Changanua risiti" na upige au '
            'uchague picha.',
        'Programu inajaza mfanyabiashara, tarehe, kiasi na kategoria — '
            'vikague kabla ya kuhifadhi.',
        'Uchanganuzi wa mtandaoni unategemea kifurushi chako; risiti '
            'isiposomeka, andika matumizi kwa mkono.',
      ],
    ),
    GuideTopic(
      route: '/budget',
      title: 'Bajeti ya mwezi',
      summary: 'Panga kiasi unachotaka kutumia kwa kila kategoria, mwezi kwa '
          'mwezi.',
      steps: <String>[
        'Chagua mwaka na mwezi juu — skrini moja inahusu kila mwezi.',
        'Weka kikomo kwa kila kategoria unayotaka kudhibiti.',
        'Mipau ya maendeleo inajaa unavyotumia; kategoria iliyozidi kikomo '
            'inawekewa alama.',
        'Kwenye kifurushi cha kulipia, "Pendekeza mgawanyo" inagawa mapato yako '
            'kwenye kategoria kulingana na matumizi yako ya karibuni — ikague, '
            'kisha uitumie.',
      ],
    ),
    GuideTopic(
      route: '/goals',
      title: 'Malengo na akiba',
      summary: 'Weka akiba kwa jambo maalum na uone umekaribia kiasi gani.',
      steps: <String>[
        'Unda lengo lenye kiasi kinacholengwa na, ukipenda, tarehe ya mwisho.',
        'Rekodi michango unapoweka akiba; maendeleo yanasasishwa yenyewe.',
        'Malengo yaliyo karibu na tarehe yake yanaangaziwa kwenye Muhtasari.',
      ],
    ),
    GuideTopic(
      route: '/debts',
      title: 'Madeni na mikopo',
      summary: 'Fuatilia unachodaiwa na unachodai wengine.',
      steps: <String>[
        'Ongeza kila deni au mkopo pamoja na kiasi na mtu au upande.',
        'Sasisha kiasi kilicholipwa hadi sasa uone kilichobaki.',
        'Madeni yanaathiri alama yako ya Afya ya kifedha.',
      ],
    ),
    GuideTopic(
      route: '/portfolio',
      title: 'Miradi',
      summary: 'Panga miradi mikubwa katika sehemu za muda mfupi, wa kati na '
          'mrefu.',
      steps: <String>[
        'Ongeza miradi na uweke kila mmoja kwenye muda wake.',
        'Ufadhili unajaza sehemu kwa mpangilio, kwa hiyo unaona miradi ipi '
            'akiba yako inaweza kuifadhili kwanza.',
      ],
    ),
    GuideTopic(
      route: '/health',
      title: 'Afya ya kifedha',
      summary: 'Alama inayojumlisha jinsi fedha zako zilivyo na afya, na kwa '
          'nini.',
      steps: <String>[
        'Alama inakokotolewa kwenye kifaa chako kutoka data yako mwenyewe.',
        'Mambo makuu yanaonyesha kinachosaidia au kudhuru — boresha hayo '
            'kwanza.',
      ],
    ),
    GuideTopic(
      route: '/reports',
      title: 'Ripoti na uchambuzi',
      summary: 'Ona mienendo ya mwaka na pesa zako zinakokwenda.',
      steps: <String>[
        'Chagua mwaka kulinganisha mapato na matumizi mwezi kwa mwezi.',
        'Tumia uchambuzi kugundua kategoria zinazoongezeka kadiri muda '
            'unavyokwenda.',
      ],
    ),
    GuideTopic(
      route: '/zakat',
      title: 'Zaka',
      summary: 'Kadiria Zaka inayopaswa kwenye mali yako na ufuatilie Hauli.',
      steps: <String>[
        'Andika mali zinazotolewa Zaka upate makadirio.',
        'Weka tarehe ambayo mali yako ilifikia nisabu ili kufuata kuhesabu '
            'mwaka wa mwezi, unaoonyeshwa kwa Hijria.',
        'Huu ni msaada wa kupanga — thibitisha wajibu wako na mwanazuoni '
            'mwenye sifa.',
      ],
    ),
    GuideTopic(
      route: '/markets',
      title: 'Viwango vya ubadilishaji na masoko',
      summary: 'Viwango vya sarafu na bei za crypto za sasa kutoka vyanzo vya '
          'umma.',
      steps: <String>[
        'Viwango vinapatikana moja kwa moja; kila mstari unaonyesha chanzo '
            'chake.',
        'Soko lisilo na chanzo cha kuaminika linasema "haipatikani" — kamwe '
            'si namba ya kubuni.',
      ],
    ),
    GuideTopic(
      route: '/assistant',
      title: 'Msaidizi wa DGOTIX AI',
      summary: 'Uliza maswali kuhusu fedha zako kwa lugha rahisi.',
      steps: <String>[
        'Andika swali au gusa pendekezo; msaidizi anajibu kwa kutumia '
            'muhtasari mfupi wa tarakimu zako.',
        'Idadi ya majibu inategemea kifurushi chako; utaona dokezo ukikaribia '
            'kikomo.',
        'Majibu yanatengenezwa kiotomatiki — hakiki maamuzi muhimu. Maarifa '
            'ya kanuni chini ya mazungumzo yanafanya kazi daima, hata bila AI.',
      ],
    ),
    GuideTopic(
      route: '/plans',
      title: 'Vifurushi na usajili',
      summary: 'Linganisha Bure na Pro, na usimamie usajili wako.',
      steps: <String>[
        'Zana za msingi za bajeti ni bure milele.',
        'Vifurushi vya kulipia vinaongeza vikomo vya AI na uchanganuzi wa '
            'mtandaoni na kuongeza vipengele.',
        'Ukijisajili, kifurushi chako cha sasa na tarehe ya kujirudia '
            'vinaonekana juu, pamoja na kitufe cha kusimamia au kughairi.',
      ],
    ),
    GuideTopic(
      route: '/settings',
      title: 'Mipangilio, data na nakala',
      summary: 'Ifanye programu iwe yako na uweke data yako salama.',
      steps: <String>[
        'Lugha, mandhari na sarafu kuu viko chini ya Mwonekano na Eneo.',
        'Simamia kategoria zako za mapato na matumizi.',
        'Chini ya Data na nakala, chukua nakala kamili wakati wowote; ukiwa '
            'umeingia, data yako inalinganishwa yenyewe kati ya vifaa vyako '
            '(pia baada ya kufanya kazi bila mtandao), na unaweza kuzima hilo.',
      ],
    ),
  ];

  // ---- Getting started (Hausa) ----
  static const List<String> _startHa = <String>[
    'Buɗe Saituna ka zaɓi harshe, jigo da babban kuɗi — kowace jimilla a '
        'manhajar ana nuna ta da wannan kuɗin.',
    'Ƙara kuɗin shiga da kashe kuɗinka (ko ka karanta rasit) — duk sauran ana '
        'lissafa su daga gare su.',
    'Saita kasafin wata don manhajar ta gaya maka nawa ya rage na kashewa.',
    'Duba Taƙaitawa da Lafiyar kuɗi don sanin matsayinka, sannan ka riƙa '
        'ƙara buri da basussuka.',
  ];

  // ---- Topics (Hausa) ----
  static const List<GuideTopic> _topicsHa = <GuideTopic>[
    GuideTopic(
      route: '/dashboard',
      title: 'Taƙaitawa',
      summary: 'Watanka a kallo ɗaya: kuɗin shiga, kashe kuɗi, tanadi da inda '
          'kuɗin suka tafi.',
      steps: <String>[
        'Akwatuna suna nuna jimillar wannan wata a babban kuɗinka.',
        'Taɓa wani yanki a rarraba kashe kuɗi don haskaka wannan rukuni.',
        'Faɗakarwa suna nuna maka abin da ke buƙatar kulawa, kamar rukunin da '
            'ya wuce kasafi ko burin gaggawa.',
        'Idan babu bayanai tukuna, akwatuna suna nuna “—” — ba a taɓa ƙirƙirar '
            'komai ba.',
      ],
    ),
    GuideTopic(
      route: '/transactions',
      title: 'Kuɗin shiga da kashe kuɗi',
      summary: 'Rubuta kowane motsin kuɗi — tushen kowane lissafi a manhajar.',
      steps: <String>[
        'Yi amfani da maɓallin ƙara da sauri don rubuta kuɗin shiga ko kashe '
            'kuɗi tare da adadi, rukuni, kwanan wata da bayani.',
        'Kuɗin shiga da Kashe kuɗi kowanne yana da allonsa; Ma\'amaloli suna '
            'nuna su tare.',
        'Nema a cikin jerin don samun kowane rikodi, ka taɓa shi don gyarawa '
            'ko sharewa.',
      ],
    ),
    GuideTopic(
      route: '/recurring',
      title: 'Ma\'amaloli masu maimaituwa',
      summary: 'Albashi, haya da biyan kuɗi na wata ana ƙara su kai tsaye a '
          'ranarsu.',
      steps: <String>[
        'Lokacin ƙara kuɗin shiga ko kashe kuɗi, saita "Maimaita" kowane mako, '
            'wata, wata 3, wata 6 ko shekara.',
        'Don kyauta ko kwamishan da adadinsa ke canzawa, kunna "Adadin yana '
            'canzawa kowane lokaci": a kowace rana manhajar tana tambayar '
            'ainihin adadi maimakon ƙara kimantawa.',
        'Duk lokacin da lokacinsa ya yi, manhajar tana ƙara shi a matsayin '
            'ma\'amala ta yau da kullum — ko da ba ka nan, tana cike gibi '
            'idan ka sake buɗe ta.',
        'A allon Masu maimaituwa, dakatar, ci gaba, canza adadi ko daina '
            'maimaitawa. Ma\'amalolin da aka riga aka ƙara ba sa canzawa.',
      ],
    ),
    GuideTopic(
      route: '/expenses',
      title: 'Karanta rasit',
      summary: 'Mayar da hoton rasit ya zama kashe kuɗi shirye don ajiyewa.',
      steps: <String>[
        'A allon Kashe kuɗi, taɓa "Karanta rasit" ka ɗauki ko zaɓi hoto.',
        'Manhajar tana cike mai sayarwa, kwanan wata, adadi da rukuni — duba '
            'su kafin ajiyewa.',
        'Karatu a intanet ya dogara da tsarinka; idan ba a iya karanta rasit '
            'ba, rubuta kashe kuɗin da hannu.',
      ],
    ),
    GuideTopic(
      route: '/budget',
      title: 'Kasafin wata',
      summary: 'Tsara nawa kake son kashewa a kowane rukuni, wata bayan wata.',
      steps: <String>[
        'Zaɓi shekara da wata a sama — allo ɗaya yana ɗaukar kowane wata.',
        'Saita iyaka ga kowane rukunin da kake son sarrafawa.',
        'Sandunan ci gaba suna cika yayin da kake kashewa; rukunin da ya wuce '
            'iyakarsa ana yi masa alama.',
        'A tsarin biya, "Ba da shawarar rabo" tana raba kuɗin shigarka a '
            'rukunoni bisa kashe-kashenka na baya-bayan nan — duba ta, sannan ka '
            'yi amfani da ita.',
      ],
    ),
    GuideTopic(
      route: '/goals',
      title: 'Buri da tanadi',
      summary: 'Yi tanadi don wani abu na musamman ka ga yadda ka kusa.',
      steps: <String>[
        'Ƙirƙiri buri mai adadin da ake nema kuma, idan kana so, ranar ƙarshe.',
        'Rubuta gudummawa yayin da kake tanadi; ci gaba yana sabuntawa kai '
            'tsaye.',
        'Burin da lokacinsu ya kusa ana haskaka su a Taƙaitawa.',
      ],
    ),
    GuideTopic(
      route: '/debts',
      title: 'Basussuka da lamuni',
      summary: 'Bi abin da kake bi da abin da wasu ke binka.',
      steps: <String>[
        'Ƙara kowane bashi ko lamuni tare da adadinsa da mutum ko ɓangare.',
        'Sabunta adadin da aka biya zuwa yanzu don ganin saura.',
        'Basussuka suna shafar makin Lafiyar kuɗinka.',
      ],
    ),
    GuideTopic(
      route: '/portfolio',
      title: 'Ayyuka',
      summary: 'Tsara manyan ayyuka a ɓangarorin gajeren, matsakaici da dogon '
          'lokaci.',
      steps: <String>[
        'Ƙara ayyuka ka sanya kowanne a lokacinsa.',
        'Ɗaukar nauyi yana cike ɓangarori bisa tsari, don haka kana ganin '
            'ayyukan da tanadinka zai fara ɗauka.',
      ],
    ),
    GuideTopic(
      route: '/health',
      title: 'Lafiyar kuɗi',
      summary: 'Maki da ke taƙaita yadda kuɗinka ke da lafiya, da dalili.',
      steps: <String>[
        'Ana lissafa makin a na\'urarka daga bayananka.',
        'Manyan abubuwa suna nuna abin da ke taimakawa ko cutarwa — fara '
            'inganta su.',
      ],
    ),
    GuideTopic(
      route: '/reports',
      title: 'Rahotanni da nazari',
      summary: 'Ga yanayin shekara da inda kuɗinka ke tafiya.',
      steps: <String>[
        'Zaɓi shekara don kwatanta kuɗin shiga da kashe kuɗi wata bayan wata.',
        'Yi amfani da rarrabuwa don gano rukunonin da ke ƙaruwa a tsawon '
            'lokaci.',
      ],
    ),
    GuideTopic(
      route: '/zakat',
      title: 'Zakka',
      summary: 'Kimanta Zakkar da ta wajaba a dukiyarka ka bi Shekara.',
      steps: <String>[
        'Rubuta kadarorin da ake fitar wa Zakka don samun kimantawa.',
        'Saita ranar da dukiyarka ta kai nisabi don bin ƙidayar shekarar '
            'wata, da ake nunawa a Hijira.',
        'Wannan taimakon tsari ne — tabbatar da wajibinka da malami mai ilimi.',
      ],
    ),
    GuideTopic(
      route: '/markets',
      title: 'Farashin musaya da kasuwanni',
      summary: 'Farashin kuɗaɗe da na crypto na yanzu daga majiyoyin jama\'a.',
      steps: <String>[
        'Ana samun farashi kai tsaye; kowane layi yana nuna majiyarsa.',
        'Idan kasuwa ba ta da majiya mai aminci ana rubuta "babu" — ba lambar '
            'ƙirƙira ba.',
      ],
    ),
    GuideTopic(
      route: '/assistant',
      title: 'Mataimakin DGOTIX AI',
      summary: 'Yi tambayoyi game da kuɗinka cikin sauƙaƙan harshe.',
      steps: <String>[
        'Rubuta tambaya ko taɓa shawara; mataimakin yana amsawa ta amfani da '
            'gajeren taƙaitaccen lambobinka.',
        'Yawan amsoshi ya dogara da tsarinka; za ka ga sanarwa idan ka kusa '
            'iyaka.',
        'Ana ƙirƙirar amsoshi kai tsaye — sake duba muhimman shawarwari. '
            'Bayanai na ƙa\'ida da ke ƙasan tattaunawa suna aiki koyaushe, ko '
            'ba AI.',
      ],
    ),
    GuideTopic(
      route: '/plans',
      title: 'Tsare-tsare da biyan kuɗi',
      summary: 'Kwatanta Kyauta da Pro, ka sarrafa biyan kuɗinka.',
      steps: <String>[
        'Kayan aikin kasafi na asali kyauta ne har abada.',
        'Tsare-tsaren biya suna ƙara iyakokin AI da karatun intanet kuma suna '
            'ƙara fasaloli.',
        'Idan ka yi rajista, tsarinka na yanzu da ranar sabuntawa suna '
            'bayyana a sama, tare da maɓallin sarrafawa ko sokewa.',
      ],
    ),
    GuideTopic(
      route: '/settings',
      title: 'Saituna, bayanai da kwafi',
      summary: 'Mayar da manhajar taka ka kiyaye bayananka.',
      steps: <String>[
        'Harshe, jigo da babban kuɗi suna ƙarƙashin Kamanni da Yanki.',
        'Sarrafa rukunonin kuɗin shiga da kashe kuɗi naka.',
        'A ƙarƙashin Bayanai da kwafi, fitar da cikakken kwafi a kowane lokaci;'
            ' idan ka shiga, bayananka ana daidaita su kai tsaye tsakanin '
            'na\'urorinka (har bayan aiki ba intanet), kuma za ka iya kashe '
            'hakan.',
      ],
    ),
  ];

  // ---- Getting started (Afrikaans) ----
  static const List<String> _startAf = <String>[
    'Maak Instellings oop en kies jou taal, tema en basisgeldeenheid — elke '
        'totaal in die app word in daardie geldeenheid gewys.',
    'Voeg jou inkomste en uitgawes by (of skandeer \'n strokie) — alles anders '
        'word daaruit bereken.',
    'Stel \'n maandbegroting sodat die app vir jou sê hoeveel jy nog kan '
        'spandeer.',
    'Kyk na die Oorsig en Finansiële gesondheid om te sien waar jy staan, en '
        'voeg dan mettertyd doelwitte en skuld by.',
  ];

  // ---- Topics (Afrikaans) ----
  static const List<GuideTopic> _topicsAf = <GuideTopic>[
    GuideTopic(
      route: '/dashboard',
      title: 'Oorsig',
      summary: 'Jou maand in een oogopslag: inkomste, uitgawes, spaargeld en '
          'waarheen die geld gegaan het.',
      steps: <String>[
        'Die teëls wys hierdie maand se totale in jou basisgeldeenheid.',
        'Tik op \'n deel van die uitgaweverdeling om daardie kategorie uit te '
            'lig.',
        'Waarskuwings wys jou wat aandag nodig het, soos \'n kategorie oor '
            'begroting of \'n dringende doel.',
        'Sonder data wys die teëls “—” — niks word ooit versin nie.',
      ],
    ),
    GuideTopic(
      route: '/transactions',
      title: 'Inkomste en uitgawes',
      summary: 'Teken elke geldbeweging aan — die basis van elke berekening in '
          'die app.',
      steps: <String>[
        'Gebruik die vinnig-byvoeg-knoppie om inkomste of \'n uitgawe met '
            'bedrag, kategorie, datum en nota aan te teken.',
        'Inkomste en Uitgawes het elk hul eie skerm; Transaksies wys hulle '
            'saam.',
        'Deursoek die lys om enige inskrywing te vind, en tik daarop om dit te '
            'wysig of te skrap.',
      ],
    ),
    GuideTopic(
      route: '/recurring',
      title: 'Herhalende transaksies',
      summary: 'Salaris, huur en intekeninge word outomaties op hul datum '
          'bygevoeg.',
      steps: <String>[
        'Wanneer jy inkomste of \'n uitgawe byvoeg, stel “Herhaal” op elke '
            'week, maand, 3 maande, 6 maande of jaar.',
        'Vir \'n bonus of kommissie wat wissel, skakel “Die bedrag verander '
            'elke keer” aan: op elke datum vra die app die werklike bedrag in '
            'plaas daarvan om \'n skatting by te voeg.',
        'Elke keer as dit betaalbaar is, voeg die app dit as \'n gewone '
            'transaksie by — selfs as jy weg was, haal dit in sodra jy die app '
            'weer oopmaak.',
        'Op die Herhalend-skerm kan jy onderbreek, hervat, die bedrag verander '
            'of die herhaling stop. Reeds bygevoegde transaksies verander nooit '
            'nie.',
      ],
    ),
    GuideTopic(
      route: '/expenses',
      title: 'Skandeer \'n strokie',
      summary: 'Maak van \'n foto van \'n strokie \'n uitgawe wat gereed is om '
          'te stoor.',
      steps: <String>[
        'Tik op die Uitgawes-skerm op “Skandeer strokie” en neem of kies \'n '
            'foto.',
        'Die app vul die handelaar, datum, bedrag en kategorie in — gaan hulle '
            'na voordat jy stoor.',
        'Skandering in die wolk hang van jou plan af; as \'n strokie nie '
            'gelees kan word nie, voer die uitgawe self in.',
      ],
    ),
    GuideTopic(
      route: '/budget',
      title: 'Maandbegroting',
      summary: 'Beplan hoeveel jy per kategorie wil spandeer, maand na maand.',
      steps: <String>[
        'Kies die jaar en maand bo-aan — een skerm dek elke maand.',
        'Stel \'n limiet vir elke kategorie wat jy wil beheer.',
        'Vorderingsbalke vul soos jy spandeer; \'n kategorie oor sy limiet word '
            'gemerk.',
        'Op \'n betaalde plan verdeel “Stel \'n verdeling voor” jou inkomste '
            'oor die kategorieë op grond van jou eie onlangse uitgawes — gaan '
            'dit na, en pas dit dan toe.',
      ],
    ),
    GuideTopic(
      route: '/goals',
      title: 'Doelwitte en spaar',
      summary: 'Spaar vir iets spesifieks en sien hoe naby jy is.',
      steps: <String>[
        'Skep \'n doel met \'n teikenbedrag en, as jy wil, \'n sperdatum.',
        'Teken bydraes aan soos jy spaar; die vordering word outomaties '
            'bygewerk.',
        'Doelwitte naby hul sperdatum word in die Oorsig uitgelig.',
      ],
    ),
    GuideTopic(
      route: '/debts',
      title: 'Skuld en lenings',
      summary: 'Hou dop wat jy skuld en wat ander jou skuld.',
      steps: <String>[
        'Voeg elke skuld of lening by met sy bedrag en die persoon of party.',
        'Werk die bedrag wat reeds betaal is by om te sien wat oorbly.',
        'Skuld tel mee in jou finansiële gesondheidstelling.',
      ],
    ),
    GuideTopic(
      route: '/portfolio',
      title: 'Projekportefeulje',
      summary: 'Beplan groter projekte in vakke vir kort-, medium- en '
          'langtermyn.',
      steps: <String>[
        'Voeg projekte by en plaas elkeen in \'n termyn.',
        'Die befondsing vul die vakke in volgorde, sodat jy sien watter '
            'projekte jou spaargeld eerste dek.',
      ],
    ),
    GuideTopic(
      route: '/health',
      title: 'Finansiële gesondheid',
      summary: '\'n Telling wat opsom hoe gesond jou finansies is, en hoekom.',
      steps: <String>[
        'Die telling word op jou toestel uit jou eie data bereken.',
        'Die belangrikste faktore wys wat help of skade doen — verbeter hulle '
            'eerste.',
      ],
    ),
    GuideTopic(
      route: '/reports',
      title: 'Verslae en ontledings',
      summary: 'Sien die tendense oor die jaar en waarheen jou geld gaan.',
      steps: <String>[
        'Kies \'n jaar om inkomste en uitgawes maand vir maand te vergelyk.',
        'Gebruik die ontledings om kategorieë raak te sien wat mettertyd '
            'groei.',
      ],
    ),
    GuideTopic(
      route: '/zakat',
      title: 'Zakat',
      summary: 'Skat die zakat op jou rykdom en volg die hawl.',
      steps: <String>[
        'Voer jou zakat-pligtige bates in om \'n skatting te kry.',
        'Stel die datum waarop jou rykdom die nisab bereik het om die aftelling'
            ' van die maanjaar te volg, gewys in die Hijri-kalender.',
        'Dit is \'n beplanningshulpmiddel — laat jou verpligting deur \'n '
            'gekwalifiseerde geleerde bevestig.',
      ],
    ),
    GuideTopic(
      route: '/markets',
      title: 'Wisselkoerse en markte',
      summary: 'Huidige wisselkoerse en kriptopryse uit openbare bronne.',
      steps: <String>[
        'Koerse word lewendig gehaal; elke reël wys sy bron.',
        'As \'n mark geen betroubare bron het nie, staan daar “onbeskikbaar” — '
            'nooit \'n versinde getal nie.',
      ],
    ),
    GuideTopic(
      route: '/assistant',
      title: 'KI-assistent DGOTIX AI',
      summary: 'Vra vrae oor jou finansies in gewone taal.',
      steps: <String>[
        'Tik \'n vraag of tik op \'n voorstel; die assistent antwoord met '
            '\'n kort opsomming van jou syfers.',
        'Die aantal antwoorde hang van jou plan af; jy sien \'n kennisgewing '
            'wanneer jy naby die limiet is.',
        'Antwoorde word outomaties gemaak — kontroleer belangrike besluite. '
            'Die reëlgebaseerde insigte onder die gesprek werk altyd, selfs '
            'sonder KI.',
      ],
    ),
    GuideTopic(
      route: '/plans',
      title: 'Planne en intekeninge',
      summary: 'Vergelyk Gratis en Pro, en bestuur jou intekening.',
      steps: <String>[
        'Die basiese begrotingshulpmiddels is vir altyd gratis.',
        'Betaalde planne verhoog die perke vir KI en wolkskandering en voeg '
            'ekstra funksies by.',
        'As jy inteken, verskyn jou huidige plan en hernuwingsdatum bo-aan, '
            'met \'n knoppie om te bestuur of te kanselleer.',
      ],
    ),
    GuideTopic(
      route: '/settings',
      title: 'Instellings, data en rugsteun',
      summary: 'Maak die app joune en hou jou data veilig.',
      steps: <String>[
        'Taal, tema en basisgeldeenheid is onder Voorkoms en Streek.',
        'Bestuur jou eie inkomste- en uitgawekategorieë.',
        'Onder Data en rugsteun voer jy enige tyd \'n volledige rugsteun uit; '
            'as jy aangemeld is, word jou data outomaties tussen jou toestelle '
            'gesinchroniseer (ook ná vanlyn werk), en jy kan dit afskakel.',
      ],
    ),
  ];

  // ---- Getting started (Persian) ----
  static const List<String> _startFa = <String>[
    'تنظیمات را باز کنید و زبان، پوسته و ارز پایه را انتخاب کنید؛ هر جمعی در'
        ' برنامه به همان ارز نمایش داده می‌شود.',
    'درآمد و هزینه‌های خود را اضافه کنید (یا رسیدی را اسکن کنید)؛ بقیه چیزها'
        ' از روی آن‌ها محاسبه می‌شود.',
    'یک بودجه ماهانه تعیین کنید تا برنامه بگوید چقدر دیگر می‌توانید خرج '
        'کنید.',
    'داشبورد و سلامت مالی را ببینید تا بدانید کجا ایستاده‌اید و سپس کم‌کم '
        'اهداف و بدهی‌ها را اضافه کنید.',
  ];

  // ---- Topics (Persian) ----
  static const List<GuideTopic> _topicsFa = <GuideTopic>[
    GuideTopic(
      route: '/dashboard',
      title: 'داشبورد',
      summary: 'ماه شما در یک نگاه: درآمد، هزینه، پس‌انداز و اینکه پول کجا '
          'رفت.',
      steps: <String>[
        'کاشی‌ها جمع‌های این ماه را به ارز پایه شما نشان می‌دهند.',
        'روی بخشی از توزیع هزینه‌ها بزنید تا آن دسته برجسته شود.',
        'هشدارها نشان می‌دهند چه چیزی توجه می‌خواهد، مثل دسته‌ای فراتر از '
            'بودجه یا هدفی فوری.',
        'بدون داده، کاشی‌ها «—» نشان می‌دهند؛ هیچ چیز ساختگی نیست.',
      ],
    ),
    GuideTopic(
      route: '/transactions',
      title: 'درآمد و هزینه',
      summary: 'هر جابه‌جایی پول را ثبت کنید؛ پایه هر محاسبه در برنامه.',
      steps: <String>[
        'با دکمه افزودن سریع، درآمد یا هزینه را با مبلغ، دسته، تاریخ و '
            'یادداشت ثبت کنید.',
        'درآمد و هزینه‌ها هر کدام صفحه خود را دارند؛ تراکنش‌ها هر دو را با هم'
            ' نشان می‌دهد.',
        'در فهرست جست‌وجو کنید تا هر مورد را پیدا کنید و برای ویرایش یا حذف '
            'رویش بزنید.',
      ],
    ),
    GuideTopic(
      route: '/recurring',
      title: 'تراکنش‌های تکراری',
      summary: 'حقوق، اجاره و اشتراک‌ها در تاریخ خودشان خودکار اضافه می‌شوند.',
      steps: <String>[
        'هنگام افزودن درآمد یا هزینه، «تکرار» را روی هر هفته، ماه، 3 ماه، 6 '
            'ماه یا سال بگذارید.',
        'برای پاداش یا پورسانتی که تغییر می‌کند، «مبلغ هر بار تغییر می‌کند» را '
            'روشن کنید: در هر تاریخ برنامه به جای افزودن تخمین، مبلغ واقعی را '
            'می‌پرسد.',
        'هر بار که سررسید شود، برنامه آن را مثل یک تراکنش عادی اضافه می‌کند؛ '
            'حتی اگر غایب بوده باشید، با باز کردن دوباره جبران می‌کند.',
        'در صفحه تکراری می‌توانید متوقف کنید، ادامه دهید، مبلغ را تغییر دهید یا'
            ' تکرار را پایان دهید. تراکنش‌های اضافه‌شده هرگز تغییر نمی‌کنند.',
      ],
    ),
    GuideTopic(
      route: '/expenses',
      title: 'اسکن رسید',
      summary: 'عکس رسید را به هزینه‌ای آماده ذخیره تبدیل کنید.',
      steps: <String>[
        'در صفحه هزینه‌ها روی «اسکن رسید» بزنید و عکس بگیرید یا انتخاب کنید.',
        'برنامه فروشنده، تاریخ، مبلغ و دسته را پر می‌کند؛ پیش از ذخیره '
            'بررسی‌شان کنید.',
        'اسکن ابری به طرح شما بستگی دارد؛ اگر رسیدی خوانده نشد، هزینه را دستی'
            ' وارد کنید.',
      ],
    ),
    GuideTopic(
      route: '/budget',
      title: 'بودجه ماهانه',
      summary: 'برنامه‌ریزی کنید هر ماه برای هر دسته چقدر خرج کنید.',
      steps: <String>[
        'سال و ماه را در بالا انتخاب کنید؛ یک صفحه همه ماه‌ها را پوشش می‌دهد.',
        'برای هر دسته‌ای که می‌خواهید کنترل کنید سقفی بگذارید.',
        'نوارهای پیشرفت با خرج کردن پر می‌شوند؛ دسته‌ای که از سقفش بگذرد '
            'علامت می‌خورد.',
        'در طرح پولی، «پیشنهاد تقسیم» درآمد شما را بر اساس خرج‌های اخیرتان بین'
            ' دسته‌ها تقسیم می‌کند؛ بررسی‌اش کنید و سپس اعمال کنید.',
      ],
    ),
    GuideTopic(
      route: '/goals',
      title: 'اهداف و پس‌انداز',
      summary: 'برای چیزی مشخص پس‌انداز کنید و ببینید چقدر نزدیک شده‌اید.',
      steps: <String>[
        'هدفی با مبلغ و در صورت تمایل سررسید بسازید.',
        'هنگام پس‌انداز سهم‌ها را ثبت کنید؛ پیشرفت خودکار به‌روز می‌شود.',
        'اهداف نزدیک به سررسید در داشبورد برجسته می‌شوند.',
      ],
    ),
    GuideTopic(
      route: '/debts',
      title: 'بدهی‌ها و وام‌ها',
      summary: 'آنچه بدهکارید و آنچه دیگران به شما بدهکارند را دنبال کنید.',
      steps: <String>[
        'هر بدهی یا وام را با مبلغ و شخص یا طرف آن اضافه کنید.',
        'مبلغ پرداخت‌شده تا اکنون را به‌روز کنید تا باقی‌مانده را ببینید.',
        'بدهی‌ها در امتیاز سلامت مالی شما اثر دارند.',
      ],
    ),
    GuideTopic(
      route: '/portfolio',
      title: 'سبد پروژه‌ها',
      summary: 'پروژه‌های بزرگ‌تر را در بخش‌های کوتاه‌مدت، میان‌مدت و بلندمدت '
          'برنامه‌ریزی کنید.',
      steps: <String>[
        'پروژه‌ها را اضافه کنید و هر کدام را در یک افق بگذارید.',
        'تأمین، بخش‌ها را به ترتیب پر می‌کند تا ببینید پس‌اندازتان اول کدام '
            'پروژه‌ها را پوشش می‌دهد.',
      ],
    ),
    GuideTopic(
      route: '/health',
      title: 'سلامت مالی',
      summary: 'امتیازی که خلاصه می‌کند وضعیت مالی شما چقدر سالم است و چرا.',
      steps: <String>[
        'امتیاز روی دستگاه شما و از داده‌های خودتان محاسبه می‌شود.',
        'عوامل اصلی نشان می‌دهند چه چیزی کمک یا آسیب می‌زند؛ اول آن‌ها را بهتر'
            ' کنید.',
      ],
    ),
    GuideTopic(
      route: '/reports',
      title: 'گزارش‌ها و تحلیل‌ها',
      summary: 'روند سال و جایی که پولتان می‌رود را ببینید.',
      steps: <String>[
        'سالی را انتخاب کنید تا درآمد و هزینه را ماه به ماه مقایسه کنید.',
        'از تفکیک‌ها برای دیدن دسته‌هایی که با زمان رشد می‌کنند استفاده کنید.',
      ],
    ),
    GuideTopic(
      route: '/zakat',
      title: 'زکات',
      summary: 'زکات دارایی خود را تخمین بزنید و حول را دنبال کنید.',
      steps: <String>[
        'دارایی‌های مشمول زکات را وارد کنید تا تخمین بگیرید.',
        'تاریخ رسیدن دارایی به نصاب را تعیین کنید تا شمارش سال قمری، به تقویم '
            'هجری، دنبال شود.',
        'این ابزار برنامه‌ریزی است؛ تکلیف خود را با یک عالم آگاه تأیید کنید.',
      ],
    ),
    GuideTopic(
      route: '/markets',
      title: 'نرخ ارز و بازارها',
      summary: 'نرخ ارزها و قیمت رمزارزها از منابع عمومی.',
      steps: <String>[
        'نرخ‌ها زنده گرفته می‌شوند؛ هر ردیف منبعش را نشان می‌دهد.',
        'بازاری که منبع معتبری ندارد «در دسترس نیست» می‌نویسد؛ هرگز عددی '
            'ساختگی.',
      ],
    ),
    GuideTopic(
      route: '/assistant',
      title: 'دستیار DGOTIX AI',
      summary: 'درباره وضعیت مالی خود به زبان ساده بپرسید.',
      steps: <String>[
        'پرسشی بنویسید یا روی پیشنهادی بزنید؛ دستیار با خلاصه‌ای کوتاه از '
            'ارقام شما پاسخ می‌دهد.',
        'تعداد پاسخ‌ها به طرح شما بستگی دارد؛ نزدیک سقف اطلاعیه می‌بینید.',
        'پاسخ‌ها خودکار ساخته می‌شوند؛ تصمیم‌های مهم را بررسی کنید. بینش‌های '
            'قاعده‌محور زیر گفت‌وگو همیشه، حتی بدون هوش مصنوعی، کار می‌کنند.',
      ],
    ),
    GuideTopic(
      route: '/plans',
      title: 'طرح‌ها و اشتراک',
      summary: 'رایگان و Pro را مقایسه و اشتراک خود را مدیریت کنید.',
      steps: <String>[
        'ابزارهای پایه بودجه برای همیشه رایگان‌اند.',
        'طرح‌های پولی سقف هوش مصنوعی و اسکن ابری را بالا می‌برند و امکانات '
            'بیشتری اضافه می‌کنند.',
        'اگر مشترک شوید، طرح فعلی و تاریخ تمدید در بالا با دکمه مدیریت یا لغو'
            ' ظاهر می‌شوند.',
      ],
    ),
    GuideTopic(
      route: '/settings',
      title: 'تنظیمات، داده و پشتیبان',
      summary: 'برنامه را مال خودتان کنید و داده‌ها را امن نگه دارید.',
      steps: <String>[
        'زبان، پوسته و ارز پایه در بخش ظاهر و منطقه هستند.',
        'دسته‌های درآمد و هزینه خود را مدیریت کنید.',
        'در بخش داده‌ها و پشتیبان هر زمان پشتیبان کامل بگیرید؛ اگر وارد شده '
            'باشید، داده‌ها خودکار بین دستگاه‌هایتان همگام می‌شوند (پس از کار '
            'آفلاین هم) و می‌توانید خاموشش کنید.',
      ],
    ),
  ];

  // ---- Getting started (Hindi) ----
  static const List<String> _startHi = <String>[
    'सेटिंग्स खोलें और अपनी भाषा, थीम और मूल मुद्रा चुनें — ऐप का हर कुल उसी'
        ' मुद्रा में दिखता है।',
    'अपनी आमदनी और ख़र्च जोड़ें (या रसीद स्कैन करें) — बाक़ी सब उन्हीं से '
        'निकाला जाता है।',
    'मासिक बजट तय करें ताकि ऐप बताए कि आप अभी कितना ख़र्च कर सकते हैं।',
    'डैशबोर्ड और वित्तीय सेहत देखें कि आप कहाँ खड़े हैं, फिर धीरे-धीरे लक्ष्य '
        'और क़र्ज़ जोड़ें।',
  ];

  // ---- Topics (Hindi) ----
  static const List<GuideTopic> _topicsHi = <GuideTopic>[
    GuideTopic(
      route: '/dashboard',
      title: 'डैशबोर्ड',
      summary: 'आपका महीना एक नज़र में: आमदनी, ख़र्च, बचत और पैसा कहाँ गया।',
      steps: <String>[
        'टाइलें इस महीने के कुल आपकी मूल मुद्रा में दिखाती हैं।',
        'ख़र्च के बँटवारे के किसी हिस्से पर टैप करें ताकि वह श्रेणी उभरे।',
        'अलर्ट बताते हैं किस पर ध्यान चाहिए, जैसे बजट से ऊपर कोई श्रेणी या '
            'कोई ज़रूरी लक्ष्य।',
        'डेटा न हो तो टाइलें “—” दिखाती हैं — कुछ भी गढ़ा नहीं जाता।',
      ],
    ),
    GuideTopic(
      route: '/transactions',
      title: 'आमदनी और ख़र्च',
      summary: 'पैसे की हर हलचल दर्ज करें — ऐप की हर गणना की बुनियाद।',
      steps: <String>[
        'जल्दी जोड़ें बटन से आमदनी या ख़र्च को रक़म, श्रेणी, तारीख़ और नोट के '
            'साथ दर्ज करें।',
        'आमदनी और ख़र्च की अपनी-अपनी स्क्रीन है; लेन-देन दोनों साथ दिखाता है।',
        'कोई भी एंट्री ढूँढने के लिए सूची में खोजें, और बदलने या हटाने के लिए उस'
            ' पर टैप करें।',
      ],
    ),
    GuideTopic(
      route: '/recurring',
      title: 'दोहराने वाले लेन-देन',
      summary: 'वेतन, किराया और सदस्यताएँ अपनी तारीख़ पर अपने आप जुड़ती हैं।',
      steps: <String>[
        'आमदनी या ख़र्च जोड़ते समय “दोहराएँ” को हर हफ़्ते, महीने, 3 महीने, 6 '
            'महीने या साल पर रखें।',
        'बदलने वाले बोनस या कमीशन के लिए “रक़म हर बार बदलती है” चालू करें: हर '
            'तारीख़ पर ऐप अनुमान जोड़ने की बजाय असली रक़म पूछता है।',
        'हर देय तारीख़ पर ऐप इसे सामान्य लेन-देन की तरह जोड़ता है — आप दूर रहे '
            'हों तब भी, ऐप फिर खोलने पर पूरा कर लेता है।',
        'दोहराने वाले स्क्रीन पर रोकें, फिर शुरू करें, रक़म बदलें या दोहराना बंद'
            ' करें। पहले जुड़े लेन-देन कभी नहीं बदलते।',
      ],
    ),
    GuideTopic(
      route: '/expenses',
      title: 'रसीद स्कैन करें',
      summary: 'रसीद की फ़ोटो को सहेजने के लिए तैयार ख़र्च में बदलें।',
      steps: <String>[
        'ख़र्च स्क्रीन पर “रसीद स्कैन करें” पर टैप करें और फ़ोटो लें या चुनें।',
        'ऐप दुकान, तारीख़, रक़म और श्रेणी भरता है — सहेजने से पहले जाँचें।',
        'क्लाउड स्कैन आपके प्लान पर निर्भर है; रसीद न पढ़ी जाए तो ख़र्च ख़ुद '
            'लिखें।',
      ],
    ),
    GuideTopic(
      route: '/budget',
      title: 'मासिक बजट',
      summary: 'हर श्रेणी में कितना ख़र्च करना है, महीने दर महीने तय करें।',
      steps: <String>[
        'ऊपर साल और महीना चुनें — एक ही स्क्रीन हर महीना दिखाती है।',
        'जिस श्रेणी को काबू में रखना है उसकी सीमा तय करें।',
        'ख़र्च के साथ प्रगति बार भरते हैं; सीमा पार करने वाली श्रेणी चिह्नित '
            'होती है।',
        'भुगतान वाले प्लान में “बँटवारा सुझाएँ” आपकी आमदनी को आपके हाल के ख़र्च'
            ' के आधार पर श्रेणियों में बाँटता है — जाँचें, फिर लागू करें।',
      ],
    ),
    GuideTopic(
      route: '/goals',
      title: 'लक्ष्य और बचत',
      summary: 'किसी ख़ास चीज़ के लिए बचाएँ और देखें कि कितने पास पहुँचे।',
      steps: <String>[
        'लक्ष्य रक़म और चाहें तो समय-सीमा के साथ लक्ष्य बनाएँ।',
        'बचत करते हुए योगदान दर्ज करें; प्रगति अपने आप अपडेट होती है।',
        'समय-सीमा के पास वाले लक्ष्य डैशबोर्ड पर उभरते हैं।',
      ],
    ),
    GuideTopic(
      route: '/debts',
      title: 'क़र्ज़ और उधार',
      summary: 'आपको क्या देना है और दूसरों को आपको क्या देना है, ट्रैक करें।',
      steps: <String>[
        'हर क़र्ज़ या उधार उसकी रक़म और व्यक्ति या पक्ष के साथ जोड़ें।',
        'अब तक चुकाई रक़म अपडेट करें ताकि बाक़ी दिखे।',
        'क़र्ज़ आपके वित्तीय सेहत स्कोर में गिना जाता है।',
      ],
    ),
    GuideTopic(
      route: '/portfolio',
      title: 'प्रोजेक्ट पोर्टफ़ोलियो',
      summary: 'बड़े प्रोजेक्ट कम, मध्यम और लंबी अवधि के खानों में रखें।',
      steps: <String>[
        'प्रोजेक्ट जोड़ें और हर एक को किसी अवधि में रखें।',
        'फ़ंडिंग खानों को क्रम से भरती है, ताकि दिखे कि आपकी बचत पहले कौन से '
            'प्रोजेक्ट पूरे करती है।',
      ],
    ),
    GuideTopic(
      route: '/health',
      title: 'वित्तीय सेहत',
      summary: 'एक स्कोर जो बताता है कि आपके पैसे की सेहत कैसी है, और क्यों।',
      steps: <String>[
        'स्कोर आपके डिवाइस पर आपके अपने डेटा से निकाला जाता है।',
        'मुख्य कारक दिखाते हैं क्या मदद करता है या नुक़सान — पहले उन्हें सुधारें।',
      ],
    ),
    GuideTopic(
      route: '/reports',
      title: 'रिपोर्ट और विश्लेषण',
      summary: 'साल भर के रुझान और पैसा कहाँ जाता है, देखें।',
      steps: <String>[
        'महीने दर महीने आमदनी और ख़र्च की तुलना के लिए साल चुनें।',
        'समय के साथ बढ़ती श्रेणियाँ पहचानने के लिए ब्योरे का इस्तेमाल करें।',
      ],
    ),
    GuideTopic(
      route: '/zakat',
      title: 'ज़कात',
      summary: 'अपनी संपत्ति पर ज़कात का अनुमान लगाएँ और हौल ट्रैक करें।',
      steps: <String>[
        'अनुमान के लिए ज़कात योग्य संपत्ति लिखें।',
        'संपत्ति निसाब तक पहुँचने की तारीख़ तय करें ताकि चंद्र वर्ष की उलटी '
            'गिनती हिजरी कैलेंडर में दिखे।',
        'यह योजना का उपकरण है — अपना दायित्व किसी योग्य आलिम से पुष्ट करें।',
      ],
    ),
    GuideTopic(
      route: '/markets',
      title: 'विनिमय दरें और बाज़ार',
      summary: 'सार्वजनिक स्रोतों से मौजूदा विनिमय दरें और क्रिप्टो दाम।',
      steps: <String>[
        'दरें लाइव आती हैं; हर पंक्ति अपना स्रोत दिखाती है।',
        'जिस बाज़ार का भरोसेमंद स्रोत न हो वहाँ “उपलब्ध नहीं” लिखा होता है — '
            'कभी कोई गढ़ा अंक नहीं।',
      ],
    ),
    GuideTopic(
      route: '/assistant',
      title: 'DGOTIX AI सहायक',
      summary: 'अपने पैसों के बारे में सीधी भाषा में सवाल पूछें।',
      steps: <String>[
        'सवाल लिखें या किसी सुझाव पर टैप करें; सहायक आपके अंकों के छोटे सारांश'
            ' से जवाब देता है।',
        'जवाबों की संख्या आपके प्लान पर निर्भर है; सीमा के पास सूचना दिखेगी।',
        'जवाब अपने आप बनते हैं — ज़रूरी फ़ैसले दोबारा जाँचें। बातचीत के नीचे की'
            ' नियम-आधारित जानकारी हमेशा, AI के बिना भी, काम करती है।',
      ],
    ),
    GuideTopic(
      route: '/plans',
      title: 'प्लान और सदस्यता',
      summary: 'मुफ़्त और Pro की तुलना करें, और सदस्यता प्रबंधित करें।',
      steps: <String>[
        'बुनियादी बजट उपकरण हमेशा के लिए मुफ़्त हैं।',
        'भुगतान वाले प्लान AI और क्लाउड स्कैन की सीमा बढ़ाते हैं और अतिरिक्त '
            'सुविधाएँ जोड़ते हैं।',
        'सदस्यता लेने पर आपका मौजूदा प्लान और नवीनीकरण की तारीख़ ऊपर दिखते हैं,'
            ' प्रबंधन या रद्द करने के बटन के साथ।',
      ],
    ),
    GuideTopic(
      route: '/settings',
      title: 'सेटिंग्स, डेटा और बैकअप',
      summary: 'ऐप को अपना बनाएँ और अपना डेटा सुरक्षित रखें।',
      steps: <String>[
        'भाषा, थीम और मूल मुद्रा रूप और क्षेत्र में हैं।',
        'अपनी आमदनी और ख़र्च की श्रेणियाँ प्रबंधित करें।',
        'डेटा और बैकअप में कभी भी पूरा बैकअप निकालें; साइन इन होने पर आपका डेटा'
            ' आपके डिवाइसों के बीच अपने आप सिंक होता है (ऑफ़लाइन काम के बाद भी),'
            ' और आप इसे बंद कर सकते हैं।',
      ],
    ),
  ];

  // ---- Getting started (Chinese) ----
  static const List<String> _startZh = <String>[
    '打开设置，选择你的语言、主题和基础货币——应用中的所有合计都'
        '以这个货币显示。',
    '添加你的收入和支出（或扫描收据）——其他一切都由它们计算得出。',
    '设定月度预算，应用就会告诉你现在还能花多少。',
    '查看总览和财务健康，了解自己的状况，然后逐步添加目标和借款。',
  ];

  // ---- Topics (Chinese) ----
  static const List<GuideTopic> _topicsZh = <GuideTopic>[
    GuideTopic(
      route: '/dashboard',
      title: '总览',
      summary: '一眼看清你的这个月：收入、支出、储蓄以及钱花到了哪里。',
      steps: <String>[
        '卡片以你的基础货币显示本月的合计。',
        '点击支出分布中的某一块，突出显示该类别。',
        '提醒会告诉你需要关注的事项，比如超出预算的类别或紧迫的目标。',
        '没有数据时卡片显示“—”——绝不编造任何内容。',
      ],
    ),
    GuideTopic(
      route: '/transactions',
      title: '收入与支出',
      summary: '记录每一笔资金往来——应用所有计算的基础。',
      steps: <String>[
        '用快速添加按钮记录收入或支出，包括金额、类别、日期和备注。',
        '收入和支出各有自己的页面；“交易”页面同时显示两者。',
        '在列表中搜索任意记录，点击即可编辑或删除。',
      ],
    ),
    GuideTopic(
      route: '/recurring',
      title: '定期交易',
      summary: '工资、房租和订阅会在日期到时自动添加。',
      steps: <String>[
        '添加收入或支出时，把“重复”设为每周、每月、每 3 个月、每'
            ' 6 个月或每年。',
        '对于金额会变的奖金或佣金，开启“每次金额不同”：每到日期，应'
            '用都会询问实际金额，而不是加入估算值。',
        '每到期一次，应用就会像普通交易一样添加——即使你一段时间没打'
            '开，再次打开时也会补上。',
        '在“定期交易”页面暂停、继续、修改金额或停止重复。已添加的交'
            '易绝不会改变。',
      ],
    ),
    GuideTopic(
      route: '/expenses',
      title: '扫描收据',
      summary: '把收据照片变成一笔可以直接保存的支出。',
      steps: <String>[
        '在“支出”页面点击“扫描收据”，拍照或选择一张照片。',
        '应用会填好商家、日期、金额和类别——保存前请检查。',
        '云端扫描取决于你的方案；如果收据读不出来，请手动输入支出。',
      ],
    ),
    GuideTopic(
      route: '/budget',
      title: '月度预算',
      summary: '逐月设定每个类别打算花多少。',
      steps: <String>[
        '在顶部选择年份和月份——同一个页面可以查看每个月。',
        '为你想控制的类别设定上限。',
        '进度条随支出增长；超出上限的类别会被标出。',
        '在付费方案中，“建议一个分配”会根据你最近的支出把收入分配到'
            '各类别——检查后再应用。',
      ],
    ),
    GuideTopic(
      route: '/goals',
      title: '目标与储蓄',
      summary: '为某件具体的事存钱，并看看离目标还有多远。',
      steps: <String>[
        '创建一个目标，填写目标金额，也可以设定截止日期。',
        '存钱时记录存入的金额；进度会自动更新。',
        '临近截止日期的目标会在总览中突出显示。',
      ],
    ),
    GuideTopic(
      route: '/debts',
      title: '借款与贷款',
      summary: '跟踪你欠别人的和别人欠你的。',
      steps: <String>[
        '添加每一笔借款或贷款，填写金额和对方。',
        '更新已还金额，查看剩余部分。',
        '借款会计入你的财务健康评分。',
      ],
    ),
    GuideTopic(
      route: '/portfolio',
      title: '项目组合',
      summary: '把大项目放进短期、中期和长期的分组中。',
      steps: <String>[
        '添加项目，并为每个项目选择一个期限。',
        '资金按顺序填充各分组，让你看到储蓄会先完成哪些项目。',
      ],
    ),
    GuideTopic(
      route: '/health',
      title: '财务健康',
      summary: '一个评分，告诉你的财务状况如何以及原因。',
      steps: <String>[
        '评分在你的设备上根据你自己的数据计算。',
        '主要因素显示哪些有帮助、哪些有拖累——先改善它们。',
      ],
    ),
    GuideTopic(
      route: '/reports',
      title: '报告与分析',
      summary: '查看全年的趋势以及钱花在了哪里。',
      steps: <String>[
        '选择一个年份，逐月对比收入和支出。',
        '用明细找出随时间增长的类别。',
      ],
    ),
    GuideTopic(
      route: '/zakat',
      title: '天课',
      summary: '估算你财富的天课，并跟踪满年。',
      steps: <String>[
        '输入应缴天课的资产进行估算。',
        '设定财富达到尼萨布的日期，伊斯兰历中就会显示太阴年的倒计时。',
        '这是一个规划工具——请向合格的学者确认你的义务。',
      ],
    ),
    GuideTopic(
      route: '/markets',
      title: '汇率与市场',
      summary: '来自公开数据源的当前汇率和加密货币价格。',
      steps: <String>[
        '汇率实时获取；每一行都显示其来源。',
        '没有可靠来源的市场会显示“不可用”——绝不编造数字。',
      ],
    ),
    GuideTopic(
      route: '/assistant',
      title: 'DGOTIX AI 助手',
      summary: '用日常语言询问关于你的钱的问题。',
      steps: <String>[
        '输入问题或点击一个建议；助手会根据你数字的简短摘要来回答。',
        '回答次数取决于你的方案；接近上限时会有提示。',
        '回答是自动生成的——重要决定请再次核实。对话下方基于规则的洞'
            '察始终可用，不需要 AI。',
      ],
    ),
    GuideTopic(
      route: '/plans',
      title: '方案与订阅',
      summary: '对比免费版和 Pro，并管理你的订阅。',
      steps: <String>[
        '基础预算工具永久免费。',
        '付费方案提高 AI 和云端扫描的额度，并增加更多功能。',
        '订阅后，顶部会显示你当前的方案和续订日期，以及管理或取消的按'
            '钮。',
      ],
    ),
    GuideTopic(
      route: '/settings',
      title: '设置、数据与备份',
      summary: '让应用更合你心意，并保护好你的数据。',
      steps: <String>[
        '语言、主题和基础货币在“外观”和“地区”中。',
        '管理你自己的收入和支出类别。',
        '在“数据与备份”中随时导出完整备份；登录后，你的数据会在你的'
            '设备之间自动同步（离线使用后也会），你也可以关闭同步。',
      ],
    ),
  ];

  // ---- Getting started (Japanese) ----
  static const List<String> _startJa = <String>[
    '設定を開き、言語、テーマ、基本通貨を選びましょう——アプリの'
        'すべての合計はこの通貨で表示されます。',
    '収入と支出を追加しましょう（またはレシートをスキャン）——他'
        'のすべてはそこから計算されます。',
    '月間予算を設定すると、今いくら使えるかをアプリが教えてくれま'
        'す。',
    'ダッシュボードと家計の健康度で現状を確認し、少しずつ目標や借'
        '金を追加しましょう。',
  ];

  // ---- Topics (Japanese) ----
  static const List<GuideTopic> _topicsJa = <GuideTopic>[
    GuideTopic(
      route: '/dashboard',
      title: 'ダッシュボード',
      summary: '今月がひと目で分かります：収入、支出、貯金、そしてお金の行き'
          '先。',
      steps: <String>[
        'カードには今月の合計が基本通貨で表示されます。',
        '支出の内訳の一部をタップすると、そのカテゴリが強調されます。',
        'お知らせが、予算オーバーのカテゴリや急ぎの目標など、注意が必'
            '要なことを伝えます。',
        'データがないときカードは「—」と表示します——何もでっち上げ'
            'ません。',
      ],
    ),
    GuideTopic(
      route: '/transactions',
      title: '収入と支出',
      summary: 'お金の動きをすべて記録——アプリのすべての計算の土台です。',
      steps: <String>[
        'クイック追加ボタンで、収入か支出を金額、カテゴリ、日付、メモ'
            'とともに記録します。',
        '収入と支出にはそれぞれの画面があり、「取引」には両方が表示さ'
            'れます。',
        'リストを検索してどの記録も見つけられ、タップすると編集・削除'
            'できます。',
      ],
    ),
    GuideTopic(
      route: '/recurring',
      title: '定期取引',
      summary: '給料、家賃、サブスクは期日に自動で追加されます。',
      steps: <String>[
        '収入や支出を追加するとき、「繰り返し」を毎週、毎月、3 か月'
            'ごと、6 か月ごと、毎年に設定します。',
        '金額が変わるボーナスや歩合給には「金額が毎回変わる」をオンに：'
            '期日ごとに、見積もりを入れる代わりに実際の金額を尋ねます。',
        '期日ごとに通常の取引と同じように追加されます——しばらく開か'
            'なくても、次に開いたときに追いつきます。',
        '「定期取引」画面で一時停止、再開、金額の変更、繰り返しの停止'
            'ができます。追加済みの取引は変わりません。',
      ],
    ),
    GuideTopic(
      route: '/expenses',
      title: 'レシートをスキャン',
      summary: 'レシートの写真を、すぐ保存できる支出に変えます。',
      steps: <String>[
        '「支出」画面で「レシートをスキャン」をタップし、写真を撮るか'
            '選びます。',
        'アプリが店名、日付、金額、カテゴリを入力します——保存前に確'
            '認してください。',
        'クラウドスキャンはプランによります。レシートが読み取れない場'
            '合は支出を手で入力してください。',
      ],
    ),
    GuideTopic(
      route: '/budget',
      title: '月間予算',
      summary: 'カテゴリごとにいくら使うかを、月ごとに決めます。',
      steps: <String>[
        '上で年と月を選びます——同じ画面ですべての月を見られます。',
        '管理したいカテゴリに上限を設定します。',
        '支出に合わせてバーが伸び、上限を超えたカテゴリには印が付きま'
            'す。',
        '有料プランでは「配分を提案」が最近の支出をもとに収入をカテゴ'
            'リに分けます——確認してから適用してください。',
      ],
    ),
    GuideTopic(
      route: '/goals',
      title: '目標と貯金',
      summary: '何か特定のもののために貯金し、どれだけ近づいたかを確認します。',
      steps: <String>[
        '目標金額と、必要なら期限を決めて目標を作ります。',
        '貯金するたびに入金を記録すると、進捗が自動で更新されます。',
        '期限が近い目標はダッシュボードで目立つように表示されます。',
      ],
    ),
    GuideTopic(
      route: '/debts',
      title: '借金と貸付',
      summary: 'あなたが借りているお金と、貸しているお金を管理します。',
      steps: <String>[
        '借金や貸付を、金額と相手とともに追加します。',
        'これまでに返した額を更新すると、残りが分かります。',
        '借金は家計の健康スコアに反映されます。',
      ],
    ),
    GuideTopic(
      route: '/portfolio',
      title: 'プロジェクトのポートフォリオ',
      summary: '大きなプロジェクトを短期・中期・長期の枠に分けます。',
      steps: <String>[
        'プロジェクトを追加し、それぞれ期間を選びます。',
        '資金は枠に順番に充てられるので、貯金で先に完成するプロジェク'
            'トが分かります。',
      ],
    ),
    GuideTopic(
      route: '/health',
      title: '家計の健康度',
      summary: '家計の状態とその理由を示すスコア。',
      steps: <String>[
        'スコアはあなた自身のデータから端末上で計算されます。',
        '主な要因が、何が助けになり何が足を引っ張っているかを示します——'
            'まずそこを改善しましょう。',
      ],
    ),
    GuideTopic(
      route: '/reports',
      title: 'レポートと分析',
      summary: '1 年の推移とお金の行き先を確認します。',
      steps: <String>[
        '年を選んで、月ごとに収入と支出を比べます。',
        '内訳で、時間とともに増えているカテゴリを見つけましょう。',
      ],
    ),
    GuideTopic(
      route: '/zakat',
      title: 'ザカート',
      summary: '資産のザカートを見積もり、ハウルを追跡します。',
      steps: <String>[
        'ザカート対象の資産を入力して見積もります。',
        '資産がニサーブに達した日を設定すると、ヒジュラ暦で太陰暦の '
            '1 年のカウントダウンが表示されます。',
        'これは計画のツールです——義務は資格のある学者に確認してくだ'
            'さい。',
      ],
    ),
    GuideTopic(
      route: '/markets',
      title: '為替レートと市場',
      summary: '公開データによる現在の為替レートと暗号資産の価格。',
      steps: <String>[
        'レートはリアルタイムで取得され、各行に出典が表示されます。',
        '信頼できる出典がない市場は「データなし」と表示します——数字'
            'をでっち上げることはありません。',
      ],
    ),
    GuideTopic(
      route: '/assistant',
      title: 'DGOTIX AI アシスタント',
      summary: 'お金について、ふだんの言葉で質問できます。',
      steps: <String>[
        '質問を入力するか提案をタップすると、アシスタントがあなたの数'
            '字の短い要約から答えます。',
        '回答の回数はプランによります。上限が近づくとお知らせします。',
        '回答は自動生成です——重要な判断は再確認してください。会話の'
            '下にあるルールに基づく分析は、AI なしでいつでも使えます。',
      ],
    ),
    GuideTopic(
      route: '/plans',
      title: 'プランとサブスクリプション',
      summary: '無料と Pro を比べ、サブスクリプションを管理します。',
      steps: <String>[
        '基本の家計ツールはずっと無料です。',
        '有料プランは AI とクラウドスキャンの上限を上げ、追加機能'
            'を加えます。',
        '申し込むと、上に現在のプランと更新日が、管理・解約のボタンと'
            'ともに表示されます。',
      ],
    ),
    GuideTopic(
      route: '/settings',
      title: '設定、データ、バックアップ',
      summary: 'アプリを自分好みにし、データを安全に保ちます。',
      steps: <String>[
        '言語、テーマ、基本通貨は「外観」と「地域」にあります。',
        '独自の収入・支出カテゴリを管理できます。',
        '「データとバックアップ」でいつでも完全なバックアップを書き出'
            'せます。ログインすると、データは端末間で自動的に同期され（オ'
            'フラインで使った後も）、オフにもできます。',
      ],
    ),
  ];
}
