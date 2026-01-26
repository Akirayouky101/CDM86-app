-- 1. AGGIUNGI COLONNE ALLA TABELLA USERS
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS data_nascita DATE,
ADD COLUMN IF NOT EXISTS codice_fiscale VARCHAR(16) UNIQUE,
ADD COLUMN IF NOT EXISTS cap_residenza VARCHAR(5),
ADD COLUMN IF NOT EXISTS sesso VARCHAR(1) CHECK (sesso IN ('M', 'F'));

-- 2. CREA TABELLA ZONES PER GESTIONE ZONE/CAP
CREATE TABLE IF NOT EXISTS public.zones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    cap_list JSONB DEFAULT '[]'::jsonb, -- Array di CAP: ["00100", "00101", ...]
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. CREA INDICI PER PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_users_codice_fiscale ON public.users(codice_fiscale);
CREATE INDEX IF NOT EXISTS idx_users_cap_residenza ON public.users(cap_residenza);
CREATE INDEX IF NOT EXISTS idx_zones_cap_list ON public.zones USING GIN (cap_list);

-- 4. RLS POLICIES PER ZONES
ALTER TABLE public.zones ENABLE ROW LEVEL SECURITY;

-- Admin può fare tutto su zones
CREATE POLICY "Admin can manage zones"
ON public.zones
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE auth_user_id = auth.uid() AND role = 'admin'
    )
);

-- Tutti possono leggere le zone (per validare CAP)
CREATE POLICY "Everyone can read zones"
ON public.zones
FOR SELECT
TO authenticated
USING (active = true);

-- 5. FUNCTION: Trova zona da CAP
CREATE OR REPLACE FUNCTION public.get_zone_by_cap(p_cap TEXT)
RETURNS TABLE (
    zone_id UUID,
    zone_name VARCHAR(100),
    zone_description TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT id, name, description
    FROM public.zones
    WHERE active = true 
      AND cap_list @> to_jsonb(p_cap);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. VERIFICA
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'users'
  AND column_name IN ('data_nascita', 'codice_fiscale', 'cap_residenza', 'sesso')
ORDER BY column_name;

SELECT * FROM public.zones LIMIT 1;
