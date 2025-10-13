/**
 * Verifica struttura tabella promotions
 */

const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://uchrjlngfzfibcpdxtky.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwMzEyMDYsImV4cCI6MjA3NTYwNzIwNn0.64JK3OhYJi2YtrErctNAp_sCcSHwB656NVLdooyceOM';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkStructure() {
  console.log('🔍 Verifico struttura tabella promotions...\n');

  try {
    // Get all columns
    const { data, error } = await supabase
      .from('promotions')
      .select('*')
      .limit(1)
      .single();

    if (error) throw error;

    console.log('📋 STRUTTURA TABELLA PROMOTIONS:\n');
    console.log('Colonne disponibili:');
    Object.keys(data).forEach((key, index) => {
      const value = data[key];
      let type = typeof value;
      
      if (value === null) {
        type = 'null (unknown type)';
      } else if (value instanceof Date || (typeof value === 'string' && value.match(/^\d{4}-\d{2}-\d{2}/))) {
        type = 'date/timestamp';
      }
      
      console.log(`  ${index + 1}. ${key.padEnd(30)} : ${type}`);
    });

    console.log('\n\n📊 ESEMPIO PRIMA PROMOZIONE:\n');
    console.log(JSON.stringify(data, null, 2));

    // Count total
    const { count } = await supabase
      .from('promotions')
      .select('*', { count: 'exact', head: true });

    console.log(`\n\n✅ Totale promozioni nel database: ${count}`);

  } catch (error) {
    console.error('\n❌ ERRORE:', error.message);
  }
}

checkStructure();
