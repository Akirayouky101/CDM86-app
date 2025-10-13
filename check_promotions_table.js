/**
 * Script per verificare la tabella promotions su Supabase
 * Esegui con: node check_promotions_table.js
 */

const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://uchrjlngfzfibcpdxtky.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwMzEyMDYsImV4cCI6MjA3NTYwNzIwNn0.64JK3OhYJi2YtrErctNAp_sCcSHwB656NVLdooyceOM';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkPromotionsTable() {
  console.log('🔍 Verifico tabella promotions...\n');

  try {
    // 1. Check if table exists
    console.log('1️⃣  Verifica esistenza tabella...');
    const { data: tables, error: tablesError } = await supabase
      .from('promotions')
      .select('*', { count: 'exact', head: true });

    if (tablesError) {
      if (tablesError.message.includes('does not exist')) {
        console.log('❌ LA TABELLA "promotions" NON ESISTE!\n');
        console.log('📝 Devi crearla con lo schema SQL.\n');
        console.log('📄 File schema: /Users/akirayouky/Desktop/Siti/CDM86/database/schema.sql');
        console.log('   Cerca la sezione "CREATE TABLE promotions" e eseguila su Supabase SQL Editor.\n');
        return;
      }
      throw tablesError;
    }

    console.log('✅ Tabella "promotions" esiste!\n');

    // 2. Count promotions
    console.log('2️⃣  Conto promozioni...');
    const { count, error: countError } = await supabase
      .from('promotions')
      .select('*', { count: 'exact', head: true });

    if (countError) throw countError;

    console.log(`✅ Totale promozioni: ${count}\n`);

    if (count === 0) {
      console.log('⚠️  NESSUNA PROMOZIONE TROVATA!\n');
      console.log('📝 Per aggiungere promozioni di test, esegui:');
      console.log('   node add_promotions.js\n');
      return;
    }

    // 3. Get first 5 promotions
    console.log('3️⃣  Prime 5 promozioni:');
    const { data: promos, error: promosError } = await supabase
      .from('promotions')
      .select('id, title, partner_name, category, price_original, price_discounted, is_active, created_at')
      .order('created_at', { ascending: false })
      .limit(5);

    if (promosError) throw promosError;

    promos.forEach((promo, index) => {
      console.log(`\n   ${index + 1}. ${promo.title}`);
      console.log(`      Partner: ${promo.partner_name}`);
      console.log(`      Categoria: ${promo.category}`);
      console.log(`      Prezzo: €${promo.price_discounted} (era €${promo.price_original})`);
      console.log(`      Attiva: ${promo.is_active ? '✅ Sì' : '❌ No'}`);
      console.log(`      ID: ${promo.id}`);
    });

    // 4. Get structure
    console.log('\n\n4️⃣  Struttura tabella:');
    const { data: sample } = await supabase
      .from('promotions')
      .select('*')
      .limit(1)
      .single();

    if (sample) {
      console.log('\n   Campi disponibili:');
      Object.keys(sample).forEach(key => {
        const value = sample[key];
        const type = typeof value;
        console.log(`      - ${key}: ${type}`);
      });
    }

    console.log('\n\n✅ VERIFICA COMPLETATA!\n');
    console.log('📊 La tabella promotions è pronta per essere usata.\n');
    console.log('🎨 Puoi creare nuove promozioni dal pannello admin:');
    console.log('   https://cdm86.com/public/admin-panel.html (tab Promozioni)\n');

  } catch (error) {
    console.error('\n❌ ERRORE:', error.message);
    console.error('\nDettagli:', error);
  }
}

checkPromotionsTable();
