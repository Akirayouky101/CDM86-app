-- AGGIORNA TRIGGER: Includi nuovi campi (data_nascita, sesso, codice_fiscale, cap_residenza)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Funzione trigger AGGIORNATA con nuovi campi
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    v_referral_code TEXT;
BEGIN
    -- Genera referral code unico (8 caratteri uppercase)
    LOOP
        v_referral_code := UPPER(SUBSTRING(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT) FROM 1 FOR 8));
        EXIT WHEN NOT EXISTS (SELECT 1 FROM public.users WHERE referral_code = v_referral_code);
    END LOOP;
    
    -- Crea record in public.users con TUTTI i campi
    INSERT INTO public.users (
        auth_user_id,
        email,
        first_name,
        last_name,
        data_nascita,
        sesso,
        codice_fiscale,
        cap_residenza,
        referral_code,
        points
    ) VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'first_name', SPLIT_PART(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
        (NEW.raw_user_meta_data->>'data_nascita')::DATE,
        NEW.raw_user_meta_data->>'sesso',
        NEW.raw_user_meta_data->>'codice_fiscale',
        NEW.raw_user_meta_data->>'cap_residenza',
        v_referral_code,
        0
    )
    ON CONFLICT (auth_user_id) DO NOTHING;
    
    RAISE LOG 'handle_new_user: Created user % with CF % from CAP %', 
        NEW.email, 
        NEW.raw_user_meta_data->>'codice_fiscale', 
        NEW.raw_user_meta_data->>'cap_residenza';
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE LOG 'handle_new_user ERROR: % for user %', SQLERRM, NEW.email;
        RETURN NEW; -- Non bloccare la registrazione
END;
$$;

-- Ricrea trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- VERIFICA
SELECT 
    t.tgname,
    t.tgenabled,
    CASE t.tgenabled
        WHEN 'O' THEN 'ENABLED'
        WHEN 'D' THEN 'DISABLED'
    END AS status,
    p.proname,
    p.prosecdef AS is_security_definer
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE t.tgname = 'on_auth_user_created';
