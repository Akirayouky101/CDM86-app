-- ============================================
-- TABELLA: organization_pages
-- Sistema pagine personalizzate per le aziende
-- ============================================

-- Crea la tabella organization_pages
CREATE TABLE IF NOT EXISTS organization_pages (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Collegamento all'organizzazione
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Slug per URL pubblico (es: /azienda/mcdonald-s)
    slug VARCHAR(255) NOT NULL UNIQUE,
    
    -- Dati della pagina (JSON con sezioni del page builder)
    page_data JSONB NOT NULL DEFAULT '{"sections": [], "style": "modern"}',
    
    -- Metadata
    page_title VARCHAR(255),
    page_description TEXT,
    meta_image TEXT, -- URL immagine per social sharing
    
    -- Stato pubblicazione
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    
    -- SEO e analytics
    views_count INTEGER DEFAULT 0,
    last_viewed_at TIMESTAMP WITH TIME ZONE,
    
    -- Timestamp
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    published_at TIMESTAMP WITH TIME ZONE
);

-- Indici per performance
CREATE INDEX IF NOT EXISTS idx_org_pages_organization_id ON organization_pages(organization_id);
CREATE INDEX IF NOT EXISTS idx_org_pages_slug ON organization_pages(slug);
CREATE INDEX IF NOT EXISTS idx_org_pages_status ON organization_pages(status);

-- Vincolo: Una sola pagina pubblicata per organizzazione
CREATE UNIQUE INDEX IF NOT EXISTS idx_org_one_published_page 
ON organization_pages(organization_id) 
WHERE status = 'published';

-- Trigger per aggiornare updated_at
CREATE OR REPLACE FUNCTION update_organization_page_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    
    -- Se passa a published, imposta published_at
    IF NEW.status = 'published' AND OLD.status != 'published' THEN
        NEW.published_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_organization_page_updated ON organization_pages;
CREATE TRIGGER on_organization_page_updated
    BEFORE UPDATE ON organization_pages
    FOR EACH ROW
    EXECUTE FUNCTION update_organization_page_updated_at();

-- Funzione per generare slug da nome organizzazione
CREATE OR REPLACE FUNCTION generate_organization_slug(org_name TEXT)
RETURNS VARCHAR(255) AS $$
DECLARE
    base_slug VARCHAR(255);
    final_slug VARCHAR(255);
    counter INTEGER := 0;
    slug_exists BOOLEAN;
BEGIN
    -- Converti nome in slug: "McDonald's" -> "mcdonald-s"
    base_slug := lower(regexp_replace(
        regexp_replace(org_name, '[^a-zA-Z0-9\s]', '', 'g'),
        '\s+', '-', 'g'
    ));
    
    -- Limita lunghezza
    base_slug := substring(base_slug from 1 for 200);
    
    -- Rimuovi trattini doppi/iniziali/finali
    base_slug := regexp_replace(base_slug, '-+', '-', 'g');
    base_slug := trim(both '-' from base_slug);
    
    final_slug := base_slug;
    
    -- Se slug esiste, aggiungi numero
    LOOP
        SELECT EXISTS(
            SELECT 1 FROM organization_pages WHERE slug = final_slug
        ) INTO slug_exists;
        
        EXIT WHEN NOT slug_exists;
        
        counter := counter + 1;
        final_slug := base_slug || '-' || counter;
    END LOOP;
    
    RETURN final_slug;
END;
$$ LANGUAGE plpgsql;

-- Row Level Security (RLS)
ALTER TABLE organization_pages ENABLE ROW LEVEL SECURITY;

-- Policy: Tutti possono vedere pagine pubblicate
CREATE POLICY "Public can view published pages" ON organization_pages
    FOR SELECT
    USING (status = 'published');

-- Policy: Le organizzazioni possono vedere le proprie pagine
CREATE POLICY "Organizations can view own pages" ON organization_pages
    FOR SELECT
    USING (
        organization_id IN (
            SELECT id FROM organizations 
            WHERE user_id = auth.uid()
        )
    );

-- Policy: Le organizzazioni possono creare/modificare le proprie pagine
CREATE POLICY "Organizations can manage own pages" ON organization_pages
    FOR ALL
    USING (
        organization_id IN (
            SELECT id FROM organizations 
            WHERE user_id = auth.uid()
        )
    );

-- Policy: Admin può vedere e modificare tutto
CREATE POLICY "Admin can manage all pages" ON organization_pages
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

COMMENT ON TABLE organization_pages IS 'Pagine personalizzate create dalle aziende con il page builder';
COMMENT ON COLUMN organization_pages.slug IS 'URL slug per accesso pubblico (es: /azienda/mcdonald-s)';
COMMENT ON COLUMN organization_pages.page_data IS 'JSON con sezioni e stile della pagina dal page builder';
COMMENT ON COLUMN organization_pages.status IS 'Stato: draft (bozza), published (pubblicata), archived (archiviata)';
