-- =====================================================
-- Aggiungi campo auth_user_id alle organizations
-- =====================================================

-- 1. Aggiungi colonna auth_user_id
ALTER TABLE organizations
ADD COLUMN IF NOT EXISTS auth_user_id UUID REFERENCES auth.users(id);

-- 2. Crea indice per performance
CREATE INDEX IF NOT EXISTS idx_organizations_auth_user_id 
ON organizations(auth_user_id);

-- 3. Verifica
SELECT 
  'Colonna auth_user_id aggiunta!' as status,
  column_name, 
  data_type 
FROM information_schema.columns 
WHERE table_name = 'organizations' 
  AND column_name = 'auth_user_id';
