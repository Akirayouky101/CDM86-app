-- ============================================================================
-- FIX TRIGGER MLM - Rimuovi dipendenza da colonna type
-- ============================================================================
-- Il trigger cercava di usare points_transactions.type che non esiste
-- Versione corretta senza quella colonna
-- ============================================================================

CREATE OR REPLACE FUNCTION award_referral_points_mlm()
RETURNS TRIGGER AS $$
DECLARE
  v_referrer_id UUID;
  v_referrer_of_referrer_id UUID;
  v_account_type VARCHAR(50);
  v_points_awarded DECIMAL(10,2) := 1.00;
BEGIN
  IF NEW.referred_by_id IS NOT NULL THEN
    
    v_account_type := COALESCE(NEW.account_type, 'user');
    v_referrer_id := NEW.referred_by_id;
    
    -- ========================================================================
    -- LIVELLO 1: Referrer diretto riceve +1 punto
    -- ========================================================================
    
    INSERT INTO referral_network (user_id, referral_id, level, points_awarded, referral_type)
    VALUES (v_referrer_id, NEW.id, 1, v_points_awarded, v_account_type)
    ON CONFLICT (user_id, referral_id, level) DO NOTHING;
    
    UPDATE user_points 
    SET 
      points_total = points_total + v_points_awarded,
      referrals_count = referrals_count + 1,
      updated_at = NOW()
    WHERE user_id = v_referrer_id;
    
    INSERT INTO user_points (user_id, points_total, referrals_count)
    VALUES (v_referrer_id, v_points_awarded, 1)
    ON CONFLICT (user_id) DO NOTHING;
    
    -- Registra transazione (SENZA colonna type)
    INSERT INTO points_transactions (user_id, points, description)
    VALUES (
      v_referrer_id, 
      v_points_awarded, 
      'Referral diretto: ' || COALESCE(NEW.first_name || ' ' || NEW.last_name, NEW.email)
    );
    
    RAISE NOTICE '✅ Livello 1: User % riceve +% punti per referral diretto %', 
      v_referrer_id, v_points_awarded, NEW.id;
    
    
    -- ========================================================================
    -- LIVELLO 2: Referrer del referrer riceve +1 punto
    -- ========================================================================
    
    SELECT referred_by_id INTO v_referrer_of_referrer_id
    FROM users
    WHERE id = v_referrer_id AND referred_by_id IS NOT NULL;
    
    IF v_referrer_of_referrer_id IS NOT NULL THEN
      
      INSERT INTO referral_network (user_id, referral_id, level, points_awarded, referral_type)
      VALUES (v_referrer_of_referrer_id, NEW.id, 2, v_points_awarded, v_account_type)
      ON CONFLICT (user_id, referral_id, level) DO NOTHING;
      
      UPDATE user_points 
      SET 
        points_total = points_total + v_points_awarded,
        updated_at = NOW()
      WHERE user_id = v_referrer_of_referrer_id;
      
      INSERT INTO user_points (user_id, points_total)
      VALUES (v_referrer_of_referrer_id, v_points_awarded)
      ON CONFLICT (user_id) DO NOTHING;
      
      -- Registra transazione (SENZA colonna type)
      INSERT INTO points_transactions (user_id, points, description)
      VALUES (
        v_referrer_of_referrer_id, 
        v_points_awarded, 
        'Rete indiretta: ' || COALESCE(NEW.first_name || ' ' || NEW.last_name, NEW.email)
      );
      
      RAISE NOTICE '✅ Livello 2: User % riceve +% punti per rete indiretta %', 
        v_referrer_of_referrer_id, v_points_awarded, NEW.id;
      
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Aggiorna anche la funzione helper per UPDATE
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
  
  -- SENZA colonna type
  INSERT INTO points_transactions (user_id, points, description)
  VALUES (v_referrer_id, v_points_awarded, 
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
    
    -- SENZA colonna type
    INSERT INTO points_transactions (user_id, points, description)
    VALUES (v_referrer_of_referrer_id, v_points_awarded, 
      'Rete indiretta: ' || COALESCE(p_first_name || ' ' || p_last_name, p_email));
  END IF;
END;
$$ LANGUAGE plpgsql;


-- Log successo
SELECT '✅ Trigger MLM fixato - Rimossa dipendenza da colonna type' as status;
