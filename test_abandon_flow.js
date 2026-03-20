// test_abandon_flow.js — v2 (aggiornato per _0014)
// Ripristina Carlo come collaboratore + catena L1→L2→L3
// poi testa Caso A (definitivo) e Caso B (reiscritto)

const SUPA_URL = 'https://uchrjlngfzfibcpdxtky.supabase.co';
const SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDAzMTIwNiwiZXhwIjoyMDc1NjA3MjA2fQ.lK0csqtGl2zREC3YsHLfQ_gt4XUAQTQr3bx0CXt96L0';

const HEADERS = {
  'apikey': SERVICE_KEY,
  'Authorization': `Bearer ${SERVICE_KEY}`,
  'Content-Type': 'application/json'
};

// IDs noti
const CARLO_PUB   = 'c8035839-a245-4911-9a49-3990fed1e34f';
const CARLO_AUTH  = '51be900d-5263-4a86-8176-3886d6156fcf';
const CARLO_COLLAB = '5306ff8f-adfd-4b0a-8ec5-7343b65267ae';
const L1A_PUB     = 'b5c02d8d-dd45-475f-8d97-38681e153747';
const L2A_PUB     = '9505502e-a3bb-4900-896b-e768a2716248';
const L3A_PUB     = 'd345ab10-e92c-4816-8fe1-e1d44b00d313';
const ADMIN_PUB   = 'e8cde03d-2aa6-4ea6-a29f-43f290ae00ce';

async function rest(method, path, body) {
  const r = await fetch(`${SUPA_URL}/rest/v1/${path}`, {
    method,
    headers: { ...HEADERS, 'Prefer': 'return=minimal' },
    body: body ? JSON.stringify(body) : undefined
  });
  const text = await r.text();
  return { status: r.status, body: text ? JSON.parse(text) : null };
}

async function rpc(fn, params) {
  const r = await fetch(`${SUPA_URL}/rest/v1/rpc/${fn}`, {
    method: 'POST',
    headers: HEADERS,
    body: JSON.stringify(params)
  });
  return r.json();
}

function ok(label, val) {
  const pass = val === true;
  console.log(`  ${pass ? '✅' : '❌'} ${label}`);
  return pass;
}

async function restoreChain() {
  console.log('\n━━━ RIPRISTINO CATENA ━━━');

  // 1. Elimina collaborators record se esiste
  await rest('DELETE', `collaborators?id=eq.${CARLO_COLLAB}`);

  // 2. Ricrea collaborators record
  const cr = await fetch(`${SUPA_URL}/rest/v1/collaborators`, {
    method: 'POST',
    headers: { ...HEADERS, 'Prefer': 'return=representation' },
    body: JSON.stringify({
      id: CARLO_COLLAB,
      user_id: CARLO_PUB,
      email: 'collab2.test@cdm86.it',
      first_name: 'Carlo',
      last_name: 'Test',
      referral_code: 'COLLAB2T',
      status: 'active',
      auth_user_id: CARLO_AUTH
    })
  });
  const crData = await cr.json();
  ok('Collaborator record creato', cr.status === 201);

  // 3. Aggiorna public.users di Carlo
  await rest('PATCH', `users?id=eq.${CARLO_PUB}`, {
    is_collaborator: true,
    account_type: 'collaborator'
  });

  // 4. Ripristina catena referred_by_id
  await rest('PATCH', `users?id=eq.${L1A_PUB}`, { referred_by_id: CARLO_PUB });
  await rest('PATCH', `users?id=eq.${L2A_PUB}`, { referred_by_id: L1A_PUB });
  await rest('PATCH', `users?id=eq.${L3A_PUB}`, { referred_by_id: L2A_PUB });

  // 5. Verifica
  const check = await fetch(`${SUPA_URL}/rest/v1/users?select=id,email,referred_by_id,is_collaborator,account_type&email=in.(collab2.test@cdm86.it,l1a2.test@cdm86.it,l2a2.test@cdm86.it,l3a2.test@cdm86.it)`, {
    headers: HEADERS
  });
  const users = await check.json();
  const map = {};
  users.forEach(u => map[u.email] = u);

  ok('Carlo is_collaborator=true',  map['collab2.test@cdm86.it']?.is_collaborator === true);
  ok('Carlo account_type=collaborator', map['collab2.test@cdm86.it']?.account_type === 'collaborator');
  ok('L1 referred_by Carlo',        map['l1a2.test@cdm86.it']?.referred_by_id === CARLO_PUB);
  ok('L2 referred_by L1',           map['l2a2.test@cdm86.it']?.referred_by_id === L1A_PUB);
  ok('L3 referred_by L2',           map['l3a2.test@cdm86.it']?.referred_by_id === L2A_PUB);

  const collabCheck = await fetch(`${SUPA_URL}/rest/v1/collaborators?id=eq.${CARLO_COLLAB}&select=id,status`, { headers: HEADERS });
  const collabData = await collabCheck.json();
  ok('Collaborators record attivo',  collabData[0]?.status === 'active');
}

async function testCasoA() {
  console.log('\n━━━ TEST CASO A: DEFINITIVO ━━━');

  const result = await rpc('abandon_collaborator_role', {
    p_collaborator_id: CARLO_COLLAB,
    p_mode: 'definitivo'
  });

  console.log('  RPC response:', JSON.stringify(result, null, 2));

  ok('success=true', result.success === true);
  if (!result.success) return;

  ok('mode=definitivo',    result.data.mode === 'definitivo');
  ok('L1 riassegnato (1)', result.data.level_1_reassigned === 1);
  ok('L2 riassegnato (1)', result.data.level_2_reassigned === 1);
  ok('L3 riassegnato (1)', result.data.level_3_reassigned === 1);
  ok('target=admin',       result.data.target_user_id === ADMIN_PUB);

  // Verifica DB
  const check = await fetch(`${SUPA_URL}/rest/v1/users?select=id,email,referred_by_id,is_collaborator,account_type&email=in.(collab2.test@cdm86.it,l1a2.test@cdm86.it,l2a2.test@cdm86.it,l3a2.test@cdm86.it)`, { headers: HEADERS });
  const users = await check.json();
  const map = {};
  users.forEach(u => map[u.email] = u);

  ok('Carlo is_collaborator=false', map['collab2.test@cdm86.it']?.is_collaborator === false);
  ok('Carlo account_type=user',     map['collab2.test@cdm86.it']?.account_type === 'user');
  ok('L1 referred_by admin',        map['l1a2.test@cdm86.it']?.referred_by_id === ADMIN_PUB);
  ok('L2 referred_by admin',        map['l2a2.test@cdm86.it']?.referred_by_id === ADMIN_PUB);
  ok('L3 referred_by admin',        map['l3a2.test@cdm86.it']?.referred_by_id === ADMIN_PUB);

  const collabCheck = await fetch(`${SUPA_URL}/rest/v1/collaborators?id=eq.${CARLO_COLLAB}`, { headers: HEADERS });
  const collabData = await collabCheck.json();
  ok('Collaborators record eliminato', collabData.length === 0);
}

async function testCasoB() {
  console.log('\n━━━ TEST CASO B: REISCRITTO ━━━');
  console.log('  (usa referral code di L3A come "nuovo utente" per il test)');

  // L3A referral code: CF72A37F
  // Attendiamo: L1+L2 → L3A, L3 → admin
  // Ma prima dobbiamo ripristinare la catena!
  await restoreChain();

  console.log('\n  Chiamata RPC...');
  const result = await rpc('abandon_collaborator_role', {
    p_collaborator_id: CARLO_COLLAB,
    p_mode: 'reiscritto',
    p_new_referral_code: 'CF72A37F'  // referral code di L3A
  });

  console.log('  RPC response:', JSON.stringify(result, null, 2));

  ok('success=true', result.success === true);
  if (!result.success) return;

  ok('mode=reiscritto',    result.data.mode === 'reiscritto');
  ok('L1 riassegnato (1)', result.data.level_1_reassigned === 1);
  ok('L2 riassegnato (1)', result.data.level_2_reassigned === 1);
  ok('target=L3A (non admin)', result.data.target_user_id === L3A_PUB);

  // Verifica DB
  const check = await fetch(`${SUPA_URL}/rest/v1/users?select=id,email,referred_by_id,is_collaborator,account_type&email=in.(collab2.test@cdm86.it,l1a2.test@cdm86.it,l2a2.test@cdm86.it,l3a2.test@cdm86.it)`, { headers: HEADERS });
  const users = await check.json();
  const map = {};
  users.forEach(u => map[u.email] = u);

  ok('Carlo is_collaborator=false', map['collab2.test@cdm86.it']?.is_collaborator === false);
  ok('L1 referred_by L3A',          map['l1a2.test@cdm86.it']?.referred_by_id === L3A_PUB);
  ok('L2 referred_by L3A',          map['l2a2.test@cdm86.it']?.referred_by_id === L3A_PUB);
  // L3 diventa orfano dopo caso B (era sotto L2, ma L2 è ora sotto L3A — riferimento circolare protetto dalla logica pre-L3 delete)
  // In realtà l3a non è un L3 di carlo ma ne usiamo il codice come nuovo utente
  // Il vero L3 della catena è l3a2 che era referred_by l2a
  // Dopo la RPC: referred_by_id di l3a2 dovrebbe essere admin
  ok('L3A referred_by admin (era L3 della catena)', map['l3a2.test@cdm86.it']?.referred_by_id === ADMIN_PUB);

  const collabCheck = await fetch(`${SUPA_URL}/rest/v1/collaborators?id=eq.${CARLO_COLLAB}`, { headers: HEADERS });
  const collabData = await collabCheck.json();
  ok('Collaborators record eliminato', collabData.length === 0);
}

async function testCasoBWithError() {
  console.log('\n━━━ TEST CASO B — ERRORI DI VALIDAZIONE ━━━');

  // Test: codice non esistente
  const r1 = await rpc('abandon_collaborator_role', {
    p_collaborator_id: CARLO_COLLAB,
    p_mode: 'reiscritto',
    p_new_referral_code: 'INESISTENTE'
  });
  ok('Errore codice inesistente', r1.success === false && r1.error.includes('Nessun utente'));
  console.log('    messaggio:', r1.error);

  // Test: codice mancante
  const r2 = await rpc('abandon_collaborator_role', {
    p_collaborator_id: CARLO_COLLAB,
    p_mode: 'reiscritto'
  });
  ok('Errore codice mancante', r2.success === false);
  console.log('    messaggio:', r2.error);

  // Test: modalità non valida
  const r3 = await rpc('abandon_collaborator_role', {
    p_collaborator_id: CARLO_COLLAB,
    p_mode: 'pippo'
  });
  ok('Errore modalità non valida', r3.success === false);
  console.log('    messaggio:', r3.error);
}

async function main() {
  console.log('╔══════════════════════════════════════════╗');
  console.log('║   TEST abandon_collaborator_role v2      ║');
  console.log('╚══════════════════════════════════════════╝');

  try {
    // 1. Ripristina + Caso A
    await restoreChain();
    await testCasoA();

    // 2. Validazione errori (catena già "usata" da A, collaborator non esiste → errori attesi)
    await testCasoBWithError();

    // 3. Ripristina + Caso B
    await testCasoB();

    console.log('\n✅ TUTTI I TEST COMPLETATI\n');
  } catch (e) {
    console.error('\n💥 ERRORE IMPREVISTO:', e.message);
  }
}

main();
