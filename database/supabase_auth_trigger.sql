-- ============================================
-- SUPABASE AUTH TRIGGER
-- Crea automaticamente utente in public.users quando si registra
-- ============================================

-- Function: Gestisce la creazione dell'utente quando si registra via Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    new_referral_code VARCHAR(8);
    referrer_user_id UUID;
BEGIN
    -- Genera referral code univoco
    new_referral_code := generate_referral_code();
    
    -- Cerca referrer se il codice è stato fornito
    referrer_user_id := NULL;
    IF NEW.raw_user_meta_data->>'referral_code_used' IS NOT NULL THEN
        SELECT id INTO referrer_user_id
        FROM users
        WHERE referral_code = UPPER(NEW.raw_user_meta_data->>'referral_code_used');
    END IF;
    
    -- Inserisci utente nella tabella public.users
    INSERT INTO users (
        id,
        email,
        password_hash,
        first_name,
        last_name,
        phone,
        referral_code,
        referred_by_id,
        role,
        is_verified,
        is_active,
        points,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.encrypted_password, ''), -- Password hash da auth.users
        COALESCE(NEW.raw_user_meta_data->>'first_name', 'User'),
        COALESCE(NEW.raw_user_meta_data->>'last_name', 'Unknown'),
        NEW.phone,
        new_referral_code,
        referrer_user_id,
        'user', -- Ruolo default
        COALESCE(NEW.email_confirmed_at IS NOT NULL, false), -- Verificato se email confermata
        true, -- Account attivo di default
        100, -- Bonus registrazione
        NOW(),
        NOW()
    );
    
    -- Se c'è un referrer, crea record referral
    IF referrer_user_id IS NOT NULL THEN
        INSERT INTO referrals (
            referrer_id,
            referred_user_id,
            referred_email,
            code_used,
            status,
            points_earned_referred,
            registered_at,
            source
        ) VALUES (
            referrer_user_id,
            NEW.id,
            NEW.email,
            UPPER(NEW.raw_user_meta_data->>'referral_code_used'),
            'registered', -- Status iniziale
            100, -- Punti per chi si registra
            NOW(),
            'web'
        );
    END IF;
    
    RETURN NEW;
END;
$$;

-- Trigger: Esegue handle_new_user quando un utente si registra
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- POLICY: Permetti agli utenti di leggere i propri dati
-- ============================================

-- Abilita RLS sulla tabella users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Policy: Gli utenti possono leggere solo i propri dati
CREATE POLICY "Users can read own data"
    ON public.users
    FOR SELECT
    USING (auth.uid() = id);

-- Policy: Gli utenti possono aggiornare solo i propri dati
CREATE POLICY "Users can update own data"
    ON public.users
    FOR UPDATE
    USING (auth.uid() = id);

-- Policy: Il trigger può inserire nuovi utenti (SECURITY DEFINER)
-- Nessuna policy aggiuntiva necessaria perché la function è SECURITY DEFINER

-- ============================================
-- VERIFICA
-- ============================================

-- Query per verificare che il trigger sia stato creato
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- Query per verificare che la function esista
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_name = 'handle_new_user'
AND routine_schema = 'public';
