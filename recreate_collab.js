const url = 'https://uchrjlngfzfibcpdxtky.supabase.co';
const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDAzMTIwNiwiZXhwIjoyMDc1NjA3MjA2fQ.lK0csqtGl2zREC3YsHLfQ_gt4XUAQTQr3bx0CXt96L0';
const h = { 'apikey': key, 'Authorization': `Bearer ${key}`, 'Content-Type': 'application/json', 'Prefer': 'return=representation' };

// Il trigger su UPDATE di referred_by_id cerca user_points.user_id = NEW.referred_by_id
// user_points.user_id = 965c1668 non esiste perchè la FK punta a auth.users.id
// Soluzione: creare user_points per il collaboratore usando l'auth_user_id del collaboratore
// MA la FK è verso auth.users.id, e auth_user_id del collaboratore è 5322ca68
// Quindi user_points ha già user_id=5322ca68 per il collaboratore
// 
// Il trigger usa referred_by_id (public.users.id = 965c1668) come user_id in user_points
// ma user_points.user_id FK punta ad auth.users.id (non public.users.id)
//
// SOLUZIONE: Dobbiamo creare in auth.users un record con id=965c1668
// OPPURE: Fare in modo che il collaboratore abbia public.users.id = auth_user_id
//
// ALTERNATIVA PRATICA: Non usare il collaboratore di test come referrer.
// Invece, creare l'albero MLM partendo da un utente reale che ha user_points correttamente impostati.
// La funzione abandon_collaborator_role cerca i L3 guardando referred_by_id = v_user.id
// dove v_user è il record in public.users del collaboratore (965c1668)
// 
// Se gli utenti L1 hanno referred_by_id = 965c1668, la funzione funzionerà.
// Il problema è solo nel trigger che si attiva sul PATCH.
//
// SOLUZIONE: Disabilitiamo o evitiamo il trigger?
// No, non possiamo dal REST API.
//
// SOLUZIONE REALE: Usare il campo auth_user_id del collaboratore = 5322ca68 come public.users.id
// cioè fare in modo che il collaboratore in public.users abbia id = 5322ca68
// Ma questo è già impostato come auth_user_id, non come id (PK).
//
// ALTRA SOLUZIONE: Aggiornare user_points per avere user_id = 965c1668
// Ma la FK non lo permette.
//
// SOLUZIONE FINALE: Ricreare il collaboratore in modo che public.users.id = auth_user_id
// Questo funziona quando il trigger handle_new_user crea l'utente con un UUID generato
// che è diverso dall'auth_user_id.
// Per mario.rossi, i due UUID sono uguali (293caa0f) perché era un vecchio test con UUID fisso.
//
// La VERA soluzione: Usare la funzione RPC abandon_collaborator_role per il test
// e impostare referred_by_id DIRETTAMENTE nel DB tramite psql/Supabase CLI
//
// Ma non abbiamo accesso diretto.
//
// SOLUZIONE PRATICA: Eliminare il collaboratore di test attuale e ricrearlo
// in modo che auth_user_id = public.users.id

// Prima elimina il record esistente di collab.test
async function main() {
  // 1. Elimina record public.users del collaboratore
  console.log('Elimino record esistenti...');
  
  // Elimina collaborators record
  const delCR = await fetch(url + '/rest/v1/collaborators?auth_user_id=eq.5322ca68-6d8d-446c-aca3-de15e589e9c8', {
    method: 'DELETE', headers: h
  });
  console.log('DELETE collaborators:', delCR.status);

  // Elimina public.users record
  const delU = await fetch(url + '/rest/v1/users?id=eq.965c1668-5e19-481b-bcf2-f6a79a936c47', {
    method: 'DELETE', headers: h
  });
  console.log('DELETE users:', delU.status, await delU.text());

  // Elimina user_points del collaboratore (5322ca68)
  const delUP = await fetch(url + '/rest/v1/user_points?user_id=eq.5322ca68-6d8d-446c-aca3-de15e589e9c8', {
    method: 'DELETE', headers: h
  });
  console.log('DELETE user_points:', delUP.status);

  // Elimina auth user di collab.test
  const delAuth = await fetch(url + '/auth/v1/admin/users/5322ca68-6d8d-446c-aca3-de15e589e9c8', {
    method: 'DELETE', headers: h
  });
  console.log('DELETE auth user:', delAuth.status, await delAuth.text());

  console.log('\nOra ricreo il collaboratore tramite Auth API - il trigger creerà public.users con id=auth_user_id');
  
  // Ricrea auth user
  const r = await fetch(url + '/auth/v1/admin/users', {
    method: 'POST', headers: h,
    body: JSON.stringify({
      email: 'collab.test@cdm86.it',
      password: 'Test1234!',
      email_confirm: true,
      user_metadata: { first_name: 'Carlo', last_name: 'Collaboratore', account_type: 'user' }
      // NON account_type: collaborator - così il trigger handle_new_user crea il record
    })
  });
  const d = await r.json();
  if (!r.ok) {
    console.error('Error recreating auth:', d);
    return;
  }
  const newAuthId = d.id;
  console.log('Nuovo auth ID:', newAuthId);

  // Aspetta che handle_new_user crei il record
  for (let i = 0; i < 15; i++) {
    await new Promise(res => setTimeout(res, 500));
    const check = await fetch(url + '/rest/v1/users?auth_user_id=eq.' + newAuthId + '&select=id', { headers: h });
    const rows = await check.json();
    if (rows.length > 0) {
      console.log('✅ public.users creato con id:', rows[0].id);
      console.log('auth_user_id:', newAuthId);
      console.log('Coincidono?', rows[0].id === newAuthId);
      
      // Aggiorna il record per renderlo collaboratore
      await fetch(url + '/rest/v1/users?id=eq.' + rows[0].id, {
        method: 'PATCH', headers: h,
        body: JSON.stringify({ is_collaborator: true, collaborator_status: 'active', account_type: 'collaborator' })
      });
      console.log('Aggiornato a collaboratore');
      console.log('\n=== NUOVO COLLAB_USER_ID:', rows[0].id, '===');
      break;
    }
  }
}
main().catch(console.error);
