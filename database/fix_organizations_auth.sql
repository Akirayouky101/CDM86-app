-- Add auth_user_id column to link organizations to auth users
ALTER TABLE organizations 
ADD COLUMN IF NOT EXISTS auth_user_id UUID UNIQUE REFERENCES auth.users(id);

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_organizations_auth_user_id ON organizations(auth_user_id);

-- Update existing organization with your auth user ID
-- Replace 'diegomarruchi@outlook.it' with the actual organization email
UPDATE organizations 
SET auth_user_id = '84c5c178-7639-43b6-acc4-ad038a611e69'
WHERE email = 'diegomarruchi@outlook.it';

-- Verify the update
SELECT id, name, email, auth_user_id 
FROM organizations 
WHERE auth_user_id = '84c5c178-7639-43b6-acc4-ad038a611e69';
