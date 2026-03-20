// Script per creare dati di test per "Abbandona Ruolo"
const SUPABASE_URL = 'https://uchrjlngfzfibcpdxtky.supabase.co';
const SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDAzMTIwNiwiZXhwIjoyMDc1NjA3MjA2fQ.lK0csqtGl2zREC3YsHLfQ_gt4XUAQTQr3bx0CXt96L0';

const ADMIN_USER_ID = 'e8cde03d-2aa6-4ea6-a29f-43f290ae00ce';
const COLLAB_AUTH_ID = '5322ca68-6d8d-446c-aca3-de15e589e9c8';

const headers = {
  'apikey': SERVICE_KEY,
  'Authorization': `Bearer ${SERVICE_KEY}`,
  'Content-Type': 'application/json',
  'Prefer': 'return=representation'
};

async function restInsert(table, data) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}`, {
    method: 'POST',
    headers,
    body: JSON.stringify(data)
  });
  const text = await res.text();
  if (!res.ok) {
    throw new Error(`INSERT into ${table} failed: ${res.status} ${text}`);
  }
  const rows = JSON.parse(text);
  return Array.isArray(rows) ? rows[0] : rows;
}

async function restGet(table, filter) {
  const params = new URLSearchParams(filter);
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}?${params}`, {
    headers: { 'apikey': SERVICE_KEY, 'Authorization': `Bearer ${SERVICE_KEY}` }
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`GET ${table} failed: ${res.status} ${text}`);
  return JSON.parse(text);
}

async function createAuthUser(email, firstName, lastName) {
  const res = await fetch(`${SUPABASE_URL}/auth/v1/admin/users`, {
    method: 'POST',
    headers: {
      'apikey': SERVICE_KEY,
      'Authorization': `Bearer ${SERVICE_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      email,
      password: 'Test1234!',
      email_confirm: true,
      user_metadata: { account_type: 'user', first_name: firstName, last_name: lastName }
    })
  });
  const data = await res.json();
  if (!res.ok) {
    // Se esiste già, recuperalo
    if (data.message && data.message.includes('already')) {
      console.log(`  Auth user ${email} già esiste, recupero...`);
      const listRes = await fetch(`${SUPABASE_URL}/auth/v1/admin/users?email=${encodeURIComponent(email)}`, {
        headers: { 'apikey': SERVICE_KEY, 'Authorization': `Bearer ${SERVICE_KEY}` }
      });
      const listData = await listRes.json();
      if (listData.users && listData.users.length > 0) return listData.users[0].id;
    }
    console.error(`  Errore creazione auth user ${email}:`, data);
    return null;
  }
  return data.id;
}

async function main() {
  console.log('=== CREAZIONE DATI DI TEST "ABBANDONA RUOLO" ===\n');

  // Step 1: Controlla se collab già esiste in public.users
  console.log('1. Controllo se il collaboratore esiste già in public.users...');
  const existingCollab = await restGet('users', { 'auth_user_id': `eq.${COLLAB_AUTH_ID}` });
  
  let collabUserId;
  if (existingCollab.length > 0) {
    collabUserId = existingCollab[0].id;
    console.log(`   ✅ Già esistente, ID: ${collabUserId}`);
  } else {
    console.log('   Inserisco collaboratore in public.users...');
    const collab = await restInsert('users', {
      auth_user_id: COLLAB_AUTH_ID,
      email: 'collab.test@cdm86.it',
      first_name: 'Carlo',
      last_name: 'Collaboratore',
      referral_code: 'COLLABT1',
      points: 0,
      referred_by_id: ADMIN_USER_ID,
      is_collaborator: true,
      collaborator_status: 'active',
      account_type: 'collaborator'
    });
    collabUserId = collab.id;
    console.log(`   ✅ Inserito, ID: ${collabUserId}`);
  }

  // Step 2: Crea utenti L1 (con auth se necessario)
  console.log('\n2. Creazione utenti livello 1...');
  
  // L1A
  let l1aAuthId = await createAuthUser('l1a.test@cdm86.it', 'Luigi', 'UnoA');
  const existingL1A = await restGet('users', { 'email': 'eq.l1a.test@cdm86.it' });
  let l1aUserId;
  if (existingL1A.length > 0) {
    l1aUserId = existingL1A[0].id;
    console.log(`   L1A già esistente, ID: ${l1aUserId}`);
  } else {
    const l1a = await restInsert('users', {
      auth_user_id: l1aAuthId,
      email: 'l1a.test@cdm86.it',
      first_name: 'Luigi',
      last_name: 'UnoA',
      referral_code: 'L1ATEST1',
      points: 0,
      referred_by_id: collabUserId
    });
    l1aUserId = l1a.id;
    console.log(`   ✅ L1A inserito, ID: ${l1aUserId}`);
  }

  // L1B
  let l1bAuthId = await createAuthUser('l1b.test@cdm86.it', 'Luigi', 'UnoB');
  const existingL1B = await restGet('users', { 'email': 'eq.l1b.test@cdm86.it' });
  let l1bUserId;
  if (existingL1B.length > 0) {
    l1bUserId = existingL1B[0].id;
    console.log(`   L1B già esistente, ID: ${l1bUserId}`);
  } else {
    const l1b = await restInsert('users', {
      auth_user_id: l1bAuthId,
      email: 'l1b.test@cdm86.it',
      first_name: 'Luigi',
      last_name: 'UnoB',
      referral_code: 'L1BTEST1',
      points: 0,
      referred_by_id: collabUserId
    });
    l1bUserId = l1b.id;
    console.log(`   ✅ L1B inserito, ID: ${l1bUserId}`);
  }

  // Step 3: Crea utenti L2
  console.log('\n3. Creazione utenti livello 2...');
  
  // L2A
  let l2aAuthId = await createAuthUser('l2a.test@cdm86.it', 'Marco', 'DueA');
  const existingL2A = await restGet('users', { 'email': 'eq.l2a.test@cdm86.it' });
  let l2aUserId;
  if (existingL2A.length > 0) {
    l2aUserId = existingL2A[0].id;
    console.log(`   L2A già esistente, ID: ${l2aUserId}`);
  } else {
    const l2a = await restInsert('users', {
      auth_user_id: l2aAuthId,
      email: 'l2a.test@cdm86.it',
      first_name: 'Marco',
      last_name: 'DueA',
      referral_code: 'L2ATEST1',
      points: 0,
      referred_by_id: l1aUserId
    });
    l2aUserId = l2a.id;
    console.log(`   ✅ L2A inserito, ID: ${l2aUserId}`);
  }

  // L2B
  let l2bAuthId = await createAuthUser('l2b.test@cdm86.it', 'Marco', 'DueB');
  const existingL2B = await restGet('users', { 'email': 'eq.l2b.test@cdm86.it' });
  let l2bUserId;
  if (existingL2B.length > 0) {
    l2bUserId = existingL2B[0].id;
    console.log(`   L2B già esistente, ID: ${l2bUserId}`);
  } else {
    const l2b = await restInsert('users', {
      auth_user_id: l2bAuthId,
      email: 'l2b.test@cdm86.it',
      first_name: 'Marco',
      last_name: 'DueB',
      referral_code: 'L2BTEST1',
      points: 0,
      referred_by_id: l1bUserId
    });
    l2bUserId = l2b.id;
    console.log(`   ✅ L2B inserito, ID: ${l2bUserId}`);
  }

  // Step 4: Crea utenti L3
  console.log('\n4. Creazione utenti livello 3 (quelli che verranno riassegnati)...');
  
  // L3A
  let l3aAuthId = await createAuthUser('l3a.test@cdm86.it', 'Sara', 'TreA');
  const existingL3A = await restGet('users', { 'email': 'eq.l3a.test@cdm86.it' });
  let l3aUserId;
  if (existingL3A.length > 0) {
    l3aUserId = existingL3A[0].id;
    console.log(`   L3A già esistente, ID: ${l3aUserId}`);
  } else {
    const l3a = await restInsert('users', {
      auth_user_id: l3aAuthId,
      email: 'l3a.test@cdm86.it',
      first_name: 'Sara',
      last_name: 'TreA',
      referral_code: 'L3ATEST1',
      points: 0,
      referred_by_id: l2aUserId
    });
    l3aUserId = l3a.id;
    console.log(`   ✅ L3A inserito, ID: ${l3aUserId}`);
  }

  // L3B
  let l3bAuthId = await createAuthUser('l3b.test@cdm86.it', 'Sara', 'TreB');
  const existingL3B = await restGet('users', { 'email': 'eq.l3b.test@cdm86.it' });
  let l3bUserId;
  if (existingL3B.length > 0) {
    l3bUserId = existingL3B[0].id;
    console.log(`   L3B già esistente, ID: ${l3bUserId}`);
  } else {
    const l3b = await restInsert('users', {
      auth_user_id: l3bAuthId,
      email: 'l3b.test@cdm86.it',
      first_name: 'Sara',
      last_name: 'TreB',
      referral_code: 'L3BTEST1',
      points: 0,
      referred_by_id: l2bUserId
    });
    l3bUserId = l3b.id;
    console.log(`   ✅ L3B inserito, ID: ${l3bUserId}`);
  }

  // Step 5: Crea il record collaboratore
  console.log('\n5. Creazione record nella tabella collaborators...');
  const existingCollabRecord = await restGet('collaborators', { 'auth_user_id': `eq.${COLLAB_AUTH_ID}` });
  let collabId;
  if (existingCollabRecord.length > 0) {
    collabId = existingCollabRecord[0].id;
    console.log(`   ✅ Record collaboratore già esistente, ID: ${collabId}`);
  } else {
    const collabRecord = await restInsert('collaborators', {
      auth_user_id: COLLAB_AUTH_ID,
      user_id: collabUserId,
      email: 'collab.test@cdm86.it',
      first_name: 'Carlo',
      last_name: 'Collaboratore',
      referral_code: 'COLLABT1',
      status: 'active',
      rate_user: 10,
      rate_azienda: 10,
      referred_by_id: ADMIN_USER_ID
    });
    collabId = collabRecord.id;
    console.log(`   ✅ Record collaboratore creato, ID: ${collabId}`);
  }

  // Riepilogo finale
  console.log('\n=== RIEPILOGO STRUTTURA MLM ===');
  console.log(`ADMIN (${ADMIN_USER_ID})`);
  console.log(`  └── COLLAB Carlo (user_id: ${collabUserId}, auth: ${COLLAB_AUTH_ID})`);
  console.log(`        ├── L1A Luigi (${l1aUserId})`);
  console.log(`        │     └── L2A Marco (${l2aUserId})`);
  console.log(`        │           └── L3A Sara (${l3aUserId}) ← verrà riassegnata`);
  console.log(`        └── L1B Luigi (${l1bUserId})`);
  console.log(`              └── L2B Marco (${l2bUserId})`);
  console.log(`                    └── L3B Sara (${l3bUserId}) ← verrà riassegnata`);
  console.log(`\nCollaborator record ID: ${collabId}`);
  console.log('\n✅ DATI DI TEST CREATI CON SUCCESSO!');
  console.log('Ora puoi testare "Abbandona Ruolo" dal pannello admin cercando "Carlo Collaboratore"');
}

main().catch(console.error);
