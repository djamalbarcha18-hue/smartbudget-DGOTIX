# SmartBudget — Billing (subscriptions via Whop)

Provider-agnostic by design: the app never talks to Whop directly. A checkout
is created **server-side** (`create-checkout`) and Whop's **webhook**
(`whop-webhook`) is the only thing that grants or revokes a paid plan — the
server stays the source of truth. The Whop API key lives **only** in Edge
Function secrets; the frontend just opens a checkout URL.

```
Plans screen ──▶ create-checkout (Edge Fn, WHOP_API_KEY)
                    └─ maps (plan,period) → Whop plan via billing_prices
                    └─ POST /checkout_configurations (metadata.user_id)
                    └─ returns purchase_url ──▶ Whop's hosted checkout
                                                (then back to #/plans)
Whop ──(membership.* / payment.* / refund.* / dispute.*)──▶ whop-webhook
                    └─ verify signature (Standard Webhooks), dedupe
                    └─ GET /memberships/{id}: Whop's current state
                    └─ sets ai_entitlements.plan + subscriptions snapshot
Client ──▶ remoteEntitlementProvider re-fetches ▶ plan reflects the purchase
```

Why Whop: it pays out to sellers in Algeria (bank, mobile wallet or crypto)
and runs the checkout (cards, Apple Pay, Google Pay…). Unlike Paddle (the
previous provider, removed) it is **not** the merchant of record for taxes by
default: turn on **Whop Collects and Remits** in Whop's tax settings so Whop
calculates, collects and remits VAT / sales tax; otherwise that stays
DGOTIX's job. API shapes follow Whop's API v1 (`https://api.whop.com/api/v1`),
as in the official `@whop/sdk`.

## One-time setup (owner)

1. **Create the product & plans** in the Whop dashboard: one product
   (SmartBudget Premium) with two **renewing** plans matching
   `docs/PRICING.md` — $7.99 / month and $49.99 / year. Copy each plan id
   (`plan_...`).

2. **Apply the schema** and record the plan ids:

   ```bash
   supabase db execute -f supabase/billing.sql
   supabase db execute -f supabase/subscription_lifecycle.sql
   ```
   ```sql
   -- Premium is stored as 'pro'.
   insert into billing_prices (price_id, provider, plan, period) values
     ('plan_xxx_monthly', 'whop', 'pro', 'monthly'),
     ('plan_xxx_yearly',  'whop', 'pro', 'yearly')
   on conflict (price_id) do update set provider = excluded.provider,
     plan = excluded.plan, period = excluded.period, active = true;
   ```

3. **Deploy the functions** (the GitHub workflow does this on every push to
   `main`; by hand):

   ```bash
   supabase functions deploy create-checkout
   supabase functions deploy whop-webhook --no-verify-jwt   # Whop can't send a user JWT
   supabase functions deploy manage-subscription billing-config
   supabase functions delete paddle-webhook                 # the removed provider
   ```

4. **Secrets** (and remove the old Paddle ones):

   ```bash
   supabase secrets set WHOP_API_KEY=...                 # company API key
   supabase secrets set WHOP_WEBHOOK_SECRET=ws_...       # from the webhook, as shown
   supabase secrets set WHOP_COMPANY_ID=biz_...          # optional: the account to sell from
   supabase secrets set WHOP_API_URL=https://sandbox-api.whop.com/api/v1   # sandbox only
   supabase secrets set CHECKOUT_SUCCESS_URL=https://smartbudget.dgotix.com/#/plans
   supabase secrets unset PADDLE_API_KEY PADDLE_API_URL PADDLE_WEBHOOK_SECRET PADDLE_CLIENT_TOKEN PADDLE_CHECKOUT_PAGE
   ```

   The API key needs to create checkout configurations and read memberships
   (including `member:manage`, for the buyer's billing page link).

5. **Webhook**: in Whop → Developer → Webhooks, add one with API version
   **v1** pointing at the `whop-webhook` function URL, subscribed to
   `membership.activated`, `membership.updated`, `membership.deactivated`,
   `payment.succeeded`, `payment.failed`, `refund.created`, `refund.updated`,
   `dispute.created` and `dispute.updated`. Put its secret in
   `WHOP_WEBHOOK_SECRET` exactly as shown (`ws_...`, prefix included).

## How entitlement changes

Each event only says *which* membership changed; the webhook reads that
membership back from Whop and applies its current state, so deliveries in any
order end in Whop's latest state:

- `active` / `trialing` → the plan of its `plan_id` (only from
  `billing_prices`, so an unknown plan never unlocks a tier).
- `canceling` (cancelled, paid until the period ends) → still the plan, with
  "ends on" shown.
- `past_due` / `unresolved` (failed payment, open dispute) → no paid access;
  Manage stays available to fix the card.
- `canceled` / `expired` / `completed` → back to `free`; the user keeps all
  their own data. A refund or chargeback acts through the state Whop gives the
  membership after it.
- Every delivery is deduped by its `webhook-id` (`billing_events`) and signed
  deliveries older than 5 minutes are refused.

## Testing (sandbox)

Use `WHOP_API_URL=https://sandbox-api.whop.com/api/v1` with a sandbox API key
and webhook. Buy each plan, confirm `ai_entitlements.plan` flips and the app
reflects it after a refresh, then cancel from Manage and confirm it returns to
`free` when the period ends.

## Adding PayPal (second provider)

The billing spine is provider-agnostic — `billing_prices.provider` and
`subscriptions.provider` keep each provider's ids side by side, and
`create-checkout` branches on a `provider` field. To enable PayPal alongside (or
instead of) Whop:

1. **Create subscription billing plans** in PayPal (one per plan+period),
   matching `docs/PRICING.md`. Copy each **plan id** (`P-...`).

2. **Record the plan ids** with `provider = 'paypal'`:

   ```sql
   insert into billing_prices (price_id, provider, plan, period) values
     ('P-PREMIUM-MONTHLY', 'paypal', 'pro', 'monthly'),
     ('P-PREMIUM-YEARLY',  'paypal', 'pro', 'yearly')
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
   `BILLING.SUBSCRIPTION.EXPIRED`, `BILLING.SUBSCRIPTION.SUSPENDED`,
   `BILLING.SUBSCRIPTION.RE-ACTIVATED`, `BILLING.SUBSCRIPTION.UPDATED`,
   `BILLING.SUBSCRIPTION.PAYMENT.FAILED`, `PAYMENT.SALE.COMPLETED`,
   `PAYMENT.SALE.REFUNDED` and `PAYMENT.SALE.REVERSED`. Put its id in
   `PAYPAL_WEBHOOK_ID`.

`billing-config` reports which providers have their secrets set, so the Plans
screen only offers the payment methods that actually work. Grant/revoke is
identical to Whop: an active subscription sets the paid plan, a
cancelled/expired/suspended one returns to `free`, every event deduped by id.

## Payment test mode (during the beta)

While `BETA_ALL_ACCESS` is on, nothing is sold and the Plans screen shows no
checkout. To try a purchase end to end anyway, open the web app with
`?paytest=1` (e.g. `https://smartbudget.dgotix.com/?paytest=1#/plans`). The
upgrade buttons then appear — but only while `billing-config` reports
`sandbox: true`, i.e. every configured provider points at its sandbox
(`PAYPAL_API_URL=https://api-m.sandbox.paypal.com`, Whop's
`WHOP_API_URL=https://sandbox-api.whop.com/api/v1`). With any live provider the
flag does nothing, so it can never take real money. The store build ignores it.

After paying with a sandbox buyer, the "You're on …" card shows the plan and
`billing_subscriptions` holds the row; Manage cancels it.

> **Algeria note:** PayPal must be able to *receive* payments on your account.
> Confirm this with PayPal before relying on it in production.

## Not yet wired

- **Coupon → Whop promo code**: our `coupons` preview is separate from Whop's
  own promo codes. Creating the matching Whop promo code and recording the
  redemption from the webhook is the next step.
- **Proration/upgrade mid-cycle** beyond what the provider handles by default.

## Done since

- **Manage/cancel from inside the app**: the Plans screen shows the active plan
  and renewal date with a "Manage subscription" button (`manage-subscription`
  returns the membership's Whop billing page (`manage_url`), or the PayPal
  autopay page).
