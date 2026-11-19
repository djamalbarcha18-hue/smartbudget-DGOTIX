# Database backups

The Supabase free plan keeps no backups, so a `db-backup.yml` workflow makes
one every day (02:23 UTC) and on demand (Actions > Database backup > Run
workflow — do this before any large change).

**The workflow lives in the owner's private repository
`smartbudget-DGOTIX-APP`, not here.** Artifacts of a public repository can be
downloaded by anyone signed in to GitHub, so the backups (every account's data,
e-mails and password hashes, even encrypted) must never be produced in this
public repository. Never add `SUPABASE_DB_URL` or `BACKUP_PASSPHRASE` to this
repository's secrets.

Each backup is a `pg_dump` of:

| File | What |
|---|---|
| `schema.sql` | the `public` schema (tables, policies, functions), for reference |
| `public-data.sql` | all rows of the app's own tables |
| `auth-users.sql` | the accounts (`auth.users`, `auth.identities`) — not sessions, tokens or logs |

It is packed and **encrypted with AES-256 (gpg) on the runner**, then kept as a
workflow artifact for **30 days** in the private repository, which only the
owner can see. Only the encrypted file ever leaves the runner (defence in
depth); it opens only with the passphrase. The run fails (and GitHub emails
the owner) if a dump comes back empty or the file can't be decrypted.

## Setup (once)

In the **private** repository `smartbudget-DGOTIX-APP` (check Settings > General
shows it as Private first), repository secrets (Settings > Secrets and
variables > Actions):

- `SUPABASE_DB_URL` — Supabase dashboard > **Connect** > **Session pooler**
  connection string, with `[YOUR-PASSWORD]` replaced by the database password.
  (The direct `db.<ref>.supabase.co` address is IPv6-only and GitHub runners
  can't reach it.) A password with characters such as `@ # / ?` must be
  URL-encoded; the simplest is to reset it to letters and digits only
  (Project Settings > Database > Reset database password).
- `BACKUP_PASSPHRASE` — 32+ random characters from a password manager (the
  workflow refuses fewer than 16). **Keep a copy outside GitHub**
  (a password manager): GitHub never shows a secret again, and without the
  passphrase no backup can be opened.

## Restore

1. In `smartbudget-DGOTIX-APP`: Actions > Database backup > a run > **Artifacts**: download
   `smartbudget-db-YYYY-MM-DD` and unzip it.
2. Decrypt and unpack (asks for the passphrase):

   ```bash
   gpg -d smartbudget-db-YYYY-MM-DD.tar.gz.gpg | tar -xzf -
   ```
3. Into an **empty** project (a new one, or after the data was lost):

   ```bash
   psql "$DB_URL" -v ON_ERROR_STOP=1 -f supabase/setup_all.sql   # schema, policies, functions
   psql "$DB_URL" -v ON_ERROR_STOP=1 -f auth-users.sql            # accounts first (other tables point to them)
   psql "$DB_URL" -v ON_ERROR_STOP=1 -f public-data.sql           # then the app's data
   ```

   `schema.sql` shows the schema as it was on that day, to compare with
   `setup_all.sql` if they have drifted apart.

Users keep their data on their own devices too (local-first), so after a
restore their apps sync back anything newer than the backup.
