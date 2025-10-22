-- =====================================================
-- FIX COMPLETO RLS - User Points + Transactions
-- Esegui questo per permettere ai trigger di funzionare
-- =====================================================

-- 1. FIX USER_POINTS POLICIES
-- =====================================================

DROP POLICY IF EXISTS "Users can view own points" ON user_points;
DROP POLICY IF EXISTS "Users can view all points for leaderboard" ON user_points;
DROP POLICY IF EXISTS "Users can view all points" ON user_points;
DROP POLICY IF EXISTS "System can insert points" ON user_points;
DROP POLICY IF EXISTS "System can update points" ON user_points;

CREATE POLICY "Allow all select on user_points"
    ON user_points FOR SELECT
    TO authenticated, anon
    USING (true);

CREATE POLICY "Allow all insert on user_points"
    ON user_points FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Allow all update on user_points"
    ON user_points FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- 2. FIX POINTS_TRANSACTIONS POLICIES
-- =====================================================

DROP POLICY IF EXISTS "Users can view own transactions" ON points_transactions;

CREATE POLICY "Allow all select on transactions"
    ON points_transactions FOR SELECT
    TO authenticated, anon
    USING (true);

CREATE POLICY "Allow all insert on transactions"
    ON points_transactions FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- 3. RICREA TRIGGER ORGANIZATION
-- =====================================================

CREATE OR REPLACE FUNCTION handle_organization_request_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status != OLD.status THEN
        IF NEW.status = 'approved' THEN
            PERFORM add_points_to_user(
                NEW.referred_by_id,
                100,
                'report_approved',
                NEW.id,
                'Segnalazione approvata: ' || NEW.organization_name
            );
            
            UPDATE user_points
            SET approved_reports_count = approved_reports_count + 1
            WHERE user_id = NEW.referred_by_id;
            
        ELSIF NEW.status = 'rejected' THEN
            INSERT INTO points_transactions (
                user_id, points, transaction_type, reference_id, description
            ) VALUES (
                NEW.referred_by_id, 0, 'report_rejected', NEW.id,
                'Segnalazione rifiutata: ' || NEW.organization_name
            );
            
            UPDATE user_points
            SET rejected_reports_count = rejected_reports_count + 1
            WHERE user_id = NEW.referred_by_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_organization_request_status ON organization_requests;
CREATE TRIGGER trigger_organization_request_status
    AFTER UPDATE ON organization_requests
    FOR EACH ROW
    EXECUTE FUNCTION handle_organization_request_status();

-- 4. VERIFICA POLICIES
-- =====================================================

SELECT 'user_points policies:' as info;
SELECT tablename, policyname, cmd 
FROM pg_policies 
WHERE tablename = 'user_points';

SELECT 'points_transactions policies:' as info;
SELECT tablename, policyname, cmd 
FROM pg_policies 
WHERE tablename = 'points_transactions';

SELECT '✅ TUTTO FIXATO! Ora i trigger possono funzionare!' as status;
