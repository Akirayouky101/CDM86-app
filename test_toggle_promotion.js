import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://uchrjlngfzfibcpdxtky.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwMzEyMDYsImV4cCI6MjA3NTYwNzIwNn0.64JK3OhYJi2YtrErctNAp_sCcSHwB656NVLdooyceOM';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testToggle() {
    console.log('🔍 Caricamento promozioni...\n');

    // Get all promotions
    const { data: promos, error: loadError } = await supabase
        .from('promotions')
        .select('*')
        .order('created_at', { ascending: false });

    if (loadError) {
        console.error('❌ Errore caricamento:', loadError.message);
        return;
    }

    if (!promos || promos.length === 0) {
        console.log('⚠️ Nessuna promozione trovata');
        return;
    }

    console.log(`✅ Trovate ${promos.length} promozioni:\n`);
    promos.forEach((p, i) => {
        console.log(`${i + 1}. ${p.title}`);
        console.log(`   Stato: ${p.is_active ? '✅ Attiva' : '⏸️ Disattivata'}`);
        console.log(`   ID: ${p.id}\n`);
    });

    // Test toggle on first promotion
    const testPromo = promos[0];
    console.log(`\n🔧 Test toggle su: "${testPromo.title}"`);
    console.log(`   Stato attuale: ${testPromo.is_active ? 'Attiva' : 'Disattivata'}`);
    console.log(`   Tentativo di ${testPromo.is_active ? 'disattivare' : 'attivare'}...\n`);

    const newStatus = !testPromo.is_active;
    const { data: updated, error: updateError } = await supabase
        .from('promotions')
        .update({ is_active: newStatus })
        .eq('id', testPromo.id)
        .select();

    if (updateError) {
        console.error('❌ Errore durante toggle:', updateError.message);
        console.error('   Code:', updateError.code);
        console.error('   Details:', updateError.details);
        console.error('   Hint:', updateError.hint);
        
        if (updateError.code === '42501') {
            console.log('\n⚠️ PROBLEMA: Permessi insufficienti (RLS)');
            console.log('📋 SQL per sistemare i permessi:\n');
            console.log(`
-- Drop existing policies
DROP POLICY IF EXISTS "Public can read active promotions" ON promotions;
DROP POLICY IF EXISTS "Authenticated users can manage promotions" ON promotions;

-- Create new policies
CREATE POLICY "Anyone can read promotions" ON promotions
    FOR SELECT USING (true);

CREATE POLICY "Anyone can update promotions" ON promotions
    FOR UPDATE USING (true);

CREATE POLICY "Anyone can insert promotions" ON promotions
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone can delete promotions" ON promotions
    FOR DELETE USING (true);
            `);
        }
    } else {
        console.log('✅ Toggle riuscito!');
        console.log(`   Nuovo stato: ${updated[0].is_active ? 'Attiva' : 'Disattivata'}`);
        
        // Toggle back
        console.log('\n🔄 Ripristino stato originale...');
        const { error: revertError } = await supabase
            .from('promotions')
            .update({ is_active: testPromo.is_active })
            .eq('id', testPromo.id);

        if (!revertError) {
            console.log('✅ Stato ripristinato!');
        }
    }
}

testToggle();
