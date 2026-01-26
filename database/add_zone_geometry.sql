-- Aggiunge colonna geometry per salvare coordinate poligoni personalizzati

-- Aggiungi colonna JSONB per memorizzare coordinate poligono
ALTER TABLE zones 
ADD COLUMN IF NOT EXISTS geometry JSONB DEFAULT NULL;

-- Aggiungi commento alla colonna
COMMENT ON COLUMN zones.geometry IS 'Coordinate poligono zona in formato GeoJSON: {type: "Polygon", coordinates: [[[lng, lat], ...]]}';

-- Verifica
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'zones' 
  AND column_name = 'geometry';
