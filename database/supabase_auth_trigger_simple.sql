-- ============================================
-- SUPABASE AUTH TRIGGER - VERSIONE SEMPLIFICATA
-- Per debugging - Crea solo l'utente base senza referral
-- ============================================

-- Step 1: Assicurati che la function generate_referral_code esista
-- Se non esiste, creala qui
CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS VARCHAR(8) AS $$
DECLARE
    chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    result VARCHAR(8) := '';
    i INTEGER;
    code_exists BOOLEAN;
BEGIN
    LOOP
        result := '';
        FOR i IN 1..8 LOOP
            result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
        END LOOP;
        
        SELECT EXISTS(SELECT 1 FROM public.users WHERE referral_code = result) INTO code_exists;
        
        EXIT WHEN NOT code_exists;
    END LOOP;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 2: Function handle_new_user SEMPLIFICATA
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
    
    -- Inserisci utente nella tabella public.users (versione semplificata)
    INSERT INTO users (
        id,
        email,
        password_hash,
        first_name,
        last_name,
        referral_code,
        role,
        is_verified,
        is_active,
        points
    ) VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.encrypted_password, 'auth_managed'),
        COALESCE(NEW.raw_user_meta_data->>'first_name', 'User'),
        COALESCE(NEW.raw_user_meta_data->>'last_name', 'Unknown'),
        new_referral_code,
        'user',
        COALESCE(NEW.email_confirmed_at IS NOT NULL, false),
        true,
        100
    );
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log l'errore ma non bloccare la registrazione
        RAISE WARNING 'Errore in handle_new_user: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Step 3: Crea il trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Step 4: Verifica che il trigger sia attivo
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- Step 5: Testa la function manualmente (opzionale)
-- Decommentare per testare:
-- SELECT generate_referral_code();
