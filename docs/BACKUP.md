# Database backups

The Supabase free plan keeps no backups, so `.github/workflows/db-backup.yml`
makes one every day (02:23 UTC) and on demand (Actions > Database backup > Run
workflow — do this before any large change).

Each backup is a `pg_dump` of:

| File | What |
|---|---|
| `schema.sql` | the `public` schema (tables, policies, functions), for reference |
| `public-data.sql` | all rows of the app's own tables |
| `auth-users.sql` | the accounts (`auth.users`, `auth.identities`) — not sessions, tokens or logs |

It is packed and **encrypted with AES-256 (gpg) on the runner**, then kept as a
workflow artifact for **30 days**. The repository is public and anyone signed
in to GitHub can download its artifacts, so only the encrypted file ever leaves
the runner; it opens only with the passphrase. The run fails (and GitHub emails
the owner) if a dump comes back empty or the file can't be decrypted.

## Setup (once)

Repository secrets (Settings > Secrets and variables > Actions):

- `SUPABASE_DB_URL` — Supabase dashboard > **Connect** > **Session pooler**
  connection string, with `[YOUR-PASSWORD]` replaced by the database password.
  (The direct `db.<ref>.supabase.co` address is IPv6-only and GitHub runners
  can't reach it.) A password with characters such as `@ # / ?` must be
  URL-encoded; the simplest is to reset it to letters and digits only
  (Project Settings > Database > Reset database password).
- `BACKUP_PASSPHRASE` — at least 16 characters. **Keep a copy outside GitHub**
  (a password manager): GitHub never shows a secret again, and without the
  passphrase no backup can be opened.

## Restore

1. Actions > Database backup > a run > **Artifacts**: download
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
