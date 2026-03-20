// Diagnosi tabella user_points e trigger
const SUPABASE_URL = 'https://uchrjlngfzfibcpdxtky.supabase.co';
const SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDAzMTIwNiwiZXhwIjoyMDc1NjA3MjA2fQ.lK0csqtGl2zREC3YsHLfQ_gt4XUAQTQr3bx0CXt96L0';

const headers = {
  'apikey': SERVICE_KEY,
  'Authorization': `Bearer ${SERVICE_KEY}`,
  'Content-Type': 'application/json'
};

async function main() {
  // Struttura user_points
  const res = await fetch(`${SUPABASE_URL}/rest/v1/user_points?limit=2`, { headers });
  const data = await res.json();
  console.log('=== user_points sample ===');
  if (data.length > 0) {
    console.log('Colonne:', Object.keys(data[0]));
    console.log('Record:', JSON.stringify(data[0], null, 2));
  } else {
    console.log('Tabella vuota');
    // Prova con una query sul primo utente
    const usersRes = await fetch(`${SUPABASE_URL}/rest/v1/users?limit=1&select=id,email`, { headers });
    const users = await usersRes.json();
    if (users.length > 0) {
      const upRes = await fetch(`${SUPABASE_URL}/rest/v1/user_points?user_id=eq.${users[0].id}`, { headers });
      const up = await upRes.json();
      console.log(`user_points per ${users[0].email}:`, up);
    }
  }

  // Prova insert in user_points per admin
  console.log('\n=== Provo insert user_points per admin ===');
  const adminId = 'e8cde03d-2aa6-4ea6-a29f-43f290ae00ce';
  const checkRes = await fetch(`${SUPABASE_URL}/rest/v1/user_points?user_id=eq.${adminId}`, { headers });
  const existing = await checkRes.json();
  console.log('user_points admin esistenti:', existing);
}

main().catch(console.error);
