-- =====================================================
-- COMPLETE FIX - RLS + Trigger Organization
-- Esegui TUTTO questo script in un colpo solo
-- =====================================================

-- STEP 1: Fix RLS Policies
-- =====================================================

-- Drop vecchie policy
DROP POLICY IF EXISTS "Users can view own points" ON user_points;
DROP POLICY IF EXISTS "Users can view all points for leaderboard" ON user_points;

-- Crea policy corrette
CREATE POLICY "Users can view all points"
    ON user_points FOR SELECT
    TO authenticated, anon
    USING (true);

CREATE POLICY "System can insert points"
    ON user_points FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "System can update points"
    ON user_points FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- STEP 2: Fix Trigger Function
-- =====================================================

CREATE OR REPLACE FUNCTION handle_organization_request_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Only process if status changed to approved or rejected
    IF NEW.status != OLD.status THEN
        IF NEW.status = 'approved' THEN
            -- Award 100 points for approved report
            PERFORM add_points_to_user(
                NEW.referred_by_id,
                100,
                'report_approved',
                NEW.id,
                'Segnalazione approvata: ' || NEW.organization_name
            );
            
            -- Increment approved reports count
            UPDATE user_points
            SET approved_reports_count = approved_reports_count + 1
            WHERE user_id = NEW.referred_by_id;
            
        ELSIF NEW.status = 'rejected' THEN
            -- No points awarded, just log
            INSERT INTO points_transactions (
                user_id,
                points,
                transaction_type,
                reference_id,
                description
            ) VALUES (
                NEW.referred_by_id,
                0,
                'report_rejected',
                NEW.id,
                'Segnalazione rifiutata: ' || NEW.organization_name
            );
            
            -- Increment rejected reports count
            UPDATE user_points
            SET rejected_reports_count = rejected_reports_count + 1
            WHERE user_id = NEW.referred_by_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- STEP 3: Ricrea Trigger
-- =====================================================

DROP TRIGGER IF EXISTS trigger_organization_request_status ON organization_requests;
CREATE TRIGGER trigger_organization_request_status
    AFTER UPDATE ON organization_requests
    FOR EACH ROW
    EXECUTE FUNCTION handle_organization_request_status();

-- STEP 4: Verifica
-- =====================================================

SELECT '✅ RLS Policies aggiornate!' as step_1;
SELECT '✅ Trigger organization corretto!' as step_2;
SELECT '✅ Sistema pronto per approvare organizzazioni!' as step_3;
