# 🏢 GUIDA WIZARD SEGNALAZIONE AZIENDE

## 📋 PANORAMICA

Il nuovo sistema di segnalazione aziende è stato trasformato in un **wizard a 2 step** che raccoglie:
1. **Dati azienda** (Step 1)
2. **Sondaggio dettagliato** (Step 2)

Tutte le segnalazioni sono collegate al **referral code** dell'utente che le invia, per tracciare le conversioni MLM.

---

## 🗄️ DATABASE SETUP

### 1. Crea la tabella `company_reports`

Esegui questo SQL su Supabase:

```sql
-- File: database/company_reports_table.sql
```

Vai su Supabase → SQL Editor → Incolla il contenuto del file `database/company_reports_table.sql` → Run

### 2. Verifica RLS Policies

Assicurati che:
- ✅ Users possono vedere solo le proprie segnalazioni
- ✅ Users possono inserire segnalazioni
- ✅ Admins possono vedere TUTTE le segnalazioni
- ✅ Admins possono aggiornare lo stato

---

## 🎯 FUNZIONALITÀ

### WIZARD STEP 1: Dati Azienda
Campi richiesti:
- Nome Azienda/Associazione
- Nome e Cognome Referente
- Email
- Telefono
- Indirizzo completo

### WIZARD STEP 2: Sondaggio
Campi richiesti:
- **Settore**: 17 opzioni predefinite + campo "Altro"
  - Ristorazione, Bar, Retail, Elettronica, Alimentari, Servizi alla Persona, Benessere, Fitness, Intrattenimento, Viaggi, Hotel, Artigianato, Automotive, Immobiliare, Associazioni (No-Profit, Sportiva, Culturale)
  
- **Azienda Consapevole**: Radio button Sì/No
  - Indica se l'azienda sa di essere segnalata
  
- **Chi ne è a conoscenza**: Dropdown + campo "Altro"
  - Titolare, Direttore, Responsabile Commerciale, Responsabile Marketing, Segreteria, Addetto Vendite
  
- **Orari di Contatto**: Dropdown con range orari
  - 08:00-10:00, 10:00-12:00, 12:00-14:00, 14:00-16:00, 16:00-18:00, 18:00-20:00, 20:00-22:00
  - Sempre disponibile, Solo mattina, Solo pomeriggio, Solo sera

---

## 🔄 FLUSSO UTENTE

1. **Dashboard** → Click "Segnala Azienda/Associazione"
2. **Modal Informativa** → Mostra 3 tipi di partnership (Inserzioniste, Partner, Associazioni)
3. **Click "Procedi"** → Apre Wizard Step 1
4. **Compila dati** → Click "Avanti"
5. **Wizard Step 2** → Compila sondaggio
6. **Click "Invia Segnalazione"** → Salva in database con referral dell'utente
7. **Success message** → Segnalazione inviata all'admin

---

## 👨‍💼 PANNELLO ADMIN

### Nuova Tab "Segnalazioni"

**Stats Cards:**
- 📊 Totale Segnalazioni
- ⏳ In Attesa
- 📞 Contattate
- ✅ Approvate

**Filtri:**
- 🔍 Ricerca: azienda, email, settore
- 📋 Stato: In Attesa, Contattate, Approvate, Rifiutate
- ✅ Consapevolezza: Azienda Consapevole / NON Consapevole

**Tabella con colonne:**
1. Azienda (nome + indirizzo)
2. Contatto (nome + email + telefono)
3. Settore
4. Segnalata da (nome utente + email)
5. **Referral Code** (del segnalante)
6. Consapevole (Sì/No badge)
7. Chi Conosce
8. Orari
9. Data
10. Stato
11. Azioni (Visualizza dettagli + Cambia stato)

### Funzioni Admin
```javascript
loadCompanyReports()        // Carica tutte le segnalazioni
applyReportFilters()        // Applica filtri
viewReportDetails(id)       // Mostra popup dettagli
updateReportStatus(id, status) // Cambia stato segnalazione
```

---

## 📁 FILE MODIFICATI

### 1. `public/promotions.html`
- Aggiunto wizard HTML completo
- Progress bar tra i 2 step
- Validazione form step-by-step

### 2. `public/dashboard.html`
- Sostituito vecchio modal con nuovo wizard
- Aggiornate funzioni `proceedToReportForm()` e `openReportCompanyModal()`

### 3. `assets/js/login-modal.js`
- Creato oggetto `CompanyWizard` globale
- Funzioni: open(), close(), nextStep(), prevStep(), submitForm()
- Toggle dinamici per campi "Altro"
- Integrazione con Supabase per salvare dati

### 4. `assets/css/login-modal.css`
- Stili per wizard progress bar
- Stili per radio groups
- Animazioni transizioni tra step
- Helper classes per campi condizionali

### 5. `public/admin-panel.html`
- Nuovo tab "Segnalazioni"
- Tabella segnalazioni con tutti i campi
- Funzioni caricamento e filtri
- Aggiornamento stati

### 6. `database/company_reports_table.sql`
- Schema completo tabella
- RLS Policies per sicurezza
- Indici per performance
- Trigger per updated_at

---

## 🧪 TESTING

### Test Utente
1. Login come user (mario.rossi@cdm86.com)
2. Dashboard → Segnala Azienda
3. Compila Step 1 con dati test
4. Click Avanti → Verifica passaggio a Step 2
5. Compila sondaggio completo
6. Invia → Verifica success message

### Test Admin
1. Login come admin (admin@cdm86.com)
2. Admin Panel → Tab "Segnalazioni"
3. Verifica presenza segnalazione con:
   - Referral code dell'utente segnalante
   - Tutti i campi del sondaggio
4. Cambia stato → Verifica aggiornamento
5. Click "Visualizza" → Verifica popup dettagli

### Verifica Database
```sql
-- Controlla segnalazioni
SELECT 
    company_name,
    sector,
    reported_by_referral_code,
    company_aware,
    who_knows,
    preferred_call_time,
    status
FROM company_reports
ORDER BY created_at DESC;

-- Verifica collegamento utente
SELECT 
    cr.company_name,
    cr.reported_by_referral_code,
    u.first_name,
    u.last_name,
    u.email
FROM company_reports cr
JOIN users u ON u.auth_id = cr.reported_by_user_id;
```

---

## 🎨 UX FEATURES

### Progress Bar
- Mostra visualmente il progresso (50% / 100%)
- Si aggiorna ad ogni step

### Validazione
- Campi obbligatori marcati con `*`
- Validazione HTML5 integrata
- Messaggio errore se mancano campi

### Campi Condizionali
- "Altro" settore → Mostra campo testo
- "Altro" chi conosce → Mostra campo testo

### Mobile Responsive
- Radio buttons in colonna su mobile
- Form a tutta larghezza
- Bottoni stacked verticalmente

---

## 🔗 INTEGRAZIONE MLM

Ogni segnalazione include:
- `reported_by_user_id`: UUID dell'utente auth
- `reported_by_referral_code`: Codice referral dell'utente

Questo permette di:
1. Tracciare chi ha segnalato l'azienda
2. Assegnare punti/premi quando l'azienda si registra
3. Calcolare statistiche conversioni per utente
4. Vedere network di segnalazioni nella dashboard admin

---

## 🚀 DEPLOYMENT

```bash
git add -A
git commit -m "Feature: Company Report Wizard"
git push
```

Vercel deploya automaticamente.

---

## ✅ CHECKLIST POST-DEPLOY

- [ ] Eseguito SQL su Supabase
- [ ] Verificata creazione tabella `company_reports`
- [ ] Testato wizard da dashboard utente
- [ ] Verificata presenza dati in admin panel
- [ ] Testati filtri e ricerca
- [ ] Verificato referral code collegato correttamente
- [ ] Testato cambio stato da admin
- [ ] Mobile test completato

---

## 🐛 TROUBLESHOOTING

### Errore "Table does not exist"
→ Esegui `database/company_reports_table.sql` su Supabase

### Wizard non si apre
→ Verifica che `CompanyWizard` sia globale: `window.CompanyWizard`

### Referral code NULL
→ Verifica che l'utente loggato abbia un referral_code nella tabella users

### Admin non vede segnalazioni
→ Verifica RLS policy: admin deve avere role='admin' in tabella users

---

## 📊 PROSSIMI STEP

1. **Email notifiche**: Inviare email admin quando arriva nuova segnalazione
2. **Punti automatici**: Assegnare punti quando azienda si registra
3. **Dashboard stats**: Mostrare "Le tue segnalazioni" in user dashboard
4. **Export CSV**: Esportare segnalazioni da admin panel
5. **Note admin**: Campo per admin per annotare followup

---

**Deployment completato! 🎉**

URL: https://www.cdm86.com
