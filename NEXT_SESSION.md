# 🚀 Quick Start - Prossima Sessione

## ✅ Cosa Abbiamo Completato

- ✅ **Interface** - Design approvato e responsive
- ✅ **PWA** - manifest.json + service-worker.js
- ✅ **Backend Structure** - Express server + routes
- ✅ **Database Models** - User, Promotion, Referral, Transaction
- ✅ **Documentation** - 4 documenti completi

---

## 🎯 Prossimi Step (in ordine)

### 1️⃣ Setup MongoDB (PRIMA DI TUTTO)

**Opzione A - MongoDB Locale (5 minuti):**
```bash
# macOS
brew install mongodb-community@7.0
brew services start mongodb-community@7.0

# Verifica
mongosh
```

**Opzione B - MongoDB Atlas Cloud (10 minuti):**
- Segui la guida completa in `DATABASE_SETUP.md`
- Account gratuito con 512MB storage
- Configurazione guidata passo-passo

**Configura .env:**
```bash
# Per MongoDB locale
MONGODB_URI=mongodb://localhost:27017/cdm86

# Per MongoDB Atlas
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/cdm86
```

### 2️⃣ Seed Database
```bash
npm run seed
```

Questo crea:
- 3 utenti (admin, user, partner)
- 6 promozioni complete
- 1 referral di esempio

**Credenziali:**
- Admin: `admin@cdm86.com` / `Admin123!`
- User: `user1@test.com` / `User123!`

### 3️⃣ Test Server
```bash
npm run dev
```

Verifica l'output:
```
✅ MongoDB connesso con successo
📊 Database: cdm86
🚀 CDM86 Platform Server
📡 Server: http://localhost:3000
```

---

## 📝 Cosa Creare Dopo

### File da Creare (in ordine di priorità):

#### 1. Authentication Controller
**File:** `server/controllers/authController.js`

**Endpoints:**
- `POST /api/auth/register` - Registrazione utente
- `POST /api/auth/login` - Login con JWT
- `POST /api/auth/logout` - Logout
- `POST /api/auth/refresh` - Refresh token
- `POST /api/auth/verify-email` - Verifica email
- `POST /api/auth/forgot-password` - Reset password
- `POST /api/auth/reset-password` - Nuova password

**Cosa implementare:**
```javascript
const User = require('../models/User');
const jwt = require('jsonwebtoken');

// Register
exports.register = async (req, res, next) => {
    try {
        const { email, password, firstName, lastName } = req.body;
        
        // 1. Check if user exists
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ 
                error: 'Email già registrata' 
            });
        }
        
        // 2. Create user (password hashed automatically)
        const user = await User.create({
            email,
            password,
            firstName,
            lastName,
            referralCode: generateReferralCode() // Helper function
        });
        
        // 3. Generate JWT
        const token = jwt.sign(
            { userId: user._id, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRE }
        );
        
        // 4. Return user + token
        res.status(201).json({
            success: true,
            user: {
                id: user._id,
                email: user.email,
                firstName: user.firstName,
                lastName: user.lastName,
                referralCode: user.referralCode
            },
            token
        });
    } catch (error) {
        next(error);
    }
};

// Login, Logout, etc...
```

#### 2. User Controller
**File:** `server/controllers/userController.js`

**Endpoints:**
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update profile
- `GET /api/users/stats` - Get user stats
- `GET /api/users/favorites` - Get favorite promotions
- `POST /api/users/favorites/:id` - Add favorite
- `DELETE /api/users/favorites/:id` - Remove favorite

#### 3. Promotion Controller
**File:** `server/controllers/promotionController.js`

**Endpoints:**
- `GET /api/promotions` - List promotions (with filters)
- `GET /api/promotions/:id` - Single promotion
- `POST /api/promotions/search` - Search promotions
- `POST /api/promotions/:id/redeem` - Redeem promotion

#### 4. Referral Controller
**File:** `server/controllers/referralController.js`

**Endpoints:**
- `GET /api/referrals/my-code` - Get my referral code
- `GET /api/referrals/stats` - Get referral stats
- `POST /api/referrals/track` - Track referral click
- `POST /api/referrals/validate` - Validate referral code

---

## 📚 Documenti di Riferimento

Leggi questi file per capire il contesto completo:

1. **DATABASE_SETUP.md** - Setup MongoDB (locale o cloud)
2. **ARCHITECTURE.md** - Architettura completa sistema
3. **PROJECT_STATUS.md** - Stato progetto e checklist
4. **DATABASE_IMPLEMENTATION_COMPLETE.md** - Riepilogo database

---

## 🔗 Links Utili

- **Repository:** https://github.com/Akirayouky/cdm86
- **Dominio:** https://cdm86.com
- **MongoDB Docs:** https://docs.mongodb.com/
- **Mongoose Docs:** https://mongoosejs.com/
- **JWT Docs:** https://jwt.io/

---

## 🎯 Obiettivo Sessione

**Completare Authentication Controller** per poter:
1. ✅ Registrare nuovi utenti
2. ✅ Login con JWT
3. ✅ Proteggere endpoint con middleware auth
4. ✅ Testare con Postman/Thunder Client

Poi procedere con gli altri controllers!

---

## 💡 Tips

### Testing con VS Code REST Client
Crea un file `test.http`:
```http
### Register
POST http://localhost:3000/api/auth/register
Content-Type: application/json

{
  "email": "test@test.com",
  "password": "Test123!",
  "firstName": "Test",
  "lastName": "User"
}

### Login
POST http://localhost:3000/api/auth/login
Content-Type: application/json

{
  "email": "test@test.com",
  "password": "Test123!"
}
```

### MongoDB GUI
- **MongoDB Compass** - GUI ufficiale
- **Studio 3T** - Alternative avanzata
- **MongoDB Atlas Web UI** - Se usi Atlas

---

**🚀 Pronto per la prossima sessione!**

Inizia da qui quando riprendi il lavoro.
