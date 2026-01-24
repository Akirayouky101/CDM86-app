-- =====================================================
-- SETUP COMPLETO + RESET: Sistema Dual Referral
-- =====================================================
-- Esegui questo file UNA VOLTA per setup iniziale + ogni volta per reset test
-- =====================================================

-- PARTE 1: SETUP (solo prima volta, poi si può commentare)
-- =====================================================

-- 1A. Aggiungi auth_user_id alle organizations (se non esiste già)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'organizations' AND column_name = 'auth_user_id'
  ) THEN
    ALTER TABLE organizations ADD COLUMN auth_user_id UUID REFERENCES auth.users(id);
    CREATE INDEX idx_organizations_auth_user_id ON organizations(auth_user_id);
  END IF;
END $$;

-- 1B. Aggiungi colonne per i due codici referral (se non esistono)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'organizations' AND column_name = 'referral_code_employees'
  ) THEN
    ALTER TABLE organizations ADD COLUMN referral_code_employees VARCHAR(20) UNIQUE;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'organizations' AND column_name = 'referral_code_external'
  ) THEN
    ALTER TABLE organizations ADD COLUMN referral_code_external VARCHAR(20) UNIQUE;
  END IF;
END $$;

-- 1C. Aggiungi referral_type agli users (se non esiste)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'referral_type'
  ) THEN
    ALTER TABLE users ADD COLUMN referral_type VARCHAR(20);
  END IF;
END $$;

-- 1D. Crea indici per performance
CREATE INDEX IF NOT EXISTS idx_org_referral_employees ON organizations(referral_code_employees);
CREATE INDEX IF NOT EXISTS idx_org_referral_external ON organizations(referral_code_external);

-- 1E. Aggiorna trigger per generare 3 codici
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
  v_base_code TEXT;
BEGIN
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    
    v_reporter_id := NEW.reported_by_user_id;
    v_company_name := NEW.company_name;
    v_company_email := NEW.email;
    v_company_type := COALESCE(NEW.company_type, 'partner');
    
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
    
    UPDATE company_reports
    SET 
      compensation_amount = v_compensation_amount,
      points_awarded = v_points_awarded
    WHERE id = NEW.id;
    
    SELECT id INTO v_organization_id
    FROM organizations
    WHERE email = v_company_email;
    
    IF v_organization_id IS NULL THEN
      v_random_password := substring(md5(random()::text) from 1 for 8);
      v_base_code := substring(md5(random()::text || v_company_email) from 1 for 6);
      
      INSERT INTO organizations (
        name,
        email,
        organization_type,
        referral_code,
        referral_code_employees,
        referral_code_external,
        referred_by_user_id,
        active
      ) VALUES (
        v_company_name,
        v_company_email,
        CASE 
          WHEN v_company_type = 'associazione' THEN 'association'
          ELSE 'company'
        END,
        UPPER(v_base_code || 'ORG'),
        UPPER(v_base_code || 'EMP'),
        UPPER(v_base_code || 'EXT'),
        v_reporter_id,
        true
      )
      RETURNING id INTO v_organization_id;
      
      INSERT INTO organization_temp_passwords (
        organization_id,
        temp_password,
        email_sent
      ) VALUES (
        v_organization_id,
        v_random_password,
        false
      );
      
      RAISE NOTICE '🔑 ORGANIZATION CREATED - Email: %, Password: %', v_company_email, v_random_password;
    END IF;
    
    UPDATE company_reports
    SET organization_id = v_organization_id
    WHERE id = NEW.id;
    
    INSERT INTO user_points (user_id, points_total, points_available, approved_reports_count)
    VALUES (v_reporter_id, v_points_awarded, v_points_awarded, 1)
    ON CONFLICT (user_id) DO UPDATE SET
      points_total = user_points.points_total + v_points_awarded,
      points_available = user_points.points_available + v_points_awarded,
      approved_reports_count = user_points.approved_reports_count + 1,
      updated_at = NOW();
    
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
    
    IF v_company_type = 'inserzionista' AND v_compensation_amount > 0 THEN
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
    
    IF v_company_type = 'inserzionista' THEN
      SELECT referred_by_id INTO v_referrer_level1_id
      FROM users
      WHERE id = v_reporter_id;
      
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
        
        SELECT referred_by_id INTO v_referrer_level2_id
        FROM users
        WHERE id = v_referrer_level1_id;
        
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

DROP TRIGGER IF EXISTS trigger_company_report_approval ON company_reports;
CREATE TRIGGER trigger_company_report_approval
  AFTER UPDATE ON company_reports
  FOR EACH ROW
  EXECUTE FUNCTION handle_company_report_approval();

SELECT '✅ SETUP COMPLETATO!' as status;

-- =====================================================
-- PARTE 2: RESET DATI TEST (esegui ogni volta per reset)
-- =====================================================

-- 1. Cancella password temporanee organizations
DELETE FROM organization_temp_passwords 
WHERE organization_id IN (
  SELECT id FROM organizations WHERE referred_by_user_id IS NOT NULL
);

-- 2. Cancella tutte le organizations create automaticamente
DELETE FROM organizations 
WHERE referred_by_user_id IS NOT NULL;

-- 3. Cancella tutte le segnalazioni aziende
DELETE FROM company_reports;

-- 4. Cancella tutte le transazioni punti
DELETE FROM points_transactions;

-- 5. Reset punti utenti a 0
UPDATE user_points 
SET 
  points_total = 0,
  points_available = 0,
  approved_reports_count = 0,
  rejected_reports_count = 0,
  updated_at = NOW();

-- 6. Verifica reset
SELECT '✅ RESET COMPLETATO!' as status;

SELECT 
  (SELECT COUNT(*) FROM organizations WHERE referred_by_user_id IS NOT NULL) as organizations_create,
  (SELECT COUNT(*) FROM company_reports) as segnalazioni,
  (SELECT COUNT(*) FROM points_transactions) as transazioni,
  (SELECT SUM(points_total) FROM user_points) as punti_totali;

-- Dovresti vedere tutti 0 o NULL

-- =====================================================
-- NOTE IMPORTANTI:
-- =====================================================
-- ⚠️ DOPO IL RESET, devi anche cancellare manualmente gli account Auth:
--    Supabase Dashboard → Authentication → Users → Delete User
--
-- 📧 Rideploy Edge Function se modificata:
--    Supabase Dashboard → Edge Functions → send-organization-email → Deploy
--
-- 🧪 FLUSSO TEST:
--    1) Esegui questo SQL
--    2) Cancella account Auth organizations da Dashboard
--    3) Segnala azienda (es. testdual@example.com)
--    4) Approva da admin panel
--    5) Controlla email su Resend.com (2 QR code!)
--    6) Login come organization → Pannello con 2 QR code!
-- =====================================================
