const url = 'https://uchrjlngfzfibcpdxtky.supabase.co';
const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDAzMTIwNiwiZXhwIjoyMDc1NjA3MjA2fQ.lK0csqtGl2zREC3YsHLfQ_gt4XUAQTQr3bx0CXt96L0';
const h = { 'apikey': key, 'Authorization': `Bearer ${key}`, 'Content-Type': 'application/json', 'Prefer': 'return=representation' };
const COLLAB_AUTH = '5322ca68-6d8d-446c-aca3-de15e589e9c8';
const COLLAB_USER = '965c1668-5e19-481b-bcf2-f6a79a936c47';
const ADMIN_USER = 'e8cde03d-2aa6-4ea6-a29f-43f290ae00ce';

async function main() {
  // 1. Controlla/crea collaborator record
  let collab = await (await fetch(url+'/rest/v1/collaborators?auth_user_id=eq.'+COLLAB_AUTH, {headers:h})).json();
  let collabId;
  if (collab.length > 0) {
    collabId = collab[0].id;
    console.log('Collaborator record:', collabId, 'status:', collab[0].status);
  } else {
    const ins = await fetch(url+'/rest/v1/collaborators', {
      method:'POST', headers:h,
      body: JSON.stringify({
        auth_user_id: COLLAB_AUTH, user_id: COLLAB_USER,
        email: 'collab.test@cdm86.it', first_name: 'Carlo', last_name: 'Collaboratore',
        referral_code: 'COLLABT1', status: 'active', rate_user: 10, rate_azienda: 10
        // NO referred_by_id - collaborators.referred_by_id FK punta a collaborators.id
      })
    });
    const cr = await ins.json();
    const row = Array.isArray(cr) ? cr[0] : cr;
    collabId = row?.id;
    console.log('Collaborator record creato:', collabId);
  }

  // 2. Lista L1 utenti
  const l1 = await (await fetch(url+'/rest/v1/users?referred_by_id=eq.'+COLLAB_USER+'&select=id,email,referred_by_id', {headers:h})).json();
  console.log('\nUtenti L1 del collaboratore:', l1.length);
  l1.forEach(u => console.log(' -', u.email, u.id));

  // 3. Test RPC abandon_collaborator_role
  if (!collabId) { console.error('No collaborator ID!'); return; }
  
  console.log('\n=== TEST RPC abandon_collaborator_role ===');
  console.log('Collaborator ID:', collabId);
  
  const rpc = await fetch(url+'/rest/v1/rpc/abandon_collaborator_role', {
    method: 'POST',
    headers: { ...h, 'Prefer': 'return=representation' },
    body: JSON.stringify({ p_collaborator_id: collabId })
  });
  const result = await rpc.json();
  console.log('\nRisultato RPC (status', rpc.status+'):');
  console.log(JSON.stringify(result, null, 2));

  if (result.success) {
    console.log('\n✅ SUCCESSO!');
    console.log('Email:', result.data?.email);
    console.log('Nuova password:', result.data?.new_password);
    console.log('Referral code:', result.data?.referral_code);
    console.log('L3 riassegnati:', result.data?.level_3_reassigned);
    console.log('Nuovo referral parent:', result.data?.new_referral_parent);
    
    // Verifica che il collaborator record sia stato eliminato
    const checkCollab = await (await fetch(url+'/rest/v1/collaborators?id=eq.'+collabId, {headers:h})).json();
    console.log('\nCollaborator record ancora esiste?', checkCollab.length > 0 ? 'SÌ (errore!)' : 'NO ✅ (eliminato correttamente)');
    
    // Verifica L1 utenti ancora puntano al collaboratore
    const l1after = await (await fetch(url+'/rest/v1/users?referred_by_id=eq.'+COLLAB_USER+'&select=id,email', {headers:h})).json();
    console.log('L1 ancora puntano al collaboratore:', l1after.length, '✅ (dovrebbero essere mantenuti)');
  } else {
    console.log('\n❌ Errore:', result.error || result);
  }
}
main().catch(console.error);
