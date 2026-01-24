-- =====================================================
-- SISTEMA EMAIL NOTIFICHE PER ORGANIZZAZIONI APPROVATE
-- =====================================================

-- 1. Crea tabella per tenere traccia delle password temporanee
CREATE TABLE IF NOT EXISTS organization_temp_passwords (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  temp_password TEXT NOT NULL,
  email_sent BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() + INTERVAL '7 days'
);

-- Index per performance
CREATE INDEX IF NOT EXISTS idx_org_temp_passwords_org_id 
  ON organization_temp_passwords(organization_id);

-- 2. Modifica il trigger per salvare la password temporanea
CREATE OR REPLACE FUNCTION handle_company_report_approval()
RETURNS TRIGGER AS $$
DECLARE
  v_reporter_id UUID;
  v_company_name TEXT;
  v_company_email TEXT;
  v_company_type TEXT;
  v_compensation_amount DECIMAL(10,2);
  v_points_awarded INT;
  v_referrer_level1_id UUID;
  v_referrer_level2_id UUID;
  v_organization_id UUID;
  v_random_password TEXT;
BEGIN
  -- Solo quando status cambia da pending/rejected a approved
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    
    -- Ottieni dati della segnalazione
    v_reporter_id := NEW.reported_by_user_id;
    v_company_name := NEW.company_name;
    v_company_email := NEW.email;  -- Campo si chiama 'email', non 'company_email'
    v_company_type := COALESCE(NEW.company_type, 'partner');
    
    -- Determina compenso basato su company_type
    CASE v_company_type
      WHEN 'inserzionista' THEN
        v_compensation_amount := 30.00;
        v_points_awarded := 1;
      WHEN 'partner' THEN
        v_compensation_amount := 0.00;
        v_points_awarded := 1;
      WHEN 'associazione' THEN
        v_compensation_amount := 0.00;
        v_points_awarded := 1;
      ELSE
        v_compensation_amount := 0.00;
        v_points_awarded := 1;
    END CASE;
    
    -- Aggiorna company_reports con compenso e punti
    UPDATE company_reports
    SET 
      compensation_amount = v_compensation_amount,
      points_awarded = v_points_awarded
    WHERE id = NEW.id;
    
    -- =====================================================
    -- CREA ORGANIZATION SE NON ESISTE
    -- =====================================================
    
    -- Controlla se esiste già un'organizzazione con questa email
    SELECT id INTO v_organization_id
    FROM organizations
    WHERE email = v_company_email;
    
    -- Se non esiste, creala
    IF v_organization_id IS NULL THEN
      -- Genera password casuale (8 caratteri)
      v_random_password := substring(md5(random()::text) from 1 for 8);
      
      -- Crea l'organizzazione
      INSERT INTO organizations (
        name,
        email,
        referral_code,
        referred_by_user_id,
        active
      ) VALUES (
        v_company_name,
        v_company_email,
        substring(md5(random()::text || v_company_email) from 1 for 8),
        v_reporter_id,
        true
      )
      RETURNING id INTO v_organization_id;
      
      -- *** SALVA LA PASSWORD TEMPORANEA ***
      INSERT INTO organization_temp_passwords (
        organization_id,
        temp_password,
        email_sent
      ) VALUES (
        v_organization_id,
        v_random_password,
        false
      );
      
      -- Log della password (visibile nei log PostgreSQL)
      RAISE NOTICE '🔑 ORGANIZATION CREATED - Email: %, Password: %', v_company_email, v_random_password;
    END IF;
    
    -- Collega organization_id a company_report
    UPDATE company_reports
    SET organization_id = v_organization_id
    WHERE id = NEW.id;
    
    -- =====================================================
    -- ASSEGNA PUNTI E COMPENSO ALL'UTENTE
    -- =====================================================
    
    -- Assegna punti all'utente
    INSERT INTO user_points (user_id, points_total, points_available, approved_reports_count)
    VALUES (v_reporter_id, v_points_awarded, v_points_awarded, 1)
    ON CONFLICT (user_id) DO UPDATE SET
      points_total = user_points.points_total + v_points_awarded,
      points_available = user_points.points_available + v_points_awarded,
      approved_reports_count = user_points.approved_reports_count + 1,
      updated_at = NOW();
    
    -- Crea transazione approvazione
    INSERT INTO points_transactions (
      user_id,
      points,
      transaction_type,
      description,
      related_entity_id,
      related_entity_type
    ) VALUES (
      v_reporter_id,
      v_points_awarded,
      'company_report_approved',
      'Segnalazione approvata: ' || v_company_name,
      NEW.id,
      'company_report'
    );
    
    -- Se è inserzionista, crea transazione compenso
    IF v_company_type = 'inserzionista' AND v_compensation_amount > 0 THEN
      -- Verifica se esiste la colonna compensation_euros, altrimenti creala
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'points_transactions' AND column_name = 'compensation_euros'
      ) THEN
        ALTER TABLE points_transactions ADD COLUMN compensation_euros DECIMAL(10,2) DEFAULT 0;
      END IF;
      
      INSERT INTO points_transactions (
        user_id,
        points,
        compensation_euros,
        transaction_type,
        description,
        related_entity_id,
        related_entity_type
      ) VALUES (
        v_reporter_id,
        0,
        v_compensation_amount,
        'company_compensation',
        'Compenso azienda inserzionista: ' || v_company_name,
        NEW.id,
        'company_report'
      );
    END IF;
    
    -- =====================================================
    -- DISTRIBUZIONE MLM (solo per inserzioniste)
    -- =====================================================
    
    IF v_company_type = 'inserzionista' THEN
      -- Trova referrer livello 1
      SELECT referred_by_id INTO v_referrer_level1_id
      FROM users
      WHERE id = v_reporter_id;
      
      -- Compenso livello 1: €15
      IF v_referrer_level1_id IS NOT NULL THEN
        INSERT INTO points_transactions (
          user_id,
          points,
          compensation_euros,
          transaction_type,
          description,
          related_entity_id,
          related_entity_type
        ) VALUES (
          v_referrer_level1_id,
          0,
          15.00,
          'mlm_compensation_level1',
          'MLM Livello 1 - Azienda: ' || v_company_name,
          NEW.id,
          'company_report'
        );
        
        -- Trova referrer livello 2
        SELECT referred_by_id INTO v_referrer_level2_id
        FROM users
        WHERE id = v_referrer_level1_id;
        
        -- Compenso livello 2: €9
        IF v_referrer_level2_id IS NOT NULL THEN
          INSERT INTO points_transactions (
            user_id,
            points,
            compensation_euros,
            transaction_type,
            description,
            related_entity_id,
            related_entity_type
          ) VALUES (
            v_referrer_level2_id,
            0,
            9.00,
            'mlm_compensation_level2',
            'MLM Livello 2 - Azienda: ' || v_company_name,
            NEW.id,
            'company_report'
          );
        END IF;
      END IF;
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Ricrea il trigger
DROP TRIGGER IF EXISTS trigger_company_report_approval ON company_reports;
CREATE TRIGGER trigger_company_report_approval
  AFTER UPDATE ON company_reports
  FOR EACH ROW
  EXECUTE FUNCTION handle_company_report_approval();

-- =====================================================
-- QUERY PER VEDERE PASSWORD TEMPORANEE
-- =====================================================

-- Commento: Usa questa query per vedere le password delle organizzazioni create
/*
SELECT 
  o.name,
  o.email,
  otp.temp_password,
  otp.email_sent,
  otp.created_at,
  otp.expires_at
FROM organization_temp_passwords otp
JOIN organizations o ON o.id = otp.organization_id
WHERE otp.email_sent = false
ORDER BY otp.created_at DESC;
*/
