-- ============================================================================
-- FIX: Modifica funzione MLM per usare UPSERT invece di solo UPDATE
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
    -- LIVELLO 1: Referral Diretto
    -- ========================================================================
    
    -- Registra nella rete referral
    INSERT INTO referral_network (user_id, referral_id, level, points_awarded, referral_type)
    VALUES (v_referrer_id, NEW.id, 1, v_points_awarded, v_account_type)
    ON CONFLICT (user_id, referral_id, level) DO NOTHING;
    
    -- UPSERT in user_points (INSERT se non esiste, UPDATE se esiste)
    INSERT INTO user_points (user_id, points_total, points_available, referrals_count)
    VALUES (v_referrer_id, v_points_awarded, v_points_awarded, 1)
    ON CONFLICT (user_id) DO UPDATE
    SET 
      points_total = user_points.points_total + v_points_awarded,
      points_available = user_points.points_available + v_points_awarded,
      referrals_count = user_points.referrals_count + 1,
      updated_at = NOW();
    
    -- Registra transazione
    INSERT INTO points_transactions (user_id, points, transaction_type, description)
    VALUES (
      v_referrer_id, 
      v_points_awarded::INTEGER,
      'referral_completed',
      'Referral diretto: ' || COALESCE(NEW.first_name || ' ' || NEW.last_name, NEW.email)
    );
    
    RAISE NOTICE '✅ Livello 1: User % riceve +% punti per referral diretto %', 
      v_referrer_id, v_points_awarded, NEW.id;
    
    
    -- ========================================================================
    -- LIVELLO 2: Rete Indiretta
    -- ========================================================================
    
    -- Cerca il referrer del referrer (livello 2)
    SELECT referred_by_id INTO v_referrer_of_referrer_id
    FROM users WHERE id = v_referrer_id AND referred_by_id IS NOT NULL;
    
    IF v_referrer_of_referrer_id IS NOT NULL THEN
      
      -- Registra nella rete referral
      INSERT INTO referral_network (user_id, referral_id, level, points_awarded, referral_type)
      VALUES (v_referrer_of_referrer_id, NEW.id, 2, v_points_awarded, v_account_type)
      ON CONFLICT (user_id, referral_id, level) DO NOTHING;
      
      -- UPSERT in user_points (INSERT se non esiste, UPDATE se esiste)
      INSERT INTO user_points (user_id, points_total, points_available, referrals_count)
      VALUES (v_referrer_of_referrer_id, v_points_awarded, v_points_awarded, 0)
      ON CONFLICT (user_id) DO UPDATE
      SET 
        points_total = user_points.points_total + v_points_awarded,
        points_available = user_points.points_available + v_points_awarded,
        updated_at = NOW();
      
      -- Registra transazione
      INSERT INTO points_transactions (user_id, points, transaction_type, description)
      VALUES (
        v_referrer_of_referrer_id, 
        v_points_awarded::INTEGER,
        'referral_completed',
        'Rete indiretta: ' || COALESCE(NEW.first_name || ' ' || NEW.last_name, NEW.email)
      );
      
      RAISE NOTICE '✅ Livello 2: User % riceve +% punti per rete indiretta %', 
        v_referrer_of_referrer_id, v_points_awarded, NEW.id;
      
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- VERIFICA: Controlla che la funzione sia stata aggiornata
-- ============================================================================

SELECT 'FUNZIONE AGGIORNATA' as status, 
       proname as function_name,
       LENGTH(prosrc) as source_length
FROM pg_proc 
WHERE proname = 'award_referral_points_mlm';
