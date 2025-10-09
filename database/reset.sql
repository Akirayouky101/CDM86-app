-- ============================================
-- CDM86 Platform - Reset Database
-- ATTENZIONE: Questo script elimina TUTTI i dati!
-- ============================================

-- Disabilita temporaneamente i trigger per evitare errori
SET session_replication_role = 'replica';

-- 1. Elimina tutti i dati (in ordine inverso per rispettare le FK)
TRUNCATE TABLE user_favorites CASCADE;
TRUNCATE TABLE referrals CASCADE;
TRUNCATE TABLE transactions CASCADE;
TRUNCATE TABLE promotions CASCADE;
TRUNCATE TABLE users CASCADE;

-- Riabilita i trigger
SET session_replication_role = 'origin';

-- ============================================
-- DONE! Database pulito
-- ============================================
-- Ora puoi eseguire seed.sql
