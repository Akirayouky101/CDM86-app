-- ============================================================
-- AGGIUNGE: comune_residenza, provincia_residenza, telefono
-- alla tabella public.users
-- Esegui nel Supabase Dashboard → SQL Editor
-- ============================================================

ALTER TABLE public.users
    ADD COLUMN IF NOT EXISTS comune_residenza    VARCHAR(100),
    ADD COLUMN IF NOT EXISTS provincia_residenza VARCHAR(2),
    ADD COLUMN IF NOT EXISTS telefono            VARCHAR(20);

-- ============================================================
-- AGGIORNA IL TRIGGER handle_new_user per leggere i nuovi campi
-- ============================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

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
        comune_residenza,
        provincia_residenza,
        telefono,
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
        NEW.raw_user_meta_data->>'comune_residenza',
        NEW.raw_user_meta_data->>'provincia_residenza',
        NEW.raw_user_meta_data->>'telefono',
        v_referral_code,
        0
    )
    ON CONFLICT (auth_user_id) DO NOTHING;

    RAISE LOG 'handle_new_user: Created user % from % (%)', 
        NEW.email,
        NEW.raw_user_meta_data->>'comune_residenza',
        NEW.raw_user_meta_data->>'cap_residenza';

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE LOG 'handle_new_user ERROR: % for user %', SQLERRM, NEW.email;
        RETURN NEW;
END;
$$;

-- Ricrea trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Verifica colonne aggiunte
SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'users'
  AND column_name IN ('comune_residenza', 'provincia_residenza', 'telefono');
