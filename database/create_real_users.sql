-- ============================================
-- ANALISI UTENTI ESISTENTI
-- ============================================

-- 1. VISUALIZZA TUTTI GLI UTENTI NELLA TABELLA AUTH (Supabase Auth)
SELECT 
    id,
    email,
    created_at,
    confirmed_at,
    last_sign_in_at,
    email_confirmed_at
FROM auth.users
ORDER BY created_at DESC;

-- 2. VISUALIZZA TUTTI GLI UTENTI NELLA TABELLA PUBLIC.USERS
SELECT 
    id,
    email,
    full_name,
    role,
    organization_id,
    referral_code,
    created_at
FROM public.users
ORDER BY created_at DESC;

-- 3. JOIN TRA AUTH E PUBLIC USERS (per vedere dati completi)
SELECT 
    au.id as auth_id,
    au.email as auth_email,
    au.created_at as auth_created,
    au.last_sign_in_at,
    pu.id as user_id,
    pu.email as user_email,
    pu.full_name,
    pu.role,
    pu.organization_id,
    pu.referral_code
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
ORDER BY au.created_at DESC;

-- ============================================
-- PULIZIA (OPZIONALE - ESEGUI SOLO SE VUOI RIPARTIRE DA ZERO)
-- ============================================

-- ATTENZIONE: Questo elimina TUTTI gli utenti!
-- Decommentare solo se sei sicuro

-- DELETE FROM public.users;
-- DELETE FROM auth.users;

-- ============================================
-- CREAZIONE UTENTI VERI E FUNZIONALI
-- ============================================

-- NOTA: Gli utenti auth vanno creati tramite Supabase Dashboard o API
-- Qui sotto creiamo i record nella tabella public.users
-- assumendo che gli auth.users siano già stati creati

-- UTENTE 1: Admin
INSERT INTO public.users (
    id, 
    email, 
    full_name, 
    role, 
    referral_code
) VALUES (
    'uuid-admin-001', -- Sostituisci con UUID reale da auth.users
    'admin@cdm86.com',
    'Mario Rossi',
    'admin',
    'ADMIN001'
);

-- UTENTE 2: Organizzazione 1
INSERT INTO public.users (
    id,
    email,
    full_name,
    role,
    organization_id,
    referral_code
) VALUES (
    'uuid-org-001',
    'pizzeria@cdm86.com',
    'Giuseppe Verdi',
    'organization',
    1, -- ID dell'organizzazione
    'PIZZA001'
);

-- UTENTE 3: Organizzazione 2  
INSERT INTO public.users (
    id,
    email,
    full_name,
    role,
    organization_id,
    referral_code
) VALUES (
    'uuid-org-002',
    'palestra@cdm86.com',
    'Laura Bianchi',
    'organization',
    2,
    'GYM001'
);

-- UTENTE 4: User normale
INSERT INTO public.users (
    id,
    email,
    full_name,
    role
) VALUES (
    'uuid-user-001',
    'utente1@test.com',
    'Marco Ferrari',
    'user'
);

-- UTENTE 5: User normale 2
INSERT INTO public.users (
    id,
    email,
    full_name,
    role
) VALUES (
    'uuid-user-002',
    'utente2@test.com',
    'Sofia Romano',
    'user'
);

-- ============================================
-- VERIFICA UTENTI CREATI
-- ============================================

SELECT 
    id,
    email,
    full_name,
    role,
    organization_id,
    referral_code,
    created_at
FROM public.users
ORDER BY role, created_at;

-- ============================================
-- SCRIPT COMPLETO PER CREARE UTENTI CON PASSWORD
-- (Da eseguire via Supabase API o Dashboard)
-- ============================================

/*
IMPORTANTE: Per creare utenti con password, devi usare:

1. SUPABASE DASHBOARD:
   - Vai su Authentication > Users
   - Clicca "Add user"
   - Inserisci email e password
   - Copia l'UUID generato
   - Usa quell'UUID nelle query sopra

2. OPPURE USA L'API SUPABASE (da eseguire in JavaScript):

const users = [
  {
    email: 'admin@cdm86.com',
    password: 'Admin123!',
    full_name: 'Mario Rossi',
    role: 'admin',
    referral_code: 'ADMIN001'
  },
  {
    email: 'pizzeria@cdm86.com',
    password: 'Pizza123!',
    full_name: 'Giuseppe Verdi',
    role: 'organization',
    organization_id: 1,
    referral_code: 'PIZZA001'
  },
  {
    email: 'palestra@cdm86.com',
    password: 'Gym123!',
    full_name: 'Laura Bianchi',
    role: 'organization',
    organization_id: 2,
    referral_code: 'GYM001'
  },
  {
    email: 'utente1@test.com',
    password: 'User123!',
    full_name: 'Marco Ferrari',
    role: 'user'
  },
  {
    email: 'utente2@test.com',
    password: 'User123!',
    full_name: 'Sofia Romano',
    role: 'user'
  }
];

// Loop per creare ogni utente
for (const user of users) {
  // 1. Crea auth user
  const { data: authData, error: authError } = await supabase.auth.signUp({
    email: user.email,
    password: user.password
  });
  
  if (authError) {
    console.error('Error creating auth user:', authError);
    continue;
  }
  
  // 2. Crea record in public.users
  const { error: dbError } = await supabase
    .from('users')
    .insert({
      id: authData.user.id,
      email: user.email,
      full_name: user.full_name,
      role: user.role,
      organization_id: user.organization_id,
      referral_code: user.referral_code
    });
    
  if (dbError) {
    console.error('Error creating user record:', dbError);
  } else {
    console.log('✅ User created:', user.email);
  }
}
*/
