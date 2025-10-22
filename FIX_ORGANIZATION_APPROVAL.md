# 🔧 Fix Approvazione Organizzazioni - Guida Rapida

## ❌ Problema Risolto

**Errore precedente:**
```
record "new" has no field "user_id"
```

**Causa:** Il trigger `handle_organization_request_status` cercava il campo `user_id` che non esiste nella tabella `organization_requests`. Il campo corretto è `referred_by_id`.

---

## ✅ Modifiche Applicate

### 1. **Trigger SQL Corretto** (`database/points_system_setup.sql`)

Cambiato da `NEW.user_id` a `NEW.referred_by_id` in tutte le occorrenze:

```sql
-- Prima (ERRORE)
PERFORM add_points_to_user(
    NEW.user_id,  -- ❌ Campo inesistente
    100,
    'report_approved',
    NEW.id,
    'Segnalazione approvata: ' || NEW.organization_name
);

-- Dopo (CORRETTO)
PERFORM add_points_to_user(
    NEW.referred_by_id,  -- ✅ Campo corretto
    100,
    'report_approved',
    NEW.id,
    'Segnalazione approvata: ' || NEW.organization_name
);
```

### 2. **Modal di Conferma Professionale** (`public/admin-panel.html`)

Sostituito il semplice `confirm()` con una modal stilizzata:

**Prima:**
```javascript
if (!confirm('Confermi di approvare questa azienda come partner?')) return;
```

**Dopo:**
```javascript
showConfirmModal(
    '⚠️ Conferma Approvazione',
    `Sei sicuro di voler approvare "${orgName}" come partner?\n\nQuesta azione assegnerà automaticamente 100 punti all'utente referrer e non può essere annullata.`,
    async () => { /* approvazione */ }
);
```

**Caratteristiche nuova modal:**
- ⚠️ Icona warning arancione
- 📝 Messaggio dettagliato con nome azienda
- 💡 Info sui punti assegnati
- 🎨 Design professionale con bottoni Annulla/Conferma
- ✨ Animazione smooth

---

## 🚀 Come Applicare il Fix su Supabase

### Opzione A: Ricrea Solo il Trigger (CONSIGLIATO - Veloce)

1. Vai su [Supabase Dashboard](https://supabase.com/dashboard)
2. Apri il progetto CDM86
3. Vai in **SQL Editor**
4. Copia e incolla questo comando:

```sql
-- Ricrea la funzione trigger corretta
CREATE OR REPLACE FUNCTION handle_organization_request_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Only process if status changed to approved or rejected
    IF NEW.status != OLD.status THEN
        IF NEW.status = 'approved' THEN
            -- Award 100 points for approved report
            PERFORM add_points_to_user(
                NEW.referred_by_id,
                100,
                'report_approved',
                NEW.id,
                'Segnalazione approvata: ' || NEW.organization_name
            );
            
            -- Increment approved reports count
            UPDATE user_points
            SET approved_reports_count = approved_reports_count + 1
            WHERE user_id = NEW.referred_by_id;
            
        ELSIF NEW.status = 'rejected' THEN
            -- No points awarded, just log
            INSERT INTO points_transactions (
                user_id,
                points,
                transaction_type,
                reference_id,
                description
            ) VALUES (
                NEW.referred_by_id,
                0,
                'report_rejected',
                NEW.id,
                'Segnalazione rifiutata: ' || NEW.organization_name
            );
            
            -- Increment rejected reports count
            UPDATE user_points
            SET rejected_reports_count = rejected_reports_count + 1
            WHERE user_id = NEW.referred_by_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Ricrea il trigger
DROP TRIGGER IF EXISTS trigger_organization_request_status ON organization_requests;
CREATE TRIGGER trigger_organization_request_status
    AFTER UPDATE ON organization_requests
    FOR EACH ROW
    EXECUTE FUNCTION handle_organization_request_status();

-- Verifica
SELECT 'Trigger corretto applicato con successo!' as status;
```

5. Clicca **RUN**
6. Verifica il messaggio: `Trigger corretto applicato con successo!`

### Opzione B: Riesegui Tutto lo Script (Se hai problemi)

1. Vai su Supabase SQL Editor
2. Apri il file `database/points_system_setup.sql` dal progetto
3. Copia tutto il contenuto
4. Incolla in SQL Editor
5. Clicca **RUN**
6. Verifica: `Points system setup completed successfully!`

---

## ✅ Test del Fix

### 1. Test Approvazione con Modal

1. Apri Admin Panel: `https://cdm86.com/public/admin-panel.html`
2. Vai al tab **"Richieste Organizzazioni"**
3. Clicca **"Approva"** su una richiesta pending
4. **Verifica:**
   - ✅ Appare modal professionale con warning icon
   - ✅ Messaggio include nome organizzazione
   - ✅ Menziona assegnazione 100 punti
   - ✅ Bottoni "Annulla" e "Conferma" funzionanti
   - ✅ Cliccando "Annulla" la modal si chiude senza approvare
   - ✅ Cliccando "Conferma" approva la richiesta

### 2. Test Assegnazione Punti

Dopo aver approvato una organizzazione:

```sql
-- Controlla punti utente referrer
SELECT * FROM user_points 
WHERE user_id = (
    SELECT referred_by_id 
    FROM organization_requests 
    WHERE status = 'approved' 
    ORDER BY approved_at DESC 
    LIMIT 1
);

-- Dovrebbe mostrare:
-- points_total: +100
-- approved_reports_count: +1
```

### 3. Test Transazione Registrata

```sql
-- Verifica log transazione
SELECT * FROM points_transactions 
WHERE transaction_type = 'report_approved' 
ORDER BY created_at DESC 
LIMIT 5;

-- Dovrebbe mostrare:
-- user_id: UUID del referrer
-- points: 100
-- description: "Segnalazione approvata: [nome azienda]"
```

### 4. Test in Dashboard Utente

1. Login come utente referrer
2. Vai su Dashboard
3. Verifica sezione punti:
   - ✅ Punti totali aumentati di 100
   - ✅ Transazione visibile in cronologia
   - ✅ Possibile avanzamento livello (se a 100+ pts)

---

## 🎯 Comportamento Atteso

### Scenario 1: Approvazione Organizzazione

```
Admin clicca "Approva" su richiesta
    ↓
Modal conferma appare
    ↓
Admin clicca "Conferma"
    ↓
Trigger SQL eseguito:
  - referred_by_id → Riceve +100 punti
  - approved_reports_count incrementato
  - Transazione registrata
    ↓
Status → 'approved'
    ↓
Modal successo: "Azienda approvata! Utente referrer ha ricevuto 100 punti"
    ↓
Admin panel refresh automatico
```

### Scenario 2: Annullamento

```
Admin clicca "Approva"
    ↓
Modal conferma appare
    ↓
Admin clicca "Annulla"
    ↓
Modal si chiude
    ↓
Nessuna azione eseguita
    ↓
Richiesta rimane 'pending'
```

---

## 🐛 Troubleshooting

### Problema: Errore "add_points_to_user does not exist"

**Soluzione:** Riesegui tutto lo script `points_system_setup.sql` (Opzione B)

### Problema: Modal non appare

**Verifica:**
1. Apri Console Browser (F12)
2. Controlla errori JavaScript
3. Verifica che `confirm-modal` esista nel DOM:
   ```javascript
   document.getElementById('confirm-modal')
   ```

**Soluzione:** 
- Pulisci cache browser (Cmd+Shift+R su Mac)
- Verifica deployment Vercel aggiornato

### Problema: Punti non assegnati dopo approvazione

**Diagnosi:**
```sql
-- Controlla se trigger è attivo
SELECT * FROM pg_trigger 
WHERE tgname = 'trigger_organization_request_status';

-- Se non c'è, ricrea il trigger (Opzione A)
```

### Problema: "user_id" error persiste

**Causa:** Vecchio trigger ancora in cache

**Soluzione:**
```sql
-- Forza drop e ricrea
DROP TRIGGER IF EXISTS trigger_organization_request_status ON organization_requests CASCADE;
DROP FUNCTION IF EXISTS handle_organization_request_status() CASCADE;

-- Poi esegui Opzione A
```

---

## 📊 Struttura Tabella organization_requests

Per riferimento, ecco i campi disponibili:

```sql
organization_requests:
  - id (UUID)
  - referred_by_id (UUID) ✅ USARE QUESTO per i punti
  - referred_by_code (VARCHAR)
  - organization_name (VARCHAR)
  - contact_first_name (VARCHAR)
  - contact_last_name (VARCHAR)
  - contact_email (VARCHAR)
  - contact_phone (VARCHAR)
  - status (VARCHAR) - pending/approved/rejected/completed
  - contract_code (VARCHAR)
  - admin_notes (TEXT)
  - created_at (TIMESTAMP)
  - updated_at (TIMESTAMP)
  - approved_at (TIMESTAMP)
  - completed_at (TIMESTAMP)
```

❌ **NON esiste:** `user_id`  
✅ **Usare:** `referred_by_id` (UUID dell'utente che ha invitato)

---

## 🎨 Preview Modal

La nuova modal ha questo aspetto:

```
┌─────────────────────────────────────┐
│  ⚠️  Conferma Approvazione          │
├─────────────────────────────────────┤
│                                     │
│  Sei sicuro di voler approvare      │
│  "Azienda XYZ" come partner?        │
│                                     │
│  Questa azione assegnerà            │
│  automaticamente 100 punti          │
│  all'utente referrer e non può      │
│  essere annullata.                  │
│                                     │
│  ┌─────────┐  ┌─────────┐          │
│  │ Annulla │  │ Conferma │          │
│  └─────────┘  └─────────┘          │
└─────────────────────────────────────┘
```

---

## ✅ Checklist Post-Fix

- [x] SQL trigger corretto pushato su GitHub
- [x] Admin panel con modal pushato su GitHub
- [x] Vercel auto-deploy completato
- [ ] **TODO: Esegui SQL fix su Supabase** (Opzione A)
- [ ] **TODO: Testa approvazione con modal**
- [ ] **TODO: Verifica punti assegnati correttamente**

---

## 📞 Supporto

Se dopo aver eseguito il fix l'errore persiste:

1. **Controlla Console Browser** per errori JavaScript
2. **Controlla Supabase Logs** per errori SQL
3. **Verifica deployment Vercel** è aggiornato
4. **Pulisci cache browser** completamente

---

*Fix applicato: 22 Ottobre 2025*  
*Commit: bf71346*  
*Files modificati: points_system_setup.sql, admin-panel.html*
