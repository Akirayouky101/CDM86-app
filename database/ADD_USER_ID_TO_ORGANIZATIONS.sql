-- ============================================
-- AGGIUNGE CAMPO user_id ALLA TABELLA ORGANIZATIONS
-- ============================================
-- Questo campo serve per collegare l'organizzazione al suo utente auth
-- necessario per il login al pannello azienda
-- ============================================

-- Aggiungi colonna user_id se non esiste
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'organizations' 
        AND column_name = 'user_id'
    ) THEN
        ALTER TABLE organizations 
        ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;
        
        -- Crea indice per performance
        CREATE INDEX idx_organizations_user_id ON organizations(user_id);
        
        -- Aggiungi vincolo di unicità (un utente auth = una sola organizzazione)
        ALTER TABLE organizations 
        ADD CONSTRAINT unique_organization_user_id UNIQUE (user_id);
        
        RAISE NOTICE 'Colonna user_id aggiunta con successo alla tabella organizations';
    ELSE
        RAISE NOTICE 'Colonna user_id già esistente nella tabella organizations';
    END IF;
END $$;

-- Verifica la struttura della tabella
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'organizations'
ORDER BY ordinal_position;
