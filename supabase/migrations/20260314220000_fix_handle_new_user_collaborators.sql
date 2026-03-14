-- ═══════════════════════════════════════════════════════════
-- FIX: handle_new_user — escludi i collaboratori da public.users
-- Esegui nel Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
      DECLARE
        v_referral_code TEXT;
        v_cf TEXT;
        v_data_nascita DATE;
      BEGIN
        -- ── NUOVO: se è un collaboratore, non creare riga in public.users ──
        IF (NEW.raw_user_meta_data->>'account_type') = 'collaborator' THEN
          RAISE LOG 'handle_new_user: collaboratore ignorato user=%', NEW.email;
          RETURN NEW;
        END IF;

        LOOP
          v_referral_code := UPPER(SUBSTRING(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT) FROM 1 FOR 8));
          EXIT WHEN NOT EXISTS (SELECT 1 FROM public.users WHERE referral_code = v_referral_code);
        END LOOP;
        v_cf := NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'codice_fiscale', '')), '');
        IF v_cf IS NOT NULL THEN
          IF EXISTS (SELECT 1 FROM public.users WHERE codice_fiscale = v_cf) THEN
            v_cf := NULL;
          END IF;
        END IF;
        BEGIN
          v_data_nascita := NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'data_nascita', '')), '')::DATE;
        EXCEPTION WHEN OTHERS THEN
          v_data_nascita := NULL;
        END;
        INSERT INTO public.users (
          auth_user_id, email, first_name, last_name,
          data_nascita, sesso, codice_fiscale, cap_residenza,
          comune_residenza, provincia_residenza, telefono,
          referral_code, points
        ) VALUES (
          NEW.id, NEW.email,
          COALESCE(NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'first_name','')), ''), SPLIT_PART(NEW.email,'@',1)),
          COALESCE(NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'last_name','')), ''), ''),
          v_data_nascita,
          NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'sesso','')), ''),
          v_cf,
          NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'cap_residenza','')), ''),
          NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'comune_residenza','')), ''),
          NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'provincia_residenza','')), ''),
          NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'telefono','')), ''),
          v_referral_code, 0
        ) ON CONFLICT (auth_user_id) DO NOTHING;
        RAISE LOG 'handle_new_user OK: user=% cf=%', NEW.email, v_cf;
        RETURN NEW;
      EXCEPTION WHEN OTHERS THEN
        RAISE LOG 'handle_new_user FATAL: % STATE=% user=%', SQLERRM, SQLSTATE, NEW.email;
        RETURN NEW;
      END;
      $function$
