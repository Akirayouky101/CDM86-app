-- ============================================
-- IMPOSTA PASSWORD PER GLI AMMINISTRATORI
-- ============================================

-- IMPORTANTE: Questo script aggiorna le password in Supabase Auth
-- Le password saranno:
-- - akirayouky@cdm86.com → Admin2025!
-- - claudio@cdm86.com → Admin2025!

DO $$
DECLARE
    v_akira_id UUID;
    v_claudio_id UUID;
BEGIN
    -- Trova l'ID di Akirayouky
    SELECT id INTO v_akira_id
    FROM auth.users
    WHERE email = 'akirayouky@cdm86.com';
    
    -- Trova l'ID di Claudio
    SELECT id INTO v_claudio_id
    FROM auth.users
    WHERE email = 'claudio@cdm86.com';
    
    -- Aggiorna password per Akirayouky
    IF v_akira_id IS NOT NULL THEN
        UPDATE auth.users
        SET 
            encrypted_password = crypt('Admin2025!', gen_salt('bf')),
            email_confirmed_at = COALESCE(email_confirmed_at, NOW())
        WHERE id = v_akira_id;
        
        RAISE NOTICE '✅ Password impostata per akirayouky@cdm86.com';
        RAISE NOTICE '   Password: Admin2025!';
    ELSE
        RAISE WARNING '⚠️ Utente akirayouky@cdm86.com non trovato in auth.users';
    END IF;
    
    -- Aggiorna password per Claudio
    IF v_claudio_id IS NOT NULL THEN
        UPDATE auth.users
        SET 
            encrypted_password = crypt('Admin2025!', gen_salt('bf')),
            email_confirmed_at = COALESCE(email_confirmed_at, NOW())
        WHERE id = v_claudio_id;
        
        RAISE NOTICE '✅ Password impostata per claudio@cdm86.com';
        RAISE NOTICE '   Password: Admin2025!';
    ELSE
        RAISE WARNING '⚠️ Utente claudio@cdm86.com non trovato in auth.users';
    END IF;
    
END $$;

-- Verifica che le password siano state impostate
SELECT 
    email,
    email_confirmed_at IS NOT NULL as email_confermata,
    encrypted_password IS NOT NULL as password_impostata,
    created_at
FROM auth.users
WHERE email IN ('akirayouky@cdm86.com', 'claudio@cdm86.com')
ORDER BY email;

-- ============================================
-- RISULTATO ATTESO:
-- ✅ akirayouky@cdm86.com → Password: Admin2025!
-- ✅ claudio@cdm86.com → Password: Admin2025!
-- ============================================
