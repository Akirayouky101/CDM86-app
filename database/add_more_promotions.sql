-- ============================================
-- CDM86 Platform - Add More Test Promotions
-- Aggiungi 20 promozioni per testare la paginazione
-- ============================================

INSERT INTO promotions (
    title, 
    description, 
    short_description,
    partner_name,
    category,
    discount_type,
    discount_value,
    original_price,
    discounted_price,
    image_main,
    is_active,
    is_featured,
    validity_start_date,
    validity_end_date,
    limit_total_redemptions
) VALUES
-- Ristoranti (5)
('Menu Completo 2x1', 'Menu completo per due persone al prezzo di uno. Include antipasto, primo, secondo e dolce.', 'Menu completo per 2 al prezzo di 1', 'Trattoria Bella Vista', 'food', 'percentage', 50, 60.00, 30.00, 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800', true, true, NOW(), NOW() + INTERVAL '60 days', 100),
('Sushi All You Can Eat', 'Formula all you can eat con sushi fresco e specialità giapponesi.', 'All you can eat sushi', 'Sakura Sushi', 'food', 'fixed', 10, 35.00, 25.00, 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=800', true, false, NOW(), NOW() + INTERVAL '45 days', 150),
('Aperitivo Deluxe', 'Aperitivo deluxe con buffet ricco e drink incluso per 2 persone.', 'Aperitivo per 2 con buffet', 'Lounge Bar 86', 'food', 'percentage', 40, 50.00, 30.00, 'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=800', true, true, NOW(), NOW() + INTERVAL '30 days', 80),
('Cena Romantica', 'Cena romantica a lume di candela con menù degustazione per 2.', 'Cena romantica per 2', 'Ristorante La Terrazza', 'food', 'fixed', 25, 120.00, 95.00, 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800', true, false, NOW(), NOW() + INTERVAL '90 days', 50),
('Brunch Domenicale', 'Brunch all you can eat con dolci e salati, bevande incluse.', 'Brunch domenicale unlimited', 'Caffè Centrale', 'food', 'percentage', 30, 40.00, 28.00, 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800', true, false, NOW(), NOW() + INTERVAL '60 days', 120),

-- Shopping (5)
('Sconto Abbigliamento', 'Sconto del 40% su tutta la collezione primavera/estate.', '40% su collezione P/E', 'Fashion Store', 'shopping', 'percentage', 40, 100.00, 60.00, 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800', true, true, NOW(), NOW() + INTERVAL '30 days', 200),
('Scarpe Premium -50%', 'Scarpe di marca scontate del 50%. Tutte le taglie disponibili.', 'Scarpe -50%', 'Shoe Paradise', 'shopping', 'percentage', 50, 150.00, 75.00, 'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=800', true, false, NOW(), NOW() + INTERVAL '45 days', 100),
('Accessori 3x2', 'Prendi 3 accessori e paghi solo 2. Borse, cinture e portafogli.', 'Accessori 3x2', 'Luxury Bags', 'shopping', 'percentage', 33, 90.00, 60.00, 'https://images.unsplash.com/photo-1590739225987-41c42ff1fdf8?w=800', true, true, NOW(), NOW() + INTERVAL '60 days', 150),
('Elettronica Tech', 'Sconto su smartphone, tablet e accessori tech.', 'Tech -30%', 'TechWorld', 'shopping', 'percentage', 30, 500.00, 350.00, 'https://images.unsplash.com/photo-1468495244123-6c6c332eeece?w=800', true, false, NOW(), NOW() + INTERVAL '20 days', 75),
('Profumi Luxury', 'Profumi di marca con sconto esclusivo del 35%.', 'Profumi -35%', 'Essence Store', 'shopping', 'percentage', 35, 80.00, 52.00, 'https://images.unsplash.com/photo-1541643600914-78b084683601?w=800', true, false, NOW(), NOW() + INTERVAL '90 days', 100),

-- Wellness (5)
('Massaggio Relax 60min', 'Massaggio rilassante di 60 minuti con oli essenziali.', 'Massaggio 60min', 'Zen Spa', 'wellness', 'fixed', 20, 70.00, 50.00, 'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=800', true, true, NOW(), NOW() + INTERVAL '60 days', 80),
('Percorso Benessere', 'Percorso benessere completo: sauna, bagno turco e idromassaggio.', 'Percorso SPA completo', 'Wellness Club', 'wellness', 'percentage', 40, 100.00, 60.00, 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=800', true, false, NOW(), NOW() + INTERVAL '45 days', 60),
('Trattamento Viso', 'Trattamento viso con pulizia profonda e maschera personalizzata.', 'Trattamento viso premium', 'Beauty Center', 'wellness', 'fixed', 15, 65.00, 50.00, 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=800', true, true, NOW(), NOW() + INTERVAL '30 days', 100),
('Yoga 10 Lezioni', 'Pacchetto 10 lezioni di yoga con istruttore certificato.', '10 lezioni yoga', 'Yoga Studio', 'wellness', 'percentage', 35, 150.00, 97.50, 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800', true, false, NOW(), NOW() + INTERVAL '90 days', 50),
('Fitness 3 Mesi', 'Abbonamento palestra 3 mesi con personal trainer incluso.', 'Abbonamento 3 mesi', 'PowerGym', 'wellness', 'percentage', 45, 300.00, 165.00, 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800', true, false, NOW(), NOW() + INTERVAL '15 days', 40),

-- Intrattenimento (5)
('Cinema 2x1', 'Due biglietti cinema al prezzo di uno, valido tutti i giorni.', 'Cinema 2 biglietti x1', 'Multiplex Cinema', 'entertainment', 'percentage', 50, 20.00, 10.00, 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800', true, true, NOW(), NOW() + INTERVAL '60 days', 300),
('Teatro Premium', 'Biglietto per spettacolo teatrale con posto in platea.', 'Teatro posto platea', 'Teatro Comunale', 'entertainment', 'fixed', 15, 45.00, 30.00, 'https://images.unsplash.com/photo-1503095396549-807759245b35?w=800', true, false, NOW(), NOW() + INTERVAL '45 days', 100),
('Parco Avventura', 'Ingresso parco avventura con tutti i percorsi inclusi.', 'Parco avventura full', 'Adventure Park', 'entertainment', 'percentage', 35, 40.00, 26.00, 'https://images.unsplash.com/photo-1591696331111-ef9586a5b17a?w=800', true, true, NOW(), NOW() + INTERVAL '90 days', 150),
('Bowling 2 Ore', 'Due ore di bowling con noleggio scarpe incluso per 4 persone.', 'Bowling 2h per 4', 'Strike Bowling', 'entertainment', 'percentage', 40, 60.00, 36.00, 'https://images.unsplash.com/photo-1566737236500-c8ac43014a67?w=800', true, false, NOW(), NOW() + INTERVAL '30 days', 80),
('Escape Room', 'Esperienza escape room per gruppo fino a 6 persone.', 'Escape room gruppo', 'Mystery Room', 'entertainment', 'fixed', 20, 90.00, 70.00, 'https://images.unsplash.com/photo-1528459801416-a9e53bbf4e17?w=800', true, false, NOW(), NOW() + INTERVAL '60 days', 70);

-- Verifica inserimento
SELECT 
    COUNT(*) as total_promotions,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_promotions
FROM promotions;

SELECT category, COUNT(*) as count
FROM promotions
GROUP BY category
ORDER BY count DESC;

-- ============================================
-- DONE! 20 nuove promozioni aggiunte
-- ============================================
