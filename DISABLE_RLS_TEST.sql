-- TEMPORARY: Disable RLS on favorites to test if it's the problem
ALTER TABLE favorites DISABLE ROW LEVEL SECURITY;

-- Test query - questo dovrebbe funzionare ora
SELECT * FROM favorites;

-- After testing, RE-ENABLE RLS:
-- ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
