-- ═══════════════════════════════════════════════════════════════════
-- FIX: abandon_collaborator_role - sync referral_count, points e
--      user_points dopo la migrazione a utente normale.
--
-- Problema: dopo abbandono ruolo, public.users.referral_count e
--           public.users.points rimangono a 0 perché non vengono
--           calcolati dalla RPC. Idem user_points.referrals_count.
-- Fix: aggiunge step 7b che conta i referral diretti del collaboratore
--      in public.users (referred_by_id = v_user.id) e aggiorna
--      referral_count + points + user_points.referrals_count.
-- ═══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.abandon_collaborator_role(
    p_collaborator_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_collab              RECORD;
    v_user                RECORD;
    v_auth_user_id        UUID;
    v_new_password        TEXT;
    v_admin_referral_id   UUID;
    v_reassigned_count    INT := 0;
    v_referral_code       TEXT;
    v_new_user_id         UUID;
    v_network_count       INT := 0;
BEGIN
    -- ══════════════════════════════════════════════════════════════
    -- 1. Recupera dati collaboratore
    -- ══════════════════════════════════════════════════════════════
    SELECT * INTO v_collab
    FROM public.collaborators
    WHERE id = p_collaborator_id;

    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Collaboratore non trovato'
        );
    END IF;

    v_auth_user_id := v_collab.auth_user_id;

    -- ══════════════════════════════════════════════════════════════
    -- 2. Verifica se esiste già un record in public.users
    -- ══════════════════════════════════════════════════════════════
    IF v_collab.user_id IS NULL THEN

        LOOP
            v_referral_code := UPPER(SUBSTRING(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT) FROM 1 FOR 8));
            EXIT WHEN NOT EXISTS (SELECT 1 FROM public.users WHERE referral_code = v_referral_code);
        END LOOP;

        INSERT INTO public.users (
            auth_user_id, email, first_name, last_name,
            referral_code, points, referred_by_id
        )
        VALUES (
            v_auth_user_id,
            v_collab.email,
            COALESCE(v_collab.first_name, 'Utente'),
            COALESCE(v_collab.last_name, ''),
            v_referral_code,
            0,
            v_collab.referred_by_id
        )
        RETURNING id INTO v_new_user_id;

        UPDATE public.collaborators
        SET user_id = v_new_user_id
        WHERE id = p_collaborator_id;

        SELECT * INTO v_user FROM public.users WHERE id = v_new_user_id;

    ELSE
        SELECT * INTO v_user
        FROM public.users
        WHERE id = v_collab.user_id;
    END IF;

    -- ══════════════════════════════════════════════════════════════
    -- 3. Genera nuova password casuale (ritornata al frontend)
    -- ══════════════════════════════════════════════════════════════
    v_new_password := UPPER(SUBSTRING(MD5(RANDOM()::TEXT || NOW()::TEXT || v_auth_user_id::TEXT) FROM 1 FOR 8));

    -- ══════════════════════════════════════════════════════════════
    -- 4. Trova il referral dell'admin (fallback: admin stesso)
    -- ══════════════════════════════════════════════════════════════
    SELECT referred_by_id INTO v_admin_referral_id
    FROM public.users
    WHERE id = 'e8cde03d-2aa6-4ea6-a29f-43f290ae00ce';

    IF v_admin_referral_id IS NULL THEN
        v_admin_referral_id := 'e8cde03d-2aa6-4ea6-a29f-43f290ae00ce';
    END IF;

    -- ══════════════════════════════════════════════════════════════
    -- 5. Conta la rete dell'ex-collaboratore (L1 + L2)
    --    Prima del riassegnamento L3 (ancora completa)
    -- ══════════════════════════════════════════════════════════════
    WITH level_1 AS (
        SELECT id FROM public.users
        WHERE referred_by_id = v_user.id
    ),
    level_2 AS (
        SELECT u.id FROM public.users u
        INNER JOIN level_1 l1 ON u.referred_by_id = l1.id
    )
    SELECT COUNT(*) INTO v_network_count
    FROM (
        SELECT id FROM level_1
        UNION ALL
        SELECT id FROM level_2
    ) AS network;

    -- ══════════════════════════════════════════════════════════════
    -- 6. Riassegna il TERZO LIVELLO MLM al referral dell'admin
    --    L1 = referred_by_id = collaboratore  → MANTIENI
    --    L2 = referred_by_id IN (L1)          → MANTIENI
    --    L3 = referred_by_id IN (L2)          → RIASSEGNA
    -- ══════════════════════════════════════════════════════════════
    WITH level_1 AS (
        SELECT id FROM public.users
        WHERE referred_by_id = v_user.id
    ),
    level_2 AS (
        SELECT u.id FROM public.users u
        INNER JOIN level_1 l1 ON u.referred_by_id = l1.id
    ),
    level_3 AS (
        SELECT u.id FROM public.users u
        INNER JOIN level_2 l2 ON u.referred_by_id = l2.id
    )
    UPDATE public.users
    SET referred_by_id = v_admin_referral_id
    WHERE id IN (SELECT id FROM level_3);

    GET DIAGNOSTICS v_reassigned_count = ROW_COUNT;

    -- ══════════════════════════════════════════════════════════════
    -- 7. Elimina il record da collaborators
    -- ══════════════════════════════════════════════════════════════
    DELETE FROM public.collaborators
    WHERE id = p_collaborator_id;

    -- ══════════════════════════════════════════════════════════════
    -- 8. Rimuove ruolo collaboratore da public.users e auth.users
    --    e aggiorna referral_count + points con la rete guadagnata
    -- ══════════════════════════════════════════════════════════════
    UPDATE public.users
    SET
        is_collaborator     = false,
        collaborator_status = NULL,
        account_type        = 'user',
        referral_count      = v_network_count,
        points              = v_network_count
    WHERE id = v_user.id;

    UPDATE auth.users
    SET raw_user_meta_data =
        COALESCE(raw_user_meta_data, '{}'::jsonb) ||
        '{"account_type": "user"}'::jsonb
    WHERE id = v_auth_user_id;

    -- ══════════════════════════════════════════════════════════════
    -- 9. Aggiorna (o crea) il record user_points con i referral
    -- ══════════════════════════════════════════════════════════════
    INSERT INTO public.user_points (
        user_id,
        points_total,
        points_available,
        points_used,
        referrals_count,
        level
    )
    VALUES (
        v_auth_user_id,
        v_network_count,
        v_network_count,
        0,
        v_network_count,
        'bronze'
    )
    ON CONFLICT (user_id) DO UPDATE
    SET
        points_total      = EXCLUDED.points_total,
        points_available  = EXCLUDED.points_available,
        referrals_count   = EXCLUDED.referrals_count,
        updated_at        = NOW();

    -- ══════════════════════════════════════════════════════════════
    -- 10. Ritorna risultato con la nuova password per il frontend
    -- ══════════════════════════════════════════════════════════════
    RETURN json_build_object(
        'success', true,
        'message', 'Ruolo collaboratore abbandonato con successo',
        'data', json_build_object(
            'email',               v_collab.email,
            'new_password',        v_new_password,
            'auth_user_id',        v_auth_user_id,
            'user_id',             v_user.id,
            'referral_code',       v_user.referral_code,
            'level_3_reassigned',  v_reassigned_count,
            'new_referral_parent', v_admin_referral_id,
            'network_count',       v_network_count
        )
    );

EXCEPTION WHEN OTHERS THEN
    RAISE LOG 'abandon_collaborator_role ERROR: % (STATE: %)', SQLERRM, SQLSTATE;
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'state', SQLSTATE
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.abandon_collaborator_role(UUID) TO authenticated;
