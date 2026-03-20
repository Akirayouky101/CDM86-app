const url = 'https://uchrjlngfzfibcpdxtky.supabase.co';
const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDAzMTIwNiwiZXhwIjoyMDc1NjA3MjA2fQ.lK0csqtGl2zREC3YsHLfQ_gt4XUAQTQr3bx0CXt96L0';
const h = { 'apikey': key, 'Authorization': `Bearer ${key}`, 'Content-Type': 'application/json', 'Prefer': 'return=representation' };

async function main() {
  const L1B = '7221b9ef-c7e9-4ab6-9c18-2c9089cd8321';
  const COLLAB = '965c1668-5e19-481b-bcf2-f6a79a936c47';

  // Prova direttamente il PATCH
  const r = await fetch(`${url}/rest/v1/users?id=eq.${L1B}`, {
    method: 'PATCH', headers: h,
    body: JSON.stringify({ referred_by_id: COLLAB })
  });
  console.log('PATCH L1B→collab:', r.status, (await r.text()).slice(0, 200));
}
main().catch(console.error);
