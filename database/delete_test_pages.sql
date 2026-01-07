-- ============================================
-- DELETE TEST PAGES
-- Cancella le pagine di test create durante lo sviluppo
-- ============================================

-- OPZIONE 1: Cancella TUTTE le pagine (usa con cautela!)
-- DELETE FROM organization_pages;

-- OPZIONE 2: Cancella solo le pagine di una specifica organization
-- Sostituisci 'YOUR_ORG_ID' con l'ID della tua organization
-- DELETE FROM organization_pages 
-- WHERE organization_id = 'YOUR_ORG_ID';

-- OPZIONE 3: Cancella pagine con slug specifico
-- DELETE FROM organization_pages 
-- WHERE slug LIKE '%test%';

-- OPZIONE 4: Visualizza prima cosa andresti a cancellare
SELECT 
    op.id,
    op.slug,
    op.status,
    op.card_published,
    op.created_at,
    o.name as organization_name,
    op.page_data->'content'->>'companyName' as company_name,
    op.card_data->>'title' as card_title
FROM organization_pages op
LEFT JOIN organizations o ON op.organization_id = o.id
ORDER BY op.created_at DESC;

-- ============================================
-- DOPO AVER VERIFICATO, USA UNA DI QUESTE:
-- ============================================

-- Cancella tutte le pagine (RESET COMPLETO)
-- DELETE FROM organization_pages;

-- Cancella solo le pagine NON pubblicate
-- DELETE FROM organization_pages WHERE status != 'published';

-- Cancella solo le card NON pubblicate
-- DELETE FROM organization_pages WHERE card_published = false;

-- Reset completo con conferma
-- ATTENZIONE: Questo cancellerà TUTTO!
-- TRUNCATE organization_pages RESTART IDENTITY CASCADE;
