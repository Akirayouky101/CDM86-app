-- =====================================================
-- QUICK FIX - Solo Trigger Organization Request
-- Esegui questo invece dello script completo!
-- =====================================================

-- Ricrea solo la funzione trigger corretta
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

-- Ricrea il trigger
DROP TRIGGER IF EXISTS trigger_organization_request_status ON organization_requests;
CREATE TRIGGER trigger_organization_request_status
    AFTER UPDATE ON organization_requests
    FOR EACH ROW
    EXECUTE FUNCTION handle_organization_request_status();

-- Verifica
SELECT 'Trigger corretto applicato con successo! ✅' as status;
