-- VERIFICA DIEGO IN PUBLIC.USERS (nuovo ID)
SELECT * FROM public.users 
WHERE auth_user_id = '2c0f9f37-081d-435f-877b-874ddd9b8b74';

-- VERIFICA IN AUTH.USERS
SELECT email, id, created_at 
FROM auth.users 
WHERE id = '2c0f9f37-081d-435f-877b-874ddd9b8b74';
