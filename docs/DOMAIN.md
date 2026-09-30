# Domain: smartbudget.dgotix.com

The web app is served by GitHub Pages at **https://smartbudget.dgotix.com/**
(`dgotix.com` is registered at Namecheap; the root is kept for a DGOTIX brand
site later). The old address, `djamalbarcha18-hue.github.io/smartbudget-DGOTIX/`,
redirects to the domain once it is set in GitHub.

## DNS (Namecheap → Domain List → dgotix.com → Manage → Advanced DNS)

| Type | Host | Value | TTL |
|---|---|---|---|
| CNAME Record | `smartbudget` | `djamalbarcha18-hue.github.io.` | Automatic |

Optional, recommended (protects the domain from being claimed by another
GitHub account): GitHub → your profile Settings → Pages → *Add a domain* →
`dgotix.com`, then add the TXT record it shows.

## GitHub

Repository → Settings → Pages → Custom domain: `smartbudget.dgotix.com` →
Save. When the DNS check passes (minutes, sometimes up to a few hours) tick
**Enforce HTTPS**.

## In the code

- The web build uses a relative base (`<base href="./">`), so the same bundle
  works at the domain and at the old github.io path (routes are hash-based).
- `AppConfig.fallbackUrl` is the domain: used by the Android app (sharing,
  QR code, world-time sync). The web app shares the address it runs at.
- With Supabase: set `ALLOWED_ORIGIN=https://smartbudget.dgotix.com` and
  `CHECKOUT_SUCCESS_URL=https://smartbudget.dgotix.com/#/plans`, and add the
  domain to Supabase Auth → URL configuration.
