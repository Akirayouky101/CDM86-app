# 🚀 SETUP RAPIDO - 3 STEP

## ✅ PROBLEMA 1: Modale "approved" → RISOLTO ✅

La modale ora mostra **"Approvata"** in italiano!

---

## 📧 PROBLEMA 2: Email non arrivano

**CAUSA:** Il trigger salva solo la password ma NON invia l'email.

**SOLUZIONE:** Creare un **Database Webhook** che chiama automaticamente l'Edge Function.

---

## 🔧 COSA FARE ORA (3 minuti)

### STEP 1: Esegui SQL su Supabase ⚡

```sql
-- Aggiungi colonne mancanti
ALTER TABLE points_transactions
ADD COLUMN IF NOT EXISTS related_entity_id UUID;

ALTER TABLE points_transactions
ADD COLUMN IF NOT EXISTS related_entity_type VARCHAR(50);

ALTER TABLE points_transactions
ADD COLUMN IF NOT EXISTS compensation_euros DECIMAL(10,2) DEFAULT 0;
```

### STEP 2: Crea Database Webhook 🔗

1. **Vai su:** https://supabase.com/dashboard/project/uchrjlngfzfibcpdxtky/database/hooks

2. **Clicca:** "Create a new hook"

3. **Compila così:**

   ```
   Name: send-email-on-org-creation
   
   Table: organization_temp_passwords
   
   Events: ✅ Insert (solo questo)
   
   Type: Supabase Edge Functions
   
   Edge Function: send-organization-email
   
   HTTP Headers: (lascia vuoto)
   ```

4. **Clicca:** "Create webhook"

### STEP 3: Testa! 🧪

1. Ricarica Admin Panel (`CTRL + SHIFT + R`)
2. Approva la segnalazione "ZG Impiantisrl srl"
3. Controlla email a `serviziomail1@gmail.com`

---

## 🎯 COME FUNZIONA

```
Admin approva 
    ↓
Trigger crea organization + password
    ↓
INSERT in organization_temp_passwords
    ↓
🔔 WEBHOOK AUTOMATICO chiama Edge Function
    ↓
📧 Email inviata via Resend!
```

---

## 🔍 Se l'email NON arriva

**1. Controlla Webhook creato:**
- Vai su Database → Webhooks
- Deve esserci `send-email-on-org-creation`

**2. Controlla logs Edge Function:**
- Functions → send-organization-email → Logs
- Vedi errori (rossi)?

**3. Verifica password salvata:**
```sql
SELECT o.name, o.email, otp.temp_password, otp.email_sent, otp.created_at
FROM organization_temp_passwords otp
JOIN organizations o ON o.id = otp.organization_id
ORDER BY otp.created_at DESC
LIMIT 1;
```

Se `email_sent = false`, il webhook non ha funzionato.

---

## 📂 FILE AGGIORNATI

✅ `admin-panel.html` - Modale ora mostra "Approvata"  
✅ `FINAL_FIX_ALL.sql` - SQL per colonne mancanti  
✅ `EMAIL_WEBHOOK_SETUP.md` - Guida completa  

---

## ⏭️ DOPO IL TEST

Se tutto funziona:
- ✅ Modale: "Approvata" ✓
- ✅ Organization creata ✓
- ✅ Password salvata ✓
- ✅ Email ricevuta ✓
- ✅ Sistema completo! 🎉

---

**Commit:** `58db7ba` - Fix modale + Setup webhook
