-- Migration _0013: fix referral_network column name in abandon_collaborator_role
-- The table uses: user_id (referrer) and referral_id (the referred user)
-- Previous migration used the wrong column name "referred_by_user_id"

CREATE OR REPLACE FUNCTION public.abandon_collaborator_role(
    p_collaborator_id UUID,
    p_mode TEXT DEFAULT 'definitivo',
    p_new_referral_code TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_collab_record     RECORD;
    v_pub_user_id       UUID;
    v_auth_user_id      UUID;
    v_admin_pub_id      UUID;
    v_new_target_pub_id UUID;
    v_new_password      TEXT;
    v_l1_ids            UUID[];
    v_l2_ids            UUID[];
    v_l3_count          INT := 0;
    v_l1_count          INT := 0;
    v_l2_count          INT := 0;
    v_network_count     INT;
BEGIN
    -- Validate mode
    IF p_mode NOT IN ('definitivo', 'reiscritto') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Modalità non valida. Usa "definitivo" o "reiscritto".');
    END IF;

    -- Require referral code if mode = reiscritto
    IF p_mode = 'reiscritto' AND (p_new_referral_code IS NULL OR trim(p_new_referral_code) = '') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Per la modalità "reiscritto" è necessario il codice referral del nuovo utente.');
    END IF;

    -- Get collaborator record
    SELECT c.*, u.id AS pub_user_id, u.auth_user_id
    INTO v_collab_record
    FROM public.collaborators c
    JOIN public.users u ON u.id = c.user_id
    WHERE c.id = p_collaborator_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Collaboratore non trovato.');
    END IF;

    v_pub_user_id  := v_collab_record.pub_user_id;
    v_auth_user_id := v_collab_record.auth_user_id;

    -- Get admin public.users.id (first user with is_admin = true)
    SELECT id INTO v_admin_pub_id
    FROM public.users
    WHERE is_admin = true
    ORDER BY created_at ASC
    LIMIT 1;

    IF v_admin_pub_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Admin non trovato nel sistema.');
    END IF;

    -- If mode = reiscritto, resolve the new target user by referral code
    IF p_mode = 'reiscritto' THEN
        SELECT id INTO v_new_target_pub_id
        FROM public.users
        WHERE upper(trim(referral_code)) = upper(trim(p_new_referral_code))
        LIMIT 1;

        IF v_new_target_pub_id IS NULL THEN
            RETURN jsonb_build_object('success', false, 'error', 'Nessun utente trovato con il codice referral "' || p_new_referral_code || '".');
        END IF;

        -- Cannot use the collaborator's own referral code
        IF v_new_target_pub_id = v_pub_user_id THEN
            RETURN jsonb_build_object('success', false, 'error', 'Il codice referral non può essere quello del collaboratore stesso.');
        END IF;
    END IF;

    -- Collect L1 (direct referrals of the collaborator in public.users)
    SELECT array_agg(id) INTO v_l1_ids
    FROM public.users
    WHERE referred_by_id = v_pub_user_id;

    -- Collect L2 (referrals of L1)
    IF v_l1_ids IS NOT NULL AND array_length(v_l1_ids, 1) > 0 THEN
        SELECT array_agg(id) INTO v_l2_ids
        FROM public.users
        WHERE referred_by_id = ANY(v_l1_ids);
    END IF;

    -- Count L3 (referrals of L2)
    IF v_l2_ids IS NOT NULL AND array_length(v_l2_ids, 1) > 0 THEN
        SELECT count(*) INTO v_l3_count
        FROM public.users
        WHERE referred_by_id = ANY(v_l2_ids);
    END IF;

    v_l1_count := COALESCE(array_length(v_l1_ids, 1), 0);
    v_l2_count := COALESCE(array_length(v_l2_ids, 1), 0);

    -- ── REASSIGN public.users.referred_by_id ─────────────────────────────────
    IF p_mode = 'definitivo' THEN
        -- All levels → admin
        IF v_l1_ids IS NOT NULL AND array_length(v_l1_ids, 1) > 0 THEN
            UPDATE public.users SET referred_by_id = v_admin_pub_id
            WHERE id = ANY(v_l1_ids);
        END IF;
        IF v_l2_ids IS NOT NULL AND array_length(v_l2_ids, 1) > 0 THEN
            UPDATE public.users SET referred_by_id = v_admin_pub_id
            WHERE id = ANY(v_l2_ids);
        END IF;
        -- L3 → admin
        IF v_l2_ids IS NOT NULL AND array_length(v_l2_ids, 1) > 0 THEN
            UPDATE public.users SET referred_by_id = v_admin_pub_id
            WHERE referred_by_id = ANY(v_l2_ids);
        END IF;

    ELSIF p_mode = 'reiscritto' THEN
        -- L1 → new user
        IF v_l1_ids IS NOT NULL AND array_length(v_l1_ids, 1) > 0 THEN
            UPDATE public.users SET referred_by_id = v_new_target_pub_id
            WHERE id = ANY(v_l1_ids);
        END IF;
        -- L2 → new user
        IF v_l2_ids IS NOT NULL AND array_length(v_l2_ids, 1) > 0 THEN
            UPDATE public.users SET referred_by_id = v_new_target_pub_id
            WHERE id = ANY(v_l2_ids);
        END IF;
        -- L3 → admin
        IF v_l2_ids IS NOT NULL AND array_length(v_l2_ids, 1) > 0 THEN
            UPDATE public.users SET referred_by_id = v_admin_pub_id
            WHERE referred_by_id = ANY(v_l2_ids);
        END IF;
    END IF;

    -- ── REASSIGN referral_network ─────────────────────────────────────────────
    -- Structure: user_id = referrer (who gets the L1/L2 credit), referral_id = the referred user
    -- We need to update the "user_id" (referrer) for rows where referral_id is in our L1/L2/L3 lists

    IF p_mode = 'definitivo' THEN
        -- All rows pointing to Carlo's direct referrals → admin
        IF v_l1_ids IS NOT NULL AND array_length(v_l1_ids, 1) > 0 THEN
            UPDATE public.referral_network
            SET user_id = v_admin_pub_id
            WHERE referral_id = ANY(v_l1_ids);
        END IF;
        IF v_l2_ids IS NOT NULL AND array_length(v_l2_ids, 1) > 0 THEN
            UPDATE public.referral_network
            SET user_id = v_admin_pub_id
            WHERE referral_id = ANY(v_l2_ids);
        END IF;
        -- L3
        IF v_l2_ids IS NOT NULL AND array_length(v_l2_ids, 1) > 0 THEN
            UPDATE public.referral_network
            SET user_id = v_admin_pub_id
            WHERE referral_id IN (
                SELECT id FROM public.users WHERE referred_by_id = ANY(v_l2_ids)
            );
        END IF;

    ELSIF p_mode = 'reiscritto' THEN
        -- L1 rows → new user
        IF v_l1_ids IS NOT NULL AND array_length(v_l1_ids, 1) > 0 THEN
            UPDATE public.referral_network
            SET user_id = v_new_target_pub_id
            WHERE referral_id = ANY(v_l1_ids);
        END IF;
        -- L2 rows → new user
        IF v_l2_ids IS NOT NULL AND array_length(v_l2_ids, 1) > 0 THEN
            UPDATE public.referral_network
            SET user_id = v_new_target_pub_id
            WHERE referral_id = ANY(v_l2_ids);
        END IF;
        -- L3 rows → admin
        IF v_l2_ids IS NOT NULL AND array_length(v_l2_ids, 1) > 0 THEN
            UPDATE public.referral_network
            SET user_id = v_admin_pub_id
            WHERE referral_id IN (
                SELECT id FROM public.users WHERE referred_by_id = ANY(v_l2_ids)
            );
        END IF;
    END IF;

    -- ── GENERATE PASSWORD ─────────────────────────────────────────────────────
    v_new_password := substring(md5(random()::text || clock_timestamp()::text) from 1 for 6) ||
                      chr(65 + (random() * 25)::int) || chr(33 + (random() * 13)::int);

    -- ── REMOVE COLLABORATOR RECORD ────────────────────────────────────────────
    DELETE FROM public.collaborators WHERE id = p_collaborator_id;

    -- ── UPDATE public.users ───────────────────────────────────────────────────
    v_network_count := v_l1_count + v_l2_count;

    UPDATE public.users
    SET
        is_collaborator = false,
        account_type    = 'user',
        referral_count  = v_network_count,
        points          = COALESCE(points, 0)
    WHERE id = v_pub_user_id;

    -- ── RETURN ────────────────────────────────────────────────────────────────
    RETURN jsonb_build_object(
        'success', true,
        'data', jsonb_build_object(
            'auth_user_id',        v_auth_user_id,
            'email',               v_collab_record.email,
            'referral_code',       v_collab_record.referral_code,
            'new_password',        v_new_password,
            'mode',                p_mode,
            'level_1_reassigned',  v_l1_count,
            'level_2_reassigned',  v_l2_count,
            'level_3_reassigned',  v_l3_count,
            'target_user_id',      CASE WHEN p_mode = 'reiscritto' THEN v_new_target_pub_id ELSE v_admin_pub_id END
        )
    );

EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

GRANT EXECUTE ON FUNCTION public.abandon_collaborator_role(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.abandon_collaborator_role(UUID, TEXT, TEXT) TO service_role;
