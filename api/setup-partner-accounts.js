// POST /api/setup-partner-accounts
// Script one-time: crea 10 account azienda partner + li lega alle promo + referral Mario Rossi
// RIMUOVERE dopo l'uso!

const { createClient } = require('@supabase/supabase-js');

// Dati delle 10 aziende partner (uno per promo)
const PARTNERS = [
    {
        promoId:     '75d64a17-7a93-4f69-abca-51703d491453',
        promoTitle:  'Cena per 2 da Il Borgo',
        name:        'Ristorante Il Borgo',
        email:       'ilborgo@partner.cdm86.it',
        password:    'IlBorgo2026!',
        city:        'Milano',
        firstName:   'Marco',
        lastName:    'Bianchi',
    },
    {
        promoId:     'bb570c6e-283e-4dda-bb80-159862a81ee3',
        promoTitle:  'Sconto Abbigliamento Sportivo',
        name:        'Sport Zone',
        email:       'sportzone@partner.cdm86.it',
        password:    'SportZone2026!',
        city:        'Roma',
        firstName:   'Luca',
        lastName:    'Ferrari',
    },
    {
        promoId:     'bced41c7-65a6-47db-8ddb-6b1c34b01458',
        promoTitle:  'Trattamento Viso Premium',
        name:        'Centro Estetico Luna',
        email:       'luna@partner.cdm86.it',
        password:    'CentroLuna2026!',
        city:        'Torino',
        firstName:   'Giulia',
        lastName:    'Romano',
    },
    {
        promoId:     'da7ab4d8-44e3-4e0a-a4fe-6e33cac010d1',
        promoTitle:  'Weekend a Firenze',
        name:        'Hotel Medici',
        email:       'hotelmedici@partner.cdm86.it',
        password:    'HotelMedici2026!',
        city:        'Firenze',
        firstName:   'Roberto',
        lastName:    'Conti',
    },
    {
        promoId:     'f9ee0973-464f-461f-9832-e48a9283390b',
        promoTitle:  'Smartphone Ricondizionato Garantito',
        name:        'TechRec Store',
        email:       'techrec@partner.cdm86.it',
        password:    'TechRec2026!',
        city:        'Napoli',
        firstName:   'Antonio',
        lastName:    'Esposito',
    },
    {
        promoId:     '15dba116-38ad-4907-830c-60f7cd1df3e2',
        promoTitle:  'Pizza + Birra Artigianale',
        name:        'Pizzeria Da Gennaro',
        email:       'dagennaro@partner.cdm86.it',
        password:    'DaGennaro2026!',
        city:        'Napoli',
        firstName:   'Gennaro',
        lastName:    'Napolitano',
    },
    {
        promoId:     '70354c80-e0ef-451e-871a-4908977fb5db',
        promoTitle:  'Corso di Yoga Mensile',
        name:        'Studio Equilibrio',
        email:       'equilibrio@partner.cdm86.it',
        password:    'Equilibrio2026!',
        city:        'Bologna',
        firstName:   'Sofia',
        lastName:    'Martinelli',
    },
    {
        promoId:     '2886b492-e42c-486b-8873-b478177c27a7',
        promoTitle:  'Taglio + Colore al Salone',
        name:        'Salone Stile',
        email:       'salonestile@partner.cdm86.it',
        password:    'SaloneStile2026!',
        city:        'Milano',
        firstName:   'Valentina',
        lastName:    'Greco',
    },
    {
        promoId:     '658ad7c5-b7dd-44f5-a537-fd86070b1ef3',
        promoTitle:  'Crociera Mediterraneo 7 Giorni',
        name:        'Cruise Italia',
        email:       'cruiseitalia@partner.cdm86.it',
        password:    'CruiseItalia2026!',
        city:        'Genova',
        firstName:   'Fabrizio',
        lastName:    'Moretti',
    },
    {
        promoId:     '1ab23143-7363-417d-8f0a-16e692f8f029',
        promoTitle:  'Laptop Gaming MSI',
        name:        'TechShop',
        email:       'techshop@partner.cdm86.it',
        password:    'TechShop2026!',
        city:        'Roma',
        firstName:   'Davide',
        lastName:    'Ricci',
    },
];

// Mario Rossi (referred_by)
const MARIO_ROSSI_ID = '293caa0f-f12c-4cde-81ba-26da97f2f13e';

module.exports = async function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    if (req.method === 'OPTIONS') return res.status(200).end();

    // Protezione: richiede una secret key nell'header
    const secret = req.headers['x-setup-secret'];
    if (secret !== 'CDM86-SETUP-2026') {
        return res.status(401).json({ error: 'Unauthorized' });
    }

    const supabaseUrl  = process.env.SUPABASE_URL;
    const supabaseKey  = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;

    if (!supabaseUrl || !supabaseKey) {
        return res.status(500).json({ error: 'Env vars mancanti' });
    }

    const supabase = createClient(supabaseUrl, supabaseKey, {
        auth: { autoRefreshToken: false, persistSession: false }
    });

    const results = [];
    const errors  = [];

    for (const partner of PARTNERS) {
        try {
            // 1. Crea auth user (Supabase Auth)
            const { data: authData, error: authErr } = await supabase.auth.admin.createUser({
                email:          partner.email,
                password:       partner.password,
                email_confirm:  true,   // già confermato, non serve email
                user_metadata: {
                    first_name:   partner.firstName,
                    last_name:    partner.lastName,
                    role:         'partner',
                    partner_name: partner.name,
                }
            });

            if (authErr) {
                // Se esiste già, lo recupera
                if (!authErr.message.includes('already been registered') && !authErr.message.includes('already exists')) {
                    throw new Error('Auth: ' + authErr.message);
                }
                console.log(`[setup] ${partner.email} già esistente in Auth, continuo...`);
            }

            const authUserId = authData?.user?.id;

            // 2. Upsert in tabella users (publica)
            if (authUserId) {
                const { error: userErr } = await supabase.from('users').upsert({
                    id:              authUserId,
                    email:           partner.email,
                    first_name:      partner.firstName,
                    last_name:       partner.lastName,
                    role:            'partner',
                    referred_by_id:  MARIO_ROSSI_ID,
                    referral_count:  0,
                    points:          0,
                    total_points_earned: 0,
                    total_points_spent:  0,
                    is_verified:     true,
                    is_active:       true,
                }, { onConflict: 'id' });

                if (userErr && !userErr.message.includes('duplicate')) {
                    console.warn(`[setup] users upsert warn per ${partner.email}:`, userErr.message);
                }
            }

            // 3. Aggiorna promotions: setta partner_email
            const { error: promoErr } = await supabase
                .from('promotions')
                .update({
                    partner_email: partner.email,
                    partner_name:  partner.name,
                })
                .eq('id', partner.promoId);

            if (promoErr) throw new Error('Promo update: ' + promoErr.message);

            results.push({
                ok:       true,
                partner:  partner.name,
                email:    partner.email,
                password: partner.password,
                promo:    partner.promoTitle,
                authId:   authUserId || 'già esistente',
            });

        } catch (err) {
            errors.push({ partner: partner.name, email: partner.email, error: err.message });
        }
    }

    // 4. Aggiorna referral_count di Mario Rossi
    await supabase
        .from('users')
        .update({ referral_count: PARTNERS.length })
        .eq('id', MARIO_ROSSI_ID);

    return res.status(200).json({
        success: errors.length === 0,
        created: results.length,
        failed:  errors.length,
        results,
        errors,
        summary: results.map(r => `${r.partner} → ${r.email} / ${r.password}`)
    });
};
