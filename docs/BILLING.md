# SmartBudget — Billing (subscriptions via Paddle)

Provider-agnostic by design: the app never talks to Paddle directly. A checkout
is created **server-side** (`create-checkout`) and Paddle's **webhook**
(`paddle-webhook`) is the only thing that grants or revokes a paid plan — the
server stays the source of truth. Paddle API keys live **only** in Edge Function
secrets; the frontend just opens a checkout URL.

```
Plans screen ──▶ create-checkout (Edge Fn, PADDLE_API_KEY)
                    └─ maps (plan,period) → Paddle price via billing_prices
                    └─ creates a Paddle transaction (custom_data.user_id)
                    └─ returns checkout.url ──▶ browser opens it
Paddle ──(subscription.*/transaction.*)──▶ paddle-webhook (verify signature)
                    └─ sets ai_entitlements.plan  + subscriptions snapshot
Client ──▶ remoteEntitlementProvider re-fetches ▶ plan reflects the purchase
```

Why Paddle: it is a **Merchant of Record** — it handles VAT/sales tax globally
and settles in regions where card acquirers like Stripe can't pay out, which
fits selling worldwide from MENA.

## One-time setup (owner)

1. **Create the products & prices** in the Paddle dashboard (Catalog → Products):
   one product per plan, with a **monthly** and a **yearly** price each, matching
   `docs/PRICING.md` (BASIC $7.99 / $50, PRO $14.99 / $119). Copy each price id
   (`pri_...`).

2. **Apply the schema** and record the price ids:

   ```bash
   supabase db execute -f supabase/ai_gateway.sql   # if not already applied
   supabase db execute -f supabase/billing.sql
   ```
   ```sql
   insert into billing_prices (price_id, plan, period) values
     ('pri_basic_monthly', 'basic', 'monthly'),
     ('pri_basic_yearly',  'basic', 'yearly'),
     ('pri_pro_monthly',   'pro',   'monthly'),
     ('pri_pro_yearly',    'pro',   'yearly')
   on conflict (price_id) do update set plan = excluded.plan, period = excluded.period;
   ```

3. **Deploy the functions**:

   ```bash
   supabase functions deploy create-checkout
   supabase functions deploy paddle-webhook --no-verify-jwt   # Paddle can't send a user JWT
   supabase functions deploy manage-subscription              # in-app manage/cancel link
   ```

4. **Secrets**:

   ```bash
   supabase secrets set PADDLE_API_KEY=...          # server-side API key
   supabase secrets set PADDLE_API_URL=https://sandbox-api.paddle.com   # or https://api.paddle.com
   supabase secrets set PADDLE_WEBHOOK_SECRET=...   # from the notification destination
   supabase secrets set CHECKOUT_SUCCESS_URL=https://djamalbarcha18-hue.github.io/smartbudget-DGOTIX/#/plans
   ```

5. **Webhook**: in Paddle → Developer tools → Notifications, add a destination
   pointing at the `paddle-webhook` function URL, subscribed to
   `subscription.activated`, `subscription.created`, `subscription.updated`,
   `subscription.canceled`, and `transaction.completed`. Put its secret in
   `PADDLE_WEBHOOK_SECRET`.

## How entitlement changes

- **Active / trialing** subscription → `ai_entitlements.plan` is set to the paid
  plan (limits follow automatically via `_shared/quota.ts`).
- **Canceled** (Paddle sends the event when the cancellation takes effect at
  period end) → plan is set back to `free`; the user keeps all their own data.
- Every event is deduped by `event_id` (`billing_events`) so replays are safe.
- Plan is granted **only** from a price id present in `billing_prices`, so an
  unknown/foreign price can never unlock a tier.

## Testing (sandbox)

Use `PADDLE_API_URL=https://sandbox-api.paddle.com`, a sandbox API key, and
Paddle's test cards. Buy each plan, confirm `ai_entitlements.plan` flips and the
app reflects it after a refresh, then cancel and confirm it returns to `free`.

## Adding PayPal (second provider)

The billing spine is provider-agnostic — `billing_prices.provider` and
`subscriptions.provider` keep each provider's ids side by side, and
`create-checkout` branches on a `provider` field. To enable PayPal alongside (or
instead of) Paddle:

1. **Create subscription billing plans** in PayPal (one per plan+period),
   matching `docs/PRICING.md`. Copy each **plan id** (`P-...`).

2. **Record the plan ids** with `provider = 'paypal'`:

   ```sql
   insert into billing_prices (price_id, provider, plan, period) values
     ('P-BASIC-MONTHLY', 'paypal', 'basic', 'monthly'),
     ('P-BASIC-YEARLY',  'paypal', 'basic', 'yearly'),
     ('P-PRO-MONTHLY',   'paypal', 'pro',   'monthly'),
     ('P-PRO-YEARLY',    'paypal', 'pro',   'yearly')
   on conflict (price_id) do update set plan = excluded.plan, period = excluded.period;
   ```

3. **Deploy the functions** (create-checkout is shared; add the PayPal webhook):

   ```bash
   supabase functions deploy create-checkout
   supabase functions deploy paypal-webhook --no-verify-jwt
   supabase functions deploy billing-config
   ```

4. **Secrets**:

   ```bash
   supabase secrets set PAYPAL_CLIENT_ID=... PAYPAL_SECRET=...
   supabase secrets set PAYPAL_API_URL=https://api-m.sandbox.paypal.com   # live: https://api-m.paypal.com
   supabase secrets set PAYPAL_WEBHOOK_ID=...   # from the webhook you create in PayPal
   ```

5. **Webhook**: in the PayPal developer dashboard, add a webhook pointing at the
   `paypal-webhook` function URL, subscribed to `BILLING.SUBSCRIPTION.ACTIVATED`,
   `BILLING.SUBSCRIPTION.UPDATED`, `BILLING.SUBSCRIPTION.CANCELLED`,
   `BILLING.SUBSCRIPTION.EXPIRED`, and `BILLING.SUBSCRIPTION.SUSPENDED`. Put its
   id in `PAYPAL_WEBHOOK_ID`.

`billing-config` reports which providers have their secrets set, so the Plans
screen only offers the payment methods that actually work. Grant/revoke is
identical to Paddle: an active subscription sets the paid plan, a
cancelled/expired/suspended one returns to `free`, every event deduped by id.

> **Algeria note:** PayPal must be able to *receive* payments on your account.
> Confirm this with PayPal before relying on it in production.

## Not yet wired

- **Coupon → Paddle discount**: our `coupons` preview is separate from Paddle's
  own discounts. Passing a validated coupon as a Paddle `discount_id` at checkout
  (and recording redemption on `transaction.completed`, already stubbed) is the
  next step.
- **Proration/upgrade mid-cycle** beyond what the provider handles by default.

## Done since

- **Manage/cancel from inside the app**: the Plans screen shows the active plan
  and renewal date with a "Manage subscription" button (`manage-subscription`
  returns the Paddle hosted management URL, or the PayPal autopay page).
