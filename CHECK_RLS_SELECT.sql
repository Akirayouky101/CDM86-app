-- Check SELECT policy per favorites
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'favorites' 
  AND cmd = 'SELECT';

-- Check se ci sono dati (senza RLS)
SELECT COUNT(*) as total_favorites FROM favorites;

-- Check per il tuo user specifico
SELECT * FROM favorites 
WHERE user_id = 'd2d15951-2adc-4e62-ae01-5e3f6dc3a16f'
ORDER BY created_at DESC;
