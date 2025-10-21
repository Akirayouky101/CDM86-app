-- ============================================
-- FIX REGISTRATION TRIGGER
-- Esegui questo SQL in Supabase SQL Editor
-- ============================================

-- Step 1: Crea la funzione per generare codici referral
CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS VARCHAR(8)
LANGUAGE plpgsql
AS $$
DECLARE
    new_code VARCHAR(8);
    code_exists BOOLEAN;
BEGIN
    LOOP
        -- Genera codice random di 8 caratteri (lettere maiuscole e numeri)
        new_code := UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8));
        
        -- Verifica che non esista già
        SELECT EXISTS(
            SELECT 1 FROM users WHERE referral_code = new_code
            UNION
            SELECT 1 FROM organizations WHERE referral_code = new_code
        ) INTO code_exists;
        
        EXIT WHEN NOT code_exists;
    END LOOP;
    
    RETURN new_code;
END;
$$;

-- Step 2: Crea la funzione per gestire nuovi utenti
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    new_referral_code VARCHAR(8);
BEGIN
    -- Genera referral code univoco
    new_referral_code := generate_referral_code();
    
    -- Inserisci utente nella tabella public.users
    INSERT INTO public.users (
        id,
        email,
        first_name,
        last_name,
        referral_code,
        role,
        is_verified,
        is_active,
        points,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'first_name', 'User'),
        COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
        new_referral_code,
        'user',
        COALESCE(NEW.email_confirmed_at IS NOT NULL, false),
        true,
        100,
        NOW(),
        NOW()
    );
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log dell'errore (opzionale)
        RAISE WARNING 'Error in handle_new_user: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Step 3: Rimuovi trigger esistente se presente
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Step 4: Crea il trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Step 5: Verifica che tutto sia stato creato
SELECT 
    'Function generate_referral_code exists' as check_name,
    COUNT(*) as exists
FROM information_schema.routines
WHERE routine_name = 'generate_referral_code'
AND routine_schema = 'public'

UNION ALL

SELECT 
    'Function handle_new_user exists' as check_name,
    COUNT(*) as exists
FROM information_schema.routines
WHERE routine_name = 'handle_new_user'
AND routine_schema = 'public'

UNION ALL

SELECT 
    'Trigger on_auth_user_created exists' as check_name,
    COUNT(*) as exists
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';
