// CDM86 — Capacitor App Config
// Questo file viene caricato da tutte le pagine nell'app/

const SUPABASE_URL = 'https://uchrjlngfzfibcpdxtky.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE5NzMzMzUsImV4cCI6MjA1NzU0OTMzNX0.y7PoGMTBpIwFMGFhhJn9nBcMwR2tsOzuCeFl1rkMpyA';

// Crea il client globale Supabase
window.supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Helper: controlla sessione — se non loggato redirect a login
window.requireAuth = async function(redirectPath = '../login.html') {
    const { data: { session } } = await window.supabaseClient.auth.getSession();
    if (!session) {
        window.location.href = redirectPath;
        return null;
    }
    return session;
};

// Helper: logout
window.doLogout = async function() {
    await window.supabaseClient.auth.signOut();
    window.location.href = '../login.html';
};
