-- ============================================================================
-- VERIFICA STRUTTURA points_transactions
-- ============================================================================

-- Controlla struttura attuale
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'points_transactions'
ORDER BY ordinal_position;
