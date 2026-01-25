-- 1. Verifica se il trigger esiste
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- 2. Verifica se la funzione esiste
SELECT proname, prosrc 
FROM pg_proc 
WHERE proname = 'handle_new_user';

-- 3. DROP e RICREA il trigger (completo)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 4. Crea la funzione aggiornata
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_is_org BOOLEAN;
BEGIN
    -- Log per debug
    RAISE LOG 'handle_new_user triggered for user: %', NEW.id;
    
    -- Controlla se è un'organizzazione (usa raw_user_meta_data invece di user_metadata)
    v_is_org := COALESCE((NEW.raw_user_meta_data->>'is_organization')::BOOLEAN, FALSE);
    
    RAISE LOG 'User metadata: %', NEW.raw_user_meta_data;
    RAISE LOG 'Is organization: %', v_is_org;
    
    IF v_is_org THEN
        -- È un'organizzazione
        RAISE LOG 'Creating organization record for user: %', NEW.id;
        
        INSERT INTO public.organizations (
            id,
            auth_user_id,
            name,
            email,
            organization_type,
            created_at
        ) VALUES (
            gen_random_uuid(),
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'organization_name', 'Nome non specificato'),
            NEW.email,
            COALESCE(NEW.raw_user_meta_data->>'organization_type', 'company'),
            NOW()
        )
        ON CONFLICT (auth_user_id) DO NOTHING;
        
    ELSE
        -- È un utente normale
        RAISE LOG 'Creating user record for user: %', NEW.id;
        
        INSERT INTO public.users (
            id,
            email,
            first_name,
            last_name,
            referral_code,
            created_at
        ) VALUES (
            NEW.id,
            NEW.email,
            COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
            COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
            UPPER(SUBSTRING(MD5(RANDOM()::TEXT || NEW.id::TEXT), 1, 8)),
            NOW()
        )
        ON CONFLICT (id) DO NOTHING;
        
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE LOG 'Error in handle_new_user: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Crea il trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 6. Verifica l'utente che ha il problema
SELECT 
    au.id as auth_id,
    au.email,
    au.raw_user_meta_data,
    au.created_at as auth_created,
    u.id as users_id,
    u.first_name,
    u.last_name,
    u.created_at as users_created
FROM auth.users au
LEFT JOIN public.users u ON au.id = u.id
WHERE au.id = 'a4b279cf-b71e-4c66-9fd3-419a195aac02';

-- 7. Se l'utente non esiste nella tabella users, crealo manualmente
INSERT INTO public.users (
    id,
    email,
    first_name,
    last_name,
    referred_by_organization_id,
    referral_code,
    created_at
)
SELECT 
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'first_name', ''),
    COALESCE(au.raw_user_meta_data->>'last_name', ''),
    '4719b5ea-18f2-47cf-9967-1cac5e8b36c7'::UUID, -- Barbell bello
    UPPER(SUBSTRING(MD5(RANDOM()::TEXT || au.id::TEXT), 1, 8)),
    au.created_at
FROM auth.users au
WHERE au.id = 'a4b279cf-b71e-4c66-9fd3-419a195aac02'
  AND NOT EXISTS (
      SELECT 1 FROM public.users WHERE id = au.id
  );

-- 8. Verifica finale
SELECT 
    u.id,
    u.email,
    u.first_name,
    u.last_name,
    u.referred_by_organization_id,
    o.name as organization_name
FROM users u
LEFT JOIN organizations o ON u.referred_by_organization_id = o.id
WHERE u.id = 'a4b279cf-b71e-4c66-9fd3-419a195aac02';
