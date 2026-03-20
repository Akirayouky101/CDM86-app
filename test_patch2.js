const url = 'https://uchrjlngfzfibcpdxtky.supabase.co';
const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDAzMTIwNiwiZXhwIjoyMDc1NjA3MjA2fQ.lK0csqtGl2zREC3YsHLfQ_gt4XUAQTQr3bx0CXt96L0';
const h = { 'apikey': key, 'Authorization': `Bearer ${key}`, 'Content-Type': 'application/json', 'Prefer': 'return=representation' };

// mario.rossi.id = 293caa0f (questo ha public.users.id = auth_user_id, quindi user_points funziona)
const MARIO_ID = '293caa0f-f12c-4cde-81ba-26da97f2f13e';
// L1A = edcf8db3
const L1A_ID = 'edcf8db3-7ec9-41b6-b4e6-1f6a31d3eb26';

async function main() {
  // test1: PATCH L1A con referred_by = mario (ha user_points)
  const r = await fetch(url + '/rest/v1/users?id=eq.' + L1A_ID, {
    method: 'PATCH', headers: h,
    body: JSON.stringify({ referred_by_id: MARIO_ID })
  });
  console.log('PATCH L1A→mario:', r.status, (await r.text()).slice(0, 100));
  
  // test2: Prova PATCH con referred_by = collaboratore (965c1668 - non ha user_points con quel id)
  const r2 = await fetch(url + '/rest/v1/users?id=eq.' + L1A_ID, {
    method: 'PATCH', headers: h,
    body: JSON.stringify({ referred_by_id: '965c1668-5e19-481b-bcf2-f6a79a936c47' })
  });
  console.log('PATCH L1A→collab:', r2.status, (await r2.text()).slice(0, 150));
}
main().catch(console.error);
