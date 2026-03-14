-- Add subscription columns to users table
ALTER TABLE users 
  ADD COLUMN IF NOT EXISTS subscription_status TEXT DEFAULT 'none',
  ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS subscription_started_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT;

COMMENT ON COLUMN users.subscription_status IS 'none | active | expired | cancelled';
COMMENT ON COLUMN users.subscription_expires_at IS 'Data scadenza abbonamento annuale';
COMMENT ON COLUMN users.subscription_started_at IS 'Data inizio abbonamento';
