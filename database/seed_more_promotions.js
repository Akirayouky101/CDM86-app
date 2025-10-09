/**
 * Script per aggiungere promozioni di test
 * Esegui con: node database/seed_more_promotions.js
 */

const { supabase } = require('../server/utils/supabase');

const newPromotions = [
    // Ristoranti (5)
    {
        title: 'Menu Completo 2x1',
        description: 'Menu completo per due persone al prezzo di uno. Include antipasto, primo, secondo e dolce.',
        short_description: 'Menu completo per 2 al prezzo di 1',
        partner_name: 'Trattoria Bella Vista',
        category: 'food',
        discount_type: 'percentage',
        discount_value: 50,
        price_original: 60.00,
        price_discounted: 30.00,
        image_main: 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
        is_active: true,
        is_featured: true,
        valid_from: new Date().toISOString(),
        valid_until: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000).toISOString(),
        redemption_limit: 100
    },
    {
        title: 'Sushi All You Can Eat',
        description: 'Formula all you can eat con sushi fresco e specialità giapponesi.',
        short_description: 'All you can eat sushi',
        partner_name: 'Sakura Sushi',
        category: 'food',
        discount_type: 'fixed',
        discount_value: 10,
        price_original: 35.00,
        price_discounted: 25.00,
        image_main: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=800',
        is_active: true,
        is_featured: false,
        valid_from: new Date().toISOString(),
        valid_until: new Date(Date.now() + 45 * 24 * 60 * 60 * 1000).toISOString(),
        redemption_limit: 150
    },
    {
        title: 'Aperitivo Deluxe',
        description: 'Aperitivo deluxe con buffet ricco e drink incluso per 2 persone.',
        short_description: 'Aperitivo per 2 con buffet',
        partner_name: 'Lounge Bar 86',
        category: 'food',
        discount_type: 'percentage',
        discount_value: 40,
        price_original: 50.00,
        price_discounted: 30.00,
        image_main: 'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=800',
        is_active: true,
        is_featured: true,
        valid_from: new Date().toISOString(),
        valid_until: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
        redemption_limit: 80
    },
    {
        title: 'Cena Romantica',
        description: 'Cena romantica a lume di candela con menù degustazione per 2.',
        short_description: 'Cena romantica per 2',
        partner_name: 'Ristorante La Terrazza',
        category: 'food',
        discount_type: 'fixed',
        discount_value: 25,
        price_original: 120.00,
        price_discounted: 95.00,
        image_main: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
        is_active: true,
        is_featured: false,
        valid_from: new Date().toISOString(),
        valid_until: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(),
        redemption_limit: 50
    },
    {
        title: 'Brunch Domenicale',
        description: 'Brunch all you can eat con dolci e salati, bevande incluse.',
        short_description: 'Brunch domenicale unlimited',
        partner_name: 'Caffè Centrale',
        category: 'food',
        discount_type: 'percentage',
        discount_value: 30,
        price_original: 40.00,
        price_discounted: 28.00,
        image_main: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800',
        is_active: true,
        is_featured: false,
        valid_from: new Date().toISOString(),
        valid_until: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000).toISOString(),
        redemption_limit: 120
    },

    // Shopping (5)
    {
        title: 'Sconto Abbigliamento',
        description: 'Sconto del 40% su tutta la collezione primavera/estate.',
        short_description: '40% su collezione P/E',
        partner_name: 'Fashion Store',
        category: 'shopping',
        discount_type: 'percentage',
        discount_value: 40,
        price_original: 100.00,
        price_discounted: 60.00,
        image_main: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800',
        is_active: true,
        is_featured: true,
        valid_from: new Date().toISOString(),
        valid_until: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
        redemption_limit: 200
    },
    {
        title: 'Scarpe Premium -50%',
        description: 'Scarpe di marca scontate del 50%. Tutte le taglie disponibili.',
        short_description: 'Scarpe -50%',
        partner_name: 'Shoe Paradise',
        category: 'shopping',
        discount_type: 'percentage',
        discount_value: 50,
        price_original: 150.00,
        price_discounted: 75.00,
        image_main: 'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=800',
        is_active: true,
        is_featured: false,
        valid_from: new Date().toISOString(),
        valid_until: new Date(Date.now() + 45 * 24 * 60 * 60 * 1000).toISOString(),
        redemption_limit: 100
    },
    {
        title: 'Accessori 3x2',
        description: 'Prendi 3 accessori e paghi solo 2. Borse, cinture e portafogli.',
        short_description: 'Accessori 3x2',
        partner_name: 'Luxury Bags',
        category: 'shopping',
        discount_type: 'percentage',
        discount_value: 33,
        price_original: 90.00,
        price_discounted: 60.00,
        image_main: 'https://images.unsplash.com/photo-1590739225987-41c42ff1fdf8?w=800',
        is_active: true,
        is_featured: true,
        valid_from: new Date().toISOString(),
        valid_until: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000).toISOString(),
        redemption_limit: 150
    },
    {
        title: 'Elettronica Tech',
        description: 'Sconto su smartphone, tablet e accessori tech.',
        short_description: 'Tech -30%',
        partner_name: 'TechWorld',
        category: 'shopping',
        discount_type: 'percentage',
        discount_value: 30,
        price_original: 500.00,
        price_discounted: 350.00,
        image_main: 'https://images.unsplash.com/photo-1468495244123-6c6c332eeece?w=800',
        is_active: true,
        is_featured: false,
        valid_from: new Date().toISOString(),
        valid_until: new Date(Date.now() + 20 * 24 * 60 * 60 * 1000).toISOString(),
        redemption_limit: 75
    },
    {
        title: 'Profumi Luxury',
        description: 'Profumi di marca con sconto esclusivo del 35%.',
        short_description: 'Profumi -35%',
        partner_name: 'Essence Store',
        category: 'shopping',
        discount_type: 'percentage',
        discount_value: 35,
        price_original: 80.00,
        price_discounted: 52.00,
        image_main: 'https://images.unsplash.com/photo-1541643600914-78b084683601?w=800',
        is_active: true,
        is_featured: false,
        valid_from: new Date().toISOString(),
        valid_until: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(),
        redemption_limit: 100
    },

    // Wellness (5)
    {
        title: 'Massaggio Relax 60min',
        description: 'Massaggio rilassante di 60 minuti con oli essenziali.',
        short_description: 'Massaggio 60min',
        partner_name: 'Zen Spa',
        category: 'wellness',
        discount_type: 'fixed',
        discount_value: 20,
        price_original: 70.00,
        price_discounted: 50.00,
        image_main: 'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=800',
        is_active: true,
        is_featured: true,
        valid_from: new Date().toISOString(),
        valid_until: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000).toISOString(),
        redemption_limit: 80
    },
    {
        title: 'Percorso Benessere',
        description: 'Percorso benessere completo: sauna, bagno turco e idromassaggio.',
        short_description: 'Percorso SPA completo',
        partner_name: 'Wellness Club',
        category: 'wellness',
        discount_type: 'percentage',
        discount_value: 40,
        price_original: 100.00,
        price_discounted: 60.00,
        image_main: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=800',
        is_active: true,
        is_featured: false,
        valid_from: new Date().toISOString(),
        valid_until: new Date(Date.now() + 45 * 24 * 60 * 60 * 1000).toISOString(),
        redemption_limit: 60
    },
    {
        title: 'Trattamento Viso',
        description: 'Trattamento viso con pulizia profonda e maschera personalizzata.',
        short_description: 'Trattamento viso premium',
        partner_name: 'Beauty Center',
        category: 'wellness',
        discount_type: 'fixed',
        discount_value: 15,
        price_original: 65.00,
        price_discounted: 50.00,
        image_main: 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=800',
        is_active: true,
        is_featured: true,
        valid_from: new Date().toISOString(),
        valid_until: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
        redemption_limit: 100
    },
    {
        title: 'Yoga 10 Lezioni',
        description: 'Pacchetto 10 lezioni di yoga con istruttore certificato.',
        short_description: '10 lezioni yoga',
        partner_name: 'Yoga Studio',
        category: 'wellness',
        discount_type: 'percentage',
        discount_value: 35,
        price_original: 150.00,
        price_discounted: 97.50,
        image_main: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800',
        is_active: true,
        is_featured: false,
        valid_from: new Date().toISOString(),
        valid_until: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(),
        redemption_limit: 50
    },
    {
        title: 'Fitness 3 Mesi',
        description: 'Abbonamento palestra 3 mesi con personal trainer incluso.',
        short_description: 'Abbonamento 3 mesi',
        partner_name: 'PowerGym',
        category: 'wellness',
        discount_type: 'percentage',
        discount_value: 45,
        price_original: 300.00,
        price_discounted: 165.00,
        image_main: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
        is_active: true,
        is_featured: false,
        valid_from: new Date().toISOString(),
        valid_until: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000).toISOString(),
        redemption_limit: 40
    },

    // Entertainment (5)
    {
        title: 'Cinema 2x1',
        description: 'Due biglietti cinema al prezzo di uno, valido tutti i giorni.',
        short_description: 'Cinema 2 biglietti x1',
        partner_name: 'Multiplex Cinema',
        category: 'entertainment',
        discount_type: 'percentage',
        discount_value: 50,
        price_original: 20.00,
        price_discounted: 10.00,
        image_main: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800',
        is_active: true,
        is_featured: true,
        valid_from: new Date().toISOString(),
        valid_until: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000).toISOString(),
        redemption_limit: 300
    },
    {
        title: 'Teatro Premium',
        description: 'Biglietto per spettacolo teatrale con posto in platea.',
        short_description: 'Teatro posto platea',
        partner_name: 'Teatro Comunale',
        category: 'entertainment',
        discount_type: 'fixed',
        discount_value: 15,
        price_original: 45.00,
        price_discounted: 30.00,
        image_main: 'https://images.unsplash.com/photo-1503095396549-807759245b35?w=800',
        is_active: true,
        is_featured: false,
        valid_from: new Date().toISOString(),
        valid_until: new Date(Date.now() + 45 * 24 * 60 * 60 * 1000).toISOString(),
        redemption_limit: 100
    },
    {
        title: 'Parco Avventura',
        description: 'Ingresso parco avventura con tutti i percorsi inclusi.',
        short_description: 'Parco avventura full',
        partner_name: 'Adventure Park',
        category: 'entertainment',
        discount_type: 'percentage',
        discount_value: 35,
        price_original: 40.00,
        price_discounted: 26.00,
        image_main: 'https://images.unsplash.com/photo-1591696331111-ef9586a5b17a?w=800',
        is_active: true,
        is_featured: true,
        valid_from: new Date().toISOString(),
        valid_until: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(),
        redemption_limit: 150
    },
    {
        title: 'Bowling 2 Ore',
        description: 'Due ore di bowling con noleggio scarpe incluso per 4 persone.',
        short_description: 'Bowling 2h per 4',
        partner_name: 'Strike Bowling',
        category: 'entertainment',
        discount_type: 'percentage',
        discount_value: 40,
        price_original: 60.00,
        price_discounted: 36.00,
        image_main: 'https://images.unsplash.com/photo-1566737236500-c8ac43014a67?w=800',
        is_active: true,
        is_featured: false,
        valid_from: new Date().toISOString(),
        valid_until: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
        redemption_limit: 80
    },
    {
        title: 'Escape Room',
        description: 'Esperienza escape room per gruppo fino a 6 persone.',
        short_description: 'Escape room gruppo',
        partner_name: 'Mystery Room',
        category: 'entertainment',
        discount_type: 'fixed',
        discount_value: 20,
        price_original: 90.00,
        price_discounted: 70.00,
        image_main: 'https://images.unsplash.com/photo-1528459801416-a9e53bbf4e17?w=800',
        is_active: true,
        is_featured: false,
        valid_from: new Date().toISOString(),
        valid_until: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000).toISOString(),
        redemption_limit: 70
    }
];

async function seedPromotions() {
    console.log('🌱 Inizio seed promozioni...');
    
    try {
        // Insert promotions
        const { data, error } = await supabase
            .from('promotions')
            .insert(newPromotions)
            .select();

        if (error) {
            console.error('❌ Errore inserimento:', error);
            process.exit(1);
        }

        console.log(`✅ ${data.length} promozioni inserite con successo!`);

        // Count total
        const { count } = await supabase
            .from('promotions')
            .select('*', { count: 'exact', head: true });

        console.log(`📊 Totale promozioni nel database: ${count}`);

        process.exit(0);
    } catch (error) {
        console.error('❌ Errore:', error);
        process.exit(1);
    }
}

seedPromotions();
