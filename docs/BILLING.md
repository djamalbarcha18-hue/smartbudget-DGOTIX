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

## Not yet wired

- **Coupon → Paddle discount**: our `coupons` preview is separate from Paddle's
  own discounts. Passing a validated coupon as a Paddle `discount_id` at checkout
  (and recording redemption on `transaction.completed`, already stubbed) is the
  next step.
- **Manage/cancel from inside the app** (Paddle customer portal link).
- **Proration/upgrade mid-cycle** beyond what Paddle handles by default.
