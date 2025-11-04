# 🧪 TEST PANNELLO AZIENDE - GUIDA COMPLETA

## 📋 FASE 1: SETUP DATABASE (5 min)

### 1.1 Esegui SQL su Supabase
```bash
# 1. Apri Supabase Dashboard
# 2. Vai su SQL Editor
# 3. Copia TUTTO il contenuto di setup_organization_panel.sql
# 4. Incolla e clicca "Run"
```

### 1.2 Verifica risultati
Dovresti vedere:
```
✅ ALTER TABLE organizations - Success
✅ UPDATE organizations - Success  
✅ CREATE TABLE organization_benefits - Success
✅ CREATE INDEX - Success
```

### 1.3 Controlla dati azienda
Esegui questa query per vedere i codici:
```sql
SELECT 
    name,
    email,
    referral_code as "Codice Dipendenti",
    referral_code_external as "Codice Esterni",
    total_points
FROM organizations;
```

**Risultato atteso:**
```
name: "Azienda Test"
email: "azienda@cdm86.com"
Codice Dipendenti: "CDM001"
Codice Esterni: "CDM001_EXT"
total_points: 0
```

---

## 📋 FASE 2: TEST REFERRAL DIPENDENTI (10 min)

### 2.1 Crea utente dipendente
```sql
-- Trova l'ID della tua azienda
SELECT id, name, referral_code FROM organizations LIMIT 1;

-- Segna utente come dipendente
UPDATE users 
SET 
    is_employee = true,
    organization_id = 'TUO_ORGANIZATION_ID_QUI'
WHERE email = 'dipendente1@cdm86.com';
```

### 2.2 Test registrazione con codice dipendenti
1. **Apri in incognito**: https://cdm86.com
2. **Clicca registrati**
3. **Usa codice referral**: `CDM001` (codice dipendenti)
4. **Completa registrazione**:
   - Email: `dipendente2@test.com`
   - Nome: `Mario`
   - Cognome: `Rossi`

### 2.3 Verifica in database
```sql
-- Controlla nuovo utente
SELECT 
    email,
    first_name,
    is_employee,
    organization_id,
    referred_by_id
FROM users 
WHERE email = 'dipendente2@test.com';
```

**Risultato atteso:**
```
✅ is_employee = true (perché usato codice aziendale)
✅ organization_id = ID dell'azienda
✅ referred_by_id = ID utente che ha condiviso
```

---

## 📋 FASE 3: TEST REFERRAL ESTERNI (10 min)

### 3.1 Test registrazione con codice esterno
1. **Apri in incognito**: https://cdm86.com
2. **Clicca registrati**
3. **Usa codice referral**: `CDM001_EXT` (codice esterni)
4. **Completa registrazione**:
   - Email: `amico1@test.com`
   - Nome: `Luigi`
   - Cognome: `Verdi`

### 3.2 Verifica in database
```sql
SELECT 
    email,
    first_name,
    is_employee,
    referred_by_organization_external,
    organization_id
FROM users 
WHERE email = 'amico1@test.com';
```

**Risultato atteso:**
```
✅ is_employee = false (è un amico esterno)
✅ referred_by_organization_external = true
✅ organization_id = ID dell'azienda
```

---

## 📋 FASE 4: TEST PANNELLO AZIENDA (15 min)

### 4.1 Crea credenziali azienda
```sql
-- Verifica email e password azienda
SELECT email FROM organizations WHERE id = 'TUO_ORG_ID';

-- Se non esiste, creala nella tabella auth.users
-- (Oppure usa admin panel per creare login azienda)
```

### 4.2 Accedi al pannello
1. Vai su: https://cdm86.com/organization-dashboard.html
2. Login con credenziali azienda
3. Dovresti vedere:
   - 📊 **Dashboard con statistiche**
   - 👥 **Lista dipendenti** (is_employee = true)
   - 🌍 **Lista amici esterni** (referred_by_organization_external = true)
   - 💰 **Punti totali azienda**
   - 🎁 **Benefit disponibili**

---

## 📋 FASE 5: TEST SISTEMA PAGAMENTI (20 min)

### 5.1 Registrati su Stripe
1. Vai su: https://stripe.com/it
2. Clicca **"Inizia subito"**
3. Compila form registrazione
4. **Rimani in modalità TEST** (toggle in alto a destra)

### 5.2 Ottieni API Keys
1. **Dashboard Stripe** → **Sviluppatori** → **Chiavi API**
2. Copia:
   - `pk_test_...` (Publishable key)
   - `sk_test_...` (Secret key)

### 5.3 Configura Vercel
1. **Vercel Dashboard** → Progetto **CDM86-NEW**
2. **Settings** → **Environment Variables**
3. Aggiungi:
```
STRIPE_SECRET_KEY=sk_test_TUA_CHIAVE_QUI
STRIPE_PUBLISHABLE_KEY=pk_test_TUA_CHIAVE_QUI
FRONTEND_URL=https://cdm86.com
```

### 5.4 Aggiorna payment-manager.js
```javascript
// Apri: assets/js/payment-manager.js
// Linea 7, sostituisci:
this.stripePublicKey = 'pk_test_TUA_CHIAVE_PUBBLICA_QUI';
```

### 5.5 Deploy su Vercel
```bash
git add .
git commit -m "💳 SETUP: Configurazione sistema pagamenti Stripe"
git push origin main
```

### 5.6 Test pagamento
1. **Apri dashboard utente**: https://cdm86.com/dashboard
2. **Clicca "Upgrade Premium"** (se hai creato il bottone)
3. **Carta di test**: `4242 4242 4242 4242`
4. **Data**: `12/25`
5. **CVC**: `123`
6. **Completa pagamento**

### 5.7 Verifica risultato
```sql
-- Controlla pagamento registrato
SELECT 
    user_id,
    amount,
    status,
    payment_type,
    created_at
FROM payments
ORDER BY created_at DESC
LIMIT 1;

-- Controlla utente attivato
SELECT email, is_active, is_verified 
FROM users 
WHERE id = 'TUO_USER_ID';
```

**Risultato atteso:**
```
✅ Pagamento status = 'completed'
✅ Utente is_active = true
✅ Redirect a /dashboard?payment=success
```

---

## 🐛 TROUBLESHOOTING

### Problema: "Referral code non trovato"
```sql
-- Controlla che l'azienda abbia entrambi i codici
SELECT referral_code, referral_code_external 
FROM organizations;

-- Se NULL, rigenera:
UPDATE organizations 
SET referral_code_external = referral_code || '_EXT'
WHERE referral_code_external IS NULL;
```

### Problema: "is_employee rimane false con codice aziendale"
```sql
-- Verifica trigger handle_new_user
-- Deve controllare se referral_code contiene '_EXT'
-- Se NO → is_employee = true
-- Se SI → referred_by_organization_external = true
```

### Problema: "Webhook Stripe non riceve eventi"
1. **Stripe Dashboard** → **Sviluppatori** → **Webhook**
2. Clicca sul tuo endpoint
3. **Invia evento di test** → `checkout.session.completed`
4. Verifica log Vercel

---

## ✅ CHECKLIST TEST COMPLETO

- [ ] Database: setup_organization_panel.sql eseguito
- [ ] Database: organization_benefits table creata
- [ ] Azienda: referral_code_external generato
- [ ] Test: Registrazione con codice dipendenti (is_employee = true)
- [ ] Test: Registrazione con codice esterni (referred_by_organization_external = true)
- [ ] Stripe: Account creato
- [ ] Stripe: API keys configurate su Vercel
- [ ] Deploy: Codice pushato su Vercel
- [ ] Test: Pagamento con carta test completato
- [ ] Verifica: Utente attivato dopo pagamento
- [ ] Pannello: organization-dashboard.html accessibile

---

## 📊 QUERY UTILI PER DEBUG

### Mostra tutti i dipendenti di un'azienda
```sql
SELECT 
    email,
    first_name || ' ' || last_name as nome_completo,
    is_employee,
    points
FROM users
WHERE organization_id = 'TUO_ORG_ID'
AND is_employee = true;
```

### Mostra tutti gli amici esterni
```sql
SELECT 
    email,
    first_name || ' ' || last_name as nome_completo,
    referred_by_organization_external,
    points
FROM users
WHERE organization_id = 'TUO_ORG_ID'
AND referred_by_organization_external = true;
```

### Calcola punti totali azienda
```sql
SELECT 
    o.name,
    COUNT(DISTINCT CASE WHEN u.is_employee = true THEN u.id END) as num_dipendenti,
    COUNT(DISTINCT CASE WHEN u.referred_by_organization_external = true THEN u.id END) as num_esterni,
    SUM(u.points) as punti_totali
FROM organizations o
LEFT JOIN users u ON u.organization_id = o.id
WHERE o.id = 'TUO_ORG_ID'
GROUP BY o.id, o.name;
```

### Mostra ultimi pagamenti
```sql
SELECT 
    u.email,
    p.amount,
    p.status,
    p.payment_type,
    p.created_at
FROM payments p
JOIN users u ON u.id = p.user_id
ORDER BY p.created_at DESC
LIMIT 10;
```

---

## 🚀 PROSSIMI STEP

Dopo che tutto funziona:
1. ✅ Crea UI per pannello azienda (organization-dashboard.html)
2. ✅ Aggiungi gestione benefit aziendali
3. ✅ Implementa tracking punti in tempo reale
4. ✅ Setup webhook Stripe in produzione
5. ✅ Test end-to-end completo

**Buon test!** 🎉
