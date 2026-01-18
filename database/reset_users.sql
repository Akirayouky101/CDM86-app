-- ============================================
-- RESET COMPLETO DATABASE UTENTI
-- ESEGUI IN SUPABASE SQL EDITOR
-- ============================================

-- ⚠️ ATTENZIONE: Queste query cancelleranno TUTTI gli utenti!
-- Esegui solo se sei sicuro!

-- 1️⃣ CONTROLLA QUANTI UTENTI HAI
SELECT 
    'public.users' as tabella,
    COUNT(*) as totale,
    COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin,
    COUNT(CASE WHEN role = 'organization' THEN 1 END) as organizzazioni,
    COUNT(CASE WHEN role = 'user' THEN 1 END) as utenti
FROM public.users;

-- 2️⃣ VISUALIZZA TUTTI GLI UTENTI PRIMA DI CANCELLARE
SELECT 
    id,
    email,
    full_name,
    role,
    referral_code,
    created_at
FROM public.users
ORDER BY role, created_at;

-- ============================================
-- CANCELLAZIONE COMPLETA
-- ============================================

-- 3️⃣ CANCELLA TUTTE LE RELAZIONI E GLI UTENTI
-- ⚠️ DECOMMENTARE PER ESEGUIRE

-- Cancella nell'ordine corretto per evitare errori di foreign key:

-- A. Transazioni
-- DELETE FROM public.transactions;

-- B. Referral
-- DELETE FROM public.referrals;

-- C. Favorites
-- DELETE FROM public.favorites;

-- D. Richieste organizzazioni
-- DELETE FROM public.organization_requests;

-- E. Utenti (ultimo!)
-- DELETE FROM public.users;

-- OPPURE ESEGUI TUTTO IN UNA VOLTA:
/*
BEGIN;
DELETE FROM public.transactions;
DELETE FROM public.referrals;
DELETE FROM public.favorites;
DELETE FROM public.organization_requests;
DELETE FROM public.users;
COMMIT;
*/

-- 4️⃣ VERIFICA CANCELLAZIONE
-- SELECT COUNT(*) as utenti_rimasti FROM public.users;

-- ============================================
-- NOTA IMPORTANTE SU AUTH.USERS
-- ============================================
-- NON puoi cancellare auth.users con SQL normale
-- Devi farlo da:
-- 1. Supabase Dashboard > Authentication > Users
-- 2. Seleziona tutti gli utenti
-- 3. Clicca su "Delete"
-- 
-- OPPURE usa questa query ADMIN (solo se hai accesso postgres):
-- DELETE FROM auth.users;

-- ============================================
-- CREAZIONE NUOVO ADMIN
-- ============================================

-- 5️⃣ DOPO AVER CANCELLATO DA AUTH.USERS VIA DASHBOARD,
-- USA LO SCRIPT HTML reset_and_create_admin.html
-- PER CREARE IL NUOVO ADMIN CON PASSWORD

-- OPPURE, se hai già creato l'auth user manualmente,
-- inserisci il record in public.users:

/*
INSERT INTO public.users (
    id,                      -- <-- Sostituisci con UUID da auth.users
    email,
    full_name,
    role,
    referral_code
) VALUES (
    'uuid-qui',              -- <-- UUID dell'utente creato in auth.users
    'admin@cdm86.com',
    'Admin CDM86',
    'admin',
    'ADMIN001'
);
*/

-- ============================================
-- VERIFICA FINALE
-- ============================================

-- 6️⃣ VERIFICA CHE ADMIN SIA STATO CREATO CORRETTAMENTE
SELECT 
    u.id,
    u.email,
    u.full_name,
    u.role,
    u.referral_code,
    u.created_at,
    au.created_at as auth_created,
    au.email_confirmed_at
FROM public.users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE u.role = 'admin';

-- ============================================
-- PROCEDURA COMPLETA STEP-BY-STEP
-- ============================================

/*
PASSO 1: Esegui query #1 per vedere quanti utenti hai

PASSO 2: Esegui query #2 per vedere i dettagli

PASSO 3: Decommenta e esegui query #3 per cancellare da public.users

PASSO 4: Vai su Supabase Dashboard:
   - Authentication > Users
   - Seleziona tutti
   - Clicca Delete

PASSO 5: Apri reset_and_create_admin.html nel browser
   - Clicca "Crea Admin"
   - Copia le credenziali

PASSO 6: Esegui query #6 per verificare che tutto sia ok

PASSO 7: Prova a fare login con:
   - Email: admin@cdm86.com
   - Password: Admin123!

FATTO! Ora hai un database pulito con solo 1 admin.
*/
