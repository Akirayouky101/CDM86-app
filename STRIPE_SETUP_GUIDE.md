# 💳 GUIDA INTEGRAZIONE STRIPE - SISTEMA PAGAMENTI

## 📋 INDICE
1. [Setup Account Stripe](#1-setup-account-stripe)
2. [Configurazione API Keys](#2-configurazione-api-keys)
3. [Installazione Dipendenze](#3-installazione-dipendenze)
4. [Configurazione Webhook](#4-configurazione-webhook)
5. [Deploy su Vercel](#5-deploy-su-vercel)
6. [Test Pagamenti](#6-test-pagamenti)

---

## 1. SETUP ACCOUNT STRIPE

### Registrazione
1. Vai su https://stripe.com/it
2. Clicca **"Inizia subito"**
3. Compila form con:
   - Email aziendale
   - Nome azienda: **CDM86**
   - Paese: **Italia**
4. Verifica email

### Configurazione Account
1. **Dashboard** → **Impostazioni** → **Dettagli dell'account**
   - Nome pubblico: `CDM86 - Centro Documentazione Multimediale`
   - URL sito: `https://cdm86.com`
   - Email supporto: `referralcdm86@cdm86.com`

2. **Attiva Modalità Test**
   - Toggle "Visualizza dati di test" in alto a destra
   - Rimani in modalità test fino a quando tutto funziona

---

## 2. CONFIGURAZIONE API KEYS

### Ottieni le chiavi
1. **Dashboard Stripe** → **Sviluppatori** → **Chiavi API**
2. Copia:
   - ✅ **Publishable key** (inizia con `pk_test_`)
   - ✅ **Secret key** (inizia con `sk_test_`)

### Aggiungi a Vercel
```bash
# 1. Vai su Vercel Dashboard
# 2. Progetto CDM86-NEW → Settings → Environment Variables

# Aggiungi queste variabili:
STRIPE_SECRET_KEY=sk_test_YOUR_SECRET_KEY_HERE
STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_PUBLISHABLE_KEY_HERE
STRIPE_WEBHOOK_SECRET=whsec_YOUR_WEBHOOK_SECRET_HERE (lo otterrai dopo)
FRONTEND_URL=https://cdm86.com
```

### Aggiorna frontend
1. Apri `assets/js/payment-manager.js`
2. Sostituisci linea 7:
```javascript
this.stripePublicKey = 'pk_test_YOUR_ACTUAL_PUBLISHABLE_KEY';
```

---

## 3. INSTALLAZIONE DIPENDENZE

### Aggiungi Stripe al package.json
```json
{
  "dependencies": {
    "@supabase/supabase-js": "^2.39.0",
    "stripe": "^14.10.0"
  }
}
```

### Installa
```bash
npm install stripe --save
```

---

## 4. CONFIGURAZIONE WEBHOOK

### Setup Webhook Endpoint
1. **Dashboard Stripe** → **Sviluppatori** → **Webhook**
2. Clicca **"Aggiungi endpoint"**
3. URL endpoint: `https://cdm86.com/api/stripe-webhook`
4. Eventi da ascoltare:
   - ✅ `checkout.session.completed`
   - ✅ `customer.subscription.created`
   - ✅ `customer.subscription.updated`
   - ✅ `customer.subscription.deleted`
   - ✅ `invoice.payment_failed`

5. Clicca **"Aggiungi endpoint"**
6. Copia il **Signing secret** (inizia con `whsec_`)
7. Aggiungilo alle variabili Vercel come `STRIPE_WEBHOOK_SECRET`

---

## 5. DEPLOY SU VERCEL

### File da deployare
```
✅ database/setup_payments_system.sql (eseguire su Supabase)
✅ api/create-checkout-session.js
✅ api/stripe-webhook.js
✅ assets/js/payment-manager.js
```

### Comandi deploy
```bash
# 1. Esegui SQL su Supabase
# Apri Supabase Dashboard → SQL Editor
# Copia/incolla contenuto di setup_payments_system.sql
# Clicca "Run"

# 2. Commit e push
git add .
git commit -m "💳 FEATURE: Integrazione sistema pagamenti Stripe"
git push origin main

# 3. Vercel deployerà automaticamente
```

### Verifica deploy
1. Apri dashboard Vercel
2. Controlla che le variabili d'ambiente siano impostate
3. Verifica che build sia completato senza errori
4. Testa endpoint: `https://cdm86.com/api/create-checkout-session`

---

## 6. TEST PAGAMENTI

### Carte di test Stripe
```
✅ Successo: 4242 4242 4242 4242
   Data: qualsiasi futura (es. 12/25)
   CVC: qualsiasi 3 cifre (es. 123)
   
❌ Fallimento: 4000 0000 0000 0002
⚠️ Richiede autenticazione: 4000 0025 0000 3155
```

### Procedura test
1. Apri dashboard CDM86
2. Clicca **"Upgrade a Premium"**
3. Compila form con carta test
4. Completa pagamento
5. Verifica reindirizzamento a `/dashboard?payment=success`
6. Controlla che utente sia attivato in Supabase

### Verifica webhook
```bash
# Stripe Dashboard → Sviluppatori → Webhook
# Clicca sul tuo endpoint
# Verifica sezione "Eventi recenti"
# Devono comparire gli eventi ricevuti con status 200
```

---

## 📊 DASHBOARD STRIPE

### Metriche da monitorare
- **Pagamenti riusciti** → Dashboard → Panoramica
- **Abbonamenti attivi** → Fatturazione → Abbonamenti
- **Clienti** → Clienti
- **Eventi webhook** → Sviluppatori → Webhook → Eventi

---

## 🚀 PASSAGGIO IN PRODUZIONE

### Quando sei pronto
1. **Dashboard Stripe** → Toggle "Visualizza dati reali"
2. Completa onboarding Stripe:
   - Verifica identità
   - Aggiungi informazioni bancarie
   - Completa KYC (Know Your Customer)
3. Ottieni chiavi produzione:
   - `pk_live_...`
   - `sk_live_...`
4. Aggiorna variabili Vercel con chiavi live
5. Ricrea webhook con URL produzione

---

## 💰 COMMISSIONI STRIPE ITALIA

- **Carte europee**: 1.5% + €0.25 per transazione
- **Carte extra-UE**: 2.9% + €0.25
- **Abbonamenti**: stesso costo
- **Nessun costo fisso mensile**

### Esempio per €9.99/mese
```
Incasso: €9.99
Commissione: €0.40 (1.5% + €0.25)
Netto: €9.59
```

---

## 🔧 TROUBLESHOOTING

### Webhook non riceve eventi
- Verifica URL corretto su Stripe Dashboard
- Controlla che STRIPE_WEBHOOK_SECRET sia impostato
- Testa manualmente: Stripe Dashboard → Webhook → Invia evento di test

### Pagamento non attiva utente
- Controlla log Vercel: Dashboard → Progetto → Logs
- Verifica evento `checkout.session.completed` ricevuto
- Controlla tabella payments su Supabase

### Errore "Invalid API Key"
- Verifica che STRIPE_SECRET_KEY sia corretto
- Assicurati di usare chiave test in modalità test

---

## 📞 SUPPORTO

- **Stripe Docs**: https://stripe.com/docs
- **Stripe Support**: support@stripe.com
- **Community**: https://stackoverflow.com/questions/tagged/stripe-payments

---

## ✅ CHECKLIST FINALE

Prima di andare live:
- [ ] Account Stripe verificato
- [ ] Chiavi API configurate su Vercel
- [ ] Webhook endpoint attivo e funzionante
- [ ] Database tables create (payments, subscriptions, subscription_plans)
- [ ] Test pagamento completato con successo
- [ ] Utente attivato dopo pagamento
- [ ] Email di conferma funzionante (opzionale)
- [ ] Informazioni bancarie aggiunte a Stripe
- [ ] KYC completato
- [ ] Passaggio a chiavi produzione

**Fatto!** 🎉 Il sistema pagamenti è pronto!
