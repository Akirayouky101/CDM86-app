-- ============================================================================
-- SISTEMA REFERRAL MLM - 2 LIVELLI
-- ============================================================================
-- Sistema di Network Marketing Multi-Livello con profondità massima 2
-- 
-- LOGICA:
-- - Livello 1 (referral diretti): +1 punto al referrer
-- - Livello 2 (rete indiretta): +1 punto al referrer del referrer
-- - Livello 3+: NESSUN punto
--
-- ESEMPIO:
-- A invita B → A riceve +1 punto (livello 1)
-- B invita C → A riceve +1 punto (livello 2), B riceve +1 punto (livello 1)
-- C invita D → B riceve +1 punto (livello 2), C riceve +1 punto (livello 1), A riceve 0
--
-- Ogni utente costruisce la propria rete indipendente
-- ============================================================================

-- ============================================================================
-- STEP 1: Creare tabella per tracciare la rete referral
-- ============================================================================

CREATE TABLE IF NOT EXISTS referral_network (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,        -- Chi riceve i punti
  referral_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,    -- Chi si è registrato
  level INTEGER NOT NULL CHECK (level BETWEEN 1 AND 2),                -- Profondità (1=diretto, 2=rete)
  points_awarded DECIMAL(10,2) NOT NULL DEFAULT 1.00,                  -- Punti assegnati
  referral_type VARCHAR(50) DEFAULT 'user',                            -- Tipo account registrato
  created_at TIMESTAMP DEFAULT NOW(),
  
  -- Indici per performance
  CONSTRAINT unique_referral_assignment UNIQUE (user_id, referral_id, level)
);

-- Indici per query veloci
CREATE INDEX IF NOT EXISTS idx_referral_network_user_id ON referral_network(user_id);
CREATE INDEX IF NOT EXISTS idx_referral_network_referral_id ON referral_network(referral_id);
CREATE INDEX IF NOT EXISTS idx_referral_network_level ON referral_network(level);

COMMENT ON TABLE referral_network IS 'Traccia ogni assegnazione di punti nella rete MLM a 2 livelli';
COMMENT ON COLUMN referral_network.user_id IS 'Utente che riceve i punti';
COMMENT ON COLUMN referral_network.referral_id IS 'Utente che si è registrato e genera i punti';
COMMENT ON COLUMN referral_network.level IS '1=referral diretto, 2=referral indiretto (rete del diretto)';


-- ============================================================================
-- STEP 2: Aggiungere account_type a users
-- ============================================================================

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'account_type'
  ) THEN
    ALTER TABLE users ADD COLUMN account_type VARCHAR(50) DEFAULT 'user';
    
    -- Valori possibili: 'user', 'organization', 'partner', 'association', 'collaborator'
    ALTER TABLE users ADD CONSTRAINT check_account_type 
      CHECK (account_type IN ('user', 'organization', 'partner', 'association', 'collaborator'));
    
    COMMENT ON COLUMN users.account_type IS 'Tipo di account: user, organization, partner, association, collaborator';
  END IF;
END $$;


-- ============================================================================
-- STEP 3: Funzione per assegnare punti MLM (2 livelli)
-- ============================================================================

CREATE OR REPLACE FUNCTION award_referral_points_mlm()
RETURNS TRIGGER AS $$
DECLARE
  v_referrer_id UUID;           -- ID del referrer diretto (livello 1)
  v_referrer_of_referrer_id UUID; -- ID del referrer del referrer (livello 2)
  v_account_type VARCHAR(50);   -- Tipo account del nuovo utente
  v_points_awarded DECIMAL(10,2) := 1.00; -- Punti per referral (sempre 1)
BEGIN
  -- Solo se il nuovo utente ha un referral code
  IF NEW.referred_by_id IS NOT NULL THEN
    
    -- Ottieni tipo account del nuovo utente
    v_account_type := COALESCE(NEW.account_type, 'user');
    
    -- ========================================================================
    -- LIVELLO 1: Referrer diretto riceve +1 punto
    -- ========================================================================
    v_referrer_id := NEW.referred_by_id;
    
    -- Registra nella rete
    INSERT INTO referral_network (user_id, referral_id, level, points_awarded, referral_type)
    VALUES (v_referrer_id, NEW.id, 1, v_points_awarded, v_account_type)
    ON CONFLICT (user_id, referral_id, level) DO NOTHING;
    
    -- Aggiorna user_points del referrer diretto
    UPDATE user_points 
    SET 
      points_total = points_total + v_points_awarded,
      referrals_count = referrals_count + 1,
      updated_at = NOW()
    WHERE user_id = v_referrer_id;
    
    -- Crea record se non esiste
    INSERT INTO user_points (user_id, points_total, referrals_count)
    VALUES (v_referrer_id, v_points_awarded, 1)
    ON CONFLICT (user_id) DO NOTHING;
    
    -- Registra transazione
    INSERT INTO points_transactions (user_id, points, type, description)
    VALUES (
      v_referrer_id, 
      v_points_awarded, 
      'referral_level_1', 
      'Referral diretto: ' || COALESCE(NEW.first_name || ' ' || NEW.last_name, NEW.email)
    );
    
    RAISE NOTICE '✅ Livello 1: User % riceve +% punti per referral diretto %', 
      v_referrer_id, v_points_awarded, NEW.id;
    
    
    -- ========================================================================
    -- LIVELLO 2: Referrer del referrer riceve +1 punto
    -- ========================================================================
    -- Trova chi ha invitato il referrer diretto
    SELECT referred_by_id INTO v_referrer_of_referrer_id
    FROM users
    WHERE id = v_referrer_id AND referred_by_id IS NOT NULL;
    
    IF v_referrer_of_referrer_id IS NOT NULL THEN
      
      -- Registra nella rete
      INSERT INTO referral_network (user_id, referral_id, level, points_awarded, referral_type)
      VALUES (v_referrer_of_referrer_id, NEW.id, 2, v_points_awarded, v_account_type)
      ON CONFLICT (user_id, referral_id, level) DO NOTHING;
      
      -- Aggiorna user_points del referrer di livello 2
      UPDATE user_points 
      SET 
        points_total = points_total + v_points_awarded,
        updated_at = NOW()
      WHERE user_id = v_referrer_of_referrer_id;
      
      -- Crea record se non esiste
      INSERT INTO user_points (user_id, points_total)
      VALUES (v_referrer_of_referrer_id, v_points_awarded)
      ON CONFLICT (user_id) DO NOTHING;
      
      -- Registra transazione
      INSERT INTO points_transactions (user_id, points, type, description)
      VALUES (
        v_referrer_of_referrer_id, 
        v_points_awarded, 
        'referral_level_2', 
        'Rete indiretta: ' || COALESCE(NEW.first_name || ' ' || NEW.last_name, NEW.email)
      );
      
      RAISE NOTICE '✅ Livello 2: User % riceve +% punti per rete indiretta %', 
        v_referrer_of_referrer_id, v_points_awarded, NEW.id;
      
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION award_referral_points_mlm() IS 'Assegna punti MLM a 2 livelli: +1 per diretti, +1 per rete';


-- ============================================================================
-- STEP 4: Trigger su INSERT users
-- ============================================================================

-- Rimuovi trigger vecchi se esistono
DROP TRIGGER IF EXISTS trigger_award_referral_points ON users;
DROP TRIGGER IF EXISTS trigger_award_referral_on_update ON users;

-- Crea nuovo trigger MLM
CREATE TRIGGER trigger_award_referral_points_mlm
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION award_referral_points_mlm();

COMMENT ON TRIGGER trigger_award_referral_points_mlm ON users IS 
  'Assegna punti MLM quando nuovo utente si registra con referral code';


-- ============================================================================
-- STEP 5: Trigger su UPDATE users (quando referred_by_id viene impostato dopo)
-- ============================================================================

CREATE OR REPLACE FUNCTION award_referral_points_mlm_on_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Solo se referred_by_id cambia da NULL a un valore
  IF OLD.referred_by_id IS NULL AND NEW.referred_by_id IS NOT NULL THEN
    
    -- Chiama la stessa logica dell'INSERT
    PERFORM award_referral_points_mlm_internal(NEW.id, NEW.referred_by_id, NEW.account_type, NEW.first_name, NEW.last_name, NEW.email);
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Funzione helper per riutilizzare la logica
CREATE OR REPLACE FUNCTION award_referral_points_mlm_internal(
  p_user_id UUID,
  p_referred_by_id UUID,
  p_account_type VARCHAR,
  p_first_name VARCHAR,
  p_last_name VARCHAR,
  p_email VARCHAR
)
RETURNS VOID AS $$
DECLARE
  v_referrer_id UUID;
  v_referrer_of_referrer_id UUID;
  v_account_type VARCHAR(50);
  v_points_awarded DECIMAL(10,2) := 1.00;
BEGIN
  v_account_type := COALESCE(p_account_type, 'user');
  v_referrer_id := p_referred_by_id;
  
  -- LIVELLO 1
  INSERT INTO referral_network (user_id, referral_id, level, points_awarded, referral_type)
  VALUES (v_referrer_id, p_user_id, 1, v_points_awarded, v_account_type)
  ON CONFLICT (user_id, referral_id, level) DO NOTHING;
  
  UPDATE user_points 
  SET points_total = points_total + v_points_awarded, referrals_count = referrals_count + 1, updated_at = NOW()
  WHERE user_id = v_referrer_id;
  
  INSERT INTO user_points (user_id, points_total, referrals_count)
  VALUES (v_referrer_id, v_points_awarded, 1)
  ON CONFLICT (user_id) DO NOTHING;
  
  INSERT INTO points_transactions (user_id, points, type, description)
  VALUES (v_referrer_id, v_points_awarded, 'referral_level_1', 
    'Referral diretto: ' || COALESCE(p_first_name || ' ' || p_last_name, p_email));
  
  -- LIVELLO 2
  SELECT referred_by_id INTO v_referrer_of_referrer_id
  FROM users WHERE id = v_referrer_id AND referred_by_id IS NOT NULL;
  
  IF v_referrer_of_referrer_id IS NOT NULL THEN
    INSERT INTO referral_network (user_id, referral_id, level, points_awarded, referral_type)
    VALUES (v_referrer_of_referrer_id, p_user_id, 2, v_points_awarded, v_account_type)
    ON CONFLICT (user_id, referral_id, level) DO NOTHING;
    
    UPDATE user_points 
    SET points_total = points_total + v_points_awarded, updated_at = NOW()
    WHERE user_id = v_referrer_of_referrer_id;
    
    INSERT INTO user_points (user_id, points_total)
    VALUES (v_referrer_of_referrer_id, v_points_awarded)
    ON CONFLICT (user_id) DO NOTHING;
    
    INSERT INTO points_transactions (user_id, points, type, description)
    VALUES (v_referrer_of_referrer_id, v_points_awarded, 'referral_level_2', 
      'Rete indiretta: ' || COALESCE(p_first_name || ' ' || p_last_name, p_email));
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger su UPDATE
CREATE TRIGGER trigger_award_referral_points_mlm_on_update
  AFTER UPDATE OF referred_by_id ON users
  FOR EACH ROW
  EXECUTE FUNCTION award_referral_points_mlm_on_update();

COMMENT ON TRIGGER trigger_award_referral_points_mlm_on_update ON users IS 
  'Assegna punti MLM quando referred_by_id viene impostato via UPDATE (API)';


-- ============================================================================
-- STEP 6: View per dashboard - Visualizzazione rete utente
-- ============================================================================

CREATE OR REPLACE VIEW user_referral_network AS
SELECT 
  rn.user_id,
  u.email as user_email,
  u.first_name || ' ' || u.last_name as user_name,
  
  -- Statistiche livello 1 (diretti)
  COUNT(CASE WHEN rn.level = 1 THEN 1 END) as direct_referrals_count,
  SUM(CASE WHEN rn.level = 1 THEN rn.points_awarded ELSE 0 END) as direct_referrals_points,
  
  -- Statistiche livello 2 (rete)
  COUNT(CASE WHEN rn.level = 2 THEN 1 END) as network_referrals_count,
  SUM(CASE WHEN rn.level = 2 THEN rn.points_awarded ELSE 0 END) as network_referrals_points,
  
  -- Totali
  COUNT(*) as total_referrals,
  SUM(rn.points_awarded) as total_points_from_referrals,
  
  -- Punti totali dal sistema
  up.points_total,
  up.referrals_count,
  up.level as user_level
  
FROM referral_network rn
JOIN users u ON rn.user_id = u.id
LEFT JOIN user_points up ON rn.user_id = up.user_id
GROUP BY rn.user_id, u.email, u.first_name, u.last_name, up.points_total, up.referrals_count, up.level;

COMMENT ON VIEW user_referral_network IS 'Dashboard: statistiche rete referral per utente (livello 1 e 2)';


-- ============================================================================
-- STEP 7: View dettaglio referral per utente
-- ============================================================================

CREATE OR REPLACE VIEW user_referral_details AS
SELECT 
  rn.user_id,
  rn.referral_id,
  u_referral.email as referral_email,
  u_referral.first_name || ' ' || u_referral.last_name as referral_name,
  u_referral.account_type as referral_account_type,
  rn.level,
  rn.points_awarded,
  rn.created_at as referral_registered_at,
  
  -- Controlla se il referral è attivo (ha fatto almeno 1 azione)
  CASE 
    WHEN EXISTS (SELECT 1 FROM user_points WHERE user_id = rn.referral_id AND points_total > 0) 
    THEN true 
    ELSE false 
  END as is_active
  
FROM referral_network rn
JOIN users u_referral ON rn.referral_id = u_referral.id
ORDER BY rn.user_id, rn.level, rn.created_at DESC;

COMMENT ON VIEW user_referral_details IS 'Dettaglio completo di ogni referral per utente con stato attività';


-- ============================================================================
-- FINE SETUP
-- ============================================================================

-- Log successo
DO $$
BEGIN
  RAISE NOTICE '✅ Sistema MLM Referral installato con successo!';
  RAISE NOTICE '📊 Tabella: referral_network creata';
  RAISE NOTICE '👤 Colonna: users.account_type aggiunta';
  RAISE NOTICE '⚡ Trigger: INSERT e UPDATE configurati';
  RAISE NOTICE '📈 View: user_referral_network e user_referral_details create';
  RAISE NOTICE '';
  RAISE NOTICE '🎯 Sistema pronto: 2 livelli, +1 punto per livello';
END $$;
