-- =====================================================
-- Aggiorna trigger per generare anche i codici dipendenti/esterni
-- =====================================================

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

SELECT '✅ Trigger aggiornato con doppi codici referral!' as status;
