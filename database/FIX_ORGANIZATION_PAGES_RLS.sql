-- ============================================
-- FIX RLS POLICIES FOR organization_pages
-- Permette alle organizzazioni di gestire le proprie pagine
-- ============================================

-- Drop existing policies (if any)
DROP POLICY IF EXISTS "Organizations can view own pages" ON organization_pages;
DROP POLICY IF EXISTS "Organizations can insert own pages" ON organization_pages;
DROP POLICY IF EXISTS "Organizations can update own pages" ON organization_pages;
DROP POLICY IF EXISTS "Organizations can delete own pages" ON organization_pages;
DROP POLICY IF EXISTS "Public can view published pages" ON organization_pages;

-- Enable RLS
ALTER TABLE organization_pages ENABLE ROW LEVEL SECURITY;

-- Policy 1: Organizations can view their own pages
CREATE POLICY "Organizations can view own pages"
ON organization_pages
FOR SELECT
USING (
    organization_id = auth.uid()
);

-- Policy 2: Organizations can insert their own pages
CREATE POLICY "Organizations can insert own pages"
ON organization_pages
FOR INSERT
WITH CHECK (
    organization_id = auth.uid()
);

-- Policy 3: Organizations can update their own pages
CREATE POLICY "Organizations can update own pages"
ON organization_pages
FOR UPDATE
USING (
    organization_id = auth.uid()
)
WITH CHECK (
    organization_id = auth.uid()
);

-- Policy 4: Organizations can delete their own pages
CREATE POLICY "Organizations can delete own pages"
ON organization_pages
FOR DELETE
USING (
    organization_id = auth.uid()
);

-- Policy 5: Everyone can view published pages (for public access)
CREATE POLICY "Public can view published pages"
ON organization_pages
FOR SELECT
USING (
    status = 'published'
);

-- Verify policies
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
WHERE tablename = 'organization_pages';
