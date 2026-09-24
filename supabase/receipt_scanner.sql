-- ============================================================================
-- SmartBudget — Receipt Scanner: remove personal (BYOK) Gemini keys
-- ----------------------------------------------------------------------------
-- DGOTIX is the only AI provider: receipt scanning uses the server's own key
-- (GEMINI_API_KEY Edge Function secret) and every scan is metered against the
-- plan's cloud-OCR quota. Users no longer store personal keys, so the old
-- encrypted-key table is removed along with any keys it held.
--
-- Apply via the Supabase SQL editor or CLI. Safe to re-run.
-- ============================================================================

drop table if exists user_ai_keys;
