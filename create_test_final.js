const SUPABASE_URL = 'https://uchrjlngfzfibcpdxtky.supabase.co';
const SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDAzMTIwNiwiZXhwIjoyMDc1NjA3MjA2fQ.lK0csqtGl2zREC3YsHLfQ_gt4XUAQTQr3bx0CXt96L0';
const ADMIN_USER_ID = 'e8cde03d-2aa6-4ea6-a29f-43f290ae00ce';
const COLLAB_AUTH_ID = '5322ca68-6d8d-446c-aca3-de15e589e9c8';
const COLLAB_USER_ID = '965c1668-5e19-481b-bcf2-f6a79a936c47'; // già esiste

const h = {
  'apikey': SERVICE_KEY,
  'Authorization': `Bearer ${SERVICE_KEY}`,
  'Content-Type': 'application/json',
  'Prefer': 'return=representation'
};

const get = async (t, f) => {
  const params = f ? '?' + new URLSearchParams(f) : '';
  const r = await fetch(`${SUPABASE_URL}/rest/v1/${t}${params}`, { headers: h });
  const tx = await r.text();
  if (!r.ok) throw new Error(`GET ${t}: ${tx}`);
  return JSON.parse(tx);
};

const patch = async (t, filter, d) => {
  const r = await fetch(`${SUPABASE_URL}/rest/v1/${t}?${filter}`, {
    method: 'PATCH', headers: h, body: JSON.stringify(d)
  });
  if (!r.ok) throw new Error(`PATCH ${t}: ${await r.text()}`);
  return await r.json();
};

const ins = async (t, d) => {
  const r = await fetch(`${SUPABASE_URL}/rest/v1/${t}`, {
    method: 'POST', headers: h, body: JSON.stringify(d)
  });
  const tx = await r.text();
  if (!r.ok) throw new Error(`INSERT ${t}: ${tx}`);
  const rows = JSON.parse(tx);
  return Array.isArray(rows) ? rows[0] : rows;
};

const createAuth = async (email, fn, ln, referredById = null) => {
  const meta = { first_name: fn, last_name: ln, account_type: 'user' };
  if (referredById) meta.referred_by_id = referredById;
  const r = await fetch(`${SUPABASE_URL}/auth/v1/admin/users`, {
    method: 'POST', headers: h,
    body: JSON.stringify({ email, password: 'Test1234!', email_confirm: true, user_metadata: meta })
  });
  const d = await r.json();
  if (!r.ok) {
    if (d.code === 'email_exists' || (d.msg && d.msg.includes('already')) || (d.message && d.message.includes('already'))) {
      console.log(`  ⚠️  ${email} auth già esiste`);
      // Cerca per email nella lista admin
      const lr = await fetch(`${SUPABASE_URL}/auth/v1/admin/users?page=1&per_page=200`, { headers: h });
      const ld = await lr.json();
      const found = (ld.users || []).find(u => u.email === email);
      return found?.id || null;
    }
    throw new Error(`Auth ${email}: ${JSON.stringify(d)}`);
  }
  return d.id;
};

const waitUser = async (authId) => {
  for (let i = 0; i < 15; i++) {
    const rows = await get('users', { 'auth_user_id': `eq.${authId}`, 'select': 'id' });
    if (rows.length > 0) return rows[0].id;
    await new Promise(r => setTimeout(r, 500));
  }
  return null;
};

// Crea o trova utente con referred_by = referredById
async function getOrCreate(email, fn, ln, referredById) {
  const ex = await get('users', { 'email': `eq.${email}`, 'select': 'id,referred_by_id' });
  if (ex.length > 0) {
    const uid = ex[0].id;
    if (ex[0].referred_by_id !== referredById) {
      await patch('users', `id=eq.${uid}`, { referred_by_id: referredById });
      console.log(`  ✅ already (updated ref→${referredById?.slice(0,8)}): ${uid}`);
    } else {
      console.log(`  ✅ already: ${uid}`);
    }
    return uid;
  }
  // Crea SENZA referred_by_id nei metadata (evita bug trigger user_points)
  const authId = await createAuth(email, fn, ln);
  if (!authId) throw new Error(`no authId for ${email}`);
  // Aspetta che handle_new_user crei il record in public.users
  const uid = await waitUser(authId);
  if (!uid) {
    // Se il record non è stato creato, prova a crearlo direttamente
    console.log(`  ⚠️  Timeout waiting for public user ${email}, creating directly...`);
    const ins_r = await fetch(`${SUPABASE_URL}/rest/v1/users`, {
      method: 'POST', headers: h,
      body: JSON.stringify({
        auth_user_id: authId, email, first_name: fn, last_name: ln,
        referral_code: fn.toUpperCase().slice(0,4) + ln.toUpperCase().slice(0,4),
        points: 0
      })
    });
    const ins_t = await ins_r.text();
    if (!ins_r.ok) throw new Error(`Direct insert ${email}: ${ins_t}`);
    const ins_rows = JSON.parse(ins_t);
    const newUid = (Array.isArray(ins_rows) ? ins_rows[0] : ins_rows)?.id;
    if (!newUid) throw new Error(`No ID from direct insert ${email}`);
    await patch('users', `id=eq.${newUid}`, { referred_by_id: referredById });
    console.log(`  ✅ direct-created: ${newUid} ref→${referredById?.slice(0,8)}`);
    return newUid;
  }
  // Poi PATCH referred_by_id
  await patch('users', `id=eq.${uid}`, { referred_by_id: referredById });
  console.log(`  ✅ created: ${uid} ref→${referredById?.slice(0,8)}`);
  return uid;
}

async function main() {
  console.log('=== TEST DATA v3 ===\n');

  // 1. Verifica collaboratore
  console.log(`1. Collaboratore già esiste: ${COLLAB_USER_ID}`);
  // Assicura che collaborator_status sia attivo
  await patch('users', `id=eq.${COLLAB_USER_ID}`, { is_collaborator: true, collaborator_status: 'active', account_type: 'collaborator' });
  console.log('   Aggiornato is_collaborator, status, account_type');
  
  // Assicura user_points per il collaboratore
  const existingCollabPoints = await get('user_points', { 'user_id': `eq.${COLLAB_USER_ID}` });
  if (existingCollabPoints.length === 0) {
    try {
      await ins('user_points', { user_id: COLLAB_USER_ID, points_total: 0, points_used: 0, points_available: 0, referrals_count: 0, approved_reports_count: 0, rejected_reports_count: 0, level: 'bronze' });
      console.log('   user_points creato per collaboratore');
    } catch(e) {
      console.log('   user_points skip:', e.message.slice(0,80));
    }
  } else {
    console.log('   user_points già esiste');
  }

  // 2-7. Crea utenti L1, L2, L3
  console.log('\n2. L1A (Luigi UnoA)...');
  const l1a = await getOrCreate('l1a.test@cdm86.it', 'Luigi', 'UnoA', COLLAB_USER_ID);

  console.log('\n3. L1B (Luigi UnoB)...');
  const l1b = await getOrCreate('l1b.test@cdm86.it', 'Luigi', 'UnoB', COLLAB_USER_ID);

  console.log('\n4. L2A (Marco DueA)...');
  const l2a = await getOrCreate('l2a.test@cdm86.it', 'Marco', 'DueA', l1a);

  console.log('\n5. L2B (Marco DueB)...');
  const l2b = await getOrCreate('l2b.test@cdm86.it', 'Marco', 'DueB', l1b);

  console.log('\n6. L3A (Sara TreA) ← verrà riassegnata...');
  const l3a = await getOrCreate('l3a.test@cdm86.it', 'Sara', 'TreA', l2a);

  console.log('\n7. L3B (Sara TreB) ← verrà riassegnata...');
  const l3b = await getOrCreate('l3b.test@cdm86.it', 'Sara', 'TreB', l2b);

  // 8. Record collaborator
  console.log('\n8. Record collaborators...');
  const exCR = await get('collaborators', { 'auth_user_id': `eq.${COLLAB_AUTH_ID}` });
  let crId;
  if (exCR.length > 0) {
    crId = exCR[0].id;
    console.log(`  ✅ already: ${crId}`);
    if (!exCR[0].user_id) {
      await patch('collaborators', `id=eq.${crId}`, { user_id: COLLAB_USER_ID });
    }
  } else {
    const cr = await ins('collaborators', {
      auth_user_id: COLLAB_AUTH_ID,
      user_id: COLLAB_USER_ID,
      email: 'collab.test@cdm86.it',
      first_name: 'Carlo',
      last_name: 'Collaboratore',
      referral_code: 'COLLABT1',
      status: 'active',
      rate_user: 10,
      rate_azienda: 10,
      referred_by_id: ADMIN_USER_ID
    });
    crId = cr.id;
    console.log(`  ✅ created: ${crId}`);
  }

  // Verifica struttura
  console.log('\n=== VERIFICA STRUTTURA ===');
  const collab = await get('users', { 'id': `eq.${COLLAB_USER_ID}`, 'select': 'id,email,referred_by_id,is_collaborator' });
  const l1aData = await get('users', { 'id': `eq.${l1a}`, 'select': 'id,email,referred_by_id' });
  const l2aData = await get('users', { 'id': `eq.${l2a}`, 'select': 'id,email,referred_by_id' });
  const l3aData = await get('users', { 'id': `eq.${l3a}`, 'select': 'id,email,referred_by_id' });
  
  console.log('COLLAB:', JSON.stringify(collab[0]));
  console.log('L1A:   ', JSON.stringify(l1aData[0]));
  console.log('L2A:   ', JSON.stringify(l2aData[0]));
  console.log('L3A:   ', JSON.stringify(l3aData[0]));

  console.log('\n══════════════════════════════════════');
  console.log('  STRUTTURA MLM:');
  console.log(`  COLLAB (${COLLAB_USER_ID})`);
  console.log(`    ├─ L1A (${l1a})`);
  console.log(`    │   └─ L2A (${l2a})`);
  console.log(`    │       └─ L3A (${l3a}) ← riassegnata`);
  console.log(`    └─ L1B (${l1b})`);
  console.log(`        └─ L2B (${l2b})`);
  console.log(`            └─ L3B (${l3b}) ← riassegnata`);
  console.log(`\n  collaborators.id: ${crId}`);
  console.log('\n✅ Vai nel pannello admin → Collaboratori → cerca "Carlo" → Abbandona Ruolo');
}

main().catch(console.error);
