# 📧 Sistema Email Automatiche per Organizzazioni Approvate

## 🎯 Obiettivo
Quando un admin approva una segnalazione azienda, il sistema:
1. ✅ Crea l'organizzazione nel database
2. 🔑 Genera password temporanea
3. 📧 **Invia email** all'organizzazione con credenziali
4. 📬 **Notifica l'utente** che ha segnalato

---

## 📦 Componenti Implementati

### 1. Database Migration
**File:** `database/add_email_notifications.sql`

**Cosa fa:**
- Crea tabella `organization_temp_passwords` per salvare password temporanee
- Modifica trigger `handle_company_report_approval()` per salvare la password
- Le password scadono dopo 7 giorni

**Esegui su Supabase:**
```sql
-- Esegui tutto il contenuto di add_email_notifications.sql
```

### 2. Edge Function per Email
**File:** `supabase/functions/send-organization-email/index.ts`

**Cosa fa:**
- Recupera dati organizzazione e password temporanea
- Invia email HTML formattata tramite Resend
- Marca email come "inviata" nel database

---

## 🚀 Setup Passo-Passo

### Step 1: Esegui Migration Database
1. Vai su **Supabase Dashboard → SQL Editor**
2. Copia e incolla tutto il contenuto di `database/add_email_notifications.sql`
3. Clicca **RUN**

### Step 2: Configura Resend (Servizio Email)
1. Vai su [https://resend.com](https://resend.com)
2. Crea account gratuito (3000 email/mese gratis)
3. Vai su **API Keys**
4. Copia la tua API Key

### Step 3: Deploy Edge Function
```bash
# Installa Supabase CLI
npm install -g supabase

# Login
supabase login

# Link al tuo progetto
supabase link --project-ref <YOUR_PROJECT_REF>

# Deploy function
supabase functions deploy send-organization-email --no-verify-jwt

# Imposta secrets
supabase secrets set RESEND_API_KEY=re_xxxxxxxxxxxxx
```

### Step 4: Configura Webhook nel Trigger
Aggiungi questa funzione nel trigger per chiamare automaticamente la Edge Function:

```sql
-- Alla fine del trigger handle_company_report_approval, aggiungi:

-- Trigger email automatica (chiama Edge Function)
PERFORM net.http_post(
  url := 'https://<YOUR_PROJECT_REF>.supabase.co/functions/v1/send-organization-email',
  headers := jsonb_build_object(
    'Content-Type', 'application/json',
    'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
  ),
  body := jsonb_build_object(
    'organizationId', v_organization_id
  )::text
);
```

---

## 📧 Template Email

L'email inviata include:
- ✉️ Benvenuto personalizzato con nome organizzazione
- 🔑 Credenziali di accesso (email + password temporanea)
- 🎫 Codice referral
- 🔗 Pulsante "Accedi ora"
- 📝 Istruzioni prossimi passi
- ⚠️ Reminder di cambiare password

---

## 🧪 Test Manuale

### Invia email per organizzazione esistente:
```bash
curl -X POST 'https://<YOUR_PROJECT_REF>.supabase.co/functions/v1/send-organization-email' \
  -H "Authorization: Bearer <YOUR_ANON_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"organizationId": "<ORGANIZATION_UUID>"}'
```

### Verifica password temporanee nel database:
```sql
SELECT 
  o.name,
  o.email,
  otp.temp_password,
  otp.email_sent,
  otp.created_at,
  otp.expires_at
FROM organization_temp_passwords otp
JOIN organizations o ON o.id = otp.organization_id
WHERE otp.email_sent = false
ORDER BY otp.created_at DESC;
```

---

## 🔧 Alternative Semplici (Senza Edge Functions)

### Opzione A: Email tramite Supabase Auth
Puoi usare il sistema email integrato di Supabase modificando i template in:
**Authentication → Email Templates → Invite user**

### Opzione B: Vedere password in Admin Panel
Aggiungi una sezione nell'admin panel per visualizzare le password temporanee:

```javascript
// In admin-panel.html
const { data } = await supabaseClient
  .from('organization_temp_passwords')
  .select(`
    temp_password,
    email_sent,
    organizations (name, email)
  `)
  .eq('email_sent', false)
  .order('created_at', { ascending: false })
```

### Opzione C: Download CSV con password
Crea pulsante per scaricare CSV con tutte le password non inviate.

---

## 📋 Checklist

- [ ] Eseguita migration database (`add_email_notifications.sql`)
- [ ] Registrato su Resend.com e ottenuta API Key
- [ ] Deployata Edge Function su Supabase
- [ ] Configurati secrets (RESEND_API_KEY)
- [ ] Testata funzione con curl
- [ ] Approvata segnalazione di test
- [ ] Verificata ricezione email

---

## 🎯 Prossime Sessioni

### Email Utente che Segnala
Crea seconda Edge Function per notificare l'utente:
```
Soggetto: ✅ La tua segnalazione è stata approvata!
Contenuto:
- Nome azienda segnalata
- Compenso ricevuto (€30 + MLM se inserzionista)
- Punti guadagnati
- Link alla dashboard
```

### Dashboard Admin - Gestione Password
Pagina per:
- Vedere tutte le password temporanee non inviate
- Reinviare email
- Generare nuova password
- Scaricare CSV

---

## ⚙️ Configurazione Dominio Email

Per evitare che le email finiscano in spam:

1. **Verifica dominio** su Resend
2. Aggiungi record DNS:
   - SPF
   - DKIM
   - DMARC

3. Usa indirizzo mittente verificato:
   ```
   from: 'CDM86 <noreply@cdm86.com>'
   ```

---

## 🆘 Troubleshooting

### Email non arrivano
- ✅ Verifica API Key Resend
- ✅ Controlla log Edge Function su Supabase
- ✅ Verifica dominio email mittente
- ✅ Controlla cartella spam

### Password non salvata
- ✅ Verifica tabella `organization_temp_passwords` esiste
- ✅ Controlla log PostgreSQL per errori trigger

### Edge Function fallisce
- ✅ Verifica secrets configurati
- ✅ Controlla formato JSON request
- ✅ Verifica permission database

---

## 📚 Risorse

- [Resend Documentation](https://resend.com/docs)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Email Templates Best Practices](https://really good emails.com)
