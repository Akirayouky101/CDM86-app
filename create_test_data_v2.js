// Script per creare dati di test "Abbandona Ruolo" usando Admin Auth API
// Il trigger handle_new_user creerà automaticamente i record in public.users
const SUPABASE_URL = 'https://uchrjlngfzfibcpdxtky.supabase.co';
const SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDAzMTIwNiwiZXhwIjoyMDc1NjA3MjA2fQ.lK0csqtGl2zREC3YsHLfQ_gt4XUAQTQr3bx0CXt96L0';

const ADMIN_USER_ID = 'e8cde03d-2aa6-4ea6-a29f-43f290ae00ce';
const COLLAB_AUTH_ID = '5322ca68-6d8d-446c-aca3-de15e589e9c8';

const authHeaders = {
  'apikey': SERVICE_KEY,
  'Authorization': `Bearer ${SERVICE_KEY}`,
  'Content-Type': 'application/json'
};

const restHeaders = {
  ...authHeaders,
  'Prefer': 'return=representation'
};

// Crea utente tramite Admin Auth API (attiva il trigger handle_new_user)
async function createAuthUser(email, firstName, lastName, metadata = {}) {
  const res = await fetch(`${SUPABASE_URL}/auth/v1/admin/users`, {
    method: 'POST',
    headers: authHeaders,
    body: JSON.stringify({
      email,
      password: 'Test1234!',
      email_confirm: true,
      user_metadata: { first_name: firstName, last_name: lastName, account_type: 'user', ...metadata }
    })
  });
  const data = await res.json();
  if (!res.ok) {
    if (data.message && (data.message.includes('already') || data.msg && data.msg.includes('already'))) {
      console.log(`  ⚠️  Auth user ${email} già esiste, cercando...`);
      return await getAuthUserByEmail(email);
    }
    console.error(`  ❌ Errore creazione auth user ${email}:`, JSON.stringify(data));
    return null;
  }
  return data.id;
}

async function getAuthUserByEmail(email) {
  const res = await fetch(`${SUPABASE_URL}/auth/v1/admin/users?email=${encodeURIComponent(email)}&per_page=1`, {
    headers: authHeaders
  });
  const data = await res.json();
  if (data.users && data.users.length > 0) return data.users[0].id;
  return null;
}

// Attendi che il trigger handle_new_user crei il record in public.users
async function waitForPublicUser(authId, maxMs = 5000) {
  const start = Date.now();
  while (Date.now() - start < maxMs) {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/users?auth_user_id=eq.${authId}&select=id`, {
      headers: authHeaders
    });
    const rows = await res.json();
    if (rows.length > 0) return rows[0].id;
    await new Promise(r => setTimeout(r, 300));
  }
  return null;
}

// Aggiorna referred_by_id di un utente
async function updateReferredBy(userId, referredById) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/users?id=eq.${userId}`, {
    method: 'PATCH',
    headers: restHeaders,
    body: JSON.stringify({ referred_by_id: referredById })
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`PATCH users ${userId} failed: ${res.status} ${text}`);
  }
}

async function restGet(table, filter) {
  const params = filter ? '?' + new URLSearchParams(filter) : '';
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}${params}`, { headers: authHeaders });
  const text = await res.text();
  if (!res.ok) throw new Error(`GET ${table} failed: ${res.status} ${text}`);
  return JSON.parse(text);
}

async function restInsert(table, data) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}`, {
    method: 'POST',
    headers: restHeaders,
    body: JSON.stringify(data)
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`INSERT into ${table} failed: ${res.status} ${text}`);
  const rows = JSON.parse(text);
  return Array.isArray(rows) ? rows[0] : rows;
}

async function main() {
  console.log('=== CREAZIONE DATI DI TEST "ABBANDONA RUOLO" ===\n');
  console.log('Strategia: creo utenti via Admin Auth API → il trigger li inserisce in public.users');
  console.log('Poi aggiorno referred_by_id con PATCH\n');

  // ── Step 1: Verifica collaboratore in public.users ──
  console.log('1. Verifica collaboratore (già creato via Auth API)...');
  let collabUserId = await waitForPublicUser(COLLAB_AUTH_ID, 2000);
  
  if (!collabUserId) {
    // Il trigger non lo ha creato (perché metadata aveva account_type=collaborator)
    // Dobbiamo aggiornare il suo auth metadata e ri-triggerare, oppure inserire direttamente
    console.log('   Il trigger non ha creato il record (account_type=collaborator). Aggiorno auth metadata...');
    const updateRes = await fetch(`${SUPABASE_URL}/auth/v1/admin/users/${COLLAB_AUTH_ID}`, {
      method: 'PUT',
      headers: authHeaders,
      body: JSON.stringify({
        user_metadata: { account_type: 'collaborator', first_name: 'Carlo', last_name: 'Collaboratore' }
      })
    });
    if (!updateRes.ok) {
      console.error('Errore aggiornamento metadata:', await updateRes.text());
    }
    
    // Inserisci direttamente in public.users SENZA referred_by_id (evita trigger user_points)
    const res = await fetch(`${SUPABASE_URL}/rest/v1/users`, {
      method: 'POST',
      headers: {
        ...restHeaders,
        'Prefer': 'return=representation,resolution=ignore-duplicates'
      },
      body: JSON.stringify({
        auth_user_id: COLLAB_AUTH_ID,
        email: 'collab.test@cdm86.it',
        first_name: 'Carlo',
        last_name: 'Collaboratore',
        referral_code: 'COLLABT1',
        points: 0,
        is_collaborator: true,
        collaborator_status: 'active',
        account_type: 'collaborator'
      })
    });
    const text = await res.text();
    if (!res.ok) {
      console.error('   ❌ Insert fallito:', text);
      return;
    }
    const rows = JSON.parse(text);
    collabUserId = rows.length > 0 ? rows[0].id : null;
    if (!collabUserId) {
      // Riprova a leggere
      collabUserId = await waitForPublicUser(COLLAB_AUTH_ID, 2000);
    }
  }
  
  if (!collabUserId) {
    console.error('   ❌ Impossibile ottenere user_id del collaboratore!');
    return;
  }
  console.log(`   ✅ Collaboratore in public.users: ${collabUserId}`);

  // Aggiorna referred_by_id del collaboratore se necessario
  const collabData = await restGet('users', { 'id': `eq.${collabUserId}`, 'select': 'referred_by_id' });
  if (collabData[0]?.referred_by_id !== ADMIN_USER_ID) {
    await updateReferredBy(collabUserId, ADMIN_USER_ID);
    console.log('   ✅ referred_by_id aggiornato → admin');
  }

  // ── Step 2: Crea L1A ──
  console.log('\n2. Creazione L1A (Luigi UnoA)...');
  const existingL1A = await restGet('users', { 'email': 'eq.l1a.test@cdm86.it', 'select': 'id' });
  let l1aUserId;
  if (existingL1A.length > 0) {
    l1aUserId = existingL1A[0].id;
    console.log(`   ✅ Già esiste: ${l1aUserId}`);
  } else {
    const l1aAuthId = await createAuthUser('l1a.test@cdm86.it', 'Luigi', 'UnoA');
    if (!l1aAuthId) return;
    l1aUserId = await waitForPublicUser(l1aAuthId);
    if (!l1aUserId) { console.error('   ❌ Timeout!'); return; }
    await updateReferredBy(l1aUserId, collabUserId);
    console.log(`   ✅ Creato: ${l1aUserId}`);
  }

  // ── Step 3: Crea L1B ──
  console.log('\n3. Creazione L1B (Luigi UnoB)...');
  const existingL1B = await restGet('users', { 'email': 'eq.l1b.test@cdm86.it', 'select': 'id' });
  let l1bUserId;
  if (existingL1B.length > 0) {
    l1bUserId = existingL1B[0].id;
    console.log(`   ✅ Già esiste: ${l1bUserId}`);
  } else {
    const l1bAuthId = await createAuthUser('l1b.test@cdm86.it', 'Luigi', 'UnoB');
    if (!l1bAuthId) return;
    l1bUserId = await waitForPublicUser(l1bAuthId);
    if (!l1bUserId) { console.error('   ❌ Timeout!'); return; }
    await updateReferredBy(l1bUserId, collabUserId);
    console.log(`   ✅ Creato: ${l1bUserId}`);
  }

  // ── Step 4: Crea L2A ──
  console.log('\n4. Creazione L2A (Marco DueA)...');
  const existingL2A = await restGet('users', { 'email': 'eq.l2a.test@cdm86.it', 'select': 'id' });
  let l2aUserId;
  if (existingL2A.length > 0) {
    l2aUserId = existingL2A[0].id;
    console.log(`   ✅ Già esiste: ${l2aUserId}`);
  } else {
    const l2aAuthId = await createAuthUser('l2a.test@cdm86.it', 'Marco', 'DueA');
    if (!l2aAuthId) return;
    l2aUserId = await waitForPublicUser(l2aAuthId);
    if (!l2aUserId) { console.error('   ❌ Timeout!'); return; }
    await updateReferredBy(l2aUserId, l1aUserId);
    console.log(`   ✅ Creato: ${l2aUserId}`);
  }

  // ── Step 5: Crea L2B ──
  console.log('\n5. Creazione L2B (Marco DueB)...');
  const existingL2B = await restGet('users', { 'email': 'eq.l2b.test@cdm86.it', 'select': 'id' });
  let l2bUserId;
  if (existingL2B.length > 0) {
    l2bUserId = existingL2B[0].id;
    console.log(`   ✅ Già esiste: ${l2bUserId}`);
  } else {
    const l2bAuthId = await createAuthUser('l2b.test@cdm86.it', 'Marco', 'DueB');
    if (!l2bAuthId) return;
    l2bUserId = await waitForPublicUser(l2bAuthId);
    if (!l2bUserId) { console.error('   ❌ Timeout!'); return; }
    await updateReferredBy(l2bUserId, l1bUserId);
    console.log(`   ✅ Creato: ${l2bUserId}`);
  }

  // ── Step 6: Crea L3A ──
  console.log('\n6. Creazione L3A (Sara TreA)...');
  const existingL3A = await restGet('users', { 'email': 'eq.l3a.test@cdm86.it', 'select': 'id' });
  let l3aUserId;
  if (existingL3A.length > 0) {
    l3aUserId = existingL3A[0].id;
    console.log(`   ✅ Già esiste: ${l3aUserId}`);
  } else {
    const l3aAuthId = await createAuthUser('l3a.test@cdm86.it', 'Sara', 'TreA');
    if (!l3aAuthId) return;
    l3aUserId = await waitForPublicUser(l3aAuthId);
    if (!l3aUserId) { console.error('   ❌ Timeout!'); return; }
    await updateReferredBy(l3aUserId, l2aUserId);
    console.log(`   ✅ Creato: ${l3aUserId}`);
  }

  // ── Step 7: Crea L3B ──
  console.log('\n7. Creazione L3B (Sara TreB)...');
  const existingL3B = await restGet('users', { 'email': 'eq.l3b.test@cdm86.it', 'select': 'id' });
  let l3bUserId;
  if (existingL3B.length > 0) {
    l3bUserId = existingL3B[0].id;
    console.log(`   ✅ Già esiste: ${l3bUserId}`);
  } else {
    const l3bAuthId = await createAuthUser('l3b.test@cdm86.it', 'Sara', 'TreB');
    if (!l3bAuthId) return;
    l3bUserId = await waitForPublicUser(l3bAuthId);
    if (!l3bUserId) { console.error('   ❌ Timeout!'); return; }
    await updateReferredBy(l3bUserId, l2bUserId);
    console.log(`   ✅ Creato: ${l3bUserId}`);
  }

  // ── Step 8: Crea record collaborator ──
  console.log('\n8. Creazione record nella tabella collaborators...');
  const existingCollabRecord = await restGet('collaborators', { 'auth_user_id': `eq.${COLLAB_AUTH_ID}` });
  let collabRecordId;
  if (existingCollabRecord.length > 0) {
    collabRecordId = existingCollabRecord[0].id;
    console.log(`   ✅ Già esiste: ${collabRecordId}`);
    // Assicurati che user_id sia collegato
    if (!existingCollabRecord[0].user_id) {
      await fetch(`${SUPABASE_URL}/rest/v1/collaborators?id=eq.${collabRecordId}`, {
        method: 'PATCH',
        headers: restHeaders,
        body: JSON.stringify({ user_id: collabUserId })
      });
      console.log('   ✅ user_id collegato al record collaboratore');
    }
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
    collabRecordId = collabRecord.id;
    console.log(`   ✅ Creato: ${collabRecordId}`);
  }

  // ── Aggiorna is_collaborator in public.users ──
  await fetch(`${SUPABASE_URL}/rest/v1/users?id=eq.${collabUserId}`, {
    method: 'PATCH',
    headers: restHeaders,
    body: JSON.stringify({ is_collaborator: true, collaborator_status: 'active', account_type: 'collaborator' })
  });

  // ── Riepilogo ──
  console.log('\n══════════════════════════════════════════');
  console.log('  STRUTTURA MLM CREATA:');
  console.log('══════════════════════════════════════════');
  console.log(`ADMIN (${ADMIN_USER_ID})`);
  console.log(`  └── COLLAB Carlo (user: ${collabUserId})`);
  console.log(`        ├── L1A Luigi (${l1aUserId})`);
  console.log(`        │     └── L2A Marco (${l2aUserId})`);
  console.log(`        │           └── L3A Sara (${l3aUserId}) ← sarà riassegnata`);
  console.log(`        └── L1B Luigi (${l1bUserId})`);
  console.log(`              └── L2B Marco (${l2bUserId})`);
  console.log(`                    └── L3B Sara (${l3bUserId}) ← sarà riassegnata`);
  console.log(`\n  Collaborator record: ${collabRecordId}`);
  console.log('\n✅ TUTTO PRONTO! Vai nel pannello admin e cerca "Carlo Collaboratore"');
  console.log('   Clicca su "🚪 Abbandona Ruolo" per testare la funzione.');
}

main().catch(console.error);
