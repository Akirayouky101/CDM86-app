-- Fix: Add referral_code to users who don't have one
-- Generate 8-character uppercase alphanumeric codes

UPDATE users
SET referral_code = UPPER(
    SUBSTRING(MD5(RANDOM()::TEXT || id::TEXT || email) FROM 1 FOR 8)
)
WHERE referral_code IS NULL OR referral_code = '';

-- Verify all users now have codes
SELECT 
    email,
    referral_code,
    CASE 
        WHEN referral_code IS NULL THEN '❌ STILL NULL'
        WHEN referral_code = '' THEN '❌ STILL EMPTY'
        ELSE '✅ OK'
    END as status
FROM users
ORDER BY created_at DESC;
