const url = 'https://uchrjlngfzfibcpdxtky.supabase.co';
const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDAzMTIwNiwiZXhwIjoyMDc1NjA3MjA2fQ.lK0csqtGl2zREC3YsHLfQ_gt4XUAQTQr3bx0CXt96L0';
const h = { 'apikey': key, 'Authorization': `Bearer ${key}`, 'Content-Type': 'application/json', 'Prefer': 'return=representation' };

async function main() {
  // user_points.user_id sembra essere auth.users.id
  // Prova con auth_user_id del collaboratore (5322ca68)
  const r = await fetch(url+'/rest/v1/user_points', {
    method: 'POST',
    headers: h,
    body: JSON.stringify({
      user_id: '5322ca68-6d8d-446c-aca3-de15e589e9c8', // auth_user_id
      points_total: 0, points_used: 0, points_available: 0,
      referrals_count: 0, approved_reports_count: 0, rejected_reports_count: 0, level: 'bronze'
    })
  });
  const t = await r.text();
  console.log('user_points with auth_user_id:', r.status, t.slice(0, 150));
}
main().catch(console.error);
