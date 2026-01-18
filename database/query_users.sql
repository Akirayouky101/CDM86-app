-- ============================================
-- QUERY PER VISUALIZZARE UTENTI ESISTENTI
-- Esegui queste query in Supabase SQL Editor
-- ============================================

-- 1. CONTEGGIO UTENTI PER TIPO
SELECT 
    role,
    COUNT(*) as totale
FROM public.users
GROUP BY role
ORDER BY totale DESC;

-- 2. TUTTI GLI UTENTI CON DATI COMPLETI
SELECT 
    u.id,
    u.email,
    u.full_name,
    u.role,
    u.organization_id,
    o.organization_name,
    u.referral_code,
    u.created_at,
    au.last_sign_in_at,
    au.email_confirmed_at
FROM public.users u
LEFT JOIN public.organizations o ON u.organization_id = o.id
LEFT JOIN auth.users au ON u.id = au.id
ORDER BY u.created_at DESC;

-- 3. SOLO ADMIN
SELECT * FROM public.users WHERE role = 'admin';

-- 4. SOLO ORGANIZZAZIONI
SELECT 
    u.*,
    o.organization_name,
    o.category
FROM public.users u
LEFT JOIN public.organizations o ON u.organization_id = o.id
WHERE u.role = 'organization';

-- 5. SOLO UTENTI NORMALI
SELECT * FROM public.users WHERE role = 'user';

-- 6. UTENTI SENZA ORGANIZZAZIONE (per organizzazioni)
SELECT * 
FROM public.users 
WHERE role = 'organization' 
AND organization_id IS NULL;

-- 7. UTENTI CON EMAIL NON CONFERMATA
SELECT 
    u.id,
    u.email,
    u.full_name,
    u.role,
    au.email_confirmed_at
FROM public.users u
JOIN auth.users au ON u.id = au.id
WHERE au.email_confirmed_at IS NULL;

-- 8. UTENTI CREATI OGGI
SELECT * 
FROM public.users 
WHERE DATE(created_at) = CURRENT_DATE;

-- 9. UTENTI CREATI NEGLI ULTIMI 7 GIORNI
SELECT 
    DATE(created_at) as data,
    COUNT(*) as nuovi_utenti,
    role
FROM public.users
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at), role
ORDER BY data DESC;

-- 10. DETTAGLI COMPLETI DI UN SINGOLO UTENTE (sostituisci l'email)
SELECT 
    u.*,
    o.organization_name,
    o.category,
    au.created_at as auth_created,
    au.last_sign_in_at,
    au.email_confirmed_at,
    COUNT(DISTINCT t.id) as total_transactions,
    SUM(t.points_earned) as total_points
FROM public.users u
LEFT JOIN public.organizations o ON u.organization_id = o.id
LEFT JOIN auth.users au ON u.id = au.id
LEFT JOIN public.transactions t ON u.id = t.user_id
WHERE u.email = 'admin@cdm86.com'  -- <-- MODIFICA QUI
GROUP BY u.id, o.id, o.organization_name, o.category, au.created_at, au.last_sign_in_at, au.email_confirmed_at;
