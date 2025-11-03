-- Check if Akirayouky and test users have referred_by_id
SELECT 
    email,
    referral_code,
    referred_by_id,
    CASE 
        WHEN referred_by_id IS NULL THEN '❌ NO REFERRER'
        ELSE '✅ HAS REFERRER'
    END as has_referrer,
    first_name,
    last_name,
    created_at
FROM users
WHERE email IN ('akirayouky@cdm86.com', 'diegomarruchi@outlook.it', 'testb@cdm86.com', 'testc@cdm86.com', 'testd@cdm86.com')
ORDER BY created_at;

-- Check who referred testb
SELECT 
    'testb referred by:' as info,
    u1.email as testb_email,
    u1.referred_by_id,
    u2.email as referrer_email,
    u2.first_name as referrer_first_name,
    u2.last_name as referrer_last_name,
    u2.referral_code as referrer_code
FROM users u1
LEFT JOIN users u2 ON u1.referred_by_id = u2.id
WHERE u1.email = 'testb@cdm86.com';
