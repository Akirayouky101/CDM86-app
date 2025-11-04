import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://uchrjlngfzfibcpdxtky.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwMzEyMDYsImV4cCI6MjA3NTYwNzIwNn0.64JK3OhYJi2YtrErctNAp_sCcSHwB656NVLdooyceOM';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkAndSeedPromotions() {
    console.log('🔍 Verificando tabella promotions...');

    // Check if table exists and get existing data
    const { data: existing, error: checkError } = await supabase
        .from('promotions')
        .select('*')
        .limit(1);

    if (checkError) {
        console.error('❌ Errore:', checkError.message);
        console.log('📋 La tabella "promotions" potrebbe non esistere.');
        console.log('\n📝 SQL per creare la tabella:\n');
        console.log(`
CREATE TABLE promotions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    short_description TEXT NOT NULL,
    description TEXT NOT NULL,
    partner_name TEXT NOT NULL,
    partner_city TEXT NOT NULL,
    partner_email TEXT,
    partner_phone TEXT,
    partner_address TEXT,
    category TEXT NOT NULL,
    discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
    discount_value NUMERIC NOT NULL,
    original_price NUMERIC NOT NULL,
    discounted_price NUMERIC NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;

-- Policy per lettura pubblica
CREATE POLICY "Public can read active promotions" ON promotions
    FOR SELECT USING (is_active = true);

-- Policy per admin (inserimento/modifica)
CREATE POLICY "Authenticated users can manage promotions" ON promotions
    FOR ALL USING (auth.role() = 'authenticated');
        `);
        return;
    }

    // Get count
    const { count } = await supabase
        .from('promotions')
        .select('*', { count: 'exact', head: true });

    console.log(`✅ Tabella trovata! Promozioni esistenti: ${count || 0}`);

    if (count === 0) {
        console.log('\n📦 Inserimento promozioni di esempio...\n');

        const samplePromotions = [
            {
                title: "Pizza Margherita + Bibita Omaggio",
                short_description: "Pizza classica con bibita gratis!",
                description: "Ordina una pizza Margherita e ricevi una bibita in omaggio. Valido su tutte le pizze Margherita del menu.",
                partner_name: "Pizzeria Da Mario",
                partner_city: "Milano",
                partner_email: "info@pizzeriadamario.it",
                partner_phone: "+39 02 12345678",
                partner_address: "Via Roma 123",
                category: "ristoranti",
                discount_type: "percentage",
                discount_value: 20,
                original_price: 10.00,
                discounted_price: 8.00,
                start_date: "2025-01-01",
                end_date: "2025-12-31",
                is_active: true,
                is_featured: true
            },
            {
                title: "Sconto 30% su Abbigliamento",
                short_description: "30% di sconto su tutto l'abbigliamento!",
                description: "Approfitta del nostro sconto del 30% su tutto l'abbigliamento estivo e invernale. Non perdere questa occasione!",
                partner_name: "Fashion Store Milano",
                partner_city: "Milano",
                partner_email: "shop@fashionstore.it",
                partner_phone: "+39 02 98765432",
                partner_address: "Corso Buenos Aires 45",
                category: "shopping",
                discount_type: "percentage",
                discount_value: 30,
                original_price: 50.00,
                discounted_price: 35.00,
                start_date: "2025-01-01",
                end_date: "2025-06-30",
                is_active: true,
                is_featured: false
            },
            {
                title: "Massaggio Relax 60 minuti",
                short_description: "Massaggio rilassante a prezzo speciale",
                description: "Concediti un'ora di puro relax con il nostro massaggio rilassante. Prenotazione obbligatoria.",
                partner_name: "Wellness SPA Center",
                partner_city: "Roma",
                partner_email: "info@wellnessspa.it",
                partner_phone: "+39 06 11223344",
                partner_address: "Via del Benessere 7",
                category: "benessere",
                discount_type: "fixed",
                discount_value: 15,
                original_price: 60.00,
                discounted_price: 45.00,
                start_date: "2025-01-01",
                end_date: "2025-12-31",
                is_active: true,
                is_featured: true
            },
            {
                title: "Ingresso Palestra 1 Mese",
                short_description: "Abbonamento mensile scontato",
                description: "Abbonamento mensile alla nostra palestra completa di tutti i corsi. Valido per nuovi iscritti.",
                partner_name: "FitGym Milano",
                partner_city: "Milano",
                partner_email: "info@fitgym.it",
                partner_phone: "+39 02 55667788",
                partner_address: "Via dello Sport 89",
                category: "sport",
                discount_type: "percentage",
                discount_value: 25,
                original_price: 80.00,
                discounted_price: 60.00,
                start_date: "2025-01-01",
                end_date: "2025-12-31",
                is_active: true,
                is_featured: false
            },
            {
                title: "Cinema 2x1 Weekend",
                short_description: "Biglietto cinema 2x1 nel weekend",
                description: "Acquista un biglietto per il cinema e porta un amico gratis! Valido solo sabato e domenica.",
                partner_name: "Cinema Multiplex",
                partner_city: "Torino",
                partner_email: "info@cinemamultiplex.it",
                partner_phone: "+39 011 9988776",
                partner_address: "Piazza Cinema 1",
                category: "intrattenimento",
                discount_type: "percentage",
                discount_value: 50,
                original_price: 18.00,
                discounted_price: 9.00,
                start_date: "2025-01-01",
                end_date: "2025-12-31",
                is_active: true,
                is_featured: true
            }
        ];

        const { data, error } = await supabase
            .from('promotions')
            .insert(samplePromotions)
            .select();

        if (error) {
            console.error('❌ Errore inserimento:', error.message);
        } else {
            console.log(`✅ Inserite ${data.length} promozioni di esempio!`);
            data.forEach((promo, i) => {
                console.log(`   ${i + 1}. ${promo.title} - ${promo.partner_city}`);
            });
        }
    } else {
        console.log('\n📋 Promozioni esistenti:');
        const { data: allPromos } = await supabase
            .from('promotions')
            .select('*')
            .order('created_at', { ascending: false });

        allPromos?.forEach((promo, i) => {
            console.log(`   ${i + 1}. ${promo.title} - ${promo.is_active ? '✅ Attiva' : '⏸️ Disattivata'}`);
        });
    }
}

checkAndSeedPromotions();
