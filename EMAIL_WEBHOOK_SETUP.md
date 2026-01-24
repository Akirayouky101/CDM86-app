# 📧 SETUP EMAIL AUTOMATICHE - GUIDA COMPLETA

## ⚠️ PROBLEMA IDENTIFICATO

Il trigger attuale **NON invia email** perché:
- Salva solo la password in `organization_temp_passwords`
- Non chiama l'Edge Function `send-organization-email`

## ✅ SOLUZIONE: Database Webhooks

Supabase offre **Database Webhooks** per chiamare automaticamente Edge Functions quando succede un evento.

---

## 🔧 SETUP (3 minuti)

### PASSO 1: Esegui il SQL base

Copia e incolla su **Supabase SQL Editor**:

```sql
-- Fix colonne mancanti
ALTER TABLE points_transactions
ADD COLUMN IF NOT EXISTS related_entity_id UUID;

ALTER TABLE points_transactions
ADD COLUMN IF NOT EXISTS related_entity_type VARCHAR(50);

ALTER TABLE points_transactions
ADD COLUMN IF NOT EXISTS compensation_euros DECIMAL(10,2) DEFAULT 0;
```

### PASSO 2: Vai su Database Webhooks

1. Apri Supabase Dashboard
2. Vai su **Database** → **Webhooks**
3. Clicca **"Create a new hook"**

### PASSO 3: Configura il Webhook

**Name:** `send-email-on-org-creation`

**Table:** `organization_temp_passwords`

**Events:** Seleziona solo ✅ **Insert**

**Type of hook:** `Supabase Edge Functions`

**Edge Function:** `send-organization-email`

**HTTP Headers:** (lascia vuoto, usa default)

**Clicca "Create webhook"**

---

## 🎯 COME FUNZIONA

```
┌─────────────────────────────────────────────────┐
│ 1. Admin approva segnalazione                  │
└──────────────┬──────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────┐
│ 2. Trigger handle_company_report_approval()    │
│    - Crea organization                          │
│    - Genera password                            │
│    - INSERT in organization_temp_passwords      │
└──────────────┬──────────────────────────────────┘
               │
               ▼ (Webhook AUTOMATICO)
┌─────────────────────────────────────────────────┐
│ 3. Database Webhook riconosce INSERT           │
│    e chiama send-organization-email             │
└──────────────┬──────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────┐
│ 4. Edge Function invia email via Resend        │
│    - Legge organization + password              │
│    - Invia email                                │
│    - Marca email_sent = true                    │
└─────────────────────────────────────────────────┘
```

---

## 📋 VERIFICA SETUP

Dopo aver creato il webhook, vai su:

**Database** → **Webhooks** 

Dovresti vedere:

```
Name                          Table                      Events    Function
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
send-email-on-org-creation   organization_temp_passwords   INSERT   send-organization-email
```

---

## 🧪 TEST

1. **Vai su Admin Panel**
2. **Approva una segnalazione** (ZG Impiantisrl srl)
3. **Controlla la Console del browser** per errori
4. **Controlla l'email** a `serviziomail1@gmail.com`
5. **Verifica logs** su: 
   - Supabase → Functions → send-organization-email → Logs

---

## 🔍 TROUBLESHOOTING

### Email non arriva?

**1. Verifica Webhook attivo:**
```sql
SELECT * FROM organization_temp_passwords 
WHERE email_sent = false
ORDER BY created_at DESC;
```

Se `email_sent = false`, il webhook non ha funzionato.

**2. Controlla logs Edge Function:**
- Supabase Dashboard → Functions → send-organization-email → Logs
- Cerca errori (rossi)

**3. Test manuale Edge Function:**
```bash
curl -X POST \
  'https://uchrjlngfzfibcpdxtky.supabase.co/functions/v1/send-organization-email' \
  -H 'Content-Type: application/json' \
  -d '{"organization_id": "INSERISCI_ID_QUI"}'
```

**4. Verifica API Key Resend:**
```sql
-- Su Supabase SQL Editor
SELECT vault.decrypted_secrets WHERE name = 'RESEND_API_KEY';
```

---

## 📊 VANTAGGI Database Webhooks

✅ **Nativo Supabase** - Non serve estensione `http`  
✅ **Affidabile** - Retry automatici in caso di errore  
✅ **Logs integrati** - Vedi tutti i tentativi su Dashboard  
✅ **Sicuro** - Autenticazione automatica  
✅ **Scalabile** - Gestisce alto volume  

---

## 🚀 PROSSIMI PASSI

1. ✅ Esegui SQL (PASSO 1)
2. ✅ Crea Webhook (PASSO 2-3)
3. 🧪 Testa approvazione
4. 📧 Verifica email ricevuta
5. 🎉 Sistema completo!

---

## 📝 NOTE

- Il webhook si attiva **SOLO su INSERT** in `organization_temp_passwords`
- Se organization già esistente, NON viene creata → NON viene inviata email
- Per ri-testare: elimina organization e password temporanea

```sql
-- Reset per ri-testare
DELETE FROM organization_temp_passwords WHERE organization_id = 'ID_QUI';
DELETE FROM organizations WHERE email = 'serviziomail1@gmail.com';
UPDATE company_reports SET status = 'pending' WHERE id = 'REPORT_ID';
```
