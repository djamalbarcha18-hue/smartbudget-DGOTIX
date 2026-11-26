# SmartBudget — ملف التسليم (للجلسة الجديدة)

آخر تحديث: 2026-11-26، من قراءة الكود على `main` (الالتزام `2ff26d4`، بتاريخ 2026-11-19).
هذا الملف يحلّ محل أي ملخص أقدم. ما لم يُرَ في الكود معلَّم بـ«غير متحقَّق» أو «تحقق أنت».

**ابدأ من:** هذا الملف، ثم `docs/LAUNCH_CHECKLIST.md` (قائمة الإطلاق)، ثم `docs/SECURITY_AUDIT.md`
(تقرير المراجعة الأمنية، أكتوبر 2026، مع إصلاحات 15 و19 نوفمبر)، ثم `docs/ARCHITECTURE.md`.
فهرس الملفات المولَّد تلقائيًا في `_docs/`.

## 0. المشروع والمالك
- **SmartBudget** (من DGOTIX): تطبيق ميزانية شخصية بـ 23 لغة. Flutter/Dart للويب وأندرويد.
  الموقع `https://smartbudget.dgotix.com` (GitHub Pages). المستودع الخاص
  `djamalbarcha18-hue/smartbudget-DGOTIX`. مشروع Supabase: `fconhnyognxcpvmwobus`.
- المالك جزائري، غير تقني، يعمل غالبًا من الهاتف، ويتواصل بالعربية. يريد تقارير قصيرة.
- Riverpod، go_router، gen-l10n (ملفات `lib/l10n/app_*.arb`؛ المولَّد في `lib/l10n/gen/` غير محفوظ في git).

## 1. قواعد العمل المتفق عليها
1. العمل على فرع، ثم إثبات (اختبارات خضراء وصور)، ولا دمج في `main` إلا بعد كلمة **«انشر»** من المالك.
2. قبل «انشر»: انتظر نجاح Flutter CI و Security tests على الفرع. بعد الدمج: تحقق من Flutter CI و
   Android build و Security tests و Deploy Web Preview على `main`.
3. كل نص جديد يُضاف إلى **23 ملف ARB** كلها (في `en` أضف `@المفتاح` مع placeholders)، ثم `flutter gen-l10n`.
4. رموز اتجاه النص في Dart تُكتب هروبًا (`⁦` …)، وإلا حذّر المحلّل.
5. الدوران اللانهائي في الواجهة يكسر `pumpAndSettle` في الاختبارات.
6. لا تُطلب أسرار في المحادثة ولا لقطات شاشة فيها بيانات بطاقات أو كلمات مرور أو رموز.
7. لا تنشر ثيم Aurora (قال المالك: اتركه جانبًا).
8. لا مصدر يُؤخذ من تطبيق منافس (ChangeDA) دون إذن صاحبه.
9. اختبار SQL محليًا: PostgreSQL 16 + `supabase/tests/supabase_stub.sql` ثم `setup_all.sql` ثم ملفات `supabase/tests/*_test.sql`.
10. نسخة المتجر ممنوع أن تبيع أو تسعّر أو تربط بدفع (انظر §5 و`docs/PLAY_STORE.md`).

## 2. بنية `lib/`
| المسار | الدور |
|---|---|
| `main.dart`، `app.dart` | الإقلاع (Supabase، حفظ رمز الدعوة ورابط الجمعية من العنوان، الإشعارات)، `MaterialApp.router`، المستمعون العامّون |
| `core/env/app_env.dart` | كل مفاتيح البناء (`--dart-define`) |
| `core/config/app_config.dart` | اسم التطبيق، بريد الدعم، `supportWhatsApp` (فارغ حاليًا)، `publicUrl` |
| `core/router/app_router.dart` | المسارات، حارس الدخول، العودة إلى الصفحة المطلوبة بعد الدخول (`?from=`) |
| `core/storage/`، `money/`، `settings/`، `theme/`، `time/` | تخزين القوائم على الجهاز، العملات و`Money`، العملة الأساسية، السمات، `AppClock` |
| `design_system/` | المكوّنات (`DsButton`، `GlassCard`…) والألوان |
| `features/<اسم>/` | domain / data / application / presentation لكل ميزة |

مجلدات `features/` (حتى 2026-11-19): account، ai، analytics، app_lock، assistant، auth، backup، billing،
budget، **calculator**، challenges، daret، dashboard، debts، dev، exchange_rates، expenses،
financial_health، goals، guide، income، install، legal، markets، metals، monthly_budget،
notifications، offers، onboarding، portfolio، privacy، quick_entry، receipts، recurring، referrals،
reminders، reports، **sadaqah**، salary_split، search، seasons، settings، share، shell،
statement_import، support، sync، transactions، trips، wallets، **zakat**.

**أين تعيش بيانات المستخدم:** على الجهاز (`LocalListStore`، وقاعدة IndexedDB عند `INDEXED_DB=true`،
`docs/LOCAL_DATABASE.md`). المزامنة بين الأجهزة بوثيقة واحدة لكل حساب في `user_backups`
(`features/sync/`، مثبَّتة على الحساب).

## 3. Supabase
الملفات في `supabase/`؛ تُشغَّل يدويًا في محرر SQL. `setup_all.sql` يجمعها بهذا الترتيب
(`tool/build_supabase_setup.sh`، لا تعدّله يدويًا): schema، cloud_backup، billing، coupons، ai_gateway،
ai_reports، receipt_scanner، security_hardening، subscription_lifecycle، entitlement_expiry،
abuse_limits، sync، backup_snapshots، app_stats، launch_offers، referrals، error_reports،
account_tombstones، maintenance، search_path_hardening. آمن للتكرار، ومعاملة واحدة.

**الجداول والدوال (كلها عليها RLS):**
- **المالية:** `schema.sql`: currencies، exchange_rates (قراءة عامة)، profiles، categories،
  payment_methods، transactions، budgets، goals، goal_allocations، debts، zakat_records،
  financial_health_snapshots (لصاحبها). الزناد `handle_new_user` ينشئ `profiles`. التطبيق لا يقرأ هذه
  الجداول مباشرة (بياناته على الجهاز). 15–19 نوفمبر: منع العميل من حذف ملف `profiles` الخاص به.
- **النسخ والمزامنة:** `user_backups(user_id, data jsonb, schema_version, updated_at, version)`؛
  `user_backup_snapshots` (لقطة يومية، آخر 7 أيام).
- **الاشتراك:** `billing_prices` (معرّفات أسعار Whop و PayPal، للخادم)، `subscriptions` (ملخص يقرؤه
  صاحبه)، `billing_subscriptions` (كل اشتراك صفًا مستقلًا، للخادم)، `billing_events` (منع التكرار)،
  `ai_entitlements(user_id, plan, trial_plan, trial_expires_at, trial_used_at, حدود…)`،
  الدالة `apply_subscription_event()`، و`entitlement_expiry.sql`: `refresh_entitlement`،
  `expire_entitlements` (مجدولة كل ساعة بـ pg_cron) فلا يبقى Pro بعد انتهاء المدة لو تأخر الـ webhook.
- **الاستهلاك والحدود:** `ai_usage_*`، `ocr_usage_*`، `usage_daily`، `usage_pools`، `rate_limits`،
  `reserve_usage`، `release_usage`، `rate_limit_hit`، `add_ai_usage` (عدّ ذرّي).
- **الحذف:** `account_tombstones` + `record_account_tombstone`: بصمة SHA-256 للبريد (لا البريد) تُحفظ
  سنتين كي لا تعود التجربة المجانية ولا الحصص بعد حذف الحساب وإعادة التسجيل.
- **الصيانة:** `purge_old_rows` (يومية)، `scheduled_jobs_health()` (للتحقق).
- **الدعوات:** `referral_codes`، `referrals`، `reward_grants` + `my_referral_code`، `claim_referral`،
  `complete_referral`، `choose_reward`، `my_referral_progress`، `referral_picks_for`، `referral_rewards`.
- **أخرى:** `coupons`، `coupon_redemptions`، `coupon_attempts`؛ `start_pro_trial()`؛
  `error_reports_daily` + `report_error`؛ `app_stats_daily` + `count_event`؛ `ai_reports`.
- كل دوال SECURITY DEFINER ثبّتت `search_path` (`search_path_hardening.sql`).
- لا يوجد `parallel_rates.sql` على `main` (انظر §7).

**Edge Functions** (`supabase/functions/`): `create-checkout`، `whop-webhook`، `paypal-webhook`،
`manage-subscription`، `billing-config`، `coupon-validate`، `delete-account`، `ai-gateway`،
`receipt-scan`، `market-proxy`، `parallel-proxy`؛ والمشترك في `_shared/`.
19 نوفمبر: تقوية ثلاث دوال، وحذف الحساب الآمن (يتطلب دخولًا حديثًا، ولا يمنعه اشتراك ملغى)،
و**الوضع التجريبي يفشل مغلقًا**: `BETA_ALL_ACCESS` على الخادم لا يعمل إلا إذا كان السر `"true"` بالضبط
(`_shared/quota.ts`).
الأسرار التي تقرؤها الدوال: `WHOP_API_KEY`، `WHOP_WEBHOOK_SECRET`، `WHOP_COMPANY_ID`، `WHOP_API_URL`،
`WHOP_API_VERSION`، `PAYPAL_CLIENT_ID`، `PAYPAL_SECRET`، `PAYPAL_WEBHOOK_ID`، `PAYPAL_API_URL`،
`BETA_ALL_ACCESS`، `PAY_TEST_USER_IDS`، `FOUNDING_YEARLY_USD`، `FOUNDING_OFFER_ENDS_AT`،
`CHECKOUT_SUCCESS_URL`، `CHECKOUT_CANCEL_URL`، `ALLOWED_ORIGIN`، `GEMINI_API_KEY`، `GEMINI_MODEL`،
`EIA_API_KEY`، `METALPRICEAPI_KEY`، `MARKET_PROVIDER`، `NEW_ACCOUNT_DAYS`، `OCR_TIMEOUT_MS`.
**الأسرار الفعلية في لوحة Supabase: تحقق أنت** (لا تُرى من الكود).

## 4. تسجيل الدخول
- الواجهة `features/auth/domain/auth_repository.dart`؛ التنفيذ `data/supabase_auth_repository.dart`
  (Supabase Auth). بلا مفاتيح Supabase: `data/fake_auth_repository.dart`.
- بريد + كلمة مرور (`domain/password_policy.dart`)، وإعادة تعيين بالرمز، والتحقق البشري Cloudflare
  Turnstile (`presentation/captcha/`).
- **Google:** مفعَّل في **الويب** (`GOOGLE_SIGN_IN=true` في `deploy-web.yml`): زر Google على الويب،
  ثم `signInWithIdToken` مع nonce (`domain/google_nonce.dart`)؛ وصورة الحساب تظهر في الشريط العلوي.
  **في تطبيق أندرويد غير مفعَّل** (`android.yml`: البريد فقط، وتسجيل Google الأصلي يأتي مع نسخة المتجر).
  الإعداد في Google Cloud و Supabase: تحقق أنت (`docs/GOOGLE_SIGN_IN.md`). Apple غير مبني.
- `data/device_data_adoption.dart`: نقل بيانات الجهاز إلى الحساب عند أول دخول.

## 5. الاشتراك والدفع
- **الخطط:** `enum Plan { free, pro }` (`billing/domain/plan.dart`). Pro: 9.99$ شهريًا، 59.99$ سنويًا
  في الكود. القواعد والحصص في `billing/domain/feature_catalog.dart` و`feature_gate.dart`
  (الخادم يكرر الحصص في `_shared/quota.ts`)؛ التسعير في `docs/PRICING.md`.
  أمثلة المجاني: محفظتان، 5 ميزانيات فئات، هدفان، ديْنان، جمعية واحدة، **حتى 12 عضوًا في الجمعية**.
- **مصدر الحقيقة:** `ai_entitlements.plan` على الخادم، يكتبه الخادم فقط. العميل:
  `data/entitlement_service.dart` ← `application/entitlement_controller.dart`
  (`remoteEntitlementProvider` → `effectivePlanProvider`)، مع نسخة محفوظة 7 أيام للعمل بلا اتصال،
  وإعادة القراءة عند العودة للتطبيق وكل ساعة.
- **مفاتيح البناء:**
  - `BETA_ALL_ACCESS` (افتراضي `true` في الكود): يجعل الجميع Pro ويخفي البيع.
    `deploy-web.yml` و`android.yml` يمرّران الآن `BETA_ALL_ACCESS=false` (**الدفع مفتوح فعليًا في البناءين**).
  - `STORE_BUILD=true` (أندرويد فقط) مع `BETA_ALL_ACCESS=false` ⇒ **`AppEnv.storeFreeMode`**: تُطبَّق حدود
    المجاني، والخطة تُقرأ من الخادم (من اشترك من الويب يعمل عنده Pro بالحساب نفسه)، وصفحة الخطط ملاحظة
    نصية فقط، بلا أسعار ولا كوبون ولا تجربة ولا «إدارة الاشتراك» ولا بطاقة ترقية
    (`upgrade_popup.dart: StorePlanNotice`، `plans_page.dart: _StorePlansNote`). اختباراته:
    `test/store_free_mode_test.dart` (تُشغَّل في CI بإعدادات المتجر).
  - الكوبونات مخفية حتى `--dart-define=COUPONS=true` (لا يطبّقها `create-checkout` بعد).
- **بوابات الدفع:**
  - **Whop:** `create-checkout`، `whop-webhook` (توقيع Standard Webhooks)، `_shared/whop.ts`؛ الوثيقة
    `docs/BILLING.md`. تُجرِّب Whop دفعًا شهريًا بخصم 95%؛ الشراء **السنوي** والتفعيل لحظة الدفع بعد
    الإصلاح: لم يُؤكَّدا بعد (`LAUNCH_CHECKLIST.md`).
  - **PayPal:** `_shared/paypal.ts`، `paypal-webhook`، `provider:"paypal"` في `create-checkout`. لم يُجرَّب
    كاملًا؛ القائمة تقترح تجربته أو إخفاءه والبيع على Whop وحده.
  - **غير موجود:** Google Play Billing، وسائل دفع جزائرية محلية (الذهبية/بريدي موب). Paddle أُزيل.
  - وضع اختبار الدفع: `?paytest=1` على الويب، مسموح فقط حين يعيد `billing-config` `sandbox:true` أو
    `liveTest:true` (حسابات `PAY_TEST_USER_IDS`).
- **سياسة Google Play** (من بحث، لا من نص السياسة الرسمي): خارج أمريكا وأوروبا يُمنع داخل التطبيق أي
  سعر أو رابط أو عبارة تقود إلى دفع خارجي. التوجيه إلى الموقع يكون **خارج** التطبيق (بريد، صفحات اجتماعية،
  الموقع، الإعلانات). راجع صفحة «Payments policy» في Play Console قبل الإطلاق.
  رابط دعم محايد في صفحة الدعم فقط مقبول، لا بجانب ميزة مقفلة.

## 6. النشر
- `deploy-web.yml`: بناء الويب ورفعه إلى GitHub Pages (مرحلة الرفع علقت عدة مرات يوم 2026-11-10 ثم نجحت).
- `android.yml`: `.aab` و`.apk` (STORE_BUILD)؛ التوقيع من الأسرار (`ANDROID_KEYSTORE_BASE64` وغيرها:
  تحقق أنت؛ بدونها يوقَّع بمفتاح تصحيح).
- `flutter-ci.yml`: تحليل + الاختبارات + خطوة وضع المتجر. `security-tests.yml`: PostgreSQL حقيقي
  (`supabase/tests/*.sql`) + Deno. `supabase-functions.yml`: ينشر الدوال عند تغيّر `supabase/functions/**`.
- نسخة قاعدة البيانات الاحتياطية الليلية **نُقلت إلى مستودع خاص** (لا `db-backup.yml` هنا).

## 7. المهام غير المكتملة والمشاكل المعروفة
**فروع جاهزة غير مدموجة:**
- `feat/owner-parallel-rates`: أسعار السوق الموازية للجزائر يُدخلها المالك (صفحة إدارة +
  `supabase/parallel_rates.sql` + جدول `app_admins`). المالك أجّل القرار. إلى ذلك الحين يظهر السعر
  «غير متاح» على `main` لأن `squarealgerie.com` (`markets/data/square_dz_repository.dart`) متوقف.
  المصدر الآلي الوحيد المعروف تجاري (ChangeDA) ولا يجوز أخذه دون إذن.

**من `LAUNCH_CHECKLIST.md` (تحقق أنت):**
- شغّل `supabase/setup_all.sql` كاملًا، ثم `select * from public.scheduled_jobs_health();`
  (يجب أن تكون `expire-entitlements` و`purge-old-rows` مجدولتين).
- تجربة شراء كاملة: السنوي، والتفعيل لحظة الدفع، والاسترداد (يُسحب من الرصيد **المتاح** في Whop)،
  ومفتاح Whop (`smartbudget-server`) وصلاحياته.
- يوم الإطلاق: حذف `PAY_TEST_USER_IDS`، وتعطيل الكودين `TEST95` و`TEST95B`، وضبط السر
  `BETA_ALL_ACCESS` في Supabase ليطابق البناء، وخطة founding yearly في Whop (59.99 والمقصود 39.99)،
  و`FOUNDING_OFFER_ENDS_AT`، ورفع حد رسائل البريد، والترقية إلى Supabase Pro **يوم فتح الدفع للعموم**.
- تحديث سياسة الخصوصية (بصمة البريد سنتين بعد الحذف).
- اختبار استعادة النسخة الاحتياطية (النسخ الليلي يعمل، الاستعادة لم تُجرَّب).

**Google Play:** حساب المطوّر (لم يُنشأ)، اختبار مغلق (12 مختبرًا × 14 يومًا)، أسرار التوقيع،
نموذج «أمان البيانات» (RECORD_AUDIO والإشعارات). المالك في الجزائر: **قائمة بلدان استلام أرباح Google
غير متحقَّقة**؛ الأرجح أن الدفع عبر الويب هو الطريق الوحيد.
**شارة «Google Play» في الويب** وجملة «اشترك هنا ثم سجّل بالحساب نفسه في تطبيق أندرويد»: غير موجودة
بعد، وتنتظر رابط التطبيق في المتجر (تُبنى مخفية).

**ينتظر المالك:** اختبار الدعوة الحقيقي (نافذة خاصة + بريد ثانٍ)، المزامنة على جهازين، مشاركة الجمعية
على هاتف حقيقي، رقم واتساب الدعم (`AppConfig.supportWhatsApp`؛ رابط اسم المستخدم `wa.me/…` غير
متحقَّق)، مفتاح `EIA_API_KEY`، إعداد Google في اللوحات.

**مخفي عمدًا:** عداد الرحلات المجهول (`ANON_STATS`، `docs/APP_STATS.md`)، رصد الأخطاء يُبنى بـ
`ERROR_REPORTS=true` (مفعّل في الـworkflows؛ يلزم `supabase/error_reports.sql`).
بند شروط عروض الشركاء (`docs/SMART_TRIP.md`) ومكافأة «ادعُ صديقًا» الإضافية (`docs/PRICING.md` §7):
بعد الإطلاق.

**معروف:** روابط الدعوة والجمعية على أندرويد تفتح الويب في المتصفح لا التطبيق المثبَّت. دفعة الاستيراد
من الإكسل مقيَّدة الحجم. الأسعار الرسمية لبنك الجزائر وتبويب أسعار «الرقمي» أفكار غير منفَّذة.

**أفكار مؤجلة (لم تُنفَّذ):** وسيلة دفع محلية، بريد متابعة للمسجّلين، قياس الاستخدام، متجر القوالب
والملصقات، دخول Apple، جمعية حيّة مشتركة، تنبيه السعر القديم.

## 8. الفحص الأسبوعي
Supabase المجاني يوقف المشروع بعد نحو أسبوع بلا نشاط: افتح
`https://supabase.com/dashboard/project/fconhnyognxcpvmwobus` وتأكد أن الحالة **Healthy**؛ وإن كان
Paused فـ **Restore project** ثم أعد فحص الـ webhooks.
