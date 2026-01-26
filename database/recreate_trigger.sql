-- CONTROLLA I LOG DEL TRIGGER
-- Supabase Dashboard → Logs → Postgres Logs
-- Cerca: "Created public.users record" o "Error in handle_new_user"

-- VERIFICA SE IL TRIGGER È DAVVERO ATTIVO
SELECT 
    t.tgname,
    t.tgenabled,
    CASE t.tgenabled
        WHEN 'O' THEN 'ENABLED'
        WHEN 'D' THEN 'DISABLED'
    END AS status
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
WHERE t.tgname = 'on_auth_user_created';

-- RIPROVA A CREARE IL TRIGGER (DROP + RECREATE)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- VERIFICA DI NUOVO
SELECT 
    t.tgname,
    t.tgenabled,
    CASE t.tgenabled
        WHEN 'O' THEN 'ENABLED'
        WHEN 'D' THEN 'DISABLED'
    END AS status
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
WHERE t.tgname = 'on_auth_user_created';
