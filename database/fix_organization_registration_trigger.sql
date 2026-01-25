-- ============================================
-- FIX TRIGGER REGISTRAZIONE ORGANIZZAZIONI
-- Evita il doppio inserimento in users quando si registra un'organizzazione
-- ============================================

-- Modifica il trigger handle_new_user per gestire organizzazioni
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    new_referral_code VARCHAR(8);
    is_org BOOLEAN;
BEGIN
    -- Controlla se è un'organizzazione dai metadata
    is_org := COALESCE((NEW.raw_user_meta_data->>'is_organization')::boolean, false);
    
    -- Genera referral code univoco
    new_referral_code := generate_referral_code();
    
    IF is_org THEN
        -- È UN'ORGANIZZAZIONE: inserisci in organizations
        RAISE NOTICE 'Registrazione organizzazione: %', NEW.email;
        
        INSERT INTO organizations (
            id,
            auth_user_id,
            email,
            name,
            organization_type,
            referral_code,
            is_verified,
            is_active,
            total_points
        ) VALUES (
            gen_random_uuid(),
            NEW.id,
            NEW.email,
            COALESCE(NEW.raw_user_meta_data->>'organization_name', 'Organizzazione'),
            COALESCE(NEW.raw_user_meta_data->>'organization_type', 'association'),
            new_referral_code,
            COALESCE(NEW.email_confirmed_at IS NOT NULL, false),
            true,
            100
        )
        ON CONFLICT (auth_user_id) DO NOTHING;  -- Evita duplicati se il frontend inserisce già
        
    ELSE
        -- È UN UTENTE NORMALE: inserisci in users
        RAISE NOTICE 'Registrazione utente: %', NEW.email;
        
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
        )
        ON CONFLICT (id) DO NOTHING;  -- Evita duplicati
        
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log l'errore ma non bloccare la registrazione
        RAISE WARNING 'Errore in handle_new_user: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Verifica che il trigger sia attivo
SELECT 
    'Trigger configurato correttamente' as status,
    trigger_name,
    event_manipulation,
    event_object_table
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- Test: Verifica le tabelle
SELECT 
    'Utenti in users' as table_name,
    COUNT(*) as count
FROM users
UNION ALL
SELECT 
    'Organizzazioni in organizations',
    COUNT(*)
FROM organizations;
