// Script diagnostico per capire la struttura di public.users
const SUPABASE_URL = 'https://uchrjlngfzfibcpdxtky.supabase.co';
const SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDAzMTIwNiwiZXhwIjoyMDc1NjA3MjA2fQ.lK0csqtGl2zREC3YsHLfQ_gt4XUAQTQr3bx0CXt96L0';

const headers = {
  'apikey': SERVICE_KEY,
  'Authorization': `Bearer ${SERVICE_KEY}`,
  'Content-Type': 'application/json'
};

async function restGet(table, filter) {
  const params = filter ? '?' + new URLSearchParams(filter) : '';
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}${params}`, { headers });
  const text = await res.text();
  if (!res.ok) throw new Error(`GET ${table} failed: ${res.status} ${text}`);
  return JSON.parse(text);
}

async function main() {
  // Controlla struttura della tabella users - guarda un record esistente
  console.log('=== STRUTTURA TABELLA users ===');
  const sample = await restGet('users', { 'limit': '1' });
  if (sample.length > 0) {
    console.log('Colonne:', Object.keys(sample[0]));
    console.log('Sample record:', JSON.stringify(sample[0], null, 2));
  } else {
    console.log('Tabella users vuota!');
  }

  // Cerca l'admin
  console.log('\n=== ADMIN USER ===');
  const admin = await restGet('users', { 'id': 'eq.e8cde03d-2aa6-4ea6-a29f-43f290ae00ce' });
  console.log(admin.length > 0 ? JSON.stringify(admin[0], null, 2) : 'Admin NON trovato in public.users!');

  // Cerca collaborators table
  console.log('\n=== STRUTTURA COLLABORATORS ===');
  const collab = await restGet('collaborators', { 'limit': '1' });
  if (collab.length > 0) {
    console.log('Colonne:', Object.keys(collab[0]));
  } else {
    console.log('Tabella collaborators vuota');
  }
}

main().catch(console.error);
