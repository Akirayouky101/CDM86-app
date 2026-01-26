-- INSERISCI ZONE DI TEST per verificare visualizzazione mappa
-- Esegui questo SQL su Supabase SQL Editor

-- Prima aggiungi la colonna geometry se non l'hai già fatto
ALTER TABLE zones ADD COLUMN IF NOT EXISTS geometry JSONB DEFAULT NULL;

-- Zona 1: CAP SINGOLO (vedrai cerchio 2km raggio)
INSERT INTO zones (name, description, cap_list, active) 
VALUES (
    'Test Roma Centro',
    'Centro storico di Roma - CAP singolo come cerchio',
    '["00100"]'::jsonb,
    true
);

-- Zona 2: CAP MULTIPLI (vedrai poligono VERDE)
INSERT INTO zones (name, description, cap_list, active) 
VALUES (
    'Test Roma Nord',
    'Quartieri nord Roma - poligono automatico',
    '["00135", "00136", "00138", "00141", "00161"]'::jsonb,
    true
);

-- Zona 3: CAP SUD (vedrai poligono ARANCIO)
INSERT INTO zones (name, description, cap_list, active) 
VALUES (
    'Test Roma Sud EUR',
    'Zona EUR e dintorni - più CAP',
    '["00142", "00143", "00144", "00145", "00146"]'::jsonb,
    true
);

-- Zona 4: MILANO (vedrai poligono ROSSO)
INSERT INTO zones (name, description, cap_list, active) 
VALUES (
    'Test Milano Centro',
    'Centro Milano - Duomo e dintorni',
    '["20121", "20122", "20123"]'::jsonb,
    true
);

-- Zona 5: NAPOLI disattiva (vedrai poligono GRIGIO)
INSERT INTO zones (name, description, cap_list, active) 
VALUES (
    'Test Napoli Centro',
    'Centro Napoli - zona disattivata',
    '["80121", "80133", "80138"]'::jsonb,
    false
);

-- VERIFICA
SELECT id, name, cap_list, active, created_at 
FROM zones 
ORDER BY created_at DESC;

-- CONTA TOTALE
SELECT COUNT(*) as total_zones FROM zones;
