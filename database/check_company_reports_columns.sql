-- Verifica struttura tabella company_reports
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'company_reports'
ORDER BY ordinal_position;
