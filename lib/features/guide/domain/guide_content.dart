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
          pt: _startPt);

  static List<GuideTopic> topics({required AppLang lang}) =>
      lang.pick(_topicsAr, _topicsEn,
          fr: _topicsFr, id: _topicsId, es: _topicsEs,
          tr: _topicsTr, ms: _topicsMs, ur: _topicsUr, de: _topicsDe,
          pt: _topicsPt);

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
}
