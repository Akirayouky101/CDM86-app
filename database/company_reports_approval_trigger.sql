-- =====================================================
-- TRIGGER: Gestione Approvazione Segnalazioni Aziende
-- =====================================================
-- Quando admin approva una segnalazione:
-- 1. Assegna 1 punto all'utente (qualsiasi tipo)
-- 2. Assegna 30€ compenso se INSERZIONISTA (0€ per partner/associazione)
-- 3. Distribuisce compenso anche a livello MLM 1 e 2 (solo per inserzionista)
-- =====================================================

-- Funzione per calcolare compenso MLM
CREATE OR REPLACE FUNCTION handle_company_report_approval()
RETURNS TRIGGER AS $$
DECLARE
  v_points_awarded INTEGER := 1;
  v_compensation DECIMAL(10,2) := 0.00;
  v_referrer_id UUID;
  v_referrer_of_referrer_id UUID;
  v_mlm_compensation_level1 DECIMAL(10,2) := 0.00;
  v_mlm_compensation_level2 DECIMAL(10,2) := 0.00;
  v_organization_id UUID;
  v_organization_type VARCHAR(20);
  v_random_password TEXT;
BEGIN
  -- Solo se cambia da altro stato ad "approved"
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    
    -- ========================================================================
    -- 1. DETERMINA COMPENSO BASATO SU TIPO AZIENDA
    -- ========================================================================
    IF NEW.company_type = 'inserzionista' THEN
      v_compensation := 30.00;
      v_mlm_compensation_level1 := 15.00;  -- 50% di 30€
      v_mlm_compensation_level2 := 9.00;   -- 30% di 30€
    ELSE
      v_compensation := 0.00;
      v_mlm_compensation_level1 := 0.00;
      v_mlm_compensation_level2 := 0.00;
    END IF;
    
    -- ========================================================================
    -- 🆕 1.5. CREA ORGANIZATION AUTOMATICAMENTE
    -- ========================================================================
    -- Verifica che l'azienda non esista già (per email)
    SELECT id INTO v_organization_id
    FROM organizations
    WHERE email = NEW.email
    LIMIT 1;
    
    IF v_organization_id IS NULL THEN
      -- Determina tipo organization
      IF NEW.company_type = 'associazione' THEN
        v_organization_type := 'association';
      ELSE
        v_organization_type := 'company';
      END IF;
      
      -- Genera password casuale (8 caratteri alfanumerici)
      v_random_password := substr(md5(random()::text), 1, 8);
      
      -- Crea organization
      INSERT INTO organizations (
        organization_type,
        name,
        email,
        phone,
        address,
        referred_by_user_id,
        active
      ) VALUES (
        v_organization_type,
        NEW.company_name,
        NEW.email,
        NEW.phone,
        NEW.address,
        NEW.reported_by_user_id,  -- Chi ha segnalato
        true  -- Attiva subito
      )
      RETURNING id INTO v_organization_id;
      
      -- 🔐 TODO: Salvare v_random_password e inviare email
      -- Per ora loggo solo la password (da implementare invio email)
      RAISE NOTICE '🏢 Organization creata: % (ID: %) - Password: %', 
        NEW.company_name, v_organization_id, v_random_password;
      
      -- Aggiorna company_report con organization_id creato
      UPDATE company_reports
      SET organization_id = v_organization_id
      WHERE id = NEW.id;
      
      RAISE NOTICE '✅ Azienda % iscritta automaticamente nel sistema', NEW.company_name;
    ELSE
      RAISE NOTICE 'ℹ️ Azienda % già esistente (ID: %)', NEW.company_name, v_organization_id;
    END IF;
    
    -- ========================================================================
    -- 2. AGGIORNA RECORD CON PUNTI E COMPENSO
    -- ========================================================================
    UPDATE company_reports
    SET 
      points_awarded = v_points_awarded,
      compensation_amount = v_compensation
    WHERE id = NEW.id;
    
    -- ========================================================================
    -- 3. ASSEGNA PUNTI ALL'UTENTE (sempre 1 punto)
    -- ========================================================================
    -- Aggiorna user_points
    UPDATE user_points
    SET 
      points_total = points_total + v_points_awarded,
      points_available = points_available + v_points_awarded,
      approved_reports_count = approved_reports_count + 1,
      updated_at = NOW()
    WHERE user_id = NEW.reported_by_user_id;
    
    -- Crea record se non esiste
    INSERT INTO user_points (user_id, points_total, points_available, approved_reports_count)
    VALUES (NEW.reported_by_user_id, v_points_awarded, v_points_awarded, 1)
    ON CONFLICT (user_id) DO NOTHING;
    
    -- Registra transazione punti
    INSERT INTO points_transactions (
      user_id,
      points,
      transaction_type,
      reference_id,
      description
    ) VALUES (
      NEW.reported_by_user_id,
      v_points_awarded,
      'company_report_approved',
      NEW.id,
      'Segnalazione approvata: ' || NEW.company_name || ' (' || NEW.company_type || ')'
    );
    
    RAISE NOTICE '✅ Punti: User % riceve +% punto per segnalazione %', 
      NEW.reported_by_user_id, v_points_awarded, NEW.company_name;
    
    -- ========================================================================
    -- 4. ASSEGNA COMPENSO SE INSERZIONISTA
    -- ========================================================================
    IF v_compensation > 0 THEN
      -- Crea transazione compenso per utente diretto
      INSERT INTO points_transactions (
        user_id,
        points,
        transaction_type,
        reference_id,
        description,
        compensation_euros
      ) VALUES (
        NEW.reported_by_user_id,
        0,  -- Non sono punti, è compenso in euro
        'company_compensation',
        NEW.id,
        'Compenso azienda inserzionista: ' || NEW.company_name,
        v_compensation
      );
      
      RAISE NOTICE '💰 Compenso: User % riceve €% per inserzionista %', 
        NEW.reported_by_user_id, v_compensation, NEW.company_name;
      
      -- ========================================================================
      -- 5. DISTRIBUZIONE MLM COMPENSO (solo per inserzionista)
      -- ========================================================================
      
      -- Trova referrer livello 1
      SELECT referred_by_id INTO v_referrer_id
      FROM users
      WHERE id = NEW.reported_by_user_id AND referred_by_id IS NOT NULL;
      
      IF v_referrer_id IS NOT NULL THEN
        -- Livello 1: 50% del compenso (15€)
        INSERT INTO points_transactions (
          user_id,
          points,
          transaction_type,
          reference_id,
          description,
          compensation_euros
        ) VALUES (
          v_referrer_id,
          0,
          'mlm_compensation_level1',
          NEW.id,
          'MLM Livello 1: Inserzionista ' || NEW.company_name || ' segnalata da rete',
          v_mlm_compensation_level1
        );
        
        RAISE NOTICE '💰 MLM L1: User % riceve €% (50%% di compenso)', 
          v_referrer_id, v_mlm_compensation_level1;
        
        -- Trova referrer livello 2
        SELECT referred_by_id INTO v_referrer_of_referrer_id
        FROM users
        WHERE id = v_referrer_id AND referred_by_id IS NOT NULL;
        
        IF v_referrer_of_referrer_id IS NOT NULL THEN
          -- Livello 2: 30% del compenso (9€)
          INSERT INTO points_transactions (
            user_id,
            points,
            transaction_type,
            reference_id,
            description,
            compensation_euros
          ) VALUES (
            v_referrer_of_referrer_id,
            0,
            'mlm_compensation_level2',
            NEW.id,
            'MLM Livello 2: Inserzionista ' || NEW.company_name || ' segnalata da rete',
            v_mlm_compensation_level2
          );
          
          RAISE NOTICE '💰 MLM L2: User % riceve €% (30%% di compenso)', 
            v_referrer_of_referrer_id, v_mlm_compensation_level2;
        END IF;
      END IF;
    END IF;
    
  -- ========================================================================
  -- 6. SE RIFIUTATA: segna ma non assegna nulla
  -- ========================================================================
  ELSIF NEW.status = 'rejected' AND (OLD.status IS NULL OR OLD.status != 'rejected') THEN
    
    UPDATE user_points
    SET 
      rejected_reports_count = rejected_reports_count + 1,
      updated_at = NOW()
    WHERE user_id = NEW.reported_by_user_id;
    
    INSERT INTO points_transactions (
      user_id,
      points,
      transaction_type,
      reference_id,
      description
    ) VALUES (
      NEW.reported_by_user_id,
      0,
      'company_report_rejected',
      NEW.id,
      'Segnalazione rifiutata: ' || NEW.company_name
    );
    
    RAISE NOTICE '❌ Segnalazione rifiutata: % - nessun compenso', NEW.company_name;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crea/Sostituisci il trigger
DROP TRIGGER IF EXISTS trigger_company_report_approval ON company_reports;
CREATE TRIGGER trigger_company_report_approval
  AFTER UPDATE ON company_reports
  FOR EACH ROW
  EXECUTE FUNCTION handle_company_report_approval();

COMMENT ON TRIGGER trigger_company_report_approval ON company_reports IS 
  'Assegna 1 punto + compenso (30€ inserzionista, 0€ partner/associazione) quando approvata. Distribuisce compenso MLM a livello 1 (50%) e 2 (30%)';

-- Verifica che compensation_euros esista in points_transactions
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'points_transactions' 
    AND column_name = 'compensation_euros'
  ) THEN
    ALTER TABLE points_transactions
    ADD COLUMN compensation_euros DECIMAL(10,2) DEFAULT 0.00;
    
    COMMENT ON COLUMN points_transactions.compensation_euros IS 'Compenso economico in euro (per aziende inserzioniste)';
    
    RAISE NOTICE '✅ Colonna compensation_euros aggiunta a points_transactions';
  END IF;
END $$;

-- Log successo
SELECT '✅ Trigger company_report_approval creato con successo!' as status;
SELECT '📊 Schema compensi:' as info;
SELECT '   - Inserzionista: 1 punto + 30€ (diretto) + 15€ (MLM L1) + 9€ (MLM L2)' as schema;
SELECT '   - Partner: 1 punto + 0€' as schema;
SELECT '   - Associazione: 1 punto + 0€' as schema;
