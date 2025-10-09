# API Documentation - CDM86 Platform

## 📋 Indice

- [Autenticazione](#autenticazione)
- [Utenti](#utenti)
- [Promozioni](#promozioni)
- [Referral](#referral)
- [Codici di Errore](#codici-di-errore)

---

## 🔐 Autenticazione

Tutte le richieste autenticate richiedono l'header:
```
Authorization: Bearer <token>
```

### POST /api/auth/register
Registrazione nuovo utente - **RICHIEDE REFERRAL CODE OBBLIGATORIO**

**Body:**
```json
{
  "email": "utente@example.com",
  "password": "Password123!",
  "firstName": "Mario",
  "lastName": "Rossi",
  "phone": "+39 333 1234567",
  "referralCode": "ADMIN001"  // 🚨 OBBLIGATORIO
}
```

**Response:**
```json
{
  "success": true,
  "message": "Registrazione completata!",
  "data": {
    "user": {
      "id": "uuid",
      "email": "utente@example.com",
      "firstName": "Mario",
      "lastName": "Rossi",
      "referralCode": "MARIO001",
      "referredBy": {
        "id": "uuid",
        "name": "Admin CDM86",
        "code": "ADMIN001"
      },
      "role": "user",
      "points": 100,
      "isVerified": false
    },
    "token": "jwt_token",
    "refreshToken": "refresh_token"
  }
}
```

---

### POST /api/auth/login
Login utente esistente

**Body:**
```json
{
  "email": "utente@example.com",
  "password": "Password123!"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login effettuato con successo",
  "data": {
    "user": {
      "id": "uuid",
      "email": "utente@example.com",
      "firstName": "Mario",
      "lastName": "Rossi",
      "referralCode": "MARIO001",
      "referredBy": {
        "id": "uuid",
        "name": "Admin CDM86",
        "code": "ADMIN001"
      },
      "role": "user",
      "points": 500,
      "referralCount": 2
    },
    "token": "jwt_token",
    "refreshToken": "refresh_token"
  }
}
```

---

### POST /api/auth/validate-referral
Valida codice referral PRIMA della registrazione

**Body:**
```json
{
  "referralCode": "ADMIN001"
}
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

---

### POST /api/auth/refresh
Rinnova access token

**Body:**
```json
{
  "refreshToken": "refresh_token"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "new_jwt_token"
  }
}
```

---

### POST /api/auth/logout
Logout (lato client rimuove token)

**Response:**
```json
{
  "success": true,
  "message": "Logout effettuato con successo"
}
```

---

## 👤 Utenti

### GET /api/users/profile
Ottieni profilo utente completo

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "mario.rossi@test.com",
    "firstName": "Mario",
    "lastName": "Rossi",
    "phone": "+39 333 1234567",
    "referralCode": "MARIO001",
    "referredBy": {
      "id": "uuid",
      "name": "Admin CDM86",
      "code": "ADMIN001"
    },
    "role": "user",
    "points": 500,
    "referralCount": 2,
    "isVerified": true,
    "createdAt": "2025-10-01T10:00:00Z"
  }
}
```

---

### GET /api/users/dashboard
Dashboard completa con info referral

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "mario.rossi@test.com",
      "firstName": "Mario",
      "lastName": "Rossi",
      "referralCode": "MARIO001",
      "points": 500,
      "referralCount": 2
    },
    "referredBy": {
      "id": "uuid",
      "name": "Admin CDM86",
      "email": "admin@cdm86.com",
      "code": "ADMIN001"
    },
    "referredUsers": [
      {
        "id": "uuid",
        "name": "Giovanni Bianchi",
        "email": "giovanni.bianchi@test.com",
        "referralCode": "GIOVA001",
        "points": 200,
        "isVerified": true,
        "joinedAt": "2025-10-05T10:00:00Z"
      },
      {
        "id": "uuid",
        "name": "Sara Neri",
        "email": "sara.neri@test.com",
        "referralCode": "SARA0001",
        "points": 150,
        "isVerified": true,
        "joinedAt": "2025-10-07T10:00:00Z"
      }
    ],
    "referralStats": {
      "totalReferrals": 3,
      "pending": 1,
      "registered": 0,
      "verified": 0,
      "completed": 2
    },
    "favorites": [...],
    "recentTransactions": [...]
  }
}
```

---

### PUT /api/users/profile
Aggiorna profilo utente

**Headers:** `Authorization: Bearer <token>`

**Body:**
```json
{
  "firstName": "Mario",
  "lastName": "Rossi",
  "phone": "+39 333 9999999"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Profilo aggiornato con successo",
  "data": {
    "firstName": "Mario",
    "lastName": "Rossi",
    "phone": "+39 333 9999999"
  }
}
```

---

### GET /api/users/stats
Statistiche dettagliate utente (usa view `user_stats`)

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": {
    "user_id": "uuid",
    "total_favorites": 5,
    "total_transactions": 12,
    "completed_transactions": 8,
    "pending_transactions": 4,
    "total_points_spent": 450,
    "total_referrals": 3,
    "completed_referrals": 2
  }
}
```

---

### GET /api/users/points
Saldo punti corrente

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": {
    "points": 500
  }
}
```

---

### GET /api/users/transactions
Storico transazioni

**Headers:** `Authorization: Bearer <token>`

**Query Params:**
- `status`: pending | completed | cancelled
- `limit`: numero (default: 20)
- `offset`: numero (default: 0)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "transaction_code": "TRX-123456",
      "status": "completed",
      "points_used": 100,
      "qr_code": "data:image/png;base64,...",
      "created_at": "2025-10-08T10:00:00Z",
      "promotion": {
        "id": "uuid",
        "title": "Pizza Margherita + Bibita",
        "partner_name": "Pizzeria da Antonio",
        "image_thumbnail": "https://..."
      }
    }
  ],
  "pagination": {
    "limit": 20,
    "offset": 0
  }
}
```

---

### GET /api/users/referral-link
Ottieni link di invito personalizzato

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": {
    "referralCode": "MARIO001",
    "referralLink": "http://localhost:3000/register?ref=MARIO001",
    "shareMessage": "Iscriviti a CDM86 usando il mio codice MARIO001 e ottieni 100 punti! http://localhost:3000/register?ref=MARIO001"
  }
}
```

---

## 🎁 Promozioni

### GET /api/promotions
Lista promozioni con filtri

**Query Params:**
- `category`: ristoranti | shopping | salute | sport | intrattenimento | tecnologia
- `search`: testo ricerca
- `featured`: true | false
- `active`: true | false (default: true)
- `limit`: numero (default: 20)
- `offset`: numero (default: 0)
- `sortBy`: created_at | discount_value | stat_views
- `sortOrder`: asc | desc (default: desc)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "title": "Pizza Margherita + Bibita Omaggio",
      "slug": "pizza-margherita-bibita-omaggio",
      "short_description": "Pizza + Bibita gratis!",
      "description": "Ordina una pizza margherita...",
      "partner_name": "Pizzeria da Antonio",
      "partner_city": "Milano",
      "category": "ristoranti",
      "tags": ["pizza", "cibo", "italiano"],
      "image_main": "https://...",
      "image_thumbnail": "https://...",
      "discount_type": "fixed",
      "discount_value": 3.00,
      "original_price": 11.00,
      "discounted_price": 8.00,
      "is_active": true,
      "is_featured": true,
      "points_cost": 0,
      "points_reward": 50,
      "stat_views": 245,
      "stat_favorites": 18,
      "stat_redemptions": 12
    }
  ],
  "pagination": {
    "total": 6,
    "limit": 20,
    "offset": 0,
    "hasMore": false
  }
}
```

---

### GET /api/promotions/:id
Dettaglio promozione singola (incrementa views)

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "title": "Pizza Margherita + Bibita Omaggio",
    "description": "Descrizione completa...",
    "partner_name": "Pizzeria da Antonio",
    "partner_address": "Via Roma 123",
    "partner_city": "Milano",
    "partner_phone": "+39 02 1234567",
    "validity_start_date": "2025-10-01",
    "validity_end_date": "2025-10-31",
    "validity_days": ["lun", "mar", "mer", "gio", "ven", "sab", "dom"],
    "validity_hours_from": "12:00",
    "validity_hours_to": "23:00",
    "terms": "Non cumulabile con altre offerte...",
    "how_to_redeem": "Mostra il QR code al cameriere...",
    "isFavorite": false
  }
}
```

---

### GET /api/promotions/category/:category
Promozioni per categoria

**Params:** `category` (ristoranti, shopping, etc.)

**Response:** Lista promozioni (stessa struttura di GET /api/promotions)

---

### POST /api/promotions/search
Ricerca avanzata

**Body:**
```json
{
  "query": "pizza",
  "categories": ["ristoranti"],
  "tags": ["cibo", "italiano"],
  "city": "Milano",
  "minDiscount": 10,
  "maxDiscount": 50
}
```

**Response:**
```json
{
  "success": true,
  "data": [...],
  "count": 2
}
```

---

### GET /api/promotions/user/favorites
Promozioni preferite dell'utente

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "title": "Pizza Margherita + Bibita",
      "favoritedAt": "2025-10-08T10:00:00Z",
      ...
    }
  ]
}
```

---

### POST /api/promotions/:id/favorite
Aggiungi/rimuovi preferita (toggle)

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "message": "Promozione aggiunta ai preferiti",
  "isFavorite": true
}
```

---

### POST /api/promotions/:id/redeem
Riscatta promozione - Genera QR code

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "message": "Promozione riscattata con successo",
  "data": {
    "transaction": {
      "id": "uuid",
      "transactionCode": "TRX-1728475200-ABC123",
      "qrCode": "data:image/png;base64,iVBORw0KGgo...",
      "status": "pending",
      "createdAt": "2025-10-09T10:00:00Z"
    },
    "promotion": {
      "id": "uuid",
      "title": "Pizza Margherita + Bibita",
      "partnerName": "Pizzeria da Antonio"
    }
  }
}
```

---

## 🔗 Referral

### GET /api/referrals/my-code
Codice referral personale e link

**Headers:** `Authorization: Bearer <token>`

**Response:**
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

### GET /api/referrals/stats
Statistiche referral dettagliate

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "data": {
    "total": 3,
    "pending": 1,
    "registered": 0,
    "verified": 0,
    "completed": 2,
    "totalPointsEarned": 400,
    "sources": {
      "link": 2,
      "email": 1
    },
    "last7Days": 1
  }
}
```

---

### GET /api/referrals/invited
Lista persone invitate con dettagli

**Headers:** `Authorization: Bearer <token>`

**Query Params:**
- `status`: pending | registered | verified | completed
- `limit`: numero (default: 50)
- `offset`: numero (default: 0)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "email": "giovanni.bianchi@test.com",
      "status": "completed",
      "codeUsed": "MARIO001",
      "source": "link",
      "pointsEarned": 200,
      "registeredAt": "2025-10-05T10:00:00Z",
      "completedAt": "2025-10-06T10:00:00Z",
      "user": {
        "id": "uuid",
        "name": "Giovanni Bianchi",
        "email": "giovanni.bianchi@test.com",
        "referralCode": "GIOVA001",
        "points": 200,
        "isVerified": true,
        "joinedAt": "2025-10-05T10:00:00Z"
      }
    }
  ]
}
```

---

### GET /api/referrals/history
Storico completo referral

**Headers:** `Authorization: Bearer <token>`

**Query Params:**
- `startDate`: ISO date
- `endDate`: ISO date
- `status`: pending | registered | verified | completed
- `limit`: numero (default: 100)
- `offset`: numero (default: 0)

**Response:**
```json
{
  "success": true,
  "data": [...],
  "pagination": {
    "total": 3,
    "limit": 100,
    "offset": 0
  }
}
```

---

### GET /api/referrals/leaderboard
Classifica top referrers (public)

**Query Params:**
- `limit`: numero (default: 10)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "user_name": "Mario Rossi",
      "referral_code": "MARIO001",
      "total_referrals": 2,
      "completed_referrals": 2,
      "total_points_earned": 400
    }
  ]
}
```

---

### POST /api/referrals/track-click
Traccia click su link referral (public)

**Body:**
```json
{
  "referralCode": "MARIO001",
  "source": "link",
  "email": "nuovo@test.com"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Click tracciato",
  "data": {
    "referralId": "uuid"
  }
}
```

---

### POST /api/referrals/validate
Valida codice referral (public)

**Body:**
```json
{
  "code": "MARIO001"
}
```

**Response:**
```json
{
  "success": true,
  "valid": true,
  "message": "Codice referral valido",
  "data": {
    "referrerName": "Mario Rossi",
    "code": "MARIO001"
  }
}
```

---

## ⚠️ Codici di Errore

### 400 Bad Request
```json
{
  "success": false,
  "message": "Codice referral obbligatorio"
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "message": "Token non valido"
}
```

### 403 Forbidden
```json
{
  "success": false,
  "message": "Accesso negato"
}
```

### 404 Not Found
```json
{
  "success": false,
  "message": "Risorsa non trovata"
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "message": "Errore del server"
}
```

---

## 📝 Note Importanti

1. **Referral Obbligatorio**: La registrazione RICHIEDE un codice referral valido
2. **JWT Token**: Scadenza default 7 giorni
3. **Rate Limiting**: Max 100 richieste per IP ogni 15 minuti
4. **Punti**: Registrazione = 100 punti bonus
5. **QR Code**: Formato base64 PNG per redemption promozioni
6. **Database**: Supabase PostgreSQL con triggers automatici

---

**Versione:** 1.0.0  
**Ultimo Aggiornamento:** 9 Ottobre 2025
