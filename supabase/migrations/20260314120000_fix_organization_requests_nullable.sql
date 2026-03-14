-- Fix organization_requests: make referred_by_id and referred_by_code nullable
-- Companies registering without a referral should still be able to submit requests

ALTER TABLE organization_requests 
    ALTER COLUMN referred_by_id DROP NOT NULL,
    ALTER COLUMN referred_by_code DROP NOT NULL;
