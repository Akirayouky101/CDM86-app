# 🏢 SETUP: Iscrizione Automatica Aziende

## 📊 COSA FA QUESTO SISTEMA

Quando l'admin **approva una segnalazione** (status → 'approved'):

1. ✅ **Assegna compensi** (come prima)
   - Utente: +1 punto + 30€ (se inserzionista)
   - Referrer L1: +15€ MLM
   - Referrer L2: +9€ MLM

2. 🆕 **Crea automaticamente l'azienda** in `organizations`
   - Se email già esistente → Skip
   - Se email nuova → Crea record completo
   - Genera referral_code automatico
   - Collega a utente che ha segnalato (`referred_by_user_id`)

3. 🆕 **Genera password random** (8 caratteri)
   - Salvata in log PostgreSQL (RAISE NOTICE)
   - 📧 TODO: Invio email automatica con credenziali

---

## ⚡ ESECUZIONE SQL (IN ORDINE!)

### **Step 1: Aggiungi colonna referred_by_user_id a organizations**

```sql
-- File: database/add_referral_to_organizations.sql
-- Supabase → SQL Editor → Copia e incolla → Run
```

Questo permette di tracciare chi ha portato l'azienda nel sistema.

---

### **Step 2: Aggiungi colonna organization_id a company_reports**

```sql
-- File: database/add_organization_id_to_company_reports.sql
-- Supabase → SQL Editor → Copia e incolla → Run
```

Questo collega la segnalazione all'organization creata.

---

### **Step 3: Aggiorna trigger con logica creazione organization**

```sql
-- File: database/company_reports_approval_trigger.sql
-- Supabase → SQL Editor → Copia TUTTO IL FILE → Run
```

Questo è il trigger completo che:
- Assegna compensi
- Crea organization automaticamente
- Collega tutto insieme

---

## 🧪 COME TESTARE

### 1. **Segnala nuova azienda come utente**
- Login come utente normale
- Segnala un'azienda (email nuova, mai usata prima)
- Seleziona tipo: **Inserzionista**
- Invia segnalazione

### 2. **Approva come admin**
- Login come admin
- Tab "Segnalazioni"
- Trova la segnalazione
- Cambia status → **"Approvata"**

### 3. **Verifica su Supabase**

#### A. Controlla che organization sia stata creata:
```sql
SELECT 
    id,
    name,
    email,
    organization_type,
    referred_by_user_id,
    referral_code,
    active,
    created_at
FROM organizations
WHERE email = 'email.azienda@test.com'  -- Sostituisci con email vera
ORDER BY created_at DESC
LIMIT 1;
```

**Dovresti vedere:**
- ✅ `name` → Nome azienda
- ✅ `email` → Email azienda
- ✅ `organization_type` → 'company' o 'association'
- ✅ `referred_by_user_id` → ID utente che ha segnalato
- ✅ `referral_code` → Es: ORG1234 (generato automaticamente)
- ✅ `active` → true

#### B. Controlla che company_report sia collegato:
```sql
SELECT 
    id,
    company_name,
    status,
    organization_id,
    compensation_amount,
    points_awarded
FROM company_reports
WHERE email = 'email.azienda@test.com'
ORDER BY created_at DESC
LIMIT 1;
```

**Dovresti vedere:**
- ✅ `status` → 'approved'
- ✅ `organization_id` → UUID dell'organization creata
- ✅ `compensation_amount` → 30.00 (se inserzionista)
- ✅ `points_awarded` → 1

#### C. Controlla compensi utente:
```sql
SELECT 
    transaction_type,
    points,
    compensation_euros,
    description,
    created_at
FROM points_transactions
WHERE user_id = 'USER_ID_QUI'  -- ID utente che ha segnalato
ORDER BY created_at DESC
LIMIT 5;
```

**Dovresti vedere 2-4 transazioni:**
1. `company_report_approved` → points = 1
2. `company_compensation` → compensation_euros = 30.00
3. `mlm_compensation_level1` → compensation_euros = 15.00 (se ha referrer)
4. `mlm_compensation_level2` → compensation_euros = 9.00 (se referrer ha referrer)

#### D. Trova password generata (nei log):
```sql
-- Vai su Supabase → Database → Logs
-- Cerca: "Organization creata"
-- Vedrai: 🏢 Organization creata: Nome Azienda (ID: xxx) - Password: abc12345
```

⚠️ **IMPORTANTE**: La password è visibile solo nei log PostgreSQL durante la creazione. Salvala subito!

---

## 📧 TODO: Invio Email Automatica

**Cosa manca ancora:**

1. Salvare password in modo sicuro (hash)
2. Inviare email all'azienda con:
   - Credenziali (email + password)
   - Link di attivazione account
   - Benvenuto a CDM86

**Opzioni implementazione:**
- Supabase Edge Functions
- Trigger + Webhook esterno
- Servizio email (SendGrid, Resend, ecc.)

---

## 🔒 SICUREZZA PASSWORD

**Attualmente:**
- Password generata random (8 caratteri md5)
- Visibile solo nei log PostgreSQL
- ⚠️ **NON salvata in chiaro nel database**

**Prossimi step:**
- Generare hash BCrypt della password
- Salvare solo hash in `organizations.password_hash`
- Inviare password in chiaro via email (una sola volta)
- Forzare cambio password al primo login

---

## 📋 SCHEMA FINALE

```
UTENTE SEGNALA AZIENDA
         ↓
    [company_reports]
    - reported_by_user_id → Utente
    - company_name
    - email
    - company_type → inserzionista
    - status → pending
         ↓
ADMIN APPROVA (status → approved)
         ↓
    ⚡ TRIGGER SCATTA
         ↓
    ┌──────────────────────┐
    │ 1. CREA ORGANIZATION │
    ├──────────────────────┤
    │ [organizations]      │
    │ - name               │
    │ - email              │
    │ - referred_by_user_id│
    │ - referral_code      │
    │ - active = true      │
    └──────────────────────┘
         ↓
    ┌──────────────────────┐
    │ 2. ASSEGNA COMPENSI  │
    ├──────────────────────┤
    │ Utente: +1p + 30€   │
    │ Referrer L1: +15€    │
    │ Referrer L2: +9€     │
    └──────────────────────┘
         ↓
    ┌──────────────────────┐
    │ 3. COLLEGA TUTTO     │
    ├──────────────────────┤
    │ company_reports.     │
    │ organization_id →    │
    │ organizations.id     │
    └──────────────────────┘
```

---

## ❓ FAQ

**Q: Se approvo 2 volte la stessa azienda (email duplicata)?**
A: Il trigger controlla se l'email esiste già in `organizations`. Se esiste, **non crea duplicato**, solo assegna compensi.

**Q: Come fa l'azienda a fare login?**
A: Per ora la password è nei log PostgreSQL. Serve implementare:
1. Sistema hash password
2. Invio email automatica
3. Pagina login organizations (già esiste?)

**Q: L'organization può vedere chi l'ha segnalata?**
A: Sì, tramite `referred_by_user_id` possiamo mostrare "Portato da: Mario Rossi".

**Q: Cosa succede se l'utente cancella il suo account?**
A: `referred_by_user_id` ha `ON DELETE SET NULL`, quindi l'organization rimane ma perde il collegamento.

---

## 🎯 ESECUZIONE RAPIDA

```sql
-- 1. Aggiungi referred_by_user_id
\i database/add_referral_to_organizations.sql

-- 2. Aggiungi organization_id
\i database/add_organization_id_to_company_reports.sql

-- 3. Aggiorna trigger
\i database/company_reports_approval_trigger.sql
```

Oppure copia-incolla i 3 file in ordine su **Supabase → SQL Editor**.

---

**Sistema pronto! Ora quando approvi una segnalazione, l'azienda viene iscritta automaticamente! 🚀**
