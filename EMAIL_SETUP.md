# 📧 Configurazione Email - CDM86

## 🎯 Soluzione Immediata: Disabilita Verifica Email (Sviluppo)

Per permettere agli utenti di registrarsi e loggarsi **immediatamente** senza aspettare l'email di verifica:

### Passaggi in Supabase Dashboard

1. **Accedi a Supabase**
   - Vai su https://supabase.com
   - Seleziona il progetto **CDM86**

2. **Disabilita Email Confirmation**
   - Clicca su **Authentication** nel menu laterale
   - Vai su **Settings** (oppure **Providers**)
   - Trova la sezione **Email**
   - **DISATTIVA**: ☐ **Confirm email**
   - Clicca **Save**

3. **Verifica RLS Policy** (importante!)
   - Vai su **Authentication** → **Policies**
   - Assicurati che le policy permettano l'accesso anche senza `email_confirmed_at`
   - Se necessario, aggiorna le policy

### Risultato
✅ Gli utenti possono registrarsi e loggarsi subito  
✅ Non serve attendere email di verifica  
✅ Perfetto per sviluppo e testing  

---

## 🚀 Configurazione SMTP per Produzione

Quando l'app andrà in produzione, riattiva la verifica email e configura SMTP personalizzato:

### Step 1: Crea App Password Gmail

1. Vai su https://myaccount.google.com/security
2. Attiva **2-Step Verification** (se non già attivo)
3. Vai su **App passwords**
4. Genera nuova password per "Mail" → "Other (CDM86)"
5. **SALVA** la password generata (es: `abcd efgh ijkl mnop`)

### Step 2: Configura SMTP in Supabase

1. **Supabase Dashboard** → **Project Settings** → **Auth**
2. Scorri fino a **SMTP Settings**
3. Attiva: ☑️ **Enable Custom SMTP**
4. Compila:
   ```
   SMTP Host: smtp.gmail.com
   Port: 587
   Sender email: noreply@cdm86.com (o la tua email)
   Sender name: CDM86 Platform
   Username: tuaemail@gmail.com
   Password: [app password generata]
   ```
5. Clicca **Save**

### Step 3: Personalizza Email Templates

1. **Authentication** → **Email Templates**
2. Personalizza **Confirm signup**:

```html
<h2>Benvenuto su CDM86!</h2>
<p>Ciao {{ .Name }},</p>
<p>Grazie per esserti registrato su CDM86 Platform.</p>
<p>Clicca sul pulsante qui sotto per confermare la tua email:</p>
<p><a href="{{ .ConfirmationURL }}">Conferma Email</a></p>
<p>Oppure copia questo link: {{ .ConfirmationURL }}</p>
<p>A presto,<br>Il team CDM86</p>
```

3. Salva e testa

### Step 4: Riattiva Email Confirmation

1. **Authentication** → **Settings** → **Email**
2. Attiva: ☑️ **Confirm email**
3. Salva

### Step 5: Testa

1. Registra un nuovo utente con email reale
2. Controlla inbox (e spam!)
3. Clicca sul link di conferma
4. Verifica che il login funzioni

---

## 🔍 Troubleshooting

### Email finiscono in SPAM

**Soluzione 1: Configura SPF/DKIM**
- Aggiungi record DNS per il tuo dominio
- Verifica su https://mxtoolbox.com/spf.aspx

**Soluzione 2: Usa servizio dedicato**
- SendGrid (100 email/giorno gratis)
- Mailgun (100 email/giorno gratis)
- Resend (3000 email/mese gratis)

### Email non arrivano

1. Controlla **SMTP Settings** in Supabase
2. Verifica che App Password Gmail sia corretta
3. Controlla i log in Supabase → **Logs**
4. Prova con un'altra email (Gmail, Outlook, etc.)

### Utenti già registrati non verificati

Se hai utenti registrati PRIMA di disabilitare la verifica:

```sql
-- Esegui in Supabase SQL Editor
UPDATE auth.users 
SET email_confirmed_at = NOW() 
WHERE email_confirmed_at IS NULL;
```

---

## 📊 Limiti Email

### Supabase Default SMTP
- ⚠️ **Limite**: ~100 email/ora
- ⚠️ Solo per testing
- ❌ Non affidabile per produzione

### Gmail SMTP
- ✅ **Limite**: 500 email/giorno
- ✅ Affidabile
- ✅ Gratuito
- ⚠️ Rischio SPAM se volume alto

### Servizi Professionali (Consigliati per Produzione)
- **SendGrid**: 100/giorno gratis, poi a pagamento
- **Mailgun**: 100/giorno gratis
- **Resend**: 3000/mese gratis
- **Amazon SES**: $0.10 per 1000 email

---

## 🎯 Raccomandazioni

### Per Sviluppo (ORA)
✅ Disabilita verifica email  
✅ Usa Supabase default SMTP  

### Per Staging
✅ Attiva verifica email  
✅ Configura Gmail SMTP  

### Per Produzione
✅ Attiva verifica email  
✅ Usa servizio professionale (SendGrid/Resend)  
✅ Configura SPF/DKIM  
✅ Monitora deliverability  

---

## 📝 Checklist Rapida

**Adesso (Sviluppo):**
- [ ] Disabilita "Confirm email" in Supabase
- [ ] Testa registrazione
- [ ] Testa login immediato

**Prima del Deploy:**
- [ ] Crea App Password Gmail
- [ ] Configura SMTP in Supabase
- [ ] Personalizza email templates
- [ ] Riattiva "Confirm email"
- [ ] Testa con email reale
- [ ] Verifica deliverability

---

**Stato Attuale**: 🟢 Email verification DISABILITATA (sviluppo)  
**Prossimo Step**: 🔵 Configurare SMTP prima della produzione
