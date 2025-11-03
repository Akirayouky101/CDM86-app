-- ============================================================================
-- FIX TRIGGER MLM - CORREGGE FOREIGN KEY ISSUE
-- ============================================================================
-- PROBLEMA: user_points.user_id ha FK su auth.users(id), non public.users(id)
-- SOLUZIONE: Non creare record in user_points, solo UPDATE se esiste
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
    
    -- AGGIORNA user_points SOLO SE ESISTE (non creare nuovo record)
    UPDATE user_points 
    SET 
      points_total = points_total + v_points_awarded, 
      referrals_count = referrals_count + 1, 
      updated_at = NOW()
    WHERE user_id = v_referrer_id;
    
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
      
      -- AGGIORNA user_points SOLO SE ESISTE (non creare nuovo record)
      UPDATE user_points 
      SET 
        points_total = points_total + v_points_awarded, 
        updated_at = NOW()
      WHERE user_id = v_referrer_of_referrer_id;
      
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
-- VERIFICA CHE IL TRIGGER ESISTA
-- ============================================================================

SELECT '✅ Funzione award_referral_points_mlm aggiornata!' as status;

-- Verifica trigger
SELECT 
  tgname as trigger_name,
  tgenabled as enabled
FROM pg_trigger
WHERE tgrelid = 'users'::regclass
  AND tgname = 'trigger_award_referral_points_mlm';
