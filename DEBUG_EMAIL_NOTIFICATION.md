# 🐛 DEBUG EMAIL NOTIFICA AZIENDA

## ✅ FIX APPLICATI

### 1. Modale appare SUBITO alla selezione di "NO"
- ✅ Aggiunto `onchange="handleCompanyAwareChange('no')"` al radio button
- ✅ Modale si apre immediatamente senza aspettare il submit
- ✅ Scelta utente salvata in `window.sendCompanyNotification`

### 2. Email inviata al momento del submit
- ✅ Logica spostata in `submitReportCompany()`
- ✅ Email inviata PRIMA del submit segnalazione
- ✅ Logging dettagliato aggiunto

---

## 🧪 TEST RAPIDO

### Flusso Aggiornato:
```
1. Dashboard → Segnala Azienda
2. Compila campi:
   - Nome Azienda: Test Company
   - Email: TUA_EMAIL@gmail.com (usa email VERA!)
   - Altri campi...
   
3. Alla domanda "Azienda consapevole?"
   → Clicca ❌ NO
   
4. ⚡ MODALE APPARE SUBITO!
   "Vuoi segnalare il sito all'azienda?"
   
5. Scegli:
   - "Sì, invia email" → email verrà inviata
   - "No, grazie" → nessuna email
   
6. Continua a compilare il form
7. Clicca INVIA SEGNALAZIONE
8. Verifica console browser (F12)
```

---

## 🔍 DEBUG CONSOLE BROWSER (F12)

### Se hai scelto "Sì, invia email":
```
✅ Utente ha scelto di inviare email
📧 Invio email notifica azienda...
✅ Email notifica inviata! {success: true, emailId: "..."}
✅ Segnalazione inviata! Ricarico lista...
```

### Se hai scelto "No, grazie":
```
❌ Utente non vuole inviare email
✅ Segnalazione inviata! Ricarico lista...
```

### Se c'è errore:
```
❌ Error sending notification: {error: "..."}
```

---

## 📊 DEBUG SUPABASE EDGE FUNCTION

### 1. Vai a Supabase Dashboard:
https://supabase.com/dashboard/project/uchrjlngfzfibcpdxtky/functions/send-company-notification

### 2. Clicca su "Logs" (in alto a destra)

### 3. Cerca questi log:
```
📧 Received notification request: {...}
✅ RESEND_API_KEY is configured
📤 Sending email to: test@example.com
📨 Resend response: {...}
✅ Email sent successfully! ID: re_xxx
```

### 4. Se vedi errore RESEND_API_KEY:
```
❌ RESEND_API_KEY is not set!
```
**FIX**: Vai su Edge Functions → send-company-notification → Settings → Secrets
Aggiungi: `RESEND_API_KEY` = `re_9spPuEQJ_52BQ6qiua7e6qSJSq4uXbsX3`

---

## 🔐 VERIFICA RESEND API KEY

### Opzione 1: Supabase Dashboard
```
1. Supabase → Edge Functions
2. send-company-notification → Settings → Secrets
3. Verifica che esista: RESEND_API_KEY
4. Valore: re_9spPuEQJ_52BQ6qiua7e6qSJSq4uXbsX3
```

### Opzione 2: Test manuale da console browser
```javascript
// Dopo aver fatto login
const result = await window.supabaseClient.functions.invoke(
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

console.log(result);
```

### Risposta attesa:
```json
{
  "data": {
    "success": true,
    "emailId": "re_abc123...",
    "message": "Notification email sent successfully"
  }
}
```

### Se errore:
```json
{
  "error": {
    "message": "RESEND_API_KEY is not configured"
  }
}
```
→ API Key non configurata, vedi fix sopra

---

## 📧 VERIFICA EMAIL SU RESEND

### 1. Login su Resend.com
https://resend.com/login

### 2. Vai su Emails → Logs

### 3. Cerca email a `tua.email@gmail.com`

### 4. Controlla Status:
- ✅ **Delivered**: Email inviata con successo
- ⚠️ **Sandbox mode**: Email arriva SOLO a indirizzi verificati
- ❌ **Failed**: Errore invio

### 5. Se NON vedi l'email nei Logs:
- Edge Function NON è stata chiamata
- Verifica logs Supabase (vedi sopra)
- Verifica console browser per errori

### 6. Se email è in Logs ma NON arriva:
- **Sandbox Mode**: Aggiungi email destinatario come verified
  - Resend → Settings → Verified emails → Add email
- Controlla cartella SPAM
- Usa email domain personale invece di @resend.dev

---

## 🚨 PROBLEMI COMUNI

### 1. Modale non si apre
**Causa**: Cache browser
**Fix**: 
```
Ctrl+Shift+R (hard refresh)
O cancella cache: F12 → Application → Clear site data
```

### 2. Email non arriva
**Cause possibili**:
- RESEND_API_KEY non configurata → Vedi fix sopra
- Sandbox mode Resend → Aggiungi email verified
- Email in spam → Controlla spam folder
- Edge Function non chiamata → Verifica logs Supabase

### 3. Errore "Missing required parameters"
**Causa**: Dati utente mancanti
**Fix**: Verifica che utente loggato abbia:
- `first_name`, `last_name` nella tabella `users`
- `referral_code` valorizzato

### 4. CORS error
**Causa**: Edge Function non deployata correttamente
**Fix**: 
```bash
npx supabase functions deploy send-company-notification --no-verify-jwt
```

---

## ✅ CHECKLIST COMPLETA

Prima di testare, verifica:

- [ ] Hard refresh browser (Ctrl+Shift+R)
- [ ] Loggato come utente (non admin)
- [ ] Utente ha `first_name`, `last_name`, `referral_code`
- [ ] RESEND_API_KEY configurata in Edge Function Secrets
- [ ] Edge Function deployata (ultima versione con logs)
- [ ] Console browser aperta (F12) per vedere logs
- [ ] Email destinatario è VERIFIED su Resend (se sandbox mode)

---

## 🎯 TEST FINALE

### Scenario Completo:
1. ✅ Apri dashboard.html
2. ✅ Clicca "Segnala Azienda"
3. ✅ Compila nome, email (TUA EMAIL VERA), telefono
4. ✅ Clicca radio "❌ NO" su "Azienda consapevole?"
5. ✅ VERIFICA: Modale appare immediatamente
6. ✅ Clicca "Sì, invia email"
7. ✅ Modale si chiude
8. ✅ Compila resto del form
9. ✅ Clicca INVIA SEGNALAZIONE
10. ✅ Apri console (F12) e verifica:
    ```
    ✅ Utente ha scelto di inviare email
    📧 Invio email notifica azienda...
    ✅ Email notifica inviata!
    ```
11. ✅ Vai su Resend.com → Logs
12. ✅ Cerca email a tua email
13. ✅ Apri preview email e verifica template
14. ✅ Controlla inbox (o spam)

---

## 📝 COMMIT CORRENTE

**Commit**: 995b256
**Branch**: main
**Status**: ✅ DEPLOYED

**Modifiche**:
- Modale appare subito su selezione NO
- Email inviata al submit (non più nella modale)
- Logging dettagliato in Edge Function
- Fix logica flow completo

---

## 🔧 PROSSIMI STEP SE EMAIL NON ARRIVA

1. **Test manuale Edge Function** (da console browser - vedi sopra)
2. **Controlla Supabase Logs** per vedere chiamata
3. **Verifica RESEND_API_KEY** in Secrets
4. **Controlla Resend Logs** per vedere se email inviata
5. **Se tutto OK** → problema email provider (spam/block)
6. **Se niente in Resend Logs** → Edge Function non chiamata
7. **Se errore in Supabase Logs** → vedi messaggio errore specifico

---

**Prova ora e fammi sapere cosa vedi nella console! 🚀**
