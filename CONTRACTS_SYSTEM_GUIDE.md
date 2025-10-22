# 📄 Sistema Gestione Contratti CDM86

## ✅ Modifiche Implementate

### 1. **Rimosso Tab "Richieste" Duplicato**
- ❌ Eliminato completamente il tab "Richieste" (doppione)
- ✅ **Tab "Richieste Aziende" ora è il primo e default**
- ✅ Aggiunto nuovo tab "Contratti" per gestione completa

### 2. **Nuovo Flusso Approvazione Organizzazioni**

**Prima:**
```
Admin clicca "Approva" → Conferma → Approvato
```

**Dopo:**
```
Admin clicca "Approva" 
    ↓
Modal richiede: "Inserisci codice contratto" (OBBLIGATORIO)
    ↓
Admin inserisce: CTR-2025-0001
    ↓
Richiede: Data inizio (default oggi)
    ↓
Richiede: Data fine (default +1 anno)
    ↓
Sistema:
  1. Crea contratto in tabella "contracts"
  2. Approva organization_request
  3. Assegna 100 punti al referrer
  4. Salva contract_code nella richiesta
    ↓
Successo! ✅
```

**Senza codice contratto → NON si può approvare!**

---

## 🗄️ Nuova Tabella: `contracts`

### Schema Completo

```sql
CREATE TABLE contracts (
    id UUID PRIMARY KEY,
    
    -- Codice contratto UNIVOCO
    contract_code VARCHAR(20) UNIQUE NOT NULL,
    
    -- Link all'organizzazione
    organization_request_id UUID REFERENCES organization_requests(id),
    organization_name VARCHAR(255) NOT NULL,
    
    -- Date contratto
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    
    -- Status auto-calcolato
    status VARCHAR(20) DEFAULT 'active', 
    -- Valori: 'active', 'expiring', 'expired', 'cancelled', 'renewed'
    
    -- Dettagli (opzionali)
    contract_type VARCHAR(50),      -- 'standard', 'premium', 'enterprise'
    annual_fee DECIMAL(10,2),       -- Costo annuale
    payment_terms VARCHAR(100),     -- 'monthly', 'quarterly', 'annual'
    
    -- Note e documenti
    notes TEXT,
    document_url TEXT,              -- Link PDF contratto
    
    -- Alert scadenza automatici
    alert_30_days BOOLEAN DEFAULT false,
    alert_15_days BOOLEAN DEFAULT false,
    alert_7_days BOOLEAN DEFAULT false,
    last_alert_sent TIMESTAMPTZ,
    
    -- Contatti
    contact_person VARCHAR(255),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    
    -- Metadata
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    cancelled_at TIMESTAMPTZ,
    renewed_to UUID REFERENCES contracts(id)  -- Link al contratto rinnovato
);
```

### Trigger Automatico Status

Il contratto calcola automaticamente lo status in base ai giorni rimanenti:

- **`active`**: Più di 30 giorni alla scadenza
- **`expiring`**: Tra 1 e 30 giorni alla scadenza ⚠️
- **`expired`**: Scaduto (giorni < 0) ❌
- **`cancelled`**: Annullato manualmente
- **`renewed`**: Rinnovato (creato nuovo contratto)

---

## 📋 Tab "Contratti" - Funzionalità

### Sezione Alerts (Top)

**Contratti in Scadenza**
- 🟡 **Automaticamente evidenziati** se mancano ≤30 giorni
- Card gialla con sfondo warning
- Mostra giorni rimanenti
- Bottone "Rinnova Ora" rapido

### Filtri e Ricerca

1. **Filtro Status:**
   - Tutti
   - Attivi
   - In Scadenza ⚠️
   - Scaduti ❌
   - Cancellati
   - Rinnovati

2. **Ricerca:**
   - Per codice contratto (es: CTR-2025-0001)
   - Per nome organizzazione

3. **Bottone Aggiorna** 🔄

### Lista Contratti

Ogni contratto mostra:

**Card Header:**
- 📛 Nome Organizzazione
- 🏷️ Status Badge colorato

**Informazioni:**
- 🔢 Codice Contratto (grande e blu)
- 📅 Data Inizio
- 📅 Data Scadenza
- ⏰ Giorni Rimanenti (rosso se <30, verde altrimenti)

**Referente:**
- 👤 Nome completo
- 📧 Email
- 📞 Telefono

**Azioni:**
- 👁️ **Dettagli** → Modal con info complete
- 🔄 **Rinnova** → Crea nuovo contratto (solo per active/expiring)
- 📧 **Email** → Apre client email pre-compilato

---

## 🔄 Funzione Rinnovo Contratto

Quando clicchi "Rinnova":

1. **Conferma**: "Vuoi rinnovare il contratto CTR-2025-0001 per Azienda XYZ?"
2. **Nuovo Codice**: Prompt per nuovo codice (suggerisce CTR-2025-XXXX)
3. **Nuova Data Inizio**: Default = oggi
4. **Nuova Data Fine**: Default = +1 anno

**Sistema:**
- ✅ Crea nuovo contratto con nuovo codice
- ✅ Marca vecchio contratto come `renewed`
- ✅ Collega vecchio contratto → nuovo via `renewed_to`
- ✅ Mantiene stesso organization_request_id
- ✅ Copia dati referente

---

## 🔔 Sistema Alerts Scadenze

### Funzioni SQL Disponibili

#### `check_contract_expiry_alerts()`
Ritorna contratti che necessitano alert:
```sql
SELECT * FROM check_contract_expiry_alerts();
```

Restituisce:
- contract_id
- contract_code
- organization_name
- days_remaining
- alert_type ('7_days', '15_days', '30_days')

### Campi Alert nella Tabella

- `alert_30_days` BOOLEAN → Mandato alert a 30 giorni?
- `alert_15_days` BOOLEAN → Mandato alert a 15 giorni?
- `alert_7_days` BOOLEAN → Mandato alert a 7 giorni?
- `last_alert_sent` TIMESTAMP → Quando mandato ultimo alert

**TODO Future:** Implementare cron job per email automatiche

---

## 📊 View Helper: `contracts_with_details`

View SQL che unisce contratti + organization_requests:

```sql
SELECT * FROM contracts_with_details;
```

Aggiunge campi calcolati:
- `days_remaining` → Giorni alla scadenza
- `status_label` → Label italiana ("Scade tra 7 giorni", "Scaduto", etc.)
- `org_contact_email` → Email da organization_requests
- `org_contact_phone` → Telefono da organization_requests

---

## 🎯 Flusso Completo Example

### Scenario: Approvazione Nuova Azienda

1. **Admin apre "Richieste Aziende"**
   - Vede: "Azienda Test SRL" status `pending`

2. **Click "Approva"**
   - Modal: "Inserisci codice contratto"
   - Admin scrive: `CTR-2025-0042`

3. **Sistema chiede date**
   - Data inizio: `2025-01-22` (oggi)
   - Data fine: `2026-01-22` (proposto automaticamente)

4. **Sistema elabora:**
   ```sql
   -- Crea contratto
   INSERT INTO contracts (...) VALUES (
       'CTR-2025-0042',
       'Azienda Test SRL',
       '2025-01-22',
       '2026-01-22',
       ...
   );
   
   -- Approva richiesta
   UPDATE organization_requests 
   SET status = 'approved', 
       contract_code = 'CTR-2025-0042'
   WHERE id = ...;
   
   -- Trigger punti assegna 100 punti al referrer
   ```

5. **Risultato:**
   - ✅ Azienda approvata
   - ✅ Contratto creato e attivo
   - ✅ Referrer ha ricevuto 100 punti
   - ✅ Visibile in tab "Contratti"

---

## 📅 Monitoring Scadenze

### Dashboard Admin - Tab Contratti

**Scenario 1: Nessuna scadenza imminente**
```
Tab Contratti
├── [Nessun alert]
└── Lista Contratti (tutti verdi ✅)
```

**Scenario 2: Contratti in scadenza**
```
Tab Contratti
├── ⚠️ CONTRATTI IN SCADENZA (3)
│   ├── Azienda A - CTR-2025-0001 (7 giorni rimanenti) [Rinnova Ora]
│   ├── Azienda B - CTR-2025-0003 (15 giorni rimanenti) [Rinnova Ora]
│   └── Azienda C - CTR-2025-0005 (28 giorni rimanenti) [Rinnova Ora]
│
└── Lista Contratti
    ├── Azienda A (STATUS: expiring ⚠️)
    ├── Azienda B (STATUS: expiring ⚠️)
    ├── Azienda C (STATUS: expiring ⚠️)
    └── Azienda D (STATUS: active ✅)
```

---

## 🛠️ Funzioni JavaScript Disponibili

### Gestione Contratti

```javascript
// Carica tutti i contratti
loadContracts()

// Filtra contratti
filterContracts() // Usa filtri UI

// Visualizza dettagli
viewContractDetails(contractId)

// Rinnova contratto
renewContract(contractId)

// Email organizzazione
emailContract(email, orgName)
```

### Approvazione Organizzazioni (Modificata)

```javascript
// Ora richiede codice contratto
approveOrg(requestId)
```

Flusso:
1. Modal conferma approvazione
2. Prompt codice contratto (OBBLIGATORIO)
3. Prompt data inizio
4. Prompt data fine
5. Crea contratto
6. Approva richiesta
7. Assegna punti

---

## 📝 SQL da Eseguire su Supabase

### 1. Crea Tabella Contratti

Esegui script completo:
```bash
database/contracts_system.sql
```

Contenuto:
- ✅ Tabella `contracts`
- ✅ Trigger calcolo automatico status
- ✅ Funzione `check_contract_expiry_alerts()`
- ✅ Funzione `generate_contract_code()`
- ✅ View `contracts_with_details`
- ✅ RLS Policies
- ✅ Indexes per performance

### 2. Fix RLS Points (se non già fatto)

Esegui:
```bash
database/FIX_ALL_RLS_FINAL.sql
```

---

## ✅ Checklist Post-Deploy

- [ ] **Eseguire `contracts_system.sql` su Supabase**
- [ ] **Verificare tabella creata**: `SELECT * FROM contracts;`
- [ ] **Test approvazione**: Approvare un'organizzazione e verificare creazione contratto
- [ ] **Test ricerca**: Filtrare contratti per status
- [ ] **Test rinnovo**: Rinnovare un contratto di test
- [ ] **Verificare alerts**: Controllare che contratti <30 giorni appaiano in giallo

---

## 🎨 Layout Admin Panel

```
┌─────────────────────────────────────────────┐
│  CDM86 Admin Panel                          │
├─────────────────────────────────────────────┤
│  [Richieste Aziende] [Contratti] [Analytics]│
│  [Promozioni] [Sistema Punti]               │
├─────────────────────────────────────────────┤
│                                             │
│  📄 GESTIONE CONTRATTI                      │
│                                             │
│  ⚠️ CONTRATTI IN SCADENZA (2)               │
│  ┌───────────────────────────────────────┐ │
│  │ Azienda A - CTR-2025-0001             │ │
│  │ Scadenza: 22/02/2025 (7 giorni)      │ │
│  │ [Rinnova Ora]                         │ │
│  └───────────────────────────────────────┘ │
│                                             │
│  Filtri: [Tutti ▼] [Cerca: _______]  🔄    │
│                                             │
│  📋 CONTRATTI (15)                          │
│  ┌───────────────────────────────────────┐ │
│  │ Azienda Test SRL      ✅ Attivo       │ │
│  │ CTR-2025-0042                         │ │
│  │ Inizio: 22/01/2025                    │ │
│  │ Scadenza: 22/01/2026                  │ │
│  │ Giorni rimanenti: 365                 │ │
│  │ [Dettagli] [Email]                    │ │
│  └───────────────────────────────────────┘ │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 🚀 Prossimi Passi (Future Features)

### Fase 2 - Automazione
- [ ] Cron job giornaliero per controllare scadenze
- [ ] Email automatiche a 30/15/7 giorni
- [ ] Notifiche push admin per scadenze imminenti
- [ ] Dashboard widget con contatore scadenze

### Fase 3 - Reporting
- [ ] Report PDF contratti generati automaticamente
- [ ] Grafici andamento rinnovi
- [ ] Export Excel lista contratti
- [ ] Statistiche: tasso rinnovo, revenue annuale, etc.

### Fase 4 - Workflow Avanzato
- [ ] Firma digitale contratti
- [ ] Upload PDF contratto scansionato
- [ ] Multi-step approval (legal → finance → CEO)
- [ ] Template contratti predefiniti
- [ ] Generazione automatica codici contratto sequenziali

---

## 📞 Supporto

**Errori Comuni:**

**1. "Codice contratto già esistente"**
- Causa: Hai inserito un codice già usato
- Soluzione: Cambia il codice (es: CTR-2025-0043)

**2. "Cannot read property 'organization_name'"**
- Causa: Contratto non trovato
- Soluzione: Ricarica la pagina e riprova

**3. View "contracts_with_details" not found**
- Causa: SQL script non eseguito completamente
- Soluzione: Riesegui `contracts_system.sql` su Supabase

---

*Documento creato: 22 Gennaio 2025*  
*Ultima modifica: 22 Gennaio 2025*  
*Versione: 1.0.0*
