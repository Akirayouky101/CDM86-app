# 🚀 Guida Setup Supabase - CDM86 Platform

## 📋 Indice
1. [Creazione Progetto Supabase](#step-1-crea-progetto)
2. [Esecuzione Schema SQL](#step-2-schema)
3. [Esecuzione Seed SQL](#step-3-seed)
4. [Configurazione Variabili Ambiente](#step-4-env)
5. [Test Connessione](#step-5-test)
6. [Struttura Referral](#referral-structure)

---

## Step 1: Crea Progetto Supabase

### 1.1 Registrazione
1. Vai su https://supabase.com
2. Clicca "Start your project"
3. Registrati con GitHub/Google o email

### 1.2 Crea Nuovo Progetto
1. Clicca "New Project"
2. **Nome Progetto:** `CDM86`
3. **Database Name:** `CDM86DB` ✅ (come richiesto!)
4. **Database Password:** Genera password forte (SALVALA!)
5. **Region:** Frankfurt (EU Central) - più vicina all'Italia
6. Clicca "Create new project"

⏳ Attendi 2-3 minuti per il provisioning...

---

## Step 2: Esegui Schema SQL

### 2.1 Apri SQL Editor
1. Nel tuo progetto Supabase, vai alla sidebar
2. Clicca su **"SQL Editor"** (icona </> )
3. Clicca **"New query"**

### 2.2 Copia e Incolla Schema
1. Apri il file `/database/schema.sql`
2. **Copia TUTTO il contenuto** (Ctrl+A / Cmd+A)
3. Incolla nell'editor SQL di Supabase
4. Clicca **"Run"** (o Ctrl+Enter)

✅ **Output atteso:**
```
Success. No rows returned.
```

### 2.3 Verifica Creazione Tabelle
1. Vai su **"Table Editor"** nella sidebar
2. Dovresti vedere 4 tabelle:
   - ✅ `users`
   - ✅ `promotions`
   - ✅ `referrals`
   - ✅ `transactions`
   - ✅ `user_favorites`

---

## Step 3: Esegui Seed SQL

### 3.1 Nuova Query
1. Torna su **"SQL Editor"**
2. Clicca **"New query"** (o crea un nuovo tab)

### 3.2 Copia e Incolla Seed
1. Apri il file `/database/seed.sql`
2. **Copia TUTTO il contenuto**
3. Incolla nell'editor SQL
4. Clicca **"Run"**

✅ **Output atteso:**
```
Success. 5 rows returned.
(Mostra la query di verifica con la struttura referral)
```

### 3.3 Verifica Dati
1. Vai su **"Table Editor"**
2. Clicca su tabella **"users"**
3. Dovresti vedere **5 utenti:**
   - Admin CDM86 (admin@cdm86.com)
   - Mario Rossi (mario.rossi@test.com)
   - Lucia Verdi (lucia.verdi@test.com)
   - Giovanni Bianchi (giovanni.bianchi@test.com)
   - Sara Neri (sara.neri@test.com)

4. Clicca su tabella **"promotions"**
5. Dovresti vedere **6 promozioni**

6. Clicca su tabella **"referrals"**
7. Dovresti vedere **5 referral** (4 completed, 1 pending)

---

## Step 4: Configura Variabili Ambiente

### 4.1 Ottieni Credenziali Supabase
1. Nel progetto Supabase, vai su **"Settings"** (⚙️ in basso a sinistra)
2. Clicca su **"API"**
3. Copia questi valori:

   - **Project URL:** `https://xxxxx.supabase.co`
   - **anon public key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### 4.2 Aggiorna file `.env`
Apri il file `.env` nella root del progetto e aggiorna:

```env
# ============================================
# SUPABASE CONFIGURATION
# ============================================
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... (opzionale)

# Server Configuration
NODE_ENV=development
PORT=3000
APP_URL=http://localhost:3000
ALLOWED_ORIGINS=http://localhost:3000,https://cdm86.com

# JWT Configuration (per token personalizzati se necessario)
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRE=7d

# Referral Configuration
REFERRAL_REWARD_POINTS=100
REFERRAL_COMPLETION_POINTS=200

# Email (per notifiche - opzionale)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
```

**IMPORTANTE:** 
- ⚠️ Non committare `.env` su Git!
- ⚠️ Il file `.env` è già in `.gitignore`

---

## Step 5: Test Connessione

### 5.1 Installa Supabase SDK
```bash
npm install @supabase/supabase-js
```

### 5.2 Test Connessione Rapido
Crea un file temporaneo `test-supabase.js`:

```javascript
require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_ANON_KEY
);

async function testConnection() {
    try {
        // Test 1: Count users
        const { count: userCount, error: userError } = await supabase
            .from('users')
            .select('*', { count: 'exact', head: true });
        
        if (userError) throw userError;
        console.log('✅ Users in DB:', userCount);
        
        // Test 2: Count promotions
        const { count: promoCount, error: promoError } = await supabase
            .from('promotions')
            .select('*', { count: 'exact', head: true });
        
        if (promoError) throw promoError;
        console.log('✅ Promotions in DB:', promoCount);
        
        // Test 3: Get admin user
        const { data: admin, error: adminError } = await supabase
            .from('users')
            .select('email, first_name, last_name, referral_code, referral_count')
            .eq('email', 'admin@cdm86.com')
            .single();
        
        if (adminError) throw adminError;
        console.log('✅ Admin User:', admin);
        
        console.log('\n🎉 Connessione Supabase OK!');
        
    } catch (error) {
        console.error('❌ Errore:', error.message);
    }
}

testConnection();
```

Esegui:
```bash
node test-supabase.js
```

**Output atteso:**
```
✅ Users in DB: 5
✅ Promotions in DB: 6
✅ Admin User: {
  email: 'admin@cdm86.com',
  first_name: 'Admin',
  last_name: 'CDM86',
  referral_code: 'ADMIN001',
  referral_count: 2
}

🎉 Connessione Supabase OK!
```

---

## 📊 Struttura Referral Creata

### Albero Referral
```
👤 Admin (ADMIN001) - referral_count: 2
   ├─ 👤 Mario (MARIO001) - referral_count: 2
   │   ├─ 👤 Giovanni (GIOVA001) - referral_count: 0
   │   ├─ 👤 Sara (SARA0001) - referral_count: 0
   │   └─ ⏳ 1 pending (nuovo.utente@test.com)
   │
   └─ 👤 Lucia (LUCIA001) - referral_count: 0
```

### Come Funziona

#### Esempio: Mario visualizza il suo pannello

**Mario vede:**
- **Il suo referral code:** `MARIO001`
- **Chi lo ha invitato:** Admin (ADMIN001)
- **Lista persone invitate:**
  1. Giovanni Bianchi - Codice: GIOVA001 - Status: ✅ Completed
  2. Sara Neri - Codice: SARA0001 - Status: ✅ Completed
  3. nuovo.utente@test.com - Codice: N/A - Status: ⏳ Pending

**Dati Mario:**
- `referral_code`: "MARIO001" (il suo codice personale)
- `referred_by_id`: ID di Admin (chi lo ha invitato)
- `referral_count`: 2 (persone che hanno usato il suo codice)

### Query per Dashboard Utente

```sql
-- Dati utente + chi lo ha invitato
SELECT 
    u.id,
    u.first_name,
    u.last_name,
    u.email,
    u.referral_code as my_code,
    u.referral_count as people_i_invited,
    u.points,
    ref.first_name || ' ' || ref.last_name as invited_by_name,
    ref.referral_code as invited_by_code
FROM users u
LEFT JOIN users ref ON u.referred_by_id = ref.id
WHERE u.id = 'USER_ID';

-- Lista persone invitate da me
SELECT 
    u.id,
    u.first_name,
    u.last_name,
    u.email,
    u.referral_code,
    u.is_verified,
    u.points,
    r.status as referral_status,
    r.points_earned_referrer,
    r.created_at as invited_at
FROM referrals r
JOIN users u ON r.referred_user_id = u.id
WHERE r.referrer_id = 'USER_ID'
  AND r.status IN ('registered', 'verified', 'completed')
ORDER BY r.created_at DESC;
```

---

## 🔒 Sicurezza Supabase

### Row Level Security (RLS)

⚠️ **IMPORTANTE:** Supabase ha RLS attivo di default!

Per development, puoi temporaneamente disabilitarlo:

1. Vai su **"Authentication"** → **"Policies"**
2. Per ogni tabella, crea una policy permissiva:

**Esempio per `users`:**
```sql
-- Policy: Allow all for development
CREATE POLICY "Allow all for development" ON users
FOR ALL
USING (true)
WITH CHECK (true);
```

**Per production:** Dovrai creare policies specifiche:
```sql
-- Users possono leggere solo i propri dati
CREATE POLICY "Users can read own data" ON users
FOR SELECT
USING (auth.uid() = id);

-- Users possono aggiornare solo i propri dati
CREATE POLICY "Users can update own data" ON users
FOR UPDATE
USING (auth.uid() = id);
```

---

## 📚 Risorse Utili

- **Supabase Docs:** https://supabase.com/docs
- **Supabase JS SDK:** https://supabase.com/docs/reference/javascript
- **SQL Editor:** Nel dashboard Supabase
- **Table Editor:** Visualizza e modifica dati
- **API Docs:** Auto-generate per il tuo progetto

---

## 🎯 Prossimi Passi

Dopo aver completato questo setup:

1. ✅ **Database operativo su Supabase**
2. ✅ **Dati iniziali caricati**
3. ✅ **Connessione testata**

**Ora puoi:**
- 🔧 Creare `server/utils/supabase.js` (database utility)
- 🎮 Implementare `authController.js` (registrazione con referral obbligatorio)
- 📊 Implementare `userController.js` (dashboard con lista referral)
- 🎁 Implementare `promotionController.js` (CRUD promozioni)

---

## 🆘 Troubleshooting

### Errore: "relation does not exist"
**Soluzione:** Verifica di aver eseguito `schema.sql` prima di `seed.sql`

### Errore: "duplicate key value violates unique constraint"
**Soluzione:** Il seed è già stato eseguito. Truncate tables:
```sql
TRUNCATE users, promotions, referrals, transactions, user_favorites CASCADE;
```
Poi ri-esegui `seed.sql`

### Errore: "invalid input syntax for type uuid"
**Soluzione:** Verifica che l'estensione `uuid-ossp` sia attiva:
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

### Non vedo i dati nel Table Editor
**Soluzione:** 
1. Refresh pagina
2. Verifica che il seed sia completato senza errori
3. Controlla tab "SQL Editor" per eventuali errori

---

## ✅ Checklist Setup

- [ ] Progetto Supabase creato (CDM86DB)
- [ ] Schema SQL eseguito (5 tabelle create)
- [ ] Seed SQL eseguito (5 users, 6 promotions)
- [ ] `.env` configurato con SUPABASE_URL e KEY
- [ ] `@supabase/supabase-js` installato
- [ ] Test connessione eseguito con successo
- [ ] RLS policies configurate (o disabilitate per dev)

---

**🎉 Setup Completato!**

Il tuo database Supabase è pronto con:
- ✅ 5 utenti (admin + 4 users)
- ✅ 6 promozioni
- ✅ 5 referral (4 completati + 1 pending)
- ✅ Sistema referral completamente funzionante
- ✅ Triggers automatici per conteggi

**Struttura referral verificata:** Admin → Mario → [Giovanni, Sara] ✅
