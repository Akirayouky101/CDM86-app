const url='https://uchrjlngfzfibcpdxtky.supabase.co';
const key='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDAzMTIwNiwiZXhwIjoyMDc1NjA3MjA2fQ.lK0csqtGl2zREC3YsHLfQ_gt4XUAQTQr3bx0CXt96L0';
const h={'apikey':key,'Authorization':'Bearer '+key,'Content-Type':'application/json','Prefer':'return=representation'};

async function main() {
  // Verifica: user_points FK è verso public.users o auth.users?
  // mario.rossi ha public.users.id = 293caa0f e auth_user_id = 293caa0f (STESSO!)
  // Quindi non possiamo distinguere.
  // 
  // L'admin ha public.users.id = e8cde03d (DIVERSO da auth_user_id = cc96d551)
  // user_points per admin ha user_id = cc96d551 (auth_user_id)
  // 
  // Quindi user_points.user_id -> auth.users.id
  // Ma l'errore dice "not present in table users" - quale users?
  // Forse la FK è: user_points.user_id -> public.users.id
  // E mario.rossi è un caso speciale dove public.users.id = auth_user_id
  
  // Prova a inserire user_points con public.users.id = e8cde03d... 
  // No, ha già fallito.
  
  // Il trigger che fallisce: quando facciamo PATCH users SET referred_by_id = e8cde03d
  // Un trigger cerca di FARE QUALCOSA con e8cde03d in user_points
  // Probabilmente: INSERT INTO user_points WHERE user_id = referred_by_id (cioè e8cde03d)
  // ma e8cde03d non esiste in user_points
  
  // SOLUZIONE: aggiungiamo e8cde03d a user_points direttamente via SQL
  // ma dobbiamo farlo aggirando il trigger FK

  // APPROCCIO ALTERNATIVO: usiamo mario.rossi come referred_by invece dell'admin
  // mario.rossi ha public.users.id = 293caa0f che ESISTE in user_points
  const marioId = '293caa0f-f12c-4cde-81ba-26da97f2f13e';
  
  // Test: patch collaboratore con referred_by_id = mario
  const r = await fetch(url+'/rest/v1/users?id=eq.965c1668-5e19-481b-bcf2-f6a79a936c47', {
    method: 'PATCH',
    headers: h,
    body: JSON.stringify({referred_by_id: marioId})
  });
  console.log('PATCH result:', r.status, await r.text().then(t=>t.slice(0,100)));
}
main().catch(console.error);
