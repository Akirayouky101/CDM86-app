-- ============================================
-- CDM86 Platform - Seed Data
-- Database: CDM86DB (Supabase PostgreSQL)
-- Popola database con dati iniziali
-- ============================================

-- NOTA IMPORTANTE: 
-- La password "Admin123!" ha hash: (verrà generato da bcrypt lato server)
-- Per questo seed usiamo un hash pre-generato con bcrypt rounds=10

-- ============================================
-- 1. UTENTE ADMIN (Primo utente - NESSUN REFERRER)
-- ============================================
-- IMPORTANTE: Questo è l'UNICO utente senza referred_by_id
-- Tutti gli altri DEVONO avere un referrer

INSERT INTO users (
    id,
    email,
    password_hash,
    first_name,
    last_name,
    referral_code,
    referred_by_id,
    role,
    is_verified,
    is_active,
    points,
    created_at
) VALUES (
    gen_random_uuid(),
    'admin@cdm86.com',
    '$2a$10$orbh8LRXb5XZBf3LRP6VdeKcpSF868NfQYZFBegW.LEw7QNhA7P4u', -- Password: Admin123!
    'Admin',
    'CDM86',
    'ADMIN001',
    NULL, -- NESSUN REFERRER (è il primo!)
    'admin',
    true,
    true,
    10000, -- Admin parte con 10k punti
    CURRENT_TIMESTAMP
);

-- ============================================
-- 2. UTENTI DI TEST (con referral di Admin)
-- ============================================

-- User 1: Mario Rossi (referral di Admin)
INSERT INTO users (
    id,
    email,
    password_hash,
    first_name,
    last_name,
    phone,
    referral_code,
    referred_by_id,
    role,
    is_verified,
    points,
    created_at
) VALUES (
    gen_random_uuid(),
    'mario.rossi@test.com',
    '$2a$10$qeTkDMH0dW3mjaAKr4vZWOE2nCZphcfA4D3XdRZPcwfUfY3e2JiXq', -- Password: User123!
    'Mario',
    'Rossi',
    '+39 333 1234567',
    'MARIO001',
    (SELECT id FROM users WHERE email = 'admin@cdm86.com'), -- Referral di Admin
    'user',
    true,
    500,
    CURRENT_TIMESTAMP - INTERVAL '10 days'
);

-- User 2: Lucia Verdi (referral di Admin)
INSERT INTO users (
    id,
    email,
    password_hash,
    first_name,
    last_name,
    referral_code,
    referred_by_id,
    role,
    is_verified,
    points,
    created_at
) VALUES (
    gen_random_uuid(),
    'lucia.verdi@test.com',
    '$2a$10$1qN1qpuGmvrMf8YEZnlHJu8Co1MzhmTIr.P3X4HFmk3lhhhs3fTni', -- Password: Partner123!
    'Lucia',
    'Verdi',
    'LUCIA001',
    (SELECT id FROM users WHERE email = 'admin@cdm86.com'), -- Referral di Admin
    'partner',
    true,
    300,
    CURRENT_TIMESTAMP - INTERVAL '8 days'
);

-- User 3: Giovanni Bianchi (referral di Mario)
INSERT INTO users (
    id,
    email,
    password_hash,
    first_name,
    last_name,
    referral_code,
    referred_by_id,
    role,
    is_verified,
    points,
    created_at
) VALUES (
    gen_random_uuid(),
    'giovanni.bianchi@test.com',
    '$2a$10$6mqDcb2SfTcZiPXvTdlsK.9Wsl7PXHKjDliEvqzISOmolLImEptJK', -- Password: Test123!
    'Giovanni',
    'Bianchi',
    'GIOVA001',
    (SELECT id FROM users WHERE email = 'mario.rossi@test.com'), -- Referral di Mario
    'user',
    true,
    200,
    CURRENT_TIMESTAMP - INTERVAL '5 days'
);

-- User 4: Sara Neri (referral di Mario)
INSERT INTO users (
    id,
    email,
    password_hash,
    first_name,
    last_name,
    referral_code,
    referred_by_id,
    role,
    is_verified,
    points,
    created_at
) VALUES (
    gen_random_uuid(),
    'sara.neri@test.com',
    '$2a$10$6mqDcb2SfTcZiPXvTdlsK.9Wsl7PXHKjDliEvqzISOmolLImEptJK', -- Password: Test123!
    'Sara',
    'Neri',
    'SARA0001',
    (SELECT id FROM users WHERE email = 'mario.rossi@test.com'), -- Referral di Mario
    'user',
    true,
    150,
    CURRENT_TIMESTAMP - INTERVAL '3 days'
);

-- ============================================
-- 3. REFERRALS (Tracking referral completati)
-- ============================================

-- Referral: Admin -> Mario (completato)
INSERT INTO referrals (
    referrer_id,
    referred_user_id,
    referred_email,
    code_used,
    status,
    points_earned_referrer,
    points_earned_referred,
    clicked_at,
    registered_at,
    verified_at,
    completed_at,
    source
) VALUES (
    (SELECT id FROM users WHERE email = 'admin@cdm86.com'),
    (SELECT id FROM users WHERE email = 'mario.rossi@test.com'),
    'mario.rossi@test.com',
    'ADMIN001',
    'completed',
    200,
    100,
    CURRENT_TIMESTAMP - INTERVAL '10 days 2 hours',
    CURRENT_TIMESTAMP - INTERVAL '10 days 1 hour',
    CURRENT_TIMESTAMP - INTERVAL '10 days',
    CURRENT_TIMESTAMP - INTERVAL '9 days',
    'link'
);

-- Referral: Admin -> Lucia (completato)
INSERT INTO referrals (
    referrer_id,
    referred_user_id,
    referred_email,
    code_used,
    status,
    points_earned_referrer,
    points_earned_referred,
    clicked_at,
    registered_at,
    verified_at,
    completed_at,
    source
) VALUES (
    (SELECT id FROM users WHERE email = 'admin@cdm86.com'),
    (SELECT id FROM users WHERE email = 'lucia.verdi@test.com'),
    'lucia.verdi@test.com',
    'ADMIN001',
    'completed',
    200,
    100,
    CURRENT_TIMESTAMP - INTERVAL '8 days 3 hours',
    CURRENT_TIMESTAMP - INTERVAL '8 days 2 hours',
    CURRENT_TIMESTAMP - INTERVAL '8 days',
    CURRENT_TIMESTAMP - INTERVAL '7 days',
    'social'
);

-- Referral: Mario -> Giovanni (completato)
INSERT INTO referrals (
    referrer_id,
    referred_user_id,
    referred_email,
    code_used,
    status,
    points_earned_referrer,
    points_earned_referred,
    clicked_at,
    registered_at,
    verified_at,
    completed_at,
    source
) VALUES (
    (SELECT id FROM users WHERE email = 'mario.rossi@test.com'),
    (SELECT id FROM users WHERE email = 'giovanni.bianchi@test.com'),
    'giovanni.bianchi@test.com',
    'MARIO001',
    'completed',
    200,
    100,
    CURRENT_TIMESTAMP - INTERVAL '5 days 4 hours',
    CURRENT_TIMESTAMP - INTERVAL '5 days 2 hours',
    CURRENT_TIMESTAMP - INTERVAL '5 days',
    CURRENT_TIMESTAMP - INTERVAL '4 days',
    'link'
);

-- Referral: Mario -> Sara (completato)
INSERT INTO referrals (
    referrer_id,
    referred_user_id,
    referred_email,
    code_used,
    status,
    points_earned_referrer,
    points_earned_referred,
    clicked_at,
    registered_at,
    verified_at,
    completed_at,
    source
) VALUES (
    (SELECT id FROM users WHERE email = 'mario.rossi@test.com'),
    (SELECT id FROM users WHERE email = 'sara.neri@test.com'),
    'sara.neri@test.com',
    'MARIO001',
    'completed',
    200,
    100,
    CURRENT_TIMESTAMP - INTERVAL '3 days 5 hours',
    CURRENT_TIMESTAMP - INTERVAL '3 days 3 hours',
    CURRENT_TIMESTAMP - INTERVAL '3 days',
    CURRENT_TIMESTAMP - INTERVAL '2 days',
    'email'
);

-- Referral: Mario -> Pending (in attesa)
INSERT INTO referrals (
    referrer_id,
    referred_email,
    code_used,
    status,
    clicked_at,
    source,
    ip_address
) VALUES (
    (SELECT id FROM users WHERE email = 'mario.rossi@test.com'),
    'nuovo.utente@test.com',
    'MARIO001',
    'pending',
    CURRENT_TIMESTAMP - INTERVAL '1 day',
    'link',
    '192.168.1.100'
);

-- ============================================
-- 4. PROMOZIONI DI ESEMPIO
-- ============================================

-- Promozione 1: Pizza + Bibita
INSERT INTO promotions (
    title,
    slug,
    description,
    short_description,
    partner_name,
    partner_address,
    partner_city,
    partner_province,
    partner_zip_code,
    partner_phone,
    partner_email,
    category,
    tags,
    image_main,
    image_thumbnail,
    discount_type,
    discount_value,
    discount_min_purchase,
    original_price,
    discounted_price,
    validity_start_date,
    validity_end_date,
    validity_days,
    validity_hours_from,
    validity_hours_to,
    limit_per_user,
    limit_per_day,
    is_active,
    is_featured,
    points_reward,
    terms,
    how_to_redeem,
    created_by_id,
    stat_views,
    stat_favorites,
    stat_clicks,
    stat_redemptions
) VALUES (
    'Pizza Margherita + Bibita Omaggio',
    'pizza-margherita-bibita-omaggio',
    'Ordina una pizza margherita e ricevi una bibita in omaggio! Valida tutti i giorni della settimana presso il nostro ristorante. Pizza napoletana cotta nel forno a legna con ingredienti freschi e di prima qualità.',
    'Pizza + Bibita gratis!',
    'Pizzeria da Antonio',
    'Via Roma 123',
    'Milano',
    'MI',
    '20100',
    '+39 02 1234567',
    'info@pizzeriaantonio.it',
    'ristoranti',
    ARRAY['pizza', 'cibo', 'italiano', 'offerta', 'ristorante'],
    'https://images.unsplash.com/photo-1513104890138-7c749659a591',
    'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
    'fixed',
    3.00,
    8.00,
    11.00,
    8.00,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP + INTERVAL '30 days',
    ARRAY['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'],
    '12:00',
    '23:00',
    3,
    1,
    true,
    true,
    50,
    'Non cumulabile con altre offerte. Valido solo nel locale.',
    'Mostra il QR code al cameriere prima di ordinare.',
    (SELECT id FROM users WHERE email = 'admin@cdm86.com'),
    245,
    18,
    89,
    12
);

-- Promozione 2: Sconto Shopping
INSERT INTO promotions (
    title,
    slug,
    description,
    short_description,
    partner_name,
    partner_address,
    partner_city,
    partner_province,
    partner_zip_code,
    partner_phone,
    category,
    tags,
    image_main,
    image_thumbnail,
    discount_type,
    discount_value,
    discount_max_amount,
    discount_min_purchase,
    validity_start_date,
    validity_end_date,
    validity_days,
    limit_total_redemptions,
    limit_per_user,
    is_active,
    is_featured,
    points_reward,
    terms,
    how_to_redeem,
    created_by_id,
    stat_views,
    stat_favorites,
    stat_clicks,
    stat_redemptions
) VALUES (
    'Sconto 20% su Tutto',
    'sconto-20-su-tutto',
    'Approfitta del nostro super sconto del 20% su tutti i prodotti! Abbigliamento, accessori e molto altro. Nuova collezione primavera/estate disponibile.',
    '20% su tutto il catalogo',
    'Fashion Store Milano',
    'Corso Buenos Aires 45',
    'Milano',
    'MI',
    '20124',
    '+39 02 7654321',
    'shopping',
    ARRAY['moda', 'abbigliamento', 'sconto', 'shopping', 'accessori'],
    'https://images.unsplash.com/photo-1441986300917-64674bd600d8',
    'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400',
    'percentage',
    20.00,
    50.00,
    50.00,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP + INTERVAL '15 days',
    ARRAY['lun', 'mar', 'mer', 'gio', 'ven', 'sab'],
    100,
    1,
    true,
    false,
    100,
    'Esclusi prodotti in saldo. Valido solo in negozio.',
    'Mostra il codice QR alla cassa prima del pagamento.',
    (SELECT id FROM users WHERE email = 'admin@cdm86.com'),
    189,
    12,
    67,
    8
);

-- Promozione 3: Weekend Spa
INSERT INTO promotions (
    title,
    slug,
    description,
    short_description,
    partner_name,
    partner_address,
    partner_city,
    partner_province,
    partner_zip_code,
    partner_phone,
    partner_website,
    category,
    tags,
    image_main,
    image_thumbnail,
    discount_type,
    discount_value,
    discount_max_amount,
    original_price,
    discounted_price,
    validity_start_date,
    validity_end_date,
    validity_days,
    validity_hours_from,
    validity_hours_to,
    limit_total_redemptions,
    limit_per_user,
    is_active,
    is_featured,
    is_exclusive,
    points_cost,
    points_reward,
    terms,
    how_to_redeem,
    created_by_id,
    stat_views,
    stat_favorites,
    stat_clicks,
    stat_redemptions
) VALUES (
    'Weekend Benessere - Spa',
    'weekend-benessere-spa',
    'Rilassati con il nostro pacchetto weekend che include accesso alla spa, massaggio di 50 minuti e merenda nel nostro bistrot. Una giornata di puro relax!',
    'Spa + Massaggio + Merenda',
    'Wellness SPA Resort',
    'Via Montenapoleone 8',
    'Milano',
    'MI',
    '20121',
    '+39 02 8888888',
    'https://wellnessspa.com',
    'salute',
    ARRAY['spa', 'benessere', 'relax', 'massaggio', 'weekend'],
    'https://images.unsplash.com/photo-1540555700478-4be289fbecef',
    'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=400',
    'percentage',
    30.00,
    60.00,
    200.00,
    140.00,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP + INTERVAL '60 days',
    ARRAY['sab', 'dom'],
    '09:00',
    '20:00',
    50,
    2,
    true,
    true,
    true,
    100,
    200,
    'Prenotazione obbligatoria. Validità 60 giorni.',
    'Prenota online e presenta il QR code alla reception.',
    (SELECT id FROM users WHERE email = 'admin@cdm86.com'),
    456,
    34,
    123,
    15
);

-- Promozione 4: Cinema 2x1
INSERT INTO promotions (
    title,
    slug,
    description,
    short_description,
    partner_name,
    partner_address,
    partner_city,
    partner_province,
    partner_zip_code,
    category,
    tags,
    image_main,
    image_thumbnail,
    discount_type,
    discount_value,
    original_price,
    discounted_price,
    validity_start_date,
    validity_end_date,
    validity_days,
    validity_hours_from,
    validity_hours_to,
    limit_per_user,
    limit_per_day,
    is_active,
    points_reward,
    terms,
    how_to_redeem,
    created_by_id,
    stat_views,
    stat_favorites,
    stat_clicks,
    stat_redemptions
) VALUES (
    'Cinema 2x1',
    'cinema-2x1',
    'Porta un amico al cinema! Acquista un biglietto e il secondo è gratis. Valido per tutti i film in programmazione, escluse prime visioni e 3D.',
    'Biglietto cinema 2x1',
    'Multisala Odeon',
    'Via Torino 51',
    'Milano',
    'MI',
    '20123',
    'intrattenimento',
    ARRAY['cinema', 'film', '2x1', 'divertimento', 'offerta'],
    'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba',
    'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=400',
    'percentage',
    50.00,
    20.00,
    10.00,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP + INTERVAL '45 days',
    ARRAY['lun', 'mar', 'mer', 'gio'],
    '14:00',
    '23:59',
    5,
    1,
    true,
    30,
    'Esclusi film in 3D e prime visioni. Valido solo infrasettimanale.',
    'Mostra il QR code alla cassa cinema.',
    (SELECT id FROM users WHERE email = 'admin@cdm86.com'),
    312,
    22,
    95,
    18
);

-- Promozione 5: Palestra Gratis
INSERT INTO promotions (
    title,
    slug,
    description,
    short_description,
    partner_name,
    partner_address,
    partner_city,
    partner_province,
    partner_zip_code,
    partner_phone,
    category,
    tags,
    image_main,
    image_thumbnail,
    discount_type,
    discount_value,
    original_price,
    discounted_price,
    validity_start_date,
    validity_end_date,
    validity_days,
    limit_total_redemptions,
    limit_per_user,
    is_active,
    is_featured,
    points_reward,
    terms,
    how_to_redeem,
    created_by_id,
    stat_views,
    stat_favorites,
    stat_clicks,
    stat_redemptions
) VALUES (
    'Palestra 1 Mese Gratis',
    'palestra-1-mese-gratis',
    'Inizia il tuo percorso fitness con noi! Primo mese di abbonamento completamente gratuito. Include accesso illimitato e consulenza personalizzata.',
    'Primo mese palestra gratis',
    'FitLife Gym',
    'Via Lorenteggio 234',
    'Milano',
    'MI',
    '20146',
    '+39 02 5555555',
    'sport',
    ARRAY['palestra', 'fitness', 'sport', 'gratis', 'allenamento'],
    'https://images.unsplash.com/photo-1534438327276-14e5300c3a48',
    'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400',
    'fixed',
    60.00,
    60.00,
    0.00,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP + INTERVAL '90 days',
    ARRAY['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'],
    30,
    1,
    true,
    true,
    150,
    'Solo per nuovi iscritti. Richiesta registrazione e documento.',
    'Presenta il QR code alla reception per attivare la promo.',
    (SELECT id FROM users WHERE email = 'admin@cdm86.com'),
    567,
    45,
    178,
    22
);

-- Promozione 6: Smartphone Samsung
INSERT INTO promotions (
    title,
    slug,
    description,
    short_description,
    partner_name,
    partner_address,
    partner_city,
    partner_province,
    partner_zip_code,
    category,
    tags,
    image_main,
    image_thumbnail,
    discount_type,
    discount_value,
    discount_max_amount,
    validity_start_date,
    validity_end_date,
    validity_days,
    limit_total_redemptions,
    limit_per_user,
    is_active,
    points_cost,
    points_reward,
    terms,
    how_to_redeem,
    created_by_id,
    stat_views,
    stat_favorites,
    stat_clicks,
    stat_redemptions
) VALUES (
    'Smartphone Samsung -15%',
    'smartphone-samsung-15',
    'Sconto del 15% su tutti gli smartphone Samsung in store. Modelli Galaxy S23, A54, e molto altro! Offerta limitata.',
    '15% su smartphone Samsung',
    'TechWorld Store',
    'Via Dante 89',
    'Milano',
    'MI',
    '20121',
    'tecnologia',
    ARRAY['smartphone', 'samsung', 'tecnologia', 'elettronica', 'sconto'],
    'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c',
    'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=400',
    'percentage',
    15.00,
    150.00,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP + INTERVAL '20 days',
    ARRAY['lun', 'mar', 'mer', 'gio', 'ven', 'sab'],
    50,
    1,
    true,
    50,
    250,
    'Esclusi modelli già in promozione.',
    'Mostra il QR code alla cassa.',
    (SELECT id FROM users WHERE email = 'admin@cdm86.com'),
    289,
    19,
    102,
    9
);

-- ============================================
-- 5. FAVORITES (Promozioni preferite)
-- ============================================

-- Mario ha 3 preferiti
INSERT INTO user_favorites (user_id, promotion_id) VALUES
    ((SELECT id FROM users WHERE email = 'mario.rossi@test.com'), (SELECT id FROM promotions WHERE slug = 'pizza-margherita-bibita-omaggio')),
    ((SELECT id FROM users WHERE email = 'mario.rossi@test.com'), (SELECT id FROM promotions WHERE slug = 'weekend-benessere-spa')),
    ((SELECT id FROM users WHERE email = 'mario.rossi@test.com'), (SELECT id FROM promotions WHERE slug = 'palestra-1-mese-gratis'));

-- Giovanni ha 2 preferiti
INSERT INTO user_favorites (user_id, promotion_id) VALUES
    ((SELECT id FROM users WHERE email = 'giovanni.bianchi@test.com'), (SELECT id FROM promotions WHERE slug = 'cinema-2x1')),
    ((SELECT id FROM users WHERE email = 'giovanni.bianchi@test.com'), (SELECT id FROM promotions WHERE slug = 'smartphone-samsung-15'));

-- Sara ha 1 preferito
INSERT INTO user_favorites (user_id, promotion_id) VALUES
    ((SELECT id FROM users WHERE email = 'sara.neri@test.com'), (SELECT id FROM promotions WHERE slug = 'sconto-20-su-tutto'));

-- ============================================
-- RIEPILOGO SEED
-- ============================================

-- Query per verificare la struttura referral
SELECT 
    u.first_name || ' ' || u.last_name as utente,
    u.referral_code as "codice personale",
    u.referral_count as "persone invitate",
    ref.first_name || ' ' || ref.last_name as "invitato da",
    ref.referral_code as "codice usato"
FROM users u
LEFT JOIN users ref ON u.referred_by_id = ref.id
ORDER BY u.created_at;

-- ============================================
-- DONE!
-- ============================================
-- Seed completato!
-- Struttura:
--   Admin (ADMIN001)
--     ├─ Mario (MARIO001) [2 referral completati]
--     │   ├─ Giovanni (GIOVA001)
--     │   ├─ Sara (SARA0001)
--     │   └─ 1 pending
--     └─ Lucia (LUCIA001) [0 referral]
-- 
-- Credenziali (tutte password: vedi commenti):
--   - admin@cdm86.com - Admin123!
--   - mario.rossi@test.com - User123!
--   - lucia.verdi@test.com - Partner123!
--   - giovanni.bianchi@test.com - Test123!
--   - sara.neri@test.com - Test123!
-- ============================================
