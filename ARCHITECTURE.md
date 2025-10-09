# 🏗️ CDM86 Platform - Architettura e Documentazione

## 📋 Panoramica

Piattaforma PWA (Progressive Web App) per la gestione di **promozioni convenzionate** con sistema di **referral integrato**.

---

## 🎯 Funzionalità Principali

### 1. **PWA (Progressive Web App)**
- ✅ Installabile su dispositivi (iOS, Android, Desktop)
- ✅ Funzionamento offline
- ✅ Notifiche push
- ✅ Background sync
- ✅ App-like experience

### 2. **Sistema di Autenticazione**
- 👤 Registrazione utenti
- 🔐 Login con JWT
- 📧 Verifica email
- 🔄 Reset password
- 👥 Gestione profili

### 3. **Sistema Referral**
- 🔗 Link referral univoci per utente
- 📊 Tracking referral (chi ha invitato chi)
- 🎁 Sistema di reward/punti
- 📈 Dashboard statistiche referral
- 💰 Conversione punti in benefit

### 4. **Gestione Promozioni**
- 🎫 Visualizzazione promozioni attive
- 🏷️ Categorie promozioni
- 🔍 Ricerca e filtri
- ⭐ Preferiti/Salvate
- 📱 QR Code per riscatto
- ⏰ Validità temporale
- 📊 Statistiche utilizzo

### 5. **Dashboard Utente**
- 📊 Statistiche personali
- 🎫 Promozioni riscattate
- 🔗 Gestione referral
- 💰 Saldo punti
- 🏆 Livello/Badge utente

---

## 🗂️ Struttura Progetto

```
CDM86/
├── index.html                      # PWA Entry point
├── manifest.json                   # PWA Manifest
├── service-worker.js               # Service Worker per offline
├── package.json                    # Dependencies Node.js
├── .env.example                    # Environment variables template
├── vercel.json                     # Vercel deployment config
│
├── assets/
│   ├── css/
│   │   ├── main.css               # Stili principali
│   │   └── animations.css         # Animazioni
│   ├── js/
│   │   ├── main.js                # Logica frontend
│   │   ├── config.js              # Configurazione
│   │   ├── auth.js                # Autenticazione frontend
│   │   ├── promotions.js          # Gestione promozioni
│   │   └── referral.js            # Sistema referral
│   └── images/
│       └── icons/                 # PWA icons
│
└── server/
    ├── index.js                   # Server Express principale
    │
    ├── routes/
    │   ├── auth.js                # Route autenticazione
    │   ├── users.js               # Route utenti
    │   ├── promotions.js          # Route promozioni
    │   └── referrals.js           # Route referral
    │
    ├── controllers/
    │   ├── authController.js      # Logic autenticazione
    │   ├── userController.js      # Logic utenti
    │   ├── promotionController.js # Logic promozioni
    │   └── referralController.js  # Logic referral
    │
    ├── models/
    │   ├── User.js                # Schema utente
    │   ├── Promotion.js           # Schema promozione
    │   ├── Referral.js            # Schema referral
    │   └── Transaction.js         # Schema transazioni
    │
    ├── middleware/
    │   ├── auth.js                # JWT verification
    │   ├── validation.js          # Input validation
    │   └── errorHandler.js        # Error handling
    │
    └── utils/
        ├── database.js            # Database connection
        ├── jwt.js                 # JWT utilities
        ├── email.js               # Email service
        └── qrcode.js              # QR code generator
```

---

## 🗄️ Database Schema

### **User (Utente)**
```javascript
{
  _id: ObjectId,
  email: String (unique, required),
  password: String (hashed),
  firstName: String,
  lastName: String,
  phone: String,
  avatar: String (URL),
  
  // Referral
  referralCode: String (unique),
  referredBy: ObjectId (ref: User),
  referralCount: Number (default: 0),
  points: Number (default: 0),
  
  // Status
  isVerified: Boolean (default: false),
  isActive: Boolean (default: true),
  role: String (enum: ['user', 'admin', 'partner']),
  
  // Metadata
  createdAt: Date,
  updatedAt: Date,
  lastLogin: Date
}
```

### **Promotion (Promozione)**
```javascript
{
  _id: ObjectId,
  title: String (required),
  description: String,
  shortDescription: String,
  
  // Media
  image: String (URL),
  images: [String],
  
  // Categorization
  category: String (enum: ['food', 'shopping', 'services', 'entertainment']),
  tags: [String],
  
  // Partner
  partnerId: ObjectId (ref: User),
  partnerName: String,
  partnerLogo: String,
  
  // Discount
  discountType: String (enum: ['percentage', 'fixed', 'freebie']),
  discountValue: Number,
  originalPrice: Number,
  finalPrice: Number,
  
  // Validity
  startDate: Date,
  endDate: Date,
  isActive: Boolean,
  stock: Number (null = unlimited),
  maxPerUser: Number (default: 1),
  
  // Requirements
  minPoints: Number (default: 0),
  requiresReferral: Boolean (default: false),
  
  // Terms
  terms: String,
  redemptionInstructions: String,
  
  // Stats
  views: Number (default: 0),
  redeemCount: Number (default: 0),
  
  // QR Code
  qrCode: String,
  
  // Metadata
  createdAt: Date,
  updatedAt: Date
}
```

### **Referral (Referral)**
```javascript
{
  _id: ObjectId,
  referrerId: ObjectId (ref: User, required),
  referredUserId: ObjectId (ref: User),
  referralCode: String (required),
  
  // Status
  status: String (enum: ['pending', 'completed', 'expired']),
  
  // Reward
  pointsAwarded: Number,
  rewardProcessed: Boolean (default: false),
  
  // Tracking
  clickCount: Number (default: 0),
  conversionDate: Date,
  
  // Metadata
  createdAt: Date,
  updatedAt: Date
}
```

### **Transaction (Transazione/Riscatto)**
```javascript
{
  _id: ObjectId,
  userId: ObjectId (ref: User, required),
  promotionId: ObjectId (ref: Promotion, required),
  
  // Type
  type: String (enum: ['redeem', 'refund']),
  
  // Points
  pointsUsed: Number,
  pointsEarned: Number,
  
  // Status
  status: String (enum: ['pending', 'completed', 'cancelled', 'expired']),
  
  // Redemption
  redemptionCode: String (unique),
  redemptionQR: String,
  redeemedAt: Date,
  expiresAt: Date,
  
  // Verification
  verifiedBy: ObjectId (ref: User), // Partner who verified
  verifiedAt: Date,
  
  // Metadata
  createdAt: Date,
  updatedAt: Date
}
```

---

## 🔐 API Endpoints

### **Authentication**
```
POST   /api/auth/register          # Registrazione
POST   /api/auth/login             # Login
POST   /api/auth/logout            # Logout
POST   /api/auth/refresh           # Refresh token
POST   /api/auth/forgot-password   # Reset password request
POST   /api/auth/reset-password    # Reset password
POST   /api/auth/verify-email      # Verifica email
```

### **Users**
```
GET    /api/users/profile          # Get profilo utente
PUT    /api/users/profile          # Update profilo
GET    /api/users/stats            # Statistiche utente
GET    /api/users/points           # Saldo punti
GET    /api/users/transactions     # Storico transazioni
```

### **Promotions**
```
GET    /api/promotions             # Lista promozioni (public)
GET    /api/promotions/:id         # Dettaglio promozione
GET    /api/promotions/category/:cat # Per categoria
POST   /api/promotions/search      # Ricerca
GET    /api/promotions/favorites   # Preferite (auth)
POST   /api/promotions/:id/favorite # Aggiungi preferita
POST   /api/promotions/:id/redeem  # Riscatta promozione (auth)
```

### **Referrals**
```
GET    /api/referrals/my-code      # Mio codice referral
GET    /api/referrals/stats        # Statistiche referral
GET    /api/referrals/history      # Storico referral
POST   /api/referrals/track-click  # Track click referral
POST   /api/referrals/validate     # Valida codice
```

---

## 🚀 Deployment

### **Development**
```bash
# Install dependencies
npm install

# Create .env from example
cp .env.example .env

# Start development server
npm run dev
```

### **Production (Vercel)**
```bash
# Already configured with vercel.json
# Just push to GitHub and Vercel will auto-deploy
git push origin main
```

---

## 🔄 Flusso Utente

### **1. Registrazione & Onboarding**
```
1. Utente arriva tramite link (opzionale referral code in URL)
2. Registrazione → email, password, nome
3. Verifica email
4. Onboarding: spiega come funziona
5. Genera codice referral personale
6. Bonus punti di benvenuto
```

### **2. Referral**
```
1. Utente condivide link referral
2. Nuovo utente clicca → tracking
3. Nuovo utente si registra → conversione
4. Entrambi ricevono punti reward
5. Dashboard aggiornata con stats
```

### **3. Riscatto Promozione**
```
1. Utente naviga promozioni
2. Seleziona promozione
3. Verifica requisiti (punti, referral)
4. Riscatta → genera QR code
5. Mostra QR al partner
6. Partner scansiona e valida
7. Promozione utilizzata
```

---

## 📱 PWA Features

- **Installabile**: Add to Home Screen
- **Offline**: Service Worker cache
- **Push Notifications**: Nuove promozioni
- **Background Sync**: Sincronizza dati offline
- **Fast**: Caching strategico
- **Responsive**: Mobile-first design

---

## 🔒 Security

- **JWT Authentication**: Token sicuri
- **Password Hashing**: bcrypt
- **Rate Limiting**: Protezione da brute force
- **Helmet.js**: Security headers
- **Input Validation**: Sanitizzazione dati
- **CORS**: Origini controllate

---

## 📊 Analytics & Tracking

- **User Analytics**: Registrazioni, login, attività
- **Promotion Analytics**: View, riscatti, conversione
- **Referral Analytics**: Click, conversioni, ROI
- **Performance**: Page load, API response time

---

## 🎨 UI/UX Features

- **Dark/Light Mode**: Tema personalizzabile
- **Multi-language**: i18n ready
- **Accessibility**: WCAG 2.1 compliant
- **Animations**: Smooth transitions
- **Toast Notifications**: Feedback utente
- **Loading States**: Skeleton screens

---

## 📈 Future Enhancements

- [ ] Payment integration (Stripe/PayPal)
- [ ] Social login (Google, Facebook)
- [ ] Geolocation promotions
- [ ] Chat support
- [ ] Partner dashboard
- [ ] Admin CMS
- [ ] Mobile app (React Native)
- [ ] Gamification avanzata

---

**CDM86 Platform v1.0** - Ready to scale! 🚀