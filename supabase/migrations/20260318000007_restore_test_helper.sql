-- Funzione temporanea per ripristinare i dati di test bypassando i trigger
CREATE OR REPLACE FUNCTION public.restore_test_data()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
    SET session_replication_role = replica;

    UPDATE public.users
    SET is_collaborator=true, collaborator_status='active', account_type='collaborator'
    WHERE id='c8035839-a245-4911-9a49-3990fed1e34f';

    UPDATE public.users
    SET referred_by_id='c8035839-a245-4911-9a49-3990fed1e34f'
    WHERE id='b5c02d8d-dd45-475f-8d97-38681e153747';

    UPDATE public.users
    SET referred_by_id='b5c02d8d-dd45-475f-8d97-38681e153747'
    WHERE id='9505502e-a3bb-4900-896b-e768a2716248';

    UPDATE public.users
    SET referred_by_id='9505502e-a3bb-4900-896b-e768a2716248'
    WHERE id='d345ab10-e92c-4816-8fe1-e1d44b00d313';

    SET session_replication_role = DEFAULT;

    RETURN 'OK';
EXCEPTION WHEN OTHERS THEN
    SET session_replication_role = DEFAULT;
    RETURN SQLERRM;
END;
$$;

GRANT EXECUTE ON FUNCTION public.restore_test_data() TO service_role;
