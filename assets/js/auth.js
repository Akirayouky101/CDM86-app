// auth.js - Supabase Authentication
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

// Carica config
const SUPABASE_URL = window.SUPABASE_URL || window.CDM86_CONFIG?.supabase?.url;
const SUPABASE_KEY = window.SUPABASE_KEY || window.CDM86_CONFIG?.supabase?.anonKey;

if (!SUPABASE_URL || !SUPABASE_KEY) {
    console.error('❌ Supabase credentials missing!');
}

// Inizializza Supabase client
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// Export per uso globale
window.supabaseClient = supabase;

// Funzione: Registrazione
export async function register(email, password, firstName, lastName, referralCode = null) {
    try {
        // 1. Registra in Supabase Auth
        const { data: authData, error: authError } = await supabase.auth.signUp({
            email,
            password,
            options: {
                data: {
                    first_name: firstName,
                    last_name: lastName,
                    referral_code_used: referralCode
                }
            }
        });

        if (authError) throw authError;

        // 2. Il trigger handle_new_user() creerà automaticamente l'utente in public.users
        
        // Verifica se email confirmation è richiesta
        const emailConfirmationRequired = authData.user && !authData.session;
        
        return {
            success: true,
            message: emailConfirmationRequired 
                ? 'Registrazione completata! Controlla la tua email per confermare.'
                : 'Registrazione completata! Puoi effettuare il login.',
            user: authData.user,
            requiresEmailConfirmation: emailConfirmationRequired
        };
    } catch (error) {
        console.error('Registration error:', error);
        return {
            success: false,
            message: error.message || 'Errore durante la registrazione'
        };
    }
}

// Funzione: Login
export async function login(email, password) {
    try {
        const { data, error } = await supabase.auth.signInWithPassword({
            email,
            password
        });

        if (error) throw error;

        // Salva session
        localStorage.setItem('supabase_session', JSON.stringify(data.session));
        
        return {
            success: true,
            user: data.user,
            session: data.session
        };
    } catch (error) {
        console.error('Login error:', error);
        return {
            success: false,
            message: error.message || 'Email o password errati'
        };
    }
}

// Funzione: Logout
export async function logout() {
    try {
        const { error } = await supabase.auth.signOut();
        if (error) throw error;
        
        localStorage.removeItem('supabase_session');
        return { success: true };
    } catch (error) {
        console.error('Logout error:', error);
        return { success: false, message: error.message };
    }
}

// Funzione: Get current user
export async function getCurrentUser() {
    try {
        const { data: { user }, error } = await supabase.auth.getUser();
        if (error) throw error;
        return user;
    } catch (error) {
        console.error('Get user error:', error);
        return null;
    }
}

// Funzione: Check if logged in
export async function isLoggedIn() {
    const user = await getCurrentUser();
    return !!user;
}

// Auto-redirect se già loggato
export async function redirectIfLoggedIn(redirectTo = '/public/promotions.html') {
    if (await isLoggedIn()) {
        window.location.href = redirectTo;
    }
}

// Auto-redirect se NON loggato
export async function redirectIfNotLoggedIn(redirectTo = '/public/login.html') {
    if (!(await isLoggedIn())) {
        window.location.href = redirectTo;
    }
}

// Mostra auth modal se non loggato (per pagine protette)
export async function showAuthModalIfNotLoggedIn() {
    if (!(await isLoggedIn())) {
        // Aspetta che authModal sia disponibile
        if (window.authModal) {
            window.authModal.open();
            return true; // Non loggato
        } else {
            // Fallback a redirect
            console.warn('⚠️ Auth modal non disponibile, redirect a login');
            window.location.href = '/public/login.html';
            return true;
        }
    }
    return false; // Loggato
}

console.log('✅ Auth module loaded');
