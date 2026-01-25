-- =====================================================
-- COLLEGA PUBLIC.USERS A SUPABASE AUTH
-- =====================================================

-- 1. Aggiungi colonna auth_user_id a public.users
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS auth_user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE;

-- 2. Crea indice per performance
CREATE INDEX IF NOT EXISTS idx_users_auth_user_id ON public.users(auth_user_id);

-- 3. Funzione per generare referral code unico
CREATE OR REPLACE FUNCTION generate_unique_referral_code()
RETURNS TEXT AS $$
DECLARE
    new_code TEXT;
    code_exists BOOLEAN;
BEGIN
    LOOP
        -- Genera codice random 8 caratteri (lettere maiuscole e numeri)
        new_code := UPPER(SUBSTRING(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT) FROM 1 FOR 8));
        
        -- Verifica se esiste già
        SELECT EXISTS(SELECT 1 FROM public.users WHERE referral_code = new_code) INTO code_exists;
        
        EXIT WHEN NOT code_exists;
    END LOOP;
    
    RETURN new_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Trigger function: crea utente in public.users quando si registra su auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_referral_code TEXT;
BEGIN
    -- Genera referral code unico
    v_referral_code := generate_unique_referral_code();
    
    -- Crea record in public.users
    INSERT INTO public.users (
        auth_user_id,
        email,
        first_name,
        last_name,
        referral_code
    ) VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'first_name', SPLIT_PART(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
        v_referral_code
    )
    ON CONFLICT (auth_user_id) DO NOTHING; -- Evita duplicati
    
    RAISE LOG 'Created public.users record for auth user %', NEW.id;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE LOG 'Error in handle_new_user: %', SQLERRM;
        RETURN NEW; -- Non bloccare la registrazione anche se fallisce
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Crea trigger su auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 6. Collega utenti esistenti in public.users al loro auth_user_id (UPDATE)
UPDATE public.users pu
SET auth_user_id = au.id
FROM auth.users au
WHERE pu.email = au.email 
AND pu.auth_user_id IS NULL
AND au.id NOT IN (
    -- Escludi organizzazioni
    SELECT auth_user_id FROM organizations WHERE auth_user_id IS NOT NULL
);

-- 7. Migra NUOVI utenti auth a public.users (INSERT solo per utenti non esistenti)
INSERT INTO public.users (
    auth_user_id,
    email,
    first_name,
    last_name,
    referral_code
)
SELECT 
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'first_name', SPLIT_PART(au.email, '@', 1)),
    COALESCE(au.raw_user_meta_data->>'last_name', ''),
    generate_unique_referral_code()
FROM auth.users au
WHERE NOT EXISTS (
    -- Non inserire se esiste già con stesso auth_user_id
    SELECT 1 FROM public.users pu WHERE pu.auth_user_id = au.id
)
AND NOT EXISTS (
    -- Non inserire se esiste già con stessa email
    SELECT 1 FROM public.users pu WHERE pu.email = au.email
)
AND au.id NOT IN (
    -- Escludi organizzazioni (hanno già auth_user_id in organizations table)
    SELECT auth_user_id FROM organizations WHERE auth_user_id IS NOT NULL
);

-- =====================================================
-- QUERY DI VERIFICA
-- =====================================================

-- Verifica link auth.users -> public.users
SELECT 
    au.id as auth_id,
    au.email as auth_email,
    pu.id as user_id,
    pu.email as user_email,
    pu.referral_code,
    pu.points,
    CASE 
        WHEN pu.auth_user_id IS NOT NULL THEN '✅ Collegato'
        ELSE '❌ Non collegato'
    END as status
FROM auth.users au
LEFT JOIN public.users pu ON pu.auth_user_id = au.id
ORDER BY au.created_at DESC
LIMIT 10;

-- Conta utenti
SELECT 
    'Auth Users' as table_name,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'Public Users (non-org)',
    COUNT(*) 
FROM public.users
WHERE auth_user_id IS NOT NULL
UNION ALL
SELECT 
    'Organizations',
    COUNT(*) 
FROM organizations
WHERE auth_user_id IS NOT NULL;

-- Verifica Barbell bello (organizzazione)
SELECT 
    'Barbell bello check' as status,
    au.email,
    o.name as org_name,
    o.auth_user_id
FROM auth.users au
JOIN organizations o ON o.auth_user_id = au.id
WHERE o.name = 'Barbell bello';
