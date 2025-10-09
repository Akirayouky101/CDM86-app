# 🎯 CDM86 - Struttura Finale App

## 📁 Struttura File

```
CDM86/
├── index.html                    # Homepage PUBBLICA (cdm86.com)
├── public/
│   ├── login.html               # Pagina login/registrazione
│   ├── promotions.html          # Promozioni (solo utenti loggati)
│   └── dashboard.html           # Dashboard referral
├── server/                      # Backend Node.js + Express
└── database/                    # SQL scripts
```

---

## 🚀 Flusso Utente

### **Utente NON Loggato** (Visitatore)

1. Apre `http://localhost:3000` → **Homepage pubblica** (`index.html`)
   - ✅ Vede: Hero, categorie, promozioni
   - ✅ Navbar con pulsante **"Accedi"**
   
2. Click su **"Accedi"** → Redirect a `/public/login.html`
   - Tab Login (email + password)
   - Tab Registrazione (con codice referral **OBBLIGATORIO**)

3. Dopo login → Redirect a `/public/promotions.html`

---

### **Utente Loggato**

1. Apre `http://localhost:3000` → **Homepage**
   - ✅ Pulsante diventa **"Mario"** (nome utente)
   - Click → va a `/public/promotions.html`

2. **Pagina Promozioni** (`/public/promotions.html`)
   - Navbar con **nome utente** + dropdown menu:
     - 📊 Dashboard
     - 👤 Profilo
     - ❤️ Preferiti
     - 🚪 Esci
   - Barra ricerca
   - Filtri categorie
   - Grid promozioni

3. **Dashboard** (`/public/dashboard.html`)
   - Statistiche (punti, persone invitate)
   - **Chi ti ha invitato** (card viola con nome e codice)
   - **Tuo codice referral** (card gialla con bottoni copia)
   - **Lista persone che hai invitato** (con i loro codici!)

4. **Logout** → Torna alla homepage pubblica

---

## 🔐 Credenziali Test

| Email | Password | Ruolo | Invitati |
|-------|----------|-------|----------|
| admin@cdm86.com | Admin123! | Admin | 2 (Mario, Lucia) |
| mario.rossi@test.com | User123! | User | 2 (Giovanni, Sara) |
| lucia.verdi@test.com | Partner123! | Partner | 0 |
| giovanni.bianchi@test.com | Test123! | User | 0 |
| sara.neri@test.com | Test123! | User | 0 |

---

## 🎫 Sistema Referral

### Registrazione
- **Codice referral è OBBLIGATORIO**
- Senza codice valido → errore 400
- Codice valido → crea utente e referral tracking

### Dashboard Mario Rossi
Quando Mario fa login e va su Dashboard vede:

**Chi ti ha invitato:**
```
Admin CDM86
admin@cdm86.com
Codice usato: ADMIN001
```

**Persone che hai invitato:**
```
1. Giovanni Bianchi (GIOVA001) - 200 punti ✓ Verificato
2. Sara Neri (SARA0001) - 150 punti ✓ Verificato
```

---

## 🧪 Test Completo

### 1. Test Homepage Pubblica
```bash
# Apri browser
http://localhost:3000

# Dovresti vedere:
✅ Hero section "Scopri Promozioni Esclusive"
✅ Categorie (Ristorazione, Shopping, etc)
✅ Grid promozioni
✅ Pulsante "Accedi" in alto a destra
```

### 2. Test Login
```bash
# Click su "Accedi" → vai a /public/login.html
# Inserisci:
Email: mario.rossi@test.com
Password: User123!

# Dopo login → redirect a /public/promotions.html
```

### 3. Test Promozioni
```bash
# In /public/promotions.html vedi:
✅ Navbar con "Mario Rossi" (nome utente)
✅ 6 promozioni dal database
✅ Filtri categorie funzionanti
✅ Barra ricerca

# Click sul nome "Mario Rossi" → dropdown menu
✅ Dashboard, Profilo, Preferiti, Esci
```

### 4. Test Dashboard
```bash
# Click su "Dashboard" dal menu

# Vedi:
✅ Punti: 500
✅ Persone invitate: 2
✅ Tuo codice: MARIO001

✅ Chi ti ha invitato: Admin CDM86 (ADMIN001)
✅ Lista invitati:
   - Giovanni Bianchi (GIOVA001)
   - Sara Neri (SARA0001)

# Bottoni funzionanti:
✅ Copia Codice
✅ Copia Link
```

### 5. Test Registrazione
```bash
# Logout → torna a homepage
# Click "Accedi" → Tab "Registrati"

# Compila:
Nome: Test
Cognome: User
Email: test.user@cdm86.com
Password: Test123!
Codice Referral: MARIO001  ← OBBLIGATORIO!

# Dopo registrazione → login automatico
# Dashboard nuovo utente:
✅ Chi ti ha invitato: Mario Rossi (MARIO001)
✅ Lista invitati: vuota
```

---

## 📡 API Backend

### Endpoints Principali

**Autenticazione:**
- `POST /api/auth/login` - Login
- `POST /api/auth/register` - Registrazione (referral obbligatorio)
- `POST /api/auth/validate-referral` - Valida codice referral

**Utente:**
- `GET /api/users/profile` - Profilo utente
- `GET /api/users/dashboard` - Dashboard con referral tree
- `GET /api/users/points` - Saldo punti

**Promozioni:**
- `GET /api/promotions` - Lista promozioni
- `GET /api/promotions/:id` - Dettaglio promozione
- `GET /api/promotions/user/favorites` - Preferiti

**Referral:**
- `GET /api/referrals/my-code` - Il mio codice
- `GET /api/referrals/invited` - Lista invitati
- `GET /api/referrals/stats` - Statistiche

---

## 🎨 Design

### Homepage Pubblica (`index.html`)
- Design originale cdm86.com
- Hero section con statistiche
- Categorie scorrevoli
- Grid promozioni responsive
- Pulsante "Accedi" (o nome utente se loggato)

### Login (`/public/login.html`)
- Design moderno gradient viola
- Tabs Login/Registrazione
- Form validation
- Alert success/error

### Promozioni (`/public/promotions.html`)
- Navbar sticky con user menu
- Filtri e ricerca
- Grid cards promozioni
- Click su card → dettaglio

### Dashboard (`/public/dashboard.html`)
- Cards statistiche
- Referrer card (chi ti ha invitato)
- Codice referral da condividere
- Lista invitati con avatar e codici

---

## ✅ Completato

- [x] Database schema PostgreSQL
- [x] Seed data con 5 utenti + 6 promozioni
- [x] Backend API (28 endpoints)
- [x] Sistema referral obbligatorio
- [x] Homepage pubblica
- [x] Login/Registrazione
- [x] Pagina promozioni con filtri
- [x] Dashboard con referral tree
- [x] User menu dropdown

---

## 🚀 Per Avviare

```bash
# 1. Server backend
npm run dev

# 2. Browser
http://localhost:3000
```

**Tutto funziona!** 🎉
