/**
 * Database Seed Script
 * Popola il database con dati di esempio
 */

require('dotenv').config();
const { connectDB, disconnectDB } = require('./utils/database');
const { User, Promotion, Referral, Transaction } = require('./models');

// Sample data
const sampleUsers = [
    {
        email: 'admin@cdm86.com',
        password: 'Admin123!',
        firstName: 'Admin',
        lastName: 'CDM86',
        role: 'admin',
        isVerified: true,
        referralCode: 'ADMIN001'
    },
    {
        email: 'user1@test.com',
        password: 'User123!',
        firstName: 'Mario',
        lastName: 'Rossi',
        role: 'user',
        isVerified: true,
        referralCode: 'MARIO001',
        points: 500
    },
    {
        email: 'partner@test.com',
        password: 'Partner123!',
        firstName: 'Lucia',
        lastName: 'Verdi',
        role: 'partner',
        isVerified: true,
        referralCode: 'PARTNER1'
    }
];

const samplePromotions = [
    {
        title: 'Pizza Margherita + Bibita Omaggio',
        description: 'Ordina una pizza margherita e ricevi una bibita in omaggio! Valida tutti i giorni della settimana presso il nostro ristorante.',
        shortDescription: 'Pizza + Bibita gratis!',
        partner: {
            name: 'Pizzeria da Antonio',
            address: 'Via Roma 123',
            city: 'Milano',
            province: 'MI',
            zipCode: '20100',
            phone: '+39 02 1234567',
            email: 'info@pizzeriaantonio.it'
        },
        category: 'ristoranti',
        tags: ['pizza', 'cibo', 'italiano', 'offerta'],
        images: {
            main: 'https://images.unsplash.com/photo-1513104890138-7c749659a591',
            thumbnail: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
            gallery: [
                'https://images.unsplash.com/photo-1513104890138-7c749659a591',
                'https://images.unsplash.com/photo-1574071318508-1cdbab80d002'
            ]
        },
        discount: {
            type: 'fixed',
            value: 3,
            minPurchase: 8
        },
        originalPrice: 11,
        discountedPrice: 8,
        validity: {
            startDate: new Date(),
            endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
            days: ['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'],
            hours: { from: '12:00', to: '23:00' }
        },
        limits: {
            totalRedemptions: null,
            perUser: 3,
            perDay: 1
        },
        isActive: true,
        isFeatured: true,
        pointsCost: 0,
        pointsReward: 50,
        terms: 'Non cumulabile con altre offerte. Valido solo nel locale.',
        howToRedeem: 'Mostra il QR code al cameriere prima di ordinare.'
    },
    {
        title: 'Sconto 20% su Tutto',
        description: 'Approfitta del nostro super sconto del 20% su tutti i prodotti! Abbigliamento, accessori e molto altro.',
        shortDescription: '20% su tutto il catalogo',
        partner: {
            name: 'Fashion Store Milano',
            address: 'Corso Buenos Aires 45',
            city: 'Milano',
            province: 'MI',
            zipCode: '20124',
            phone: '+39 02 7654321'
        },
        category: 'shopping',
        tags: ['moda', 'abbigliamento', 'sconto', 'shopping'],
        images: {
            main: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8',
            thumbnail: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400'
        },
        discount: {
            type: 'percentage',
            value: 20,
            maxAmount: 50,
            minPurchase: 50
        },
        validity: {
            startDate: new Date(),
            endDate: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000),
            days: ['lun', 'mar', 'mer', 'gio', 'ven', 'sab']
        },
        limits: {
            totalRedemptions: 100,
            perUser: 1
        },
        isActive: true,
        isFeatured: false,
        pointsCost: 0,
        pointsReward: 100,
        terms: 'Esclusi prodotti in saldo. Valido solo in negozio.',
        howToRedeem: 'Mostra il codice QR alla cassa prima del pagamento.'
    },
    {
        title: 'Weekend Benessere - Spa',
        description: 'Rilassati con il nostro pacchetto weekend che include accesso alla spa, massaggio di 50 minuti e merenda nel nostro bistrot.',
        shortDescription: 'Spa + Massaggio + Merenda',
        partner: {
            name: 'Wellness SPA Resort',
            address: 'Via Montenapoleone 8',
            city: 'Milano',
            province: 'MI',
            zipCode: '20121',
            phone: '+39 02 8888888',
            website: 'https://wellnessspa.com'
        },
        category: 'salute',
        tags: ['spa', 'benessere', 'relax', 'massaggio'],
        images: {
            main: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef',
            thumbnail: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=400'
        },
        discount: {
            type: 'percentage',
            value: 30,
            maxAmount: 60
        },
        originalPrice: 200,
        discountedPrice: 140,
        validity: {
            startDate: new Date(),
            endDate: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000),
            days: ['sab', 'dom'],
            hours: { from: '09:00', to: '20:00' }
        },
        limits: {
            totalRedemptions: 50,
            perUser: 2
        },
        isActive: true,
        isFeatured: true,
        isExclusive: true,
        pointsCost: 100,
        pointsReward: 200,
        terms: 'Prenotazione obbligatoria. Validità 60 giorni.',
        howToRedeem: 'Prenota online e presenta il QR code alla reception.'
    },
    {
        title: 'Cinema 2x1',
        description: 'Porta un amico al cinema! Acquista un biglietto e il secondo è gratis. Valido per tutti i film in programmazione.',
        shortDescription: 'Biglietto cinema 2x1',
        partner: {
            name: 'Multisala Odeon',
            address: 'Via Torino 51',
            city: 'Milano',
            province: 'MI',
            zipCode: '20123'
        },
        category: 'intrattenimento',
        tags: ['cinema', 'film', '2x1', 'divertimento'],
        images: {
            main: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba',
            thumbnail: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=400'
        },
        discount: {
            type: 'percentage',
            value: 50
        },
        originalPrice: 20,
        discountedPrice: 10,
        validity: {
            startDate: new Date(),
            endDate: new Date(Date.now() + 45 * 24 * 60 * 60 * 1000),
            days: ['lun', 'mar', 'mer', 'gio'],
            hours: { from: '14:00', to: '23:59' }
        },
        limits: {
            totalRedemptions: null,
            perUser: 5,
            perDay: 1
        },
        isActive: true,
        pointsCost: 0,
        pointsReward: 30,
        terms: 'Esclusi film in 3D e prime visioni. Valido solo infrasettimanale.',
        howToRedeem: 'Mostra il QR code alla cassa cinema.'
    },
    {
        title: 'Palestra 1 Mese Gratis',
        description: 'Inizia il tuo percorso fitness con noi! Primo mese di abbonamento completamente gratuito. Include accesso illimitato e consulenza personalizzata.',
        shortDescription: 'Primo mese palestra gratis',
        partner: {
            name: 'FitLife Gym',
            address: 'Via Lorenteggio 234',
            city: 'Milano',
            province: 'MI',
            zipCode: '20146',
            phone: '+39 02 5555555'
        },
        category: 'sport',
        tags: ['palestra', 'fitness', 'sport', 'gratis'],
        images: {
            main: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48',
            thumbnail: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400'
        },
        discount: {
            type: 'fixed',
            value: 60
        },
        originalPrice: 60,
        discountedPrice: 0,
        validity: {
            startDate: new Date(),
            endDate: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
            days: ['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom']
        },
        limits: {
            totalRedemptions: 30,
            perUser: 1
        },
        isActive: true,
        isFeatured: true,
        pointsCost: 0,
        pointsReward: 150,
        terms: 'Solo per nuovi iscritti. Richiesta registrazione e documento.',
        howToRedeem: 'Presenta il QR code alla reception per attivare la promo.'
    },
    {
        title: 'Smartphone Samsung -15%',
        description: 'Sconto del 15% su tutti gli smartphone Samsung in store. Modelli Galaxy S23, A54, e molto altro!',
        shortDescription: '15% su smartphone Samsung',
        partner: {
            name: 'TechWorld Store',
            address: 'Via Dante 89',
            city: 'Milano',
            province: 'MI',
            zipCode: '20121'
        },
        category: 'tecnologia',
        tags: ['smartphone', 'samsung', 'tecnologia', 'elettronica'],
        images: {
            main: 'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c',
            thumbnail: 'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=400'
        },
        discount: {
            type: 'percentage',
            value: 15,
            maxAmount: 150
        },
        validity: {
            startDate: new Date(),
            endDate: new Date(Date.now() + 20 * 24 * 60 * 60 * 1000),
            days: ['lun', 'mar', 'mer', 'gio', 'ven', 'sab']
        },
        limits: {
            totalRedemptions: 50,
            perUser: 1
        },
        isActive: true,
        pointsCost: 50,
        pointsReward: 250,
        terms: 'Esclusi modelli già in promozione.',
        howToRedeem: 'Mostra il QR code alla cassa.'
    }
];

/**
 * Seed database
 */
const seedDatabase = async () => {
    try {
        console.log('🌱 Inizio seed database...\n');
        
        // Connect to database
        await connectDB();
        
        // Clear existing data
        console.log('🗑️  Pulizia database...');
        await User.deleteMany({});
        await Promotion.deleteMany({});
        await Referral.deleteMany({});
        await Transaction.deleteMany({});
        console.log('✅ Database pulito\n');
        
        // Create users
        console.log('👥 Creazione utenti...');
        const users = await User.create(sampleUsers);
        console.log(`✅ Creati ${users.length} utenti\n`);
        
        // Create promotions (assign to admin)
        console.log('🎁 Creazione promozioni...');
        const promotionsWithCreator = samplePromotions.map(promo => ({
            ...promo,
            createdBy: users[0]._id // Admin user
        }));
        const promotions = await Promotion.create(promotionsWithCreator);
        console.log(`✅ Create ${promotions.length} promozioni\n`);
        
        // Create sample referral
        console.log('🔗 Creazione referral di esempio...');
        const referral = await Referral.create({
            referrerId: users[1]._id, // Mario
            referredUserId: users[2]._id, // Lucia
            codeUsed: users[1].referralCode,
            status: 'completed',
            pointsEarned: {
                referrer: 200,
                referred: 100
            },
            registeredAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000),
            verifiedAt: new Date(Date.now() - 9 * 24 * 60 * 60 * 1000),
            completedAt: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000)
        });
        console.log('✅ Referral creato\n');
        
        // Add favorite promotions to user
        console.log('⭐ Aggiunta promozioni preferite...');
        users[1].favoritePromotions = [promotions[0]._id, promotions[2]._id, promotions[4]._id];
        await users[1].save();
        console.log('✅ Preferiti aggiunti\n');
        
        // Update promotion stats
        console.log('📊 Aggiornamento statistiche promozioni...');
        for (let i = 0; i < promotions.length; i++) {
            promotions[i].stats.views = Math.floor(Math.random() * 500) + 100;
            promotions[i].stats.favorites = Math.floor(Math.random() * 50) + 5;
            promotions[i].stats.clicks = Math.floor(Math.random() * 200) + 20;
            promotions[i].stats.redemptions = Math.floor(Math.random() * 30);
            await promotions[i].save();
        }
        console.log('✅ Statistiche aggiornate\n');
        
        // Summary
        console.log('═══════════════════════════════════════');
        console.log('✅ SEED COMPLETATO CON SUCCESSO!');
        console.log('═══════════════════════════════════════');
        console.log(`👥 Utenti creati: ${users.length}`);
        console.log(`🎁 Promozioni create: ${promotions.length}`);
        console.log(`🔗 Referral creati: 1`);
        console.log('\n📧 Credenziali di accesso:');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log('Admin:');
        console.log('  Email: admin@cdm86.com');
        console.log('  Password: Admin123!');
        console.log('\nUser:');
        console.log('  Email: user1@test.com');
        console.log('  Password: User123!');
        console.log('\nPartner:');
        console.log('  Email: partner@test.com');
        console.log('  Password: Partner123!');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        
    } catch (error) {
        console.error('❌ Errore durante il seed:', error.message);
        console.error(error);
    } finally {
        await disconnectDB();
        process.exit();
    }
};

// Run seed
seedDatabase();