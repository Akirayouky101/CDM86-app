# 🐛 PROBLEMA: Compensi MLM non funzionanti

## ❌ SINTOMI

Quando approvi una segnalazione azienda inserzionista dall'admin panel:

1. ✅ Punto assegnato correttamente (+1)
2. ❌ **Compenso mostra 0€** invece di 30€
3. ❌ **Nessuna transazione MLM** creata (dovrebbero esserci `mlm_compensation_level1` e `mlm_compensation_level2`)

---

## 🔍 CAUSA

Il problema è che **la colonna `compensation_euros` non esiste** nella tabella `points_transactions`.

Quando il trigger esegue questo INSERT:

```sql
INSERT INTO points_transactions (
  user_id,
  points,
  transaction_type,
  reference_id,
  description,
  compensation_euros  -- ❌ QUESTA COLONNA NON ESISTE!
) VALUES (
  user_id,
  0,
  'company_compensation',
  company_id,
  'Compenso azienda inserzionista: ...',
  30.00  -- ❌ Valore ignorato perché colonna mancante
);
```

Il database **non dà errore**, ma semplicemente ignora il campo `compensation_euros` perché non esiste.

---

## ✅ SOLUZIONE

### Step 1: Verifica lo stato attuale

Vai su **Supabase → SQL Editor** ed esegui questo script:

```sql
-- File: database/check_compensation_system.sql
```

Questo ti dirà esattamente cosa manca nel database.

### Step 2: Riesegui il trigger SQL

Il trigger include già il codice per creare la colonna se non esiste:

```sql
-- File: database/company_reports_approval_trigger.sql
-- Vai su Supabase → SQL Editor → Copia e incolla → Run
```

Alla fine dello script c'è:

```sql
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'points_transactions' 
    AND column_name = 'compensation_euros'
  ) THEN
    ALTER TABLE points_transactions
    ADD COLUMN compensation_euros DECIMAL(10,2) DEFAULT 0.00;
    
    RAISE NOTICE '✅ Colonna compensation_euros aggiunta';
  END IF;
END $$;
```

### Step 3: Verifica che funzioni

Dopo aver eseguito il trigger SQL:

1. **Approva una nuova segnalazione inserzionista**
2. **Vai su Supabase → Table Editor → points_transactions**
3. **Dovresti vedere**:
   - 1 riga `company_report_approved` con `points = 1`
   - 1 riga `company_compensation` con `compensation_euros = 30.00`
   - 1 riga `mlm_compensation_level1` con `compensation_euros = 15.00` (se utente ha referrer)
   - 1 riga `mlm_compensation_level2` con `compensation_euros = 9.00` (se referrer ha referrer)

---

## 📊 PERCHÉ MLM RIMANE A 0?

**MLM funziona SOLO se l'utente ha un referrer**.

Quando crei una segnalazione, verifica che l'utente abbia `referred_by_id` nella tabella `users`:

```sql
SELECT 
    id,
    email,
    referred_by_id,
    referral_code
FROM users
WHERE id = 'USER_ID_QUI';
```

Se `referred_by_id` è **NULL**, allora:
- ✅ Utente riceve 1 punto + 30€
- ❌ Nessun MLM perché non ha referrer

Se `referred_by_id` è **compilato**:
- ✅ Utente riceve 1 punto + 30€
- ✅ Referrer livello 1 riceve 15€
- ✅ Referrer livello 2 riceve 9€ (se esiste)

---

## 🎨 MODIFICHE UI

### Dashboard Utente

**Prima:**
```
company_compensation         0
```

**Dopo:**
```
💰 Compenso Azienda Inserzionista
Compenso azienda inserzionista: ZG Impianti
€30.00
```

### Admin Panel

**Prima:**
```
Status: approved
```

**Dopo:**
```
Status: Approvata
```

---

## 🛠 FILE MODIFICATI

### 1. `public/dashboard.html`
- ✅ Aggiunti nuovi `typeLabels` e `typeIcons` per transaction types
- ✅ Modificato rendering per mostrare `€X.XX` invece di punti quando `compensation_euros > 0`
- ✅ Aggiunto stile `.compensation` con colore arancione

### 2. `public/admin-panel.html`
- ✅ Cambiato "Iscritta" → "Approvata" in 2 posti

### 3. `database/check_compensation_system.sql` (NUOVO)
- ✅ Script diagnostico per verificare setup database

---

## 🧪 COME TESTARE

### Test Completo:

1. **Login come utente normale**
2. **Segnala un'azienda inserzionista**
3. **Login come admin**
4. **Approva la segnalazione**
5. **Torna come utente**
6. **Clicca "Cronologia Movimenti"**

**Dovresti vedere:**
- ✅ `📋 Segnalazione Approvata` → +1 punto
- ✅ `💰 Compenso Azienda Inserzionista` → €30.00
- ✅ `💸 Compenso Rete MLM - Livello 1` → €15.00 (solo se hai referrer)
- ✅ `💵 Compenso Rete MLM - Livello 2` → €9.00 (solo se referrer ha referrer)

---

## 📝 NOTE TECNICHE

### Ordine Esecuzione SQL (IMPORTANTE!)

```
1. database/add_company_type_field.sql       ← Aggiunge campi company_type, compensation_amount
2. database/fix_transaction_type_constraint.sql  ← Fix CHECK constraint
3. database/company_reports_approval_trigger.sql ← Crea trigger + colonna compensation_euros
```

Se esegui fuori ordine, potresti avere errori.

### Perché compensation_euros è separato da points?

- `points` → Punti fedeltà CDM (usati per premi)
- `compensation_euros` → Compenso economico reale (€30 per inserzionista)

Sono 2 sistemi separati che viaggiano in parallelo:
- **Utente segnala inserzionista** → riceve 1 punto + 30€
- **Utente segnala partner** → riceve 1 punto + 0€
- **Utente segnala associazione** → riceve 1 punto + 0€

---

## ❓ FAQ

**Q: Perché nella cronologia vedo 0 per company_compensation?**
A: La colonna `compensation_euros` non esiste ancora. Riesegui il trigger SQL.

**Q: Ho approvato 10 segnalazioni e non ho ricevuto MLM, perché?**
A: Verifica che l'utente abbia `referred_by_id` nella tabella `users`. Se è NULL, non c'è referrer quindi non c'è MLM.

**Q: Posso vedere i compensi anche per segnalazioni già approvate in passato?**
A: No, il trigger funziona solo per nuove approvazioni. Le vecchie approvazioni non verranno ricalcolate.

---

## 🎯 PROSSIMI PASSI

1. ✅ Esegui `database/check_compensation_system.sql` per diagnostica
2. ✅ Riesegui `database/company_reports_approval_trigger.sql` se colonna mancante
3. ✅ Testa con nuova segnalazione inserzionista
4. ✅ Verifica cronologia movimenti mostra €30.00

Se tutto funziona, il sistema è pronto! 🚀
