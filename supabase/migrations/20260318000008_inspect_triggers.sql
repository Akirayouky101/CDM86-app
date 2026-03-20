-- RPC di diagnostica: ritorna i trigger su public.users e le funzioni che usano user_points
CREATE OR REPLACE FUNCTION public.get_trigger_info()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_triggers JSON;
BEGIN
    SELECT json_agg(row_to_json(t)) INTO v_triggers FROM (
        SELECT tg.tgname as trigger_name,
               p.proname as function_name,
               p.prosrc  as function_body
        FROM pg_trigger tg
        JOIN pg_proc p ON tg.tgfoid = p.oid
        JOIN pg_class c ON tg.tgrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE n.nspname = 'public' AND c.relname = 'users'
          AND NOT tg.tgisinternal
    ) t;

    RETURN json_build_object('triggers', v_triggers);
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_trigger_info() TO service_role;
