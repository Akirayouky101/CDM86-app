-- ============================================
-- SETUP SUPABASE STORAGE FOR IMAGES
-- Crea bucket per immagini card/pagine organizzazioni
-- ============================================

-- 1. Crea bucket per le immagini (esegui da Supabase Dashboard → Storage)
-- Bucket name: organization-images
-- Public: true
-- File size limit: 5MB
-- Allowed MIME types: image/png, image/jpeg, image/jpg, image/webp, image/gif

-- 2. Storage Policies per organization-images bucket

-- Policy: Chiunque può leggere le immagini (public bucket)
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'organization-images' );

-- Policy: Solo organizzazioni autenticate possono caricare immagini
CREATE POLICY "Authenticated organizations can upload"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'organization-images' 
  AND auth.role() = 'authenticated'
);

-- Policy: Solo il proprietario può aggiornare la propria immagine
CREATE POLICY "Users can update own images"
ON storage.objects FOR UPDATE
USING ( 
  bucket_id = 'organization-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Solo il proprietario può eliminare la propria immagine
CREATE POLICY "Users can delete own images"
ON storage.objects FOR DELETE
USING ( 
  bucket_id = 'organization-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- 3. Verifica policies
SELECT 
  policyname,
  tablename,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'storage' 
  AND tablename = 'objects';

-- NOTA: Prima di eseguire questo SQL, crea manualmente il bucket 'organization-images' 
-- da Supabase Dashboard → Storage → New Bucket
-- Impostazioni:
-- - Name: organization-images
-- - Public: ✓ (checked)
-- - File size limit: 5242880 (5MB)
-- - Allowed MIME types: image/*
