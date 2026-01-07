-- =====================================================
-- CREA ORGANIZZAZIONE DI TEST
-- =====================================================

-- STEP 1: Crea organizzazione di test
-- =====================================================
INSERT INTO organizations (
    id,
    organization_type,
    name,
    email,
    vat_number,
    address,
    city,
    province,
    zip_code,
    phone,
    referral_code,
    referral_code_external,
    total_points,
    points,
    active
) VALUES (
    uuid_generate_v4(),
    'company',
    'Azienda Test CDM86',
    'azienda.test@cdm86.com',
    '12345678901',
    'Via Roma 123',
    'Milano',
    'MI',
    '20100',
    '+39 02 12345678',
    'TEST001',  -- Codice dipendenti
    'TEST001_EXT',  -- Codice esterni
    0,  -- total_points
    0,  -- points
    true
);

-- STEP 2: Verifica creazione
-- =====================================================
SELECT 
    id,
    name,
    email,
    referral_code as "Codice Dipendenti",
    referral_code_external as "Codice Esterni",
    organization_type as "Tipo"
FROM organizations
WHERE email = 'azienda.test@cdm86.com';

-- STEP 3: Crea utente auth per l'organizzazione (OPZIONALE - solo se vuoi fare login)
-- =====================================================
-- NOTA: Questo inserisce nella tabella auth.users di Supabase
-- Potrebbe richiedere privilegi speciali

-- Salva l'ID dell'organizzazione
DO $$
DECLARE
    org_id UUID;
BEGIN
    -- Prendi ID organizzazione
    SELECT id INTO org_id FROM organizations WHERE email = 'azienda.test@cdm86.com';
    
    -- Crea user in auth.users (se hai i permessi)
    -- Altrimenti usa Supabase Dashboard → Authentication → Users → Add User
    
    -- Password: Test123! (da cambiare)
    RAISE NOTICE 'Organizzazione ID: %', org_id;
    RAISE NOTICE 'Email: azienda.test@cdm86.com';
    RAISE NOTICE 'Password da impostare: Test123!';
END $$;

-- STEP 4: Crea alcuni dipendenti di test
-- =====================================================
DO $$
DECLARE
    org_id UUID;
BEGIN
    -- Prendi ID organizzazione
    SELECT id INTO org_id FROM organizations WHERE email = 'azienda.test@cdm86.com';
    
    -- Aggiorna utenti esistenti come dipendenti
    UPDATE users 
    SET 
        is_employee = true,
        organization_id = org_id
    WHERE email IN (
        'diegomarruchi@outlook.it'
        -- Aggiungi altre email qui se vuoi
    );
    
    RAISE NOTICE 'Dipendenti aggiornati per org_id: %', org_id;
END $$;

-- STEP 5: Verifica finale
-- =====================================================
SELECT 
    'Organizzazione' as tipo,
    name,
    email,
    referral_code
FROM organizations
WHERE email = 'azienda.test@cdm86.com'

UNION ALL

SELECT 
    'Dipendente' as tipo,
    first_name || ' ' || last_name as name,
    email,
    referral_code
FROM users
WHERE organization_id = (SELECT id FROM organizations WHERE email = 'azienda.test@cdm86.com');

-- =====================================================
-- ISTRUZIONI POST-CREAZIONE
-- =====================================================

-- 1. CREA USER MANUALMENTE su Supabase:
--    Dashboard → Authentication → Users → Add User
--    Email: azienda.test@cdm86.com
--    Password: Test123!
--    
-- 2. Collega l'auth.user all'organization:
--    L'ID dell'auth.user DEVE ESSERE UGUALE all'ID dell'organization
--    
--    Oppure usa questo SQL dopo aver creato l'user:
--    UPDATE organizations 
--    SET id = 'ID_DELL_AUTH_USER_QUI'
--    WHERE email = 'azienda.test@cdm86.com';

-- 3. TESTA IL LOGIN:
--    Vai su: https://cdm86-new.vercel.app/public/organization-dashboard.html
--    Login: azienda.test@cdm86.com / Test123!
