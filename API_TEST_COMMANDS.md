# 🧪 Test API CDM86 - Comandi Manuali

Il server è in esecuzione su: **http://localhost:3000**

---

## ✅ Test Rapidi (copia e incolla nel terminale)

### 1️⃣ Health Check
```bash
curl http://localhost:3000/api/health
```

**Risposta attesa:**
```json
{
  "status": "ok",
  "timestamp": "2025-10-09T...",
  "uptime": 123.456
}
```

---

### 2️⃣ Valida Referral Code (ADMIN001)
```bash
curl -X POST http://localhost:3000/api/auth/validate-referral \
  -H "Content-Type: application/json" \
  -d '{"referralCode": "ADMIN001"}'
```

**Risposta attesa:**
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

---

### 3️⃣ Login con Mario Rossi
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "mario.rossi@test.com",
    "password": "User123!"
  }'
```

**Risposta attesa:**
```json
{
  "success": true,
  "message": "Login effettuato con successo",
  "data": {
    "user": {
      "id": "...",
      "email": "mario.rossi@test.com",
      "firstName": "Mario",
      "lastName": "Rossi",
      "referralCode": "MARIO001",
      "referredBy": {
        "id": "...",
        "name": "Admin CDM86",
        "code": "ADMIN001"
      },
      "points": 500,
      "referralCount": 2
    },
    "token": "eyJhbGci....",
    "refreshToken": "eyJhbGci...."
  }
}
```

**⚠️ SALVA IL TOKEN!** Lo userai per i prossimi test.

---

### 4️⃣ Dashboard Utente (con token)

Sostituisci `YOUR_TOKEN_HERE` con il token ricevuto dal login:

```bash
curl http://localhost:3000/api/users/dashboard \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Risposta attesa:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "...",
      "referralCode": "MARIO001",
      "points": 500,
      "referralCount": 2
    },
    "referredBy": {
      "id": "...",
      "name": "Admin CDM86",
      "email": "admin@cdm86.com",
      "code": "ADMIN001"
    },
    "referredUsers": [
      {
        "id": "...",
        "name": "Giovanni Bianchi",
        "email": "giovanni.bianchi@test.com",
        "referralCode": "GIOVA001",
        "points": 200,
        "isVerified": true,
        "joinedAt": "..."
      },
      {
        "id": "...",
        "name": "Sara Neri",
        "email": "sara.neri@test.com",
        "referralCode": "SARA0001",
        "points": 150,
        "isVerified": true,
        "joinedAt": "..."
      }
    ],
    "referralStats": {
      "totalReferrals": 3,
      "pending": 1,
      "completed": 2
    }
  }
}
```

---

### 5️⃣ Il Mio Codice Referral
```bash
curl http://localhost:3000/api/referrals/my-code \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Risposta attesa:**
```json
{
  "success": true,
  "data": {
    "code": "MARIO001",
    "link": "http://localhost:3000/register?ref=MARIO001",
    "totalReferrals": 2,
    "shareMessage": "Iscriviti a CDM86 con il mio codice MARIO001..."
  }
}
```

---

### 6️⃣ Lista Persone che HO Invitato
```bash
curl http://localhost:3000/api/referrals/invited \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Risposta attesa:**
```json
{
  "success": true,
  "data": [
    {
      "id": "...",
      "email": "giovanni.bianchi@test.com",
      "status": "completed",
      "codeUsed": "MARIO001",
      "pointsEarned": 200,
      "user": {
        "id": "...",
        "name": "Giovanni Bianchi",
        "referralCode": "GIOVA001",
        "points": 200,
        "isVerified": true
      }
    },
    {
      "id": "...",
      "email": "sara.neri@test.com",
      "status": "completed",
      "codeUsed": "MARIO001",
      "pointsEarned": 200,
      "user": {
        "id": "...",
        "name": "Sara Neri",
        "referralCode": "SARA0001",
        "points": 150
      }
    }
  ]
}
```

---

### 7️⃣ Statistiche Referral
```bash
curl http://localhost:3000/api/referrals/stats \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

### 8️⃣ Lista Promozioni (public - no auth)
```bash
curl http://localhost:3000/api/promotions
```

**Risposta attesa:**
```json
{
  "success": true,
  "data": [
    {
      "id": "...",
      "title": "Pizza Margherita + Bibita Omaggio",
      "partner_name": "Pizzeria da Antonio",
      "category": "ristoranti",
      "discount_value": 3.00,
      "is_featured": true,
      ...
    },
    ...
  ],
  "pagination": {
    "total": 6,
    "limit": 20,
    "offset": 0
  }
}
```

---

### 9️⃣ Promozioni Preferite
```bash
curl http://localhost:3000/api/promotions/user/favorites \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

### 🔟 Saldo Punti
```bash
curl http://localhost:3000/api/users/points \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## 📊 Test con Postman/Insomnia

Importa questa collection:

**Base URL:** `http://localhost:3000/api`

**Headers:**
- `Content-Type: application/json`
- `Authorization: Bearer <token>` (per endpoint protetti)

---

## 🧑‍💻 Credenziali Test

| Email | Password | Referral Code | Invitati |
|-------|----------|---------------|----------|
| admin@cdm86.com | Admin123! | ADMIN001 | 2 |
| mario.rossi@test.com | User123! | MARIO001 | 2 |
| lucia.verdi@test.com | Partner123! | LUCIA001 | 0 |
| giovanni.bianchi@test.com | Test123! | GIOVA001 | 0 |
| sara.neri@test.com | Test123! | SARA0001 | 0 |

---

## 🎯 Test Workflow Completo

1. **Valida referral** (ADMIN001)
2. **Registra nuovo utente** con referral ADMIN001
3. **Login** con nuovo utente
4. **Dashboard** - vedi chi ti ha invitato
5. **My referral code** - ottieni il tuo codice
6. **Lista promozioni** - vedi offerte disponibili
7. **Toggle favorite** - aggiungi ai preferiti
8. **Redeem** - riscatta promozione con QR code

---

## 📚 Documentazione Completa

Vedi: `API_DOCUMENTATION.md` per tutti i 28 endpoints disponibili!

---

**Status:** ✅ Server attivo su http://localhost:3000  
**Database:** ✅ Supabase PostgreSQL connesso  
**Seed Data:** ✅ 5 utenti + 6 promozioni caricate
