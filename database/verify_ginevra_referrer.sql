-- =====================================================
-- VERIFICA ID MARTINA vs referred_by_id di Ginevra
-- =====================================================

-- 1. Trova l'ID di Martina (serviziomail1@gmail.com)
SELECT 
    id as "ID Martina",
    email,
    first_name,
    referral_code
FROM users
WHERE email = 'serviziomail1@gmail.com';

-- 2. Mostra referred_by_id di Ginevra
SELECT 
    'GINEVRA referred_by_id' as campo,
    referred_by_id as valore
FROM users
WHERE email = 'ginevra@cdm86.com';

-- 3. Trova chi ha l'ID d2d15951-2adc-4e62-ae01-5e3f6dc3a16f
SELECT 
    'UTENTE CON QUESTO ID' as tipo,
    id,
    email,
    first_name,
    referral_code
FROM users
WHERE id = 'd2d15951-2adc-4e62-ae01-5e3f6dc3a16f';

-- 4. CONFRONTO
SELECT 
    'Ginevra dovrebbe puntare a Martina' as problema,
    g.referred_by_id as "ID a cui punta Ginevra",
    m.id as "ID di Martina",
    CASE 
        WHEN g.referred_by_id = m.id THEN '✅ CORRETTO'
        ELSE '❌ SBAGLIATO!'
    END as stato
FROM users g
CROSS JOIN users m
WHERE g.email = 'ginevra@cdm86.com'
AND m.email = 'serviziomail1@gmail.com';