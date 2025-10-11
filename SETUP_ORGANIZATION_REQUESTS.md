# 📋 ISTRUZIONI SETUP DATABASE - Sistema Segnalazioni Aziende

## ⚠️ IMPORTANTE - SQL DA ESEGUIRE SU SUPABASE

Devi eseguire questi comandi SQL sul tuo database Supabase per attivare il sistema completo di gestione segnalazioni aziende.

### 1️⃣ Esegui: `database/organization_requests.sql`

Questo file crea:
- ✅ Tabella `organization_requests` per salvare tutte le richieste di codice contratto
- ✅ Funzione `create_organization_request()` per creare richieste dal form
- ✅ View `admin_organization_requests` per il pannello admin (con JOIN su users e organizations)
- ✅ Trigger per aggiornare automaticamente timestamp e status
- ✅ Funzione `get_user_organization_referrals()` per statistiche utente

**Come fare:**
1. Vai su [Supabase SQL Editor](https://supabase.com/dashboard/project/uchrjlngfzfibcpdxtky/sql)
2. Apri il file `database/organization_requests.sql`
3. Copia tutto il contenuto
4. Incolla nell'editor SQL di Supabase
5. Clicca **RUN** ▶️

---

## 🎯 FUNZIONALITÀ ATTIVATE

### Per gli UTENTI (Dashboard):
- 📊 **Sezione "Segnalazioni Aziende/Associazioni"** con:
  - Statistiche: Totale, In Attesa, Approvate, Completate
  - Filtri per stato (Tutte, In Attesa, Approvate, Completate)
  - Lista dettagliata delle organizzazioni segnalate
  - Visualizzazione codice contratto quando approvato

### Per le ORGANIZZAZIONI (Registrazione):
- ✅ Form con **Step 0** obbligatorio: validazione codice referral
- ✅ Salvataggio richiesta nel database (non solo email)
- ✅ Tracking completo: chi ha invitato, quando, con quale codice

### Per l'ADMIN (Pannello Admin):
- 🔐 **Accesso esclusivo**: solo diegomarruchi@outlook.it
- 📊 **Dashboard con statistiche** globali
- 🔍 **Filtri e ricerca** avanzati
- ✅ **Azioni disponibili:**
  - Approva richiesta → Assegna codice contratto
  - Rifiuta richiesta → Scrivi motivo
  - Completa richiesta → Segna come completata
  - Aggiungi/modifica note admin
- 👤 **Visualizza chi ha segnalato** ogni organizzazione (utente o organizzazione)
- 📧 **Email referente** per comunicazioni

---

## 🌐 URL PANNELLI

- **Dashboard Utente**: https://cdm86.com/public/dashboard.html
- **Pannello Admin**: https://cdm86.com/public/admin-panel.html
- **Registrazione Organizzazione**: https://cdm86.com/public/register-organization.html

---

## 🔄 WORKFLOW COMPLETO

1. **Utente condivide** il suo codice referral (ABC1234)
2. **Organizzazione** clicca sul link/QR code
3. **Registrazione organizzazione:**
   - Step 0: Inserisce codice referral → Validato ✅
   - Step 1-4: Compila dati organizzazione
   - Invia richiesta → Salvata nel database + Email admin
4. **Admin riceve notifica:**
   - Vede richiesta nel pannello admin
   - Vede chi ha segnalato l'organizzazione
   - Approva → Assegna codice contratto (es: ORG9999)
5. **Utente vede nella sua dashboard:**
   - +1 nelle "Segnalazioni Aziende"
   - Dettagli organizzazione segnalata
   - Codice contratto assegnato (quando approvato)

---

## ✅ CHECKLIST POST-SETUP

- [ ] Eseguito `organization_requests.sql` su Supabase
- [ ] Verificato creazione tabella `organization_requests`
- [ ] Verificato creazione view `admin_organization_requests`
- [ ] Testato accesso pannello admin (solo admin)
- [ ] Testato registrazione organizzazione con codice referral
- [ ] Verificato salvataggio richiesta nel database
- [ ] Testato visualizzazione segnalazioni nella dashboard utente
- [ ] Testato approvazione richiesta da admin
- [ ] Verificato aggiornamento codice contratto visibile all'utente

---

## 🐛 TROUBLESHOOTING

### La richiesta non viene salvata
- Controlla che `create_organization_request()` esista nel database
- Verifica console browser per errori JavaScript

### Pannello admin non accessibile
- Assicurati di essere loggato come **diegomarruchi@outlook.it**
- Altri utenti vedranno "Accesso negato"

### View admin_organization_requests non funziona
- Assicurati che esistano le tabelle: `organization_requests`, `users`, `organizations`
- La view fa JOIN su tutte e tre

### Segnalazioni non appaiono nella dashboard utente
- Verifica che `referred_by_id` nella richiesta corrisponda all'ID dell'utente loggato
- Controlla console browser per errori

---

## 📁 FILE MODIFICATI

- `database/organization_requests.sql` ← **NUOVO** (DA ESEGUIRE SU SUPABASE)
- `public/admin-panel.html` ← **NUOVO** (Pannello amministratore)
- `public/register-organization.html` ← Aggiunto salvataggio DB
- `public/dashboard.html` ← Aggiunta sezione "Segnalazioni Aziende"

---

**🚀 Tutto pronto! Esegui l'SQL e il sistema sarà completo!**
