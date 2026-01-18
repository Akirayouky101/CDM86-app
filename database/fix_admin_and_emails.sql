-- ============================================
-- FIX ADMIN DATA E CONFERMA EMAIL
-- ESEGUI IN SUPABASE SQL EDITOR
-- ============================================

-- 1️⃣ FIX DATI ADMIN IN public.users
UPDATE public.users 
SET 
  email = 'admin@cdm86.com',
  first_name = 'Admin',
  last_name = 'CDM86',
  role = 'admin',
  referral_code = 'ADMIN001',
  full_name = 'Admin CDM86'
WHERE id = '46bd5e0c-30ac-4b2c-8d71-73b0cbd416a7';

-- 2️⃣ CONFERMA EMAIL PER TUTTI GLI UTENTI NON CONFERMATI
UPDATE auth.users 
SET email_confirmed_at = NOW() 
WHERE email_confirmed_at IS NULL;

-- 3️⃣ VERIFICA CHE TUTTO SIA OK
SELECT 
  u.id,
  u.email,
  u.first_name,
  u.last_name,
  u.role,
  u.referral_code,
  au.email_confirmed_at,
  CASE 
    WHEN u.email IS NOT NULL AND au.email_confirmed_at IS NOT NULL THEN '✅ OK'
    ELSE '❌ PROBLEMA'
  END as status
FROM public.users u
LEFT JOIN auth.users au ON u.id = au.id
ORDER BY u.role;
