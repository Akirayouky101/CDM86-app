-- Check if referral_code column exists and has data
SELECT 
    email,
    referral_code,
    CASE 
        WHEN referral_code IS NULL THEN '❌ NULL'
        WHEN referral_code = '' THEN '❌ EMPTY STRING'
        ELSE '✅ HAS CODE: ' || referral_code
    END as status,
    referred_by_id,
    first_name,
    last_name
FROM users
WHERE email IN ('akirayouky@cdm86.com', 'diegomarruchi@outlook.it')
ORDER BY created_at DESC;

-- Check table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'users' 
AND column_name IN ('referral_code', 'referred_by_id', 'email')
ORDER BY ordinal_position;
