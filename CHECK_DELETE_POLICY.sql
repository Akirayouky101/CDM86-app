-- Check DELETE policy per favorites
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'favorites' 
  AND cmd = 'DELETE';

-- Check se il record esiste davvero
SELECT 
    id,
    user_id,
    promotion_id,
    created_at
FROM favorites
WHERE promotion_id = 'add0ffc2-df7c-4581-94c8-ba0331ad4f8e';

-- Check auth.uid() function
SELECT auth.uid() as current_auth_uid;
