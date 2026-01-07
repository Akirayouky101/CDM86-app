# ✓ CHECKLIST SVILUPPO CDM86 - Sistema Aziende

**Data:** 7 Gennaio 2026  
**Progetto:** CDM86-NEW  
**Focus:** Completamento Sistema Aziende + Fix Sistema Preferiti

---

## 1. DATABASE - SETUP INIZIALE

### SQL da Eseguire su Supabase
- [ ] Eseguire `database/setup_organization_panel.sql`
  - Crea campi: referral_code_external, total_points
  - Crea tabella: organization_benefits
  - Aggiunge indici per performance

- [ ] Eseguire `database/organization_requests.sql`
  - Crea tabella: organization_requests
  - Crea funzioni: get_user_organization_referrals()
  - Crea view: admin_organization_requests
  - Attiva trigger per status updates

- [ ] Verificare creazione tabelle
  - organization_benefits
  - organization_requests

- [ ] Verificare colonne organizations
  - referral_code_external
  - total_points

---

## 2. ORGANIZATION DASHBOARD - IMPLEMENTAZIONE

### 2.1 Autenticazione e Accesso
- [ ] Sistema login per organizzazioni
- [ ] Distinguere login utente vs organizzazione
- [ ] Redirect automatico a organization-dashboard.html dopo login
- [ ] Protezione route: solo organizzazioni autorizzate
- [ ] Gestione sessione organizzazione

### 2.2 Sezione Overview (Dashboard Principale)
- [ ] Statistiche principali:
  - [ ] Totale dipendenti registrati
  - [ ] Totale utenti esterni referenziati
  - [ ] Punti totali accumulati
  - [ ] Benefit attivi

- [ ] Grafici visualizzazione dati
- [ ] Box informazioni rapide
- [ ] Andamento mensile registrazioni

### 2.3 Sezione Gestione Dipendenti
- [ ] Lista dipendenti completa con filtri
- [ ] Colonne: Nome, Email, Data Registrazione, Stato, Punti, Attivita
- [ ] Funzione aggiungi dipendente manualmente
- [ ] Funzione rimuovi/disattiva dipendente
- [ ] Esportazione lista dipendenti (CSV/Excel)
- [ ] Filtri: Attivi, Inattivi, Tutti
- [ ] Ricerca per nome/email
- [ ] Dettaglio singolo dipendente:
  - [ ] Transazioni effettuate
  - [ ] Benefit riscattati
  - [ ] Storico attivita

### 2.4 Sezione Gestione Benefit
- [ ] Lista benefit esistenti
- [ ] Pulsante "Crea Nuovo Benefit"
- [ ] Form creazione benefit:
  - [ ] Titolo benefit
  - [ ] Descrizione dettagliata
  - [ ] Punti richiesti
  - [ ] Stato (Attivo/Disattivo)
  - [ ] Data inizio validita
  - [ ] Data fine validita (opzionale)

- [ ] Modifica benefit esistente
- [ ] Elimina benefit
- [ ] Attiva/Disattiva benefit
- [ ] Storico utilizzo benefit:
  - [ ] Chi ha riscattato
  - [ ] Quando
  - [ ] Quante volte

### 2.5 Sezione Referral Esterni
- [ ] Visualizzazione codice referral esterno
- [ ] QR Code per condivisione
- [ ] Link condivisione diretto
- [ ] Statistiche referral:
  - [ ] Totale utenti registrati con codice esterno
  - [ ] Conversione registrazione → prima transazione
  - [ ] Punti guadagnati da referral esterni

- [ ] Lista utenti esterni referenziati:
  - [ ] Nome utente
  - [ ] Data registrazione
  - [ ] Numero transazioni
  - [ ] Punti generati per azienda
  - [ ] Stato account

### 2.6 Sezione Impostazioni Azienda
- [ ] Modifica dati organizzazione
- [ ] Cambio email/password
- [ ] Gestione notifiche
- [ ] Preferenze dashboard

---

## 3. SISTEMA PUNTI AZIENDE

### 3.1 Logica Accumulo Punti
- [ ] Definire formula punti:
  - [ ] 1 transazione utente = X punti azienda
  - [ ] Bonus per primo acquisto dipendente
  - [ ] Bonus per referral esterno che completa transazione

- [ ] Trigger database automatico:
  - [ ] Quando user fa transazione → aggiungi punti all'organization
  - [ ] Verificare se user.is_employee = true
  - [ ] Verificare se user.referred_by_organization_external = true

### 3.2 Dashboard Punti
- [ ] Visualizzazione saldo punti corrente
- [ ] Storico accumulo punti:
  - [ ] Data
  - [ ] Tipo evento (transazione dipendente, referral esterno)
  - [ ] Utente
  - [ ] Punti guadagnati
  - [ ] Totale progressivo

- [ ] Grafico andamento punti nel tempo
- [ ] Esportazione storico punti

---

## 4. SISTEMA CODICI REFERRAL DOPPI

### 4.1 Codice Interno (Dipendenti)
- [ ] Generazione automatica alla creazione organizzazione
- [ ] Campo: organizations.referral_code
- [ ] Pagina registrazione dipendente con codice interno
- [ ] Al signup con codice interno:
  - [ ] Impostare user.is_employee = true
  - [ ] Impostare user.organization_id

### 4.2 Codice Esterno (Marketing/Pubblico)
- [ ] Generazione automatica: referral_code + "_EXT"
- [ ] Campo: organizations.referral_code_external
- [ ] Pagina registrazione pubblica con codice esterno
- [ ] Al signup con codice esterno:
  - [ ] Impostare user.referred_by_organization_external = true
  - [ ] Impostare user.organization_id
  - [ ] is_employee = false

### 4.3 Validazione e Tracking
- [ ] Funzione validazione codice in tempo reale
- [ ] Impedire uso codice interno su form esterno e viceversa
- [ ] Tracking: chi usa quale codice, quando

---

## 5. PANNELLO ADMIN - GESTIONE RICHIESTE AZIENDE

### 5.1 Verifica Funzionalita Esistenti
- [ ] Testare accesso pannello admin
- [ ] Verificare visualizzazione richieste organization_requests
- [ ] Testare filtri (Tutte, Pending, Approved, Rejected, Completed)
- [ ] Testare ricerca per nome organizzazione

### 5.2 Azioni Admin
- [ ] Approva richiesta:
  - [ ] Assegnare codice contratto
  - [ ] Inviare email notifica approvazione
  - [ ] Aggiornare status → approved

- [ ] Rifiuta richiesta:
  - [ ] Inserire motivo rifiuto
  - [ ] Inviare email notifica rifiuto
  - [ ] Aggiornare status → rejected

- [ ] Completa richiesta:
  - [ ] Segnare come completed
  - [ ] Aggiungere timestamp completed_at

- [ ] Modifica note admin
- [ ] Visualizzare dettagli completi richiesta

---

## 6. USER DASHBOARD - SEGNALAZIONI AZIENDE

### 6.1 Verifica Sezione Esistente
- [ ] Testare visualizzazione sezione "Segnalazioni Aziende/Associazioni"
- [ ] Verificare statistiche:
  - [ ] Totale
  - [ ] In Attesa
  - [ ] Approvate
  - [ ] Completate

### 6.2 Funzionalita da Testare
- [ ] Filtri per stato
- [ ] Lista organizzazioni segnalate
- [ ] Visualizzazione codice contratto quando approvato
- [ ] Dettagli organizzazione al click

---

## 7. REGISTRAZIONE ORGANIZZAZIONE

### 7.1 Verifica Form
- [ ] Step 0: Validazione codice referral funzionante
- [ ] Step 1-4: Form completo
- [ ] Salvataggio in database organization_requests
- [ ] Invio email conferma a organizzazione
- [ ] Invio notifica email ad admin

### 7.2 UX Miglioramenti
- [ ] Indicatore progresso step
- [ ] Validazione real-time campi
- [ ] Messaggi errore chiari
- [ ] Conferma invio richiesta
- [ ] Redirect a pagina thank-you

---

## 8. SISTEMA PREFERITI - FIX CRITICO

### 8.1 Problema Corrente
- [ ] DEBUG: Capire perche .maybeSingle() ritorna null
- [ ] Verificare query Supabase in Network tab
- [ ] Testare query diretta in Supabase SQL Editor
- [ ] Controllare cache Supabase client

### 8.2 Approccio Alternativo (RACCOMANDATO)
- [ ] Ripristinare codice da backup 21 Ottobre 2025:
  - [ ] Estrarre toggleFavorite() da backups/20251021_120850/promotions.html
  - [ ] Estrarre loadFavorites() da backup
  - [ ] Sostituire in public/promotions.html corrente

- [ ] Testare versione ripristinata
- [ ] Documentare differenze tra backup e versione corrente
- [ ] Identificare cosa ha rotto il sistema

### 8.3 Soluzione Database-First (se ripristino fallisce)
- [ ] Creare stored procedure PostgreSQL:
  ```sql
  toggle_favorite(p_user_id UUID, p_promotion_id UUID) RETURNS BOOLEAN
  ```
- [ ] Logica: IF EXISTS DELETE ELSE INSERT, return final state
- [ ] Chiamare da JS via supabase.rpc('toggle_favorite', {...})
- [ ] Eliminare logica client-side complessa

### 8.4 Testing Completo
- [ ] Aggiungere preferito → verifica salvataggio DB
- [ ] Rimuovere preferito → verifica DELETE da DB
- [ ] Ricaricare pagina → verifica caricamento favoriti
- [ ] Andare su favorites.html → verifica lista completa
- [ ] Rimuovere da favorites.html → verifica funzionamento
- [ ] Testare con utenti diversi
- [ ] Verificare RLS (riabilitare dopo fix)

---

## 9. DEPLOYMENT E TESTING

### 9.1 Pre-Deploy Checklist
- [ ] Eseguire tutti gli script SQL su Supabase
- [ ] Testare localmente tutte le funzionalita
- [ ] Verificare nessun errore console
- [ ] Controllare responsive mobile
- [ ] Testare su browser diversi (Chrome, Safari, Firefox)

### 9.2 Deploy Vercel
- [ ] Committare modifiche: `git add . && git commit -m "..."`
- [ ] Push su GitHub: `git push origin main`
- [ ] Deploy manuale: `cd /Users/akirayouky/Desktop/Siti/CDM86-NEW && vercel --prod`
- [ ] Verificare deploy success
- [ ] Testare su https://cdm86-new.vercel.app/

### 9.3 Post-Deploy Testing
- [ ] Login admin → Pannello funzionante
- [ ] Login utente → Dashboard funzionante
- [ ] Login organizzazione → Dashboard funzionante
- [ ] Registrazione nuova organizzazione → Form funzionante
- [ ] Sistema preferiti → Add/Remove funzionante
- [ ] Sistema referral → Codici funzionanti

---

## 10. DOCUMENTAZIONE

### 10.1 File da Aggiornare
- [ ] README.md con istruzioni complete
- [ ] API_DOCUMENTATION.md (se API nuove)
- [ ] Creare ORGANIZATION_GUIDE.md:
  - [ ] Come registrare un'azienda
  - [ ] Come usare dashboard azienda
  - [ ] Come gestire dipendenti
  - [ ] Come creare benefit

### 10.2 Credenziali e Accessi
- [ ] Documentare credenziali test:
  - Admin: admin@cdm86.it / Admin123!
  - Admin2: akirayouky@cdm86.com / Admin2025!
  - User: diegomarruchi@outlook.it / Diego123!

- [ ] Documentare URL:
  - Dashboard: /public/dashboard.html
  - Admin: /public/admin-panel.html
  - Organization: /public/organization-dashboard.html
  - Register Org: /public/register-organization.html

---

## 11. SICUREZZA E OTTIMIZZAZIONE

### 11.1 Row Level Security (RLS)
- [ ] Riabilitare RLS su favorites (dopo fix)
- [ ] Creare policy corrette per organization_benefits
- [ ] Creare policy per organization_requests
- [ ] Testare accessi non autorizzati

### 11.2 Performance
- [ ] Aggiungere indici mancanti
- [ ] Ottimizzare query pesanti
- [ ] Implementare paginazione liste lunghe
- [ ] Cache per dati statici

### 11.3 Validazione
- [ ] Validazione input lato client
- [ ] Validazione input lato server
- [ ] Sanitizzazione dati
- [ ] Protezione XSS/SQL Injection

---

## PRIORITA DI ESECUZIONE

### FASE 1 - CRITICO (Da fare subito)
1. Eseguire SQL su Supabase (setup_organization_panel.sql + organization_requests.sql)
2. Fix sistema preferiti (ripristino da backup)
3. Testare pannello admin richieste aziende

### FASE 2 - ALTA (Questa settimana)
4. Implementare Organization Dashboard (Overview + Dipendenti)
5. Sistema login organizzazioni
6. Sistema punti base (trigger automatico)

### FASE 3 - MEDIA (Prossima settimana)
7. Organization Dashboard completo (Benefit + Referral)
8. Testing completo flusso aziende
9. Deploy e verifica produzione

### FASE 4 - BASSA (Quando possibile)
10. Ottimizzazioni performance
11. Documentazione completa
12. UX miglioramenti

---

**Note:**
- Ogni checkbox completato = task finito e testato
- Priorita: CRITICO > ALTA > MEDIA > BASSA
- Testare SEMPRE prima di deployare in produzione
- Mantenere backup prima di modifiche importanti

---

**Ultimo aggiornamento:** 7 Gennaio 2026  
**Prossima revisione:** Dopo completamento FASE 1
