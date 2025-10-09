// Script per aggiungere promozioni direttamente al database tramite Supabase Admin API
const https = require('https');

const SUPABASE_URL = 'fzqfcehkhyldkfmcizux.supabase.co';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ6cWZjZWhraHlsZGtmbWNpenV4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczMzMxOTA0MSwiZXhwIjoyMDQ4ODk1MDQxfQ.iY2-Z9F8eLRnBdBVmXC_RRTnyxaI5Zd7WRBb8n3dIwE';

// First, get or create an admin user
const userData = {
  email: 'admin@cdm86.com',
  name: 'Admin CDM86',
  phone: '+39 02 1234567',
  referral_code: 'ADMIN001'
};

const promotionsData = [
  {
    title: 'Taglio Capelli Uomo -30%',
    slug: 'taglio-capelli-uomo-sconto',
    description: 'Approfitta dello sconto del 30% sul taglio capelli uomo.',
    short_description: 'Taglio capelli -30%',
    partner_name: 'Salone Marco Hair',
    partner_address: 'Via Verdi 45',
    partner_city: 'Milano',
    partner_province: 'MI',
    partner_zip_code: '20121',
    partner_phone: '+39 02 9876543',
    partner_email: 'info@marcohair.it',
    category: 'benessere',
    tags: ['parrucchiere', 'bellezza', 'uomo'],
    image_main: 'https://images.unsplash.com/photo-1622296089863-eb7fc530daa8',
    image_thumbnail: 'https://images.unsplash.com/photo-1622296089863-eb7fc530daa8?w=400',
    discount_type: 'percentage',
    discount_value: 30,
    original_price: 25.00,
    discounted_price: 17.50,
    validity_days: ['lun', 'mar', 'mer', 'gio', 'ven', 'sab'],
    validity_hours_from: '09:00',
    validity_hours_to: '19:00',
    limit_per_user: 2,
    is_active: true,
    is_featured: false,
    points_reward: 30,
    terms: 'Su prenotazione.',
    how_to_redeem: 'Mostra il QR code.'
  },
  {
    title: 'Lezione di Yoga Gratuita',
    slug: 'lezione-yoga-gratuita',
    description: 'Prima lezione di Yoga completamente gratuita.',
    short_description: 'Prova Yoga Gratis',
    partner_name: 'Yoga Studio Milano',
    partner_address: 'Via Dante 78',
    partner_city: 'Milano',
    partner_province: 'MI',
    partner_zip_code: '20123',
    partner_phone: '+39 02 5551234',
    partner_email: 'info@yogastudio.it',
    category: 'benessere',
    tags: ['yoga', 'fitness', 'salute'],
    image_main: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b',
    image_thumbnail: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400',
    discount_type: 'fixed',
    discount_value: 15.00,
    original_price: 15.00,
    discounted_price: 0.00,
    validity_days: ['lun', 'mer', 'ven'],
    validity_hours_from: '18:00',
    validity_hours_to: '20:00',
    limit_per_user: 1,
    is_active: true,
    is_featured: true,
    points_reward: 80,
    terms: 'Solo per nuovi iscritti.',
    how_to_redeem: 'Prenota online.'
  },
  {
    title: 'Lavaggio Auto Completo -40%',
    slug: 'lavaggio-auto-completo',
    description: 'Lavaggio esterno e interno completo con aspirazione.',
    short_description: 'Auto pulita -40%',
    partner_name: 'AutoClean Express',
    partner_address: 'Via Tibaldi 12',
    partner_city: 'Milano',
    partner_province: 'MI',
    partner_zip_code: '20136',
    partner_phone: '+39 02 4445566',
    partner_email: 'info@autoclean.it',
    category: 'servizi',
    tags: ['auto', 'lavaggio', 'pulizia'],
    image_main: 'https://images.unsplash.com/photo-1607860108855-64acf2078ed9',
    image_thumbnail: 'https://images.unsplash.com/photo-1607860108855-64acf2078ed9?w=400',
    discount_type: 'percentage',
    discount_value: 40,
    original_price: 30.00,
    discounted_price: 18.00,
    validity_days: ['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'],
    validity_hours_from: '08:00',
    validity_hours_to: '20:00',
    limit_per_user: 3,
    is_active: true,
    is_featured: false,
    points_reward: 40,
    terms: 'Valido per piccola/media cilindrata.',
    how_to_redeem: 'Mostra il QR code.'
  },
  {
    title: 'Colazione Completa €3.50',
    slug: 'colazione-completa-bar',
    description: 'Colazione italiana con brioche, caffè e succo.',
    short_description: 'Colazione a €3.50',
    partner_name: 'Bar Centrale',
    partner_address: 'Piazza Duomo 5',
    partner_city: 'Milano',
    partner_province: 'MI',
    partner_zip_code: '20122',
    partner_phone: '+39 02 7778899',
    partner_email: 'info@barcentrale.it',
    category: 'ristoranti',
    tags: ['colazione', 'bar', 'caffè'],
    image_main: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085',
    image_thumbnail: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400',
    discount_type: 'fixed',
    discount_value: 2.00,
    original_price: 5.50,
    discounted_price: 3.50,
    validity_days: ['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'],
    validity_hours_from: '07:00',
    validity_hours_to: '11:00',
    limit_per_user: 5,
    is_active: true,
    is_featured: true,
    points_reward: 20,
    terms: 'Valido solo al banco.',
    how_to_redeem: 'Mostra il QR code.'
  },
  {
    title: '2x1 Biglietto Cinema',
    slug: '2x1-biglietto-cinema',
    description: 'Prendi 2 biglietti e paghi 1!',
    short_description: '2 biglietti al prezzo di 1',
    partner_name: 'Multisala Odeon',
    partner_address: 'Corso Buenos Aires 23',
    partner_city: 'Milano',
    partner_province: 'MI',
    partner_zip_code: '20124',
    partner_phone: '+39 02 3334455',
    partner_email: 'info@odeoncinema.it',
    category: 'intrattenimento',
    tags: ['cinema', 'film', 'spettacolo'],
    image_main: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba',
    image_thumbnail: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=400',
    discount_type: 'percentage',
    discount_value: 50,
    original_price: 20.00,
    discounted_price: 10.00,
    validity_days: ['lun', 'mar', 'mer', 'gio'],
    validity_hours_from: '14:00',
    validity_hours_to: '22:00',
    limit_per_user: 2,
    is_active: true,
    is_featured: true,
    points_reward: 60,
    terms: 'Non valido per anteprime.',
    how_to_redeem: 'Mostra il QR code.'
  }
];

function makeRequest(options, data) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(body));
        } catch {
          resolve(body);
        }
      });
    });
    
    req.on('error', reject);
    if (data) req.write(JSON.stringify(data));
    req.end();
  });
}

async function run() {
  console.log('🚀 Avvio script...\n');

  // 1. Get or create user
  console.log('1️⃣  Cerco utente esistente...');
  const getUserOptions = {
    hostname: SUPABASE_URL,
    path: '/rest/v1/users?select=id&limit=1',
    method: 'GET',
    headers: {
      'apikey': SUPABASE_SERVICE_KEY,
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'Content-Type': 'application/json'
    }
  };

  let users = await makeRequest(getUserOptions);
  let userId;

  if (users && users.length > 0) {
    userId = users[0].id;
    console.log(`✅ Utente trovato: ${userId}\n`);
  } else {
    console.log('Nessun utente trovato, ne creo uno...');
    const createUserOptions = {
      hostname: SUPABASE_URL,
      path: '/rest/v1/users',
      method: 'POST',
      headers: {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
      }
    };

    const newUser = await makeRequest(createUserOptions, userData);
    userId = newUser[0].id;
    console.log(`✅ Utente creato: ${userId}\n`);
  }

  // 2. Add promotions
  console.log('2️⃣  Aggiunta promozioni...\n');
  
  const now = new Date().toISOString();
  const endDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();

  let successCount = 0;

  for (const promo of promotionsData) {
    try {
      const promoWithMeta = {
        ...promo,
        created_by_id: userId,
        validity_start_date: now,
        validity_end_date: endDate
      };

      const addPromoOptions = {
        hostname: SUPABASE_URL,
        path: '/rest/v1/promotions',
        method: 'POST',
        headers: {
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal'
        }
      };

      await makeRequest(addPromoOptions, promoWithMeta);
      console.log(`✅ ${promo.title}`);
      successCount++;
    } catch (error) {
      console.error(`❌ Errore: ${promo.title}`, error.message);
    }
  }

  console.log(`\n🎉 Completato! ${successCount}/${promotionsData.length} promozioni aggiunte\n`);

  // 3. Verify count
  const countOptions = {
    hostname: SUPABASE_URL,
    path: '/rest/v1/promotions?select=count',
    method: 'HEAD',
    headers: {
      'apikey': SUPABASE_SERVICE_KEY,
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'Prefer': 'count=exact'
    }
  };

  console.log('📊 Verifica totale promozioni nel database...');
}

run().catch(console.error);
