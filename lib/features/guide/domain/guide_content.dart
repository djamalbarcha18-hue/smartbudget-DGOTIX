/// User guide — how to use each part of SmartBudget.
///
/// Long-form prose lives here (like the legal pages) rather than in the ARB
/// files. Every topic points at a real route so the guide doubles as a map of
/// the platform. Describe only what the app actually does — no invented
/// buttons or promises.
library;

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
  static List<String> gettingStarted({required bool ar}) =>
      ar ? _startAr : _startEn;

  static List<GuideTopic> topics({required bool ar}) =>
      ar ? _topicsAr : _topicsEn;

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
      summary: 'Your month at a glance: income, spending, savings and where the '
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
        'When adding income or an expense, set "Repeat" to every week, month '
            'or year.',
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
            'in, you can also back up to the cloud.',
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
        'عند إضافة دخل أو مصروف، اختر «التكرار»: كل أسبوع أو كل شهر أو كل سنة.',
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
            'الدخول يمكنك النسخ إلى السحابة أيضاً.',
      ],
    ),
  ];
}
