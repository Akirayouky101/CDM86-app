const url = 'https://uchrjlngfzfibcpdxtky.supabase.co';
const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDAzMTIwNiwiZXhwIjoyMDc1NjA3MjA2fQ.lK0csqtGl2zREC3YsHLfQ_gt4XUAQTQr3bx0CXt96L0';
const h = { 'apikey': key, 'Authorization': `Bearer ${key}`, 'Content-Type': 'application/json', 'Prefer': 'return=representation' };

async function main() {
  const get = async (t, f) => {
    const r = await fetch(url + '/rest/v1/' + t + (f ? '?' + new URLSearchParams(f) : ''), { headers: h });
    return await r.json();
  };

  const L1A = 'edcf8db3-7ec9-41b6-b4e6-1f6a31d3eb26';
  const COLLAB = '965c1668-5e19-481b-bcf2-f6a79a936c47';
  const COLLAB_AUTH = '5322ca68-6d8d-446c-aca3-de15e589e9c8';

  const l1a = await get('users', { 'id': `eq.${L1A}`, 'select': 'id,email,referred_by_id,auth_user_id' });
  console.log('L1A:', JSON.stringify(l1a[0]));

  const l1aPoints = await get('user_points', { 'user_id': `eq.${L1A}` });
  console.log('L1A user_points (by public id):', l1aPoints);
  
  const l1aAuth = l1a[0]?.auth_user_id;
  const l1aPointsByAuth = await get('user_points', { 'user_id': `eq.${l1aAuth}` });
  console.log('L1A user_points (by auth id):', l1aPointsByAuth.length > 0 ? 'EXISTS' : 'NONE');

  const collabPoints = await get('user_points', { 'user_id': `eq.${COLLAB}` });
  console.log('COLLAB user_points (by public id):', collabPoints);
  
  const collabPointsByAuth = await get('user_points', { 'user_id': `eq.${COLLAB_AUTH}` });
  console.log('COLLAB user_points (by auth id):', collabPointsByAuth.length > 0 ? 'EXISTS, id:' + collabPointsByAuth[0].user_id : 'NONE');

  // Ora capire perché il PATCH L1A→collab funzionava ma L1B→collab fallisce
  // L1B è stato appena creato - verifica stato
  const l1b = await get('users', { 'email': 'eq.l1b.test@cdm86.it', 'select': 'id,email,referred_by_id,auth_user_id' });
  console.log('\nL1B:', JSON.stringify(l1b[0]));
  if (l1b.length > 0) {
    const l1bPointsByPub = await get('user_points', { 'user_id': `eq.${l1b[0].id}` });
    const l1bPointsByAuth = await get('user_points', { 'user_id': `eq.${l1b[0].auth_user_id}` });
    console.log('L1B user_points (pub):', l1bPointsByPub);
    console.log('L1B user_points (auth):', l1bPointsByAuth.length > 0 ? 'EXISTS' : 'NONE');
  }
}
main().catch(console.error);
