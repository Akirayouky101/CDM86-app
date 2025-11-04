-- ============================================
-- FIX: Aggiorna handle_new_user per gestire referral code
-- ============================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    new_referral_code VARCHAR(8);
    referrer_user_id UUID;
    referral_code_used TEXT;
BEGIN
    -- Genera referral code univoco per il nuovo utente
    new_referral_code := generate_referral_code();
    
    -- Estrai il codice referral usato dai metadata (se presente)
    referral_code_used := NEW.raw_user_meta_data->>'referral_code_used';
    
    -- Se c'è un codice referral, trova l'ID dell'utente che lo possiede
    IF referral_code_used IS NOT NULL AND referral_code_used != '' THEN
        SELECT id INTO referrer_user_id
        FROM public.users
        WHERE referral_code = referral_code_used
        LIMIT 1;
        
        RAISE NOTICE '🔍 Referral code used: %, Found referrer ID: %', referral_code_used, referrer_user_id;
    END IF;
    
    -- Inserisci utente nella tabella public.users CON referred_by_id
    INSERT INTO users (
        id,
        email,
        first_name,
        last_name,
        referral_code,
        referred_by_id,  -- 👈 AGGIUNTO!
        role,
        is_verified,
        is_active,
        points
    ) VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'first_name', 'User'),
        COALESCE(NEW.raw_user_meta_data->>'last_name', 'Unknown'),
        new_referral_code,
        referrer_user_id,  -- 👈 NULL se nessun referral, altrimenti ID del referrer
        'user',
        COALESCE(NEW.email_confirmed_at IS NOT NULL, false),
        true,
        100
    );
    
    RAISE NOTICE '✅ User created: ID=%, Email=%, ReferredBy=%, OwnCode=%', 
                 NEW.id, NEW.email, referrer_user_id, new_referral_code;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log l'errore ma non bloccare la registrazione
        RAISE WARNING '❌ Errore in handle_new_user: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Verifica che la funzione sia stata aggiornata
SELECT 
    'handle_new_user function updated' as status,
    pg_get_functiondef(oid) as definition
FROM pg_proc 
WHERE proname = 'handle_new_user' 
AND pronamespace = 'public'::regnamespace;
