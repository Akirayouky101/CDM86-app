-- ═══════════════════════════════════════════════════════════════════
-- DEBUG: Verifica cosa è stato creato nel database
-- Esegui nel Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════════

-- 1. Controlla se il collaboratore esiste in collaborators
SELECT 
    '=== COLLABORATORS ===' AS tabella,
    id,
    email,
    first_name,
    last_name,
    status,
    auth_user_id,
    user_id
FROM public.collaborators
WHERE email = 'collab.test@cdm86.it';

-- 2. Controlla se esiste in public.users
SELECT 
    '=== PUBLIC.USERS ===' AS tabella,
    id,
    email,
    first_name,
    last_name,
    referred_by_id,
    referral_code,
    auth_user_id
FROM public.users
WHERE email IN (
    'collab.test@cdm86.it',
    'l1a.test@cdm86.it', 'l1b.test@cdm86.it',
    'l2a.test@cdm86.it', 'l2b.test@cdm86.it',
    'l3a.test@cdm86.it', 'l3b.test@cdm86.it'
);

-- 3. Controlla se esiste in auth.users
SELECT 
    '=== AUTH.USERS ===' AS tabella,
    id,
    email,
    created_at,
    email_confirmed_at
FROM auth.users
WHERE email IN (
    'collab.test@cdm86.it',
    'l1a.test@cdm86.it', 'l1b.test@cdm86.it',
    'l2a.test@cdm86.it', 'l2b.test@cdm86.it',
    'l3a.test@cdm86.it', 'l3b.test@cdm86.it'
);

-- 4. Quanti collaboratori ci sono in totale?
SELECT COUNT(*) AS totale_collaboratori, status FROM public.collaborators GROUP BY status;
