// Ricrea il collaboratore di test eliminato dalla RPC
// Crea un auth user + public.users + collaborators record da zero

const url = 'https://uchrjlngfzfibcpdxtky.supabase.co';
const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDAzMTIwNiwiZXhwIjoyMDc1NjA3MjA2fQ.lK0csqtGl2zREC3YsHLfQ_gt4XUAQTQr3bx0CXt96L0';
const h  = { 'apikey': key, 'Authorization': `Bearer ${key}`, 'Content-Type': 'application/json', 'Prefer': 'return=representation' };

async function main() {
  // ── 1. Crea auth user ─────────────────────────────────────────────
  console.log('1. Creo auth user...');
  const authRes = await fetch(`${url}/auth/v1/admin/users`, {
    method: 'POST',
    headers: h,
    body: JSON.stringify({
      email: 'collab2.test@cdm86.it',
      password: 'TestPass123!',
      email_confirm: true,
      user_metadata: { first_name: 'Carlo', last_name: 'Collaboratore', account_type: 'collaborator' }
    })
  });
  const authData = await authRes.json();
  if (!authRes.ok) { console.error('ERRORE auth:', authData); return; }
  const authId = authData.id;
  console.log('✅ Auth user:', authId);

  // ── 2. Aspetta che handle_new_user crei public.users ──────────────
  await new Promise(r => setTimeout(r, 1500));

  // ── 3. Cerca il public.users creato dal trigger, o crealo manualmente ────
  console.log('2. Cerco public.users...');
  let uRes = await fetch(`${url}/rest/v1/users?auth_user_id=eq.${authId}&select=id,email,auth_user_id`, { headers: h });
  let uData = await uRes.json();
  let userId;
  if (!uData.length) {
    console.log('   Trigger non ha creato public.users, lo creo manualmente...');
    const insRes = await fetch(`${url}/rest/v1/users`, {
      method: 'POST',
      headers: h,
      body: JSON.stringify({
        auth_user_id: authId,
        email: 'collab2.test@cdm86.it',
        first_name: 'Carlo',
        last_name: 'Collaboratore',
        referral_code: 'COLLAB2T',
        points: 0,
        is_collaborator: true,
        collaborator_status: 'active',
        account_type: 'collaborator'
      })
    });
    const insData = await insRes.json();
    if (!insRes.ok) { console.error('ERRORE insert public.users:', insData); return; }
    userId = insData[0]?.id || insData.id;
    console.log('✅ public.users creato manualmente:', userId);
  } else {
    userId = uData[0].id;
    console.log('✅ public.users id (dal trigger):', userId);
  }
  console.log('✅ public.users id:', userId);

  // ── 4. Aggiorna is_collaborator e account_type in public.users ────
  await fetch(`${url}/rest/v1/users?id=eq.${userId}`, {
    method: 'PATCH',
    headers: h,
    body: JSON.stringify({ is_collaborator: true, collaborator_status: 'active', account_type: 'collaborator' })
  });

  // ── 5. Crea record in collaborators ──────────────────────────────
  console.log('3. Creo collaborators record...');
  const cRes = await fetch(`${url}/rest/v1/collaborators`, {
    method: 'POST',
    headers: h,
    body: JSON.stringify({
      user_id: userId,
      auth_user_id: authId,
      email: 'collab2.test@cdm86.it',
      first_name: 'Carlo',
      last_name: 'Collaboratore',
      referral_code: 'COLLAB2T',
      status: 'active'
    })
  });
  const cData = await cRes.json();
  if (!cRes.ok) { console.error('ERRORE collaborators:', cData); return; }
  const collabId = cData[0]?.id || cData.id;
  console.log('✅ Collaborator id:', collabId);

  // ── 6. Crea L1A: utente referenziato dal collaboratore ───────────
  console.log('4. Creo L1A...');
  const l1aAuth = await fetch(`${url}/auth/v1/admin/users`, {
    method: 'POST',
    headers: h,
    body: JSON.stringify({
      email: 'l1a2.test@cdm86.it',
      password: 'TestPass123!',
      email_confirm: true,
      user_metadata: { first_name: 'Luigi', last_name: 'L1A' }
    })
  });
  const l1aData = await l1aAuth.json();
  if (!l1aAuth.ok) { console.error('ERRORE L1A auth:', l1aData); return; }
  const l1aAuthId = l1aData.id;
  await new Promise(r => setTimeout(r, 1500));

  // Trova public.users di L1A
  const l1aU = await fetch(`${url}/rest/v1/users?auth_user_id=eq.${l1aAuthId}&select=id`, { headers: h });
  const l1aUD = await l1aU.json();
  let l1aId;
  if (!l1aUD.length) {
    const insR = await fetch(`${url}/rest/v1/users`, {
      method: 'POST', headers: h,
      body: JSON.stringify({ auth_user_id: l1aAuthId, email: 'l1a2.test@cdm86.it', first_name: 'Luigi', last_name: 'L1A', referral_code: 'L1A2TEST', points: 0 })
    });
    const insD = await insR.json();
    l1aId = insD[0]?.id || insD.id;
  } else {
    l1aId = l1aUD[0].id;
  }

  // PATCH referred_by_id → userId (collaboratore)
  await fetch(`${url}/rest/v1/users?id=eq.${l1aId}`, {
    method: 'PATCH', headers: h,
    body: JSON.stringify({ referred_by_id: userId })
  });
  console.log('✅ L1A:', l1aId, '→ referred_by', userId);

  // ── 7. Crea L2A: referenziato da L1A ────────────────────────────
  console.log('5. Creo L2A...');
  const l2aAuth = await fetch(`${url}/auth/v1/admin/users`, {
    method: 'POST',
    headers: h,
    body: JSON.stringify({
      email: 'l2a2.test@cdm86.it',
      password: 'TestPass123!',
      email_confirm: true,
      user_metadata: { first_name: 'Marco', last_name: 'L2A' }
    })
  });
  const l2aData = await l2aAuth.json();
  if (!l2aAuth.ok) { console.error('ERRORE L2A:', l2aData); return; }
  const l2aAuthId = l2aData.id;
  await new Promise(r => setTimeout(r, 1500));

  const l2aU = await fetch(`${url}/rest/v1/users?auth_user_id=eq.${l2aAuthId}&select=id`, { headers: h });
  const l2aUD = await l2aU.json();
  let l2aId;
  if (!l2aUD.length) {
    const insR = await fetch(`${url}/rest/v1/users`, {
      method: 'POST', headers: h,
      body: JSON.stringify({ auth_user_id: l2aAuthId, email: 'l2a2.test@cdm86.it', first_name: 'Marco', last_name: 'L2A', referral_code: 'L2A2TEST', points: 0 })
    });
    const insD = await insR.json();
    l2aId = insD[0]?.id || insD.id;
  } else {
    l2aId = l2aUD[0].id;
  }

  await fetch(`${url}/rest/v1/users?id=eq.${l2aId}`, {
    method: 'PATCH', headers: h,
    body: JSON.stringify({ referred_by_id: l1aId })
  });
  console.log('✅ L2A:', l2aId, '→ referred_by', l1aId);

  // ── 8. Crea L3A: referenziato da L2A (sarà riassegnato) ─────────
  console.log('6. Creo L3A...');
  const l3aAuth = await fetch(`${url}/auth/v1/admin/users`, {
    method: 'POST',
    headers: h,
    body: JSON.stringify({
      email: 'l3a2.test@cdm86.it',
      password: 'TestPass123!',
      email_confirm: true,
      user_metadata: { first_name: 'Anna', last_name: 'L3A' }
    })
  });
  const l3aData = await l3aAuth.json();
  if (!l3aAuth.ok) { console.error('ERRORE L3A:', l3aData); return; }
  const l3aAuthId = l3aData.id;
  await new Promise(r => setTimeout(r, 1500));

  const l3aU = await fetch(`${url}/rest/v1/users?auth_user_id=eq.${l3aAuthId}&select=id`, { headers: h });
  const l3aUD = await l3aU.json();
  let l3aId;
  if (!l3aUD.length) {
    const insR = await fetch(`${url}/rest/v1/users`, {
      method: 'POST', headers: h,
      body: JSON.stringify({ auth_user_id: l3aAuthId, email: 'l3a2.test@cdm86.it', first_name: 'Anna', last_name: 'L3A', referral_code: 'L3A2TEST', points: 0 })
    });
    const insD = await insR.json();
    l3aId = insD[0]?.id || insD.id;
  } else {
    l3aId = l3aUD[0].id;
  }

  await fetch(`${url}/rest/v1/users?id=eq.${l3aId}`, {
    method: 'PATCH', headers: h,
    body: JSON.stringify({ referred_by_id: l2aId })
  });
  console.log('✅ L3A:', l3aId, '→ referred_by', l2aId);

  // ── 9. Riepilogo ─────────────────────────────────────────────────
  console.log('\n════════════════════════════════════');
  console.log('✅ SETUP COMPLETATO');
  console.log('════════════════════════════════════');
  console.log('Collaboratore: Carlo Collaboratore');
  console.log('  auth_user_id:', authId);
  console.log('  public.users.id:', userId);
  console.log('  collaborators.id:', collabId);
  console.log('');
  console.log('Catena MLM:');
  console.log('  L1A (Luigi):', l1aId, '→ ref:', userId);
  console.log('  L2A (Marco):', l2aId, '→ ref:', l1aId);
  console.log('  L3A (Anna):', l3aId, '→ ref:', l2aId, '← sarà riassegnata');
  console.log('');
  console.log('Ora vai nel pannello admin e premi "Abbandona Ruolo" su Carlo Collaboratore!');
  console.log('Collaborator ID per test diretto:', collabId);
}

main().catch(console.error);
