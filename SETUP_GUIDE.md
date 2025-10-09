# 🚀 Setup Completo CDM86 Platform

## 📋 Prerequisiti

- Node.js 16+ installato
- Account Supabase (gratuito: https://supabase.com)
- Git installato

---

## 1️⃣ Clone Repository

```bash
git clone https://github.com/Akirayouky/cdm86.git
cd cdm86
```

---

## 2️⃣ Installa Dipendenze

```bash
npm install
```

**Dipendenze installate:**
- `@supabase/supabase-js` - Client Supabase
- `bcryptjs` - Hash password
- `jsonwebtoken` - JWT tokens
- `qrcode` - Generazione QR codes
- `express` - Web framework
- `cors`, `helmet`, `morgan` - Middleware
- Altri (vedi package.json)

---

## 3️⃣ Configura Supabase

### A. Crea Progetto Supabase

1. Vai su https://supabase.com
2. Crea un nuovo progetto
3. Scegli nome, password database, region (Europe West preferibile)
4. Attendi creazione (~2 minuti)

### B. Esegui Schema SQL

1. Nel pannello Supabase, vai su **SQL Editor**
2. Apri il file `database/schema.sql`
3. Copia tutto il contenuto
4. Incolla nell'editor SQL di Supabase
5. Clicca **RUN** (⏯️)
6. Verifica che non ci siano errori

**Cosa crea lo schema:**
- 5 tabelle (users, promotions, user_favorites, referrals, transactions)
- 4 triggers (auto-update timestamps, referral counter, favorites counter)
- 3 functions (generate codes, increment counter)
- 3 views (user_stats, active_promotions, top_referrers)
- Indexes per performance
- Constraints per integrità dati

### C. Carica Dati Iniziali

1. Nel SQL Editor, apri nuovo tab
2. Apri il file `database/seed.sql`
3. Copia tutto il contenuto
4. Incolla nell'editor SQL
5. Clicca **RUN**

**Cosa carica il seed:**
- Admin utente (email: admin@cdm86.com)
- 4 utenti test (Mario, Lucia, Giovanni, Sara)
- 6 promozioni di esempio (pizza, shopping, spa, cinema, gym, tech)
- Referral tree: Admin → Mario → Giovanni, Sara
- User favorites

### D. Ottieni Credenziali Supabase

1. Nel pannello Supabase, vai su **Settings** ⚙️
2. Vai su **API**
3. Copia:
   - **Project URL** (es: https://xxxxxxxxxxx.supabase.co)
   - **anon/public key** (chiave pubblica)

---

## 4️⃣ Configura File .env

1. Apri il file `.env` nella root del progetto
2. Trova le righe:
   ```env
   SUPABASE_URL=your_supabase_project_url_here
   SUPABASE_ANON_KEY=your_supabase_anon_key_here
   ```
3. Sostituisci con le tue credenziali:
   ```env
   SUPABASE_URL=https://xxxxxxxxxxx.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

**File .env completo:**
```env
# Server Configuration
NODE_ENV=development
PORT=3000
APP_URL=http://localhost:3000
ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# Supabase PostgreSQL
SUPABASE_URL=https://xxxxxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# JWT Authentication
JWT_SECRET=dev-secret-key-change-in-production-12345678
JWT_EXPIRE=7d
JWT_REFRESH_SECRET=dev-refresh-secret-key-change-in-production
JWT_REFRESH_EXPIRE=30d
```

---

## 5️⃣ Avvia Server

```bash
npm run dev
```

**Output atteso:**
```
📡 Test connessione Supabase...
✅ Supabase connesso con successo

╔═══════════════════════════════════════════════╗
║                                               ║
║    🚀 CDM86 Platform Server                  ║
║    💾 Database: Supabase PostgreSQL          ║
║                                               ║
║    📡 Server: http://localhost:3000          ║
║    🌐 Environment: development                ║
║                                               ║
╚═══════════════════════════════════════════════╝
```

---

## 6️⃣ Testa API

### A. Health Check

```bash
curl http://localhost:3000/api/health
```

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2025-10-09T10:00:00.000Z",
  "uptime": 5.123
}
```

### B. Valida Referral Code

```bash
curl -X POST http://localhost:3000/api/auth/validate-referral \
  -H "Content-Type: application/json" \
  -d '{"referralCode": "ADMIN001"}'
```

**Response:**
```json
{
  "success": true,
  "message": "Codice referral valido",
  "data": {
    "referrer": {
      "name": "Admin CDM86",
      "code": "ADMIN001"
    }
  }
}
```

### C. Registrazione Nuovo Utente

```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!",
    "firstName": "Test",
    "lastName": "User",
    "referralCode": "ADMIN001"
  }'
```

### D. Login

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "mario.rossi@test.com",
    "password": "User123!"
  }'
```

Salva il `token` dalla response!

### E. Dashboard (richiede auth)

```bash
curl http://localhost:3000/api/users/dashboard \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### F. Lista Promozioni

```bash
curl http://localhost:3000/api/promotions
```

---

## 7️⃣ Credenziali Test

**Utenti seed già creati:**

| Email | Password | Referral Code | Invitati |
|-------|----------|---------------|----------|
| admin@cdm86.com | Admin123! | ADMIN001 | 2 (Mario, Lucia) |
| mario.rossi@test.com | User123! | MARIO001 | 2 (Giovanni, Sara) |
| lucia.verdi@test.com | Partner123! | LUCIA001 | 0 |
| giovanni.bianchi@test.com | Test123! | GIOVA001 | 0 |
| sara.neri@test.com | Test123! | SARA0001 | 0 |

**Nota:** Le password sono hashate con bcrypt nel database.

---

## 8️⃣ Verifica Database

### Query SQL per verificare dati:

```sql
-- Verifica utenti
SELECT 
    first_name || ' ' || last_name as nome,
    referral_code,
    referral_count as invitati,
    points as punti
FROM users
ORDER BY created_at;

-- Verifica referral tree
SELECT 
    u.first_name || ' ' || u.last_name as utente,
    u.referral_code as "codice personale",
    u.referral_count as "persone invitate",
    ref.first_name || ' ' || ref.last_name as "invitato da",
    ref.referral_code as "codice usato"
FROM users u
LEFT JOIN users ref ON u.referred_by_id = ref.id
ORDER BY u.created_at;

-- Verifica promozioni
SELECT title, partner_name, category, is_active
FROM promotions;

-- Top referrers
SELECT * FROM top_referrers;

-- User stats
SELECT * FROM user_stats;
```

---

## 9️⃣ Struttura API Endpoints

### 🔐 Auth (Public)
- `POST /api/auth/register` - Registrazione (RICHIEDE referral)
- `POST /api/auth/login` - Login
- `POST /api/auth/validate-referral` - Valida codice
- `POST /api/auth/refresh` - Refresh token
- `POST /api/auth/logout` - Logout

### 👤 Users (Protected)
- `GET /api/users/profile` - Profilo
- `PUT /api/users/profile` - Aggiorna profilo
- `GET /api/users/dashboard` - Dashboard con referral
- `GET /api/users/stats` - Statistiche
- `GET /api/users/points` - Saldo punti
- `GET /api/users/transactions` - Storico transazioni
- `GET /api/users/referral-link` - Link invito

### 🎁 Promotions (Mixed)
- `GET /api/promotions` - Lista (public)
- `GET /api/promotions/:id` - Dettaglio (public)
- `GET /api/promotions/category/:cat` - Per categoria (public)
- `POST /api/promotions/search` - Ricerca (public)
- `GET /api/promotions/user/favorites` - Preferite (protected)
- `POST /api/promotions/:id/favorite` - Toggle favorite (protected)
- `POST /api/promotions/:id/redeem` - Riscatta (protected)

### 🔗 Referrals (Mixed)
- `POST /api/referrals/validate` - Valida codice (public)
- `POST /api/referrals/track-click` - Traccia click (public)
- `GET /api/referrals/leaderboard` - Classifica (public)
- `GET /api/referrals/my-code` - Mio codice (protected)
- `GET /api/referrals/stats` - Statistiche (protected)
- `GET /api/referrals/invited` - Lista invitati (protected)
- `GET /api/referrals/history` - Storico (protected)

**Documentazione completa:** Vedi `API_DOCUMENTATION.md`

---

## 🔟 Script NPM Disponibili

```bash
# Sviluppo (con nodemon)
npm run dev

# Produzione
npm start

# Lint
npm run lint

# Test (se configurati)
npm test
```

---

## 🛠️ Troubleshooting

### ❌ Errore: "SUPABASE_URL e SUPABASE_ANON_KEY devono essere definiti"
**Soluzione:** Verifica che il file `.env` contenga le credenziali corrette.

### ❌ Errore: "relation users does not exist"
**Soluzione:** Esegui `database/schema.sql` su Supabase SQL Editor.

### ❌ Errore: "Codice referral obbligatorio"
**Soluzione:** La registrazione RICHIEDE un referral code valido. Usa "ADMIN001" o un altro codice esistente.

### ❌ Errore: "Token non valido"
**Soluzione:** Verifica che JWT_SECRET sia definito in `.env` e che il token non sia scaduto.

### ❌ Server non si avvia
**Soluzione:** 
1. Verifica che la porta 3000 non sia occupata
2. Controlla che tutte le dipendenze siano installate (`npm install`)
3. Verifica credenziali Supabase

---

## 📚 Prossimi Passi

1. ✅ **Database configurato** (Supabase PostgreSQL)
2. ✅ **API implementate** (Auth, Users, Promotions, Referrals)
3. ✅ **Seed data caricato** (5 utenti, 6 promozioni)
4. 🔲 **Frontend** - Implementare pagine:
   - Login/Register (con input referral code)
   - Dashboard utente (mostra chi mi ha invitato + lista invitati)
   - Lista promozioni
   - Dettaglio promozione
   - Redemption con QR code
5. 🔲 **Testing** - Unit test e integration test
6. 🔲 **Deploy** - Vercel/Netlify per frontend, Heroku/Railway per backend

---

## 📞 Supporto

Per problemi o domande:
- Controlla `API_DOCUMENTATION.md` per dettagli endpoint
- Controlla `SUPABASE_SETUP.md` per setup database
- Verifica logs del server: `npm run dev`

---

**Versione:** 1.0.0  
**Data:** 9 Ottobre 2025  
**Status:** ✅ Backend Completo - Ready for Frontend Development
