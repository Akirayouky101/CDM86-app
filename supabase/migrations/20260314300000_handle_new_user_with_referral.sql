-- ═══════════════════════════════════════════════════════════════════
-- FIX: handle_new_user legge i dati referral dai raw_user_meta_data
-- e li scrive direttamente in public.users al momento della registrazione.
-- Così il referral viene salvato anche quando la conferma email è attiva
-- (nessun access_token disponibile dopo signUp → la Edge Function non può girare).
-- ═══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_referral_code              TEXT;
  v_cf                         TEXT;
  v_data_nascita               DATE;
  v_referred_by_id             UUID;
  v_referred_by_org_id         UUID;
  v_referred_by_collab_id      UUID;
  v_referral_type              TEXT;
BEGIN
  -- ── Se è un collaboratore, non creare riga in public.users ──
  IF (NEW.raw_user_meta_data->>'account_type') = 'collaborator' THEN
    RAISE LOG 'handle_new_user: collaboratore ignorato user=%', NEW.email;
    RETURN NEW;
  END IF;

  -- ── Genera codice referral univoco ──
  LOOP
    v_referral_code := UPPER(SUBSTRING(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT) FROM 1 FOR 8));
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.users WHERE referral_code = v_referral_code);
  END LOOP;

  -- ── Codice fiscale ──
  v_cf := NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'codice_fiscale', '')), '');
  IF v_cf IS NOT NULL THEN
    IF EXISTS (SELECT 1 FROM public.users WHERE codice_fiscale = v_cf) THEN
      v_cf := NULL;
    END IF;
  END IF;

  -- ── Data nascita ──
  BEGIN
    v_data_nascita := NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'data_nascita', '')), '')::DATE;
  EXCEPTION WHEN OTHERS THEN
    v_data_nascita := NULL;
  END;

  -- ── Leggi dati referral dai metadata ──
  v_referred_by_id        := NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'referred_by_id', '')), '')::UUID;
  v_referred_by_org_id    := NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'referred_by_organization_id', '')), '')::UUID;
  v_referred_by_collab_id := NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'referred_by_collaborator_id', '')), '')::UUID;
  v_referral_type         := NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'referral_type', '')), '');

  -- ── Inserisci in public.users ──
  INSERT INTO public.users (
    auth_user_id, email, first_name, last_name,
    data_nascita, sesso, codice_fiscale, cap_residenza,
    comune_residenza, provincia_residenza, telefono,
    referral_code, points,
    referred_by_id, referred_by_organization_id,
    referred_by_collaborator_id, referral_type
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
    v_referral_code, 0,
    v_referred_by_id,
    v_referred_by_org_id,
    v_referred_by_collab_id,
    v_referral_type
  ) ON CONFLICT (auth_user_id) DO NOTHING;

  -- ── Se referral collaboratore: incrementa users_count ──
  IF v_referred_by_collab_id IS NOT NULL THEN
    BEGIN
      PERFORM public.increment_collaborator_users_count(v_referred_by_collab_id);
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'handle_new_user: errore incremento users_count collaboratore %: %', v_referred_by_collab_id, SQLERRM;
    END;
  END IF;

  RAISE LOG 'handle_new_user OK: user=% referral_type=% collab=%', NEW.email, v_referral_type, v_referred_by_collab_id;
  RETURN NEW;

EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'handle_new_user FATAL: % STATE=% user=%', SQLERRM, SQLSTATE, NEW.email;
  RETURN NEW;
END;
$function$;
