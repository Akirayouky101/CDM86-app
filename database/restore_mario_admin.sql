-- =====================================================
-- RIPRISTINA MARIO ROSSI E ADMIN NELLA TABELLA USERS
-- =====================================================

-- 1. Inserisci Mario Rossi
INSERT INTO users (
    id,
    email,
    first_name,
    last_name,
    phone,
    role,
    referral_code,
    points,
    referral_count,
    is_verified,
    is_active,
    created_at,
    updated_at
) VALUES (
    '293caa0f-f12c-4cde-81ba-26da97f2f13e',
    'mario.rossi@cdm86.com',
    'Mario',
    'Rossi',
    '+39 333 1234567',
    'user',
    'MARIO123',
    0,
    0,
    true,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    updated_at = NOW();

-- 2. Inserisci Admin
INSERT INTO users (
    id,
    email,
    first_name,
    last_name,
    phone,
    role,
    referral_code,
    points,
    referral_count,
    is_verified,
    is_active,
    created_at,
    updated_at
) VALUES (
    '68e617b6-1735-4779-ab1c-7571df9c27e9',
    'admin@cdm86.com',
    'Admin',
    'CDM86',
    NULL,
    'admin',
    'ADMIN001',
    0,
    0,
    true,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    updated_at = NOW();

-- Verifica
SELECT id, email, first_name, last_name, role, referral_code, points 
FROM users
WHERE email IN ('mario.rossi@cdm86.com', 'admin@cdm86.com');
