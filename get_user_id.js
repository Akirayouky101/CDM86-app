const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://fzqfcehkhyldkfmcizux.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ6cWZjZWhraHlsZGtmbWNpenV4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzMzMTkwNDEsImV4cCI6MjA0ODg5NTA0MX0.Sg0mG6xB4Mz2-4P_6DgB6bDSrWZuGh0_nEy7XVx9r6c';
const supabase = createClient(supabaseUrl, supabaseKey);

async function getAdminUser() {
  const { data, error } = await supabase
    .from('users')
    .select('id, email')
    .limit(1)
    .single();
  
  if (error) {
    console.log('Error:', error);
  } else {
    console.log('User ID:', data.id);
    console.log('Email:', data.email);
  }
  process.exit(0);
}

getAdminUser();
