-- ============================================
-- RESET PASSWORD AMMINISTRATORI - METODO SICURO
-- ============================================

-- IMPORTANTE: Questo metodo NON funziona direttamente via SQL
-- Devi usare il pannello Supabase per resettare le password

-- METODO 1: Reset via Supabase Dashboard (CONSIGLIATO)
-- 1. Vai su Supabase Dashboard → Authentication → Users
-- 2. Cerca l'utente (akirayouky@cdm86.com o claudio@cdm86.com)
-- 3. Clicca sui tre puntini (⋮)
-- 4. Seleziona "Send password recovery email"
-- 5. Controlla l'email e clicca sul link per impostare una nuova password

-- METODO 2: Imposta password temporanea via Admin API
-- Questo richiede l'uso di un client HTTP o JavaScript

-- Per ora, usa questo per ELIMINARE e RICREARE gli utenti con password nota:

-- ============================================
-- STEP 1: Elimina utenti esistenti
-- ============================================
DELETE FROM auth.users WHERE email = 'akirayouky@cdm86.com';
DELETE FROM auth.users WHERE email = 'claudio@cdm86.com';

-- ============================================
-- STEP 2: Ricrea con password tramite Supabase Auth
-- ============================================

-- NOTA: Non possiamo creare utenti direttamente in auth.users via SQL
-- con password funzionanti. Devi usare:

-- OPZIONE A: Registrazione normale dalla UI
-- 1. Vai su https://cdm86-3sgi6ejem-akirayoukys-projects.vercel.app
-- 2. Registrati con:
--    - Email: akirayouky@cdm86.com
--    - Password: Admin2025!
--    - Nome: Akirayouky
--    - Cognome: Admin

-- OPZIONE B: Usa questo script JavaScript nel browser console:
/*
const supabase = window.supabaseClient;

// Registra Akirayouky
const { data: akira, error: akiraError } = await supabase.auth.signUp({
  email: 'akirayouky@cdm86.com',
  password: 'Admin2025!',
  options: {
    data: {
      first_name: 'Akirayouky',
      last_name: 'Admin'
    }
  }
});

console.log('Akirayouky:', akira, akiraError);

// Registra Claudio
const { data: claudio, error: claudioError } = await supabase.auth.signUp({
  email: 'claudio@cdm86.com',
  password: 'Admin2025!',
  options: {
    data: {
      first_name: 'Claudio',
      last_name: 'Admin'
    }
  }
});

console.log('Claudio:', claudio, claudioError);
*/

-- ============================================
-- STEP 3: Conferma email via SQL (dopo registrazione)
-- ============================================
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email IN ('akirayouky@cdm86.com', 'claudio@cdm86.com')
AND email_confirmed_at IS NULL;

-- ============================================
-- STEP 4: Imposta come admin nella tabella users
-- ============================================
UPDATE public.users
SET 
    role = 'admin',
    is_verified = true
WHERE email IN ('akirayouky@cdm86.com', 'claudio@cdm86.com');

-- Verifica
SELECT 
    u.email,
    u.role,
    u.referral_code,
    au.email_confirmed_at IS NOT NULL as email_confermata
FROM public.users u
JOIN auth.users au ON au.id = u.id
WHERE u.email IN ('akirayouky@cdm86.com', 'claudio@cdm86.com');
