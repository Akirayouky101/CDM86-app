# 🗄️ Guida Database Setup - CDM86 Platform

## 📋 Indice
1. [Opzione 1: MongoDB Locale (Sviluppo)](#opzione-1-mongodb-locale)
2. [Opzione 2: MongoDB Atlas (Cloud)](#opzione-2-mongodb-atlas)
3. [Configurazione Variabili Ambiente](#configurazione)
4. [Seed Database](#seed-database)
5. [Verifica Connessione](#verifica)

---

## Opzione 1: MongoDB Locale (Sviluppo)

### macOS

**Installazione con Homebrew:**
```bash
# Installa MongoDB
brew tap mongodb/brew
brew install mongodb-community@7.0

# Avvia MongoDB
brew services start mongodb-community@7.0

# Verifica che sia in esecuzione
brew services list | grep mongodb
```

**Configurazione `.env`:**
```env
MONGODB_URI=mongodb://localhost:27017/cdm86
```

### Windows

**Installazione:**
1. Scarica MongoDB da: https://www.mongodb.com/try/download/community
2. Installa seguendo il wizard
3. MongoDB si avvia automaticamente come servizio Windows

**Verifica installazione:**
```powershell
mongod --version
```

---

## Opzione 2: MongoDB Atlas (Cloud) ☁️

### Setup (Gratis fino a 512MB)

1. **Crea account su MongoDB Atlas:**
   - Vai su https://www.mongodb.com/cloud/atlas/register
   - Registrati gratuitamente

2. **Crea un Cluster:**
   - Clicca "Build a Database"
   - Scegli "M0 Sandbox" (FREE)
   - Seleziona la region più vicina (es: Frankfurt per EU)
   - Clicca "Create"

3. **Configura Accesso:**
   - **Database Access:** Crea un utente con password
     - Username: `cdm86user`
     - Password: Genera password sicura (salvala!)
   
   - **Network Access:** Aggiungi IP
     - Per sviluppo: `0.0.0.0/0` (tutti gli IP)
     - Per produzione: IP specifico del server

4. **Ottieni Connection String:**
   - Clicca "Connect" sul tuo cluster
   - Scegli "Connect your application"
   - Copia la connection string:
   ```
   mongodb+srv://cdm86user:<password>@cluster0.xxxxx.mongodb.net/cdm86?retryWrites=true&w=majority
   ```
   - Sostituisci `<password>` con la tua password

5. **Configura `.env`:**
   ```env
   MONGODB_URI=mongodb+srv://cdm86user:TUA_PASSWORD@cluster0.xxxxx.mongodb.net/cdm86?retryWrites=true&w=majority
   ```

---

## 📝 Configurazione

### File `.env`

Copia `.env.example` in `.env`:
```bash
cp .env.example .env
```

Modifica `.env` con i tuoi dati:
```env
# Scegli una delle due opzioni:

# OPZIONE 1 - MongoDB Locale
MONGODB_URI=mongodb://localhost:27017/cdm86

# OPZIONE 2 - MongoDB Atlas
# MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/cdm86
```

---

## 🌱 Seed Database

Dopo aver configurato MongoDB, popola il database con dati di esempio:

```bash
npm run seed
```

Questo comando:
- ✅ Crea 3 utenti (admin, user, partner)
- ✅ Crea 6 promozioni di esempio
- ✅ Crea 1 referral completato
- ✅ Aggiunge statistiche e preferiti

### Credenziali create:

**Admin:**
- Email: `admin@cdm86.com`
- Password: `Admin123!`
- Referral Code: `ADMIN001`

**User:**
- Email: `user1@test.com`
- Password: `User123!`
- Referral Code: `MARIO001`
- Punti: 500

**Partner:**
- Email: `partner@test.com`
- Password: `Partner123!`
- Referral Code: `PARTNER1`

---

## ✅ Verifica Connessione

### Test 1: Avvia il server
```bash
npm run dev
```

Output atteso:
```
📡 Connessione a MongoDB... (tentativo 1/5)
✅ MongoDB connesso con successo
📊 Database: cdm86
🔗 Mongoose connesso a MongoDB
🚀 CDM86 Platform Server
📡 Server: http://localhost:3000
```

### Test 2: Controlla database
```bash
# MongoDB locale
mongosh
use cdm86
db.users.find()

# MongoDB Atlas
# Usa MongoDB Compass o la Web UI
```

### Test 3: API Health Check
```bash
curl http://localhost:3000/api/health
```

Output atteso:
```json
{
  "status": "ok",
  "timestamp": "2024-01-XX...",
  "uptime": XX,
  "environment": "development"
}
```

---

## 🛠️ Comandi Utili

### NPM Scripts
```bash
# Avvia server in sviluppo (con nodemon)
npm run dev

# Avvia server in produzione
npm start

# Popola database con dati di esempio
npm run seed

# Seed in produzione
npm run seed:prod
```

### MongoDB Shell (mongosh)
```bash
# Connetti al database locale
mongosh

# Usa database cdm86
use cdm86

# Lista tutte le collections
show collections

# Conta documenti
db.users.countDocuments()
db.promotions.countDocuments()

# Trova tutti gli utenti
db.users.find().pretty()

# Trova promozioni attive
db.promotions.find({ isActive: true }).pretty()

# Elimina tutti i dati
db.users.deleteMany({})
db.promotions.deleteMany({})
db.referrals.deleteMany({})
db.transactions.deleteMany({})
```

---

## 📊 Struttura Database

### Collections Create:

1. **users** - Utenti della piattaforma
   - email, password (hashed), nome, cognome
   - referralCode, points, role
   - favoritePromotions[]

2. **promotions** - Promozioni convenzionate
   - title, description, category, tags
   - partner info, discount, validity
   - stats (views, favorites, redemptions)

3. **referrals** - Sistema referral/inviti
   - referrerId, referredUserId, codeUsed
   - status, pointsEarned
   - tracking info

4. **transactions** - Transazioni/Riscatti
   - userId, promotionId
   - transactionCode, qrCode
   - status, pointsUsed/Earned
   - redemption info

---

## 🚨 Troubleshooting

### Errore: "MONGODB_URI non definita"
**Soluzione:** Verifica che il file `.env` esista e contenga `MONGODB_URI`

### Errore: "Connection timeout"
**Soluzioni:**
- MongoDB locale: Verifica che MongoDB sia avviato (`brew services list`)
- MongoDB Atlas: Controlla Network Access (IP whitelist)

### Errore: "Authentication failed"
**Soluzioni:**
- Verifica username/password nella connection string
- Controlla Database Access su Atlas

### Errore: "Database name missing"
**Soluzione:** Assicurati che la connection string includa `/cdm86` prima dei parametri

---

## 📚 Risorse Utili

- [MongoDB Manual](https://docs.mongodb.com/manual/)
- [Mongoose Docs](https://mongoosejs.com/docs/)
- [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
- [MongoDB Compass](https://www.mongodb.com/products/compass) (GUI)

---

## 🔐 Sicurezza

### Produzione:
- ⚠️ **MAI** committare `.env` su Git
- ⚠️ Usa password forti per MongoDB
- ⚠️ Limita Network Access su Atlas a IP specifici
- ⚠️ Cambia `JWT_SECRET` in produzione
- ⚠️ Usa HTTPS per connessioni

### Best Practices:
- ✅ Backup regolari del database
- ✅ Monitora performance e slow queries
- ✅ Usa indexes appropriati
- ✅ Valida input prima di salvare
- ✅ Sanitizza query per prevenire injection

---

**🎉 Setup Completato!**

Ora sei pronto per sviluppare con il database configurato.
