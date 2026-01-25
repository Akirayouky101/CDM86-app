-- =====================================================
-- FIX RLS POLICY: company_reports
-- =====================================================
-- Permetti agli utenti autenticati di inserire segnalazioni

-- 1. Drop existing policies (se esistono)
DROP POLICY IF EXISTS "Users can insert their own company reports" ON company_reports;
DROP POLICY IF EXISTS "Users can view their own company reports" ON company_reports;
DROP POLICY IF EXISTS "Admins can view all company reports" ON company_reports;
DROP POLICY IF EXISTS "Admins can update company reports" ON company_reports;

-- 2. Enable RLS (se non già abilitato)
ALTER TABLE company_reports ENABLE ROW LEVEL SECURITY;

-- 3. CREATE POLICY: Gli utenti possono inserire le proprie segnalazioni
CREATE POLICY "Users can insert their own company reports"
ON company_reports
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() IS NOT NULL
);

-- 4. CREATE POLICY: Gli utenti possono vedere le proprie segnalazioni
CREATE POLICY "Users can view their own company reports"
ON company_reports
FOR SELECT
TO authenticated
USING (
  reported_by_user_id IN (
    SELECT id FROM users WHERE id = auth.uid()
  )
);

-- 5. CREATE POLICY: Gli admin possono vedere tutte le segnalazioni
CREATE POLICY "Admins can view all company reports"
ON company_reports
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() 
    AND role = 'admin'
  )
);

-- 6. CREATE POLICY: Gli admin possono aggiornare le segnalazioni
CREATE POLICY "Admins can update company reports"
ON company_reports
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() 
    AND role = 'admin'
  )
);

-- 7. Verifica policies create
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename = 'company_reports'
ORDER BY policyname;

SELECT '✅ RLS POLICIES FIXED!' as status;
