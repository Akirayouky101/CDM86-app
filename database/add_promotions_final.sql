-- ============================================
-- Script per aggiungere 20 nuove promozioni
-- Copiare ed eseguire nella console SQL di Supabase
-- ============================================

-- Prima otteniamo l'ID di un utente esistente
-- (Se non c'è nessun utente, verrà creato "admin@cdm86.com")

DO $$
DECLARE
    v_user_id UUID;
    v_start_date TIMESTAMP;
    v_end_date TIMESTAMP;
BEGIN
    -- Cerca un utente esistente o crea admin
    SELECT id INTO v_user_id FROM users LIMIT 1;
    
    IF v_user_id IS NULL THEN
        INSERT INTO users (email, name, phone, referral_code)
        VALUES ('admin@cdm86.com', 'Admin CDM86', '+39 02 1234567', 'ADMIN001')
        RETURNING id INTO v_user_id;
    END IF;
    
    -- Imposta le date
    v_start_date := CURRENT_TIMESTAMP;
    v_end_date := CURRENT_TIMESTAMP + INTERVAL '30 days';
    
    -- Inserisci le promozioni
    INSERT INTO promotions (
        title, slug, description, short_description,
        partner_name, partner_address, partner_city, partner_province, partner_zip_code,
        partner_phone, partner_email, category, tags,
        image_main, image_thumbnail,
        discount_type, discount_value, original_price, discounted_price,
        validity_start_date, validity_end_date,
        validity_days, validity_hours_from, validity_hours_to,
        limit_per_user, is_active, is_featured, points_reward,
        terms, how_to_redeem, created_by_id
    ) VALUES
    -- 1. Taglio Capelli
    (
        'Taglio Capelli Uomo -30%', 'taglio-capelli-uomo-sconto',
        'Approfitta dello sconto del 30% sul taglio capelli uomo. Include shampoo e styling.',
        'Taglio capelli -30%',
        'Salone Marco Hair', 'Via Verdi 45', 'Milano', 'MI', '20121',
        '+39 02 9876543', 'info@marcohair.it', 'salute',
        ARRAY['parrucchiere', 'bellezza', 'uomo'],
        'https://images.unsplash.com/photo-1622296089863-eb7fc530daa8',
        'https://images.unsplash.com/photo-1622296089863-eb7fc530daa8?w=400',
        'percentage', 30, 25.00, 17.50,
        v_start_date, v_end_date,
        ARRAY['lun', 'mar', 'mer', 'gio', 'ven', 'sab'],
        '09:00', '19:00', 2, true, false, 30,
        'Su prenotazione.', 'Mostra il QR code.', v_user_id
    ),
    -- 2. Yoga
    (
        'Lezione di Yoga Gratuita', 'lezione-yoga-gratuita',
        'Prima lezione di Yoga completamente gratuita. Istruttori certificati.',
        'Prova Yoga Gratis',
        'Yoga Studio Milano', 'Via Dante 78', 'Milano', 'MI', '20123',
        '+39 02 5551234', 'info@yogastudio.it', 'salute',
        ARRAY['yoga', 'fitness', 'salute'],
        'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b',
        'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400',
        'fixed', 15.00, 15.00, 0.00,
        v_start_date, v_end_date,
        ARRAY['lun', 'mer', 'ven'],
        '18:00', '20:00', 1, true, true, 80,
        'Solo per nuovi iscritti.', 'Prenota online.', v_user_id
    ),
    -- 3. Lavaggio Auto
    (
        'Lavaggio Auto Completo -40%', 'lavaggio-auto-completo',
        'Lavaggio esterno e interno completo con aspirazione e lucidatura.',
        'Auto pulita -40%',
        'AutoClean Express', 'Via Tibaldi 12', 'Milano', 'MI', '20136',
        '+39 02 4445566', 'info@autoclean.it', 'servizi',
        ARRAY['auto', 'lavaggio', 'pulizia'],
        'https://images.unsplash.com/photo-1607860108855-64acf2078ed9',
        'https://images.unsplash.com/photo-1607860108855-64acf2078ed9?w=400',
        'percentage', 40, 30.00, 18.00,
        v_start_date, v_end_date,
        ARRAY['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'],
        '08:00', '20:00', 3, true, false, 40,
        'Valido per piccola/media cilindrata.', 'Mostra il QR code.', v_user_id
    ),
    -- 4. Colazione
    (
        'Colazione Completa €3.50', 'colazione-completa-bar',
        'Colazione italiana con brioche, caffè e succo di frutta.',
        'Colazione a €3.50',
        'Bar Centrale', 'Piazza Duomo 5', 'Milano', 'MI', '20122',
        '+39 02 7778899', 'info@barcentrale.it', 'ristoranti',
        ARRAY['colazione', 'bar', 'caffè'],
        'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085',
        'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400',
        'fixed', 2.00, 5.50, 3.50,
        v_start_date, v_end_date,
        ARRAY['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'],
        '07:00', '11:00', 5, true, true, 20,
        'Valido solo al banco.', 'Mostra il QR code.', v_user_id
    ),
    -- 5. Cinema
    (
        '2x1 Biglietto Cinema', '2x1-biglietto-cinema',
        'Prendi 2 biglietti e paghi 1! Valido dal lunedì al giovedì.',
        '2 biglietti al prezzo di 1',
        'Multisala Odeon', 'Corso Buenos Aires 23', 'Milano', 'MI', '20124',
        '+39 02 3334455', 'info@odeoncinema.it', 'intrattenimento',
        ARRAY['cinema', 'film', 'spettacolo'],
        'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba',
        'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=400',
        'percentage', 50, 20.00, 10.00,
        v_start_date, v_end_date,
        ARRAY['lun', 'mar', 'mer', 'gio'],
        '14:00', '22:00', 2, true, true, 60,
        'Non valido per anteprime.', 'Mostra il QR code.', v_user_id
    ),
    -- 6. Libri
    (
        '3 Libri paghi 2', 'tre-libri-paghi-due',
        'Acquista 3 libri e paghi solo 2! Il libro di minor valore è gratis.',
        '3x2 sui libri',
        'Libreria Mondadori', 'Via Manzoni 1', 'Milano', 'MI', '20121',
        '+39 02 6667788', 'info@mondadorilibri.it', 'servizi',
        ARRAY['libri', 'lettura', 'cultura'],
        'https://images.unsplash.com/photo-1512820790803-83ca734da794',
        'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=400',
        'percentage', 33, 45.00, 30.00,
        v_start_date, v_end_date,
        ARRAY['lun', 'mar', 'mer', 'gio', 'ven', 'sab'],
        '09:00', '19:30', 1, true, false, 70,
        'Esclusi libri scolastici.', 'Mostra il QR code.', v_user_id
    ),
    -- 7. Hamburger
    (
        'Hamburger Menu €8', 'hamburger-menu-completo',
        'Menu completo con hamburger 200g, patatine e bibita.',
        'Menu Burger €8',
        'Burger House', 'Corso di Porta Ticinese 80', 'Milano', 'MI', '20123',
        '+39 02 5556677', 'info@burgerhouse.it', 'ristoranti',
        ARRAY['hamburger', 'fast food', 'americano'],
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd',
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
        'fixed', 6.00, 14.00, 8.00,
        v_start_date, v_end_date,
        ARRAY['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'],
        '12:00', '23:00', 4, true, true, 50,
        'Solo consumazione al tavolo.', 'Mostra il QR code.', v_user_id
    ),
    -- 8. Massaggio
    (
        'Massaggio Rilassante -35%', 'massaggio-rilassante-sconto',
        'Massaggio rilassante di 50 minuti con oli essenziali.',
        'Massaggio -35%',
        'Zen Spa Milano', 'Via Montenapoleone 8', 'Milano', 'MI', '20121',
        '+39 02 8889900', 'info@zenspa.it', 'salute',
        ARRAY['massaggio', 'relax', 'spa'],
        'https://images.unsplash.com/photo-1544161515-4ab6ce6db874',
        'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=400',
        'percentage', 35, 70.00, 45.50,
        v_start_date, v_end_date,
        ARRAY['lun', 'mar', 'mer', 'gio', 'ven', 'sab'],
        '10:00', '20:00', 2, true, true, 90,
        'Prenotazione obbligatoria.', 'Prenota e mostra il QR code.', v_user_id
    ),
    -- 9. Abbigliamento
    (
        'Abbigliamento Sportivo -20%', 'sconto-abbigliamento-sportivo',
        'Sconto del 20% su tutto l''abbigliamento sportivo.',
        'Sportswear -20%',
        'Sport Store Milano', 'Corso Vercelli 50', 'Milano', 'MI', '20144',
        '+39 02 4443322', 'info@sportstore.it', 'shopping',
        ARRAY['sport', 'abbigliamento', 'fitness'],
        'https://images.unsplash.com/photo-1556906781-9a412961c28c',
        'https://images.unsplash.com/photo-1556906781-9a412961c28c?w=400',
        'percentage', 20, 100.00, 80.00,
        v_start_date, v_end_date,
        ARRAY['lun', 'mar', 'mer', 'gio', 'ven', 'sab'],
        '09:30', '19:30', 3, true, false, 60,
        'Non valido su articoli in promozione.', 'Mostra il QR code.', v_user_id
    ),
    -- 10. Sushi
    (
        'All You Can Eat Sushi €19.90', 'all-you-can-eat-sushi',
        'Formula All You Can Eat. Menu completo con sushi e sashimi.',
        'Sushi illimitato €19.90',
        'Sakura Sushi', 'Via Paolo Sarpi 15', 'Milano', 'MI', '20154',
        '+39 02 3338844', 'info@sakurasushi.it', 'ristoranti',
        ARRAY['sushi', 'giapponese', 'all you can eat'],
        'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351',
        'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400',
        'fixed', 5.00, 24.90, 19.90,
        v_start_date, v_end_date,
        ARRAY['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'],
        '12:00', '15:00', 2, true, true, 70,
        'Bevande escluse. Limite 2 ore.', 'Prenota e mostra il QR code.', v_user_id
    ),
    -- 11. Chitarra
    (
        'Lezione Chitarra Gratis', 'lezione-chitarra-gratuita',
        'Lezione di prova gratuita di chitarra classica o elettrica.',
        'Lezione Chitarra Gratis',
        'Music Academy Milano', 'Via Boccaccio 70', 'Milano', 'MI', '20123',
        '+39 02 7774455', 'info@musicacademy.it', 'servizi',
        ARRAY['musica', 'chitarra', 'corso'],
        'https://images.unsplash.com/photo-1510915361894-db8b60106cb1',
        'https://images.unsplash.com/photo-1510915361894-db8b60106cb1?w=400',
        'fixed', 30.00, 30.00, 0.00,
        v_start_date, v_end_date,
        ARRAY['lun', 'mar', 'mer', 'gio', 'ven'],
        '14:00', '20:00', 1, true, false, 85,
        'Solo per nuovi studenti.', 'Prenota e mostra il QR code.', v_user_id
    ),
    -- 12. Aperitivo
    (
        'Aperitivo con Buffet €7', 'aperitivo-buffet-sette-euro',
        'Aperitivo con drink a scelta e accesso al buffet ricco.',
        'Aperitivo + Buffet €7',
        'Lounge Bar Navigli', 'Alzaia Naviglio Grande 44', 'Milano', 'MI', '20144',
        '+39 02 5552233', 'info@loungenaviglia.it', 'ristoranti',
        ARRAY['aperitivo', 'cocktail', 'buffet'],
        'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b',
        'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=400',
        'fixed', 5.00, 12.00, 7.00,
        v_start_date, v_end_date,
        ARRAY['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'],
        '18:00', '21:00', 3, true, true, 45,
        'Consumazione al tavolo.', 'Mostra il QR code.', v_user_id
    ),
    -- 13. Scarpe Running
    (
        'Scarpe Running -25%', 'scarpe-running-sconto',
        'Sconto del 25% su tutte le scarpe da running.',
        'Running Shoes -25%',
        'Runner''s World', 'Via Washington 70', 'Milano', 'MI', '20146',
        '+39 02 6665544', 'info@runnersworld.it', 'shopping',
        ARRAY['scarpe', 'running', 'sport'],
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff',
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
        'percentage', 25, 120.00, 90.00,
        v_start_date, v_end_date,
        ARRAY['lun', 'mar', 'mer', 'gio', 'ven', 'sab'],
        '09:00', '19:30', 1, true, false, 75,
        'Prodotti selezionati.', 'Mostra il QR code.', v_user_id
    ),
    -- 14. Pizza Gourmet
    (
        'Pizza Gourmet + Dolce €12', 'pizza-gourmet-con-dolce',
        'Pizza gourmet a scelta più dolce della casa.',
        'Pizza Gourmet + Dolce',
        'Pizzeria Stella', 'Via Tortona 31', 'Milano', 'MI', '20144',
        '+39 02 4446677', 'info@pizzeriastella.it', 'ristoranti',
        ARRAY['pizza', 'gourmet', 'italiano'],
        'https://images.unsplash.com/photo-1574071318508-1cdbab80d002',
        'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400',
        'fixed', 6.00, 18.00, 12.00,
        v_start_date, v_end_date,
        ARRAY['mar', 'mer', 'gio', 'ven', 'sab', 'dom'],
        '19:00', '23:30', 2, true, true, 65,
        'Valido solo a cena.', 'Mostra il QR code.', v_user_id
    ),
    -- 15. Corso Photoshop
    (
        'Corso Photoshop Base -40%', 'corso-photoshop-base-sconto',
        'Corso base di Adobe Photoshop di 12 ore con certificato.',
        'Photoshop Base -40%',
        'Digital School Milano', 'Via Mecenate 84', 'Milano', 'MI', '20138',
        '+39 02 9998877', 'info@digitalschool.it', 'servizi',
        ARRAY['corso', 'photoshop', 'grafica'],
        'https://images.unsplash.com/photo-1626785774573-4b799315345d',
        'https://images.unsplash.com/photo-1626785774573-4b799315345d?w=400',
        'percentage', 40, 300.00, 180.00,
        v_start_date, v_end_date,
        ARRAY['lun', 'mer', 'ven'],
        '18:30', '21:30', 1, true, false, 120,
        'Minimo 5 partecipanti.', 'Iscriviti online.', v_user_id
    ),
    -- 16. Gelato
    (
        'Coppetta Gelato 3 Gusti €3', 'coppetta-gelato-tre-gusti',
        'Coppetta con 3 gusti a scelta. Gelato artigianale.',
        'Gelato 3 gusti €3',
        'Gelateria Giolitti', 'Corso di Porta Romana 96', 'Milano', 'MI', '20122',
        '+39 02 3337766', 'info@giolitti.it', 'ristoranti',
        ARRAY['gelato', 'dolce', 'artigianale'],
        'https://images.unsplash.com/photo-1563805042-7684c019e1cb',
        'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=400',
        'fixed', 1.50, 4.50, 3.00,
        v_start_date, v_end_date,
        ARRAY['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'],
        '12:00', '23:00', 5, true, true, 25,
        'Solo in negozio o asporto.', 'Mostra il QR code.', v_user_id
    ),
    -- 17. Piscina
    (
        'Ingresso Piscina €6', 'ingresso-piscina-sconto',
        'Ingresso giornaliero alla piscina olimpionica.',
        'Piscina €6',
        'Piscina Cozzi', 'Viale Tunisia 35', 'Milano', 'MI', '20124',
        '+39 02 7776655', 'info@piscinacozzi.it', 'sport',
        ARRAY['piscina', 'nuoto', 'sport'],
        'https://images.unsplash.com/photo-1576013551627-0cc20b96c2a7',
        'https://images.unsplash.com/photo-1576013551627-0cc20b96c2a7?w=400',
        'fixed', 4.00, 10.00, 6.00,
        v_start_date, v_end_date,
        ARRAY['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'],
        '07:00', '21:00', 4, true, false, 40,
        'Portare costume e cuffia.', 'Mostra il QR code.', v_user_id
    ),
    -- 18. Tacos
    (
        '3 Tacos + Nachos €9', 'tre-tacos-con-nachos',
        'Menu con 3 tacos a scelta più nachos con guacamole.',
        '3 Tacos + Nachos €9',
        'El Sombrero Loco', 'Via Vigevano 18', 'Milano', 'MI', '20144',
        '+39 02 4445533', 'info@elsombrero.it', 'ristoranti',
        ARRAY['messicano', 'tacos', 'etnico'],
        'https://images.unsplash.com/photo-1565299585323-38d6b0865b47',
        'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=400',
        'fixed', 4.00, 13.00, 9.00,
        v_start_date, v_end_date,
        ARRAY['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'],
        '12:00', '23:00', 3, true, true, 55,
        'Anche asporto disponibile.', 'Mostra il QR code.', v_user_id
    ),
    -- 19. Manga
    (
        '5 Manga paghi 4', 'cinque-manga-paghi-quattro',
        'Acquista 5 volumi manga e paghi solo 4!',
        '5 Manga = 4 prezzi',
        'Fumetteria Panini Comics', 'Via Torino 51', 'Milano', 'MI', '20123',
        '+39 02 8887766', 'info@paninicomics.it', 'shopping',
        ARRAY['manga', 'fumetti', 'libri'],
        'https://images.unsplash.com/photo-1612178537253-bccd437b730e',
        'https://images.unsplash.com/photo-1612178537253-bccd437b730e?w=400',
        'percentage', 20, 30.00, 24.00,
        v_start_date, v_end_date,
        ARRAY['lun', 'mar', 'mer', 'gio', 'ven', 'sab'],
        '10:00', '19:30', 2, true, false, 50,
        'Escluse edizioni limitate.', 'Mostra il QR code.', v_user_id
    ),
    -- 20. Brunch
    (
        'Brunch Domenicale €15', 'brunch-domenicale-offerta',
        'Brunch all-inclusive ogni domenica. Dolce, salato e cocktail.',
        'Brunch Domenica €15',
        'The Breakfast Club', 'Via Solferino 25', 'Milano', 'MI', '20121',
        '+39 02 6664433', 'info@breakfastclub.it', 'ristoranti',
        ARRAY['brunch', 'colazione', 'domenica'],
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400',
        'fixed', 10.00, 25.00, 15.00,
        v_start_date, v_end_date,
        ARRAY['dom'],
        '10:00', '15:00', 2, true, true, 80,
        'Solo la domenica. Prenotazione obbligatoria.', 'Prenota online.', v_user_id
    );
    
    RAISE NOTICE '✅ 20 nuove promozioni aggiunte con successo!';
    RAISE NOTICE 'User ID usato: %', v_user_id;
    
END $$;

-- Verifica totale promozioni
SELECT COUNT(*) as total_promotions FROM promotions;
