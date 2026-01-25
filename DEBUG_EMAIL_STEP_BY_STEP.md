# 🔍 GUIDA COMPLETA DEBUG EMAIL NON ARRIVA

## PROBLEMA: Email notifica non arriva all'azienda

---

## 🎯 STEP 1: TEST MANUALE EDGE FUNCTION

### Apri il file di test:
```
https://cdm86-new.vercel.app/test-email-notification.html
```

### Compila il form:
- **Email Azienda**: usa la TUA email Gmail/Outlook
- **Nome Azienda**: Test Company
- **Nome Referrer**: Mario Rossi
- **Codice Referral**: ABC123

### Clicca "Invia Email Test"

### Risultati attesi:

#### ✅ SE FUNZIONA:
```
✅ Email inviata con successo!
{
  "success": true,
  "emailId": "re_abc123...",
  "message": "Notification email sent successfully"
}
```
→ **Email configurata correttamente!** Controlla inbox/spam

#### ❌ SE ERRORE:
Vai allo STEP 2 in base all'errore

---

## 🔍 STEP 2: VERIFICA RESEND_API_KEY

### Opzione A: Supabase Dashboard

1. Vai su: https://supabase.com/dashboard/project/uchrjlngfzfibcpdxtky/settings/functions
2. Clicca su **"Edge Functions Secrets"**
3. Verifica che esista:
   - **Name**: `RESEND_API_KEY`
   - **Value**: `re_9spPuEQJ_52BQ6qiua7e6qSJSq4uXbsX3`

#### ❌ Se NON esiste:
Aggiungila:
1. Clicca "New Secret"
2. Name: `RESEND_API_KEY`
3. Value: `re_9spPuEQJ_52BQ6qiua7e6qSJSq4uXbsX3`
4. Clicca "Save"
5. **RIDEPLOY** Edge Function:
   ```bash
   npx supabase functions deploy send-company-notification --no-verify-jwt
   ```

### Opzione B: CLI (più veloce)

```bash
# Aggiungi il secret
npx supabase secrets set RESEND_API_KEY=re_9spPuEQJ_52BQ6qiua7e6qSJSq4uXbsX3

# Rideploy
npx supabase functions deploy send-company-notification --no-verify-jwt
```

---

## 📊 STEP 3: CONTROLLA LOGS SUPABASE

### Vai ai logs:
https://supabase.com/dashboard/project/uchrjlngfzfibcpdxtky/functions/send-company-notification/logs

### Cerca nei logs:

#### ✅ Se vedi:
```
📧 Received notification request: {...}
✅ RESEND_API_KEY is configured
📤 Sending email to: test@example.com
📨 Resend response: {...}
✅ Email sent successfully! ID: re_xxx
```
→ **Edge Function OK!** Vai allo STEP 4

#### ❌ Se vedi:
```
❌ RESEND_API_KEY is not set!
```
→ **API Key mancante!** Torna allo STEP 2

#### ❌ Se vedi:
```
Resend API error: {...}
```
→ **Problema Resend!** Vai allo STEP 5

#### ❌ Se NON vedi NULLA:
→ **Edge Function non chiamata!** Vai allo STEP 6

---

## 📧 STEP 4: VERIFICA RESEND DASHBOARD

### Vai su Resend:
https://resend.com/emails

### Cerca l'email:
- Filtro: ultimi 30 minuti
- Destinatario: la tua email

### Status:

#### ✅ **Delivered**:
Email inviata! Controlla:
1. Inbox
2. Cartella Spam/Junk
3. Filtri email automatici

#### ⚠️ **Not Found**:
Email NON inviata da Resend
→ Problema in Edge Function, torna allo STEP 3

#### ⚠️ **Sandbox Mode**:
```
Error: Email can only be sent to verified addresses in sandbox mode
```

**FIX**: Aggiungi email come verified
1. Resend → Settings → Verified Emails
2. Add Email → Inserisci la tua email
3. Verifica email (clicca link in email ricevuta)
4. Riprova test

---

## 🔍 STEP 5: DEBUG ERRORI SPECIFICI

### Errore: "Missing required parameters"
**Causa**: Dati mancanti
**Fix**: Verifica che il form invii tutti i parametri:
- companyEmail
- companyName
- referrerName
- referralCode

### Errore: "RESEND_API_KEY is not configured"
**Causa**: Secret non impostato
**Fix**: Vai allo STEP 2

### Errore: "Invalid API Key"
**Causa**: API Key sbagliata o scaduta
**Fix**: 
1. Login su Resend.com
2. Settings → API Keys
3. Verifica che `re_9spPuEQJ_52BQ6qiua7e6qSJSq4uXbsX3` sia valida
4. Se scaduta, genera nuova API Key e aggiorna Secret

### Errore: CORS
**Causa**: Edge Function non configurata correttamente
**Fix**: Rideploy Edge Function

---

## 🧪 STEP 6: TEST DA CONSOLE BROWSER

### Apri Console (F12) su dashboard.html e esegui:

```javascript
// Test 1: Verifica Supabase client
console.log('Supabase client:', window.supabaseClient);

// Test 2: Chiama Edge Function direttamente
const testResult = await window.supabaseClient.functions.invoke(
  'send-company-notification',
  {
    body: {
      companyEmail: 'tua.email@gmail.com',
      companyName: 'Test Company',
      referrerName: 'Mario Rossi',
      referralCode: 'ABC123'
    }
  }
);

console.log('Test result:', testResult);
```

### Risultati:

#### ✅ Success:
```javascript
{
  data: {
    success: true,
    emailId: "re_...",
    message: "Notification email sent successfully"
  },
  error: null
}
```
→ **Funziona!** Problema è nel flusso della dashboard

#### ❌ Error:
```javascript
{
  data: null,
  error: {
    message: "..."
  }
}
```
→ Vedi messaggio errore e vai allo step corrispondente

---

## 🔄 STEP 7: VERIFICA FLUSSO DASHBOARD

### Apri Console (F12) su dashboard.html

### Fai il flusso completo:
1. Segnala Azienda
2. Seleziona "❌ NO" su "Azienda consapevole?"
3. Modale appare
4. Clicca "Sì, invia email"
5. Compila form
6. Clicca INVIA

### Verifica console log:

```
✅ Utente ha scelto di inviare email        ← OK
📧 Invio email notifica azienda...          ← OK
✅ Email notifica inviata! {...}            ← OK
✅ Segnalazione inviata!                    ← OK
```

### Se manca qualcosa:

#### ❌ Non vedi "Invio email notifica azienda...":
**Causa**: `window.sendCompanyNotification` non è `true`
**Fix**: Verifica che la modale salvi correttamente la scelta

#### ❌ Non vedi "Email notifica inviata!":
**Causa**: Errore nella chiamata Edge Function
**Debug**: Controlla errore nella console

---

## 🎯 CHECKLIST COMPLETA

Prima di testare di nuovo, verifica:

- [ ] **Hard refresh** browser (Ctrl+Shift+R)
- [ ] **RESEND_API_KEY** configurata in Edge Function Secrets
- [ ] **Edge Function** deployata (ultima versione)
- [ ] **Email destinatario** è VERIFIED su Resend (se sandbox mode)
- [ ] **Logs Supabase** Edge Function accessibili
- [ ] **Console browser** aperta (F12) per vedere log
- [ ] **Test manuale** con test-email-notification.html funziona

---

## 🚀 QUICK FIX (più probabile)

### Il problema più comune è la RESEND_API_KEY non configurata.

**FIX RAPIDO:**

```bash
cd /Users/akirayouky/Desktop/Siti/CDM86-NEW

# Aggiungi il secret (esegui questo comando!)
npx supabase secrets set RESEND_API_KEY=re_9spPuEQJ_52BQ6qiua7e6qSJSq4uXbsX3

# Rideploy Edge Function
npx supabase functions deploy send-company-notification --no-verify-jwt

# Aspetta 10 secondi, poi riprova test
```

**Poi testa:**
1. Vai su: https://cdm86-new.vercel.app/test-email-notification.html
2. Inserisci la TUA email
3. Clicca "Invia Email Test"
4. Controlla inbox/spam

---

## 📞 SE ANCORA NON FUNZIONA

Mandami screenshot di:
1. Console browser (F12) durante il test
2. Logs Supabase Edge Function
3. Risultato del test test-email-notification.html

E dimmi esattamente cosa vedi! 🔍
