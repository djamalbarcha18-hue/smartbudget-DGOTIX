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
      lang.pick(_startAr, _startEn, fr: _startFr, id: _startId);

  static List<GuideTopic> topics({required AppLang lang}) =>
      lang.pick(_topicsAr, _topicsEn, fr: _topicsFr, id: _topicsId);

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
      summary: 'Compare Free, Basic and Pro, and manage your subscription.',
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
      summary: 'قارن بين المجانية والأساسية والاحترافية، وأدِر اشتراكك.',
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
      summary: 'Comparez Gratuit, Basic et Pro, et gérez votre abonnement.',
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
      summary: 'Bandingkan Gratis, Basic, dan Pro, lalu kelola langganan Anda.',
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
}
