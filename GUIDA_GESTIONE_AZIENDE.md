# 📋 GUIDA GESTIONE AZIENDE - Pannello Admin

**Data:** 7 Gennaio 2026  
**URL Pannello Admin:** https://cdm86-new.vercel.app/public/admin-panel.html

---

## 🎯 FLUSSO COMPLETO GESTIONE AZIENDE

### **SCENARIO 1: Utente Segnala Azienda** (Con Referral)

1. **Utente** fa login e segnala un'azienda
   - Va su Dashboard → Segnala Azienda
   - Compila form con dati azienda
   - Richiesta salvata in `organization_requests` (status: **pending**)

2. **Admin** riceve notifica
   - Login su admin-panel.html
   - Va su tab **"Richieste Aziende"**
   - Vede richiesta con nome azienda e chi l'ha segnalata

3. **Admin** contatta telefonicamente l'azienda
   - Presenta l'offerta CDM86
   - Negozia contratto
   - Fa firmare contratto cartaceo

4. **Admin** inserisce azienda nel sistema
   - Click su **"Aggiungi Azienda"** (pulsante in alto)
   - Compila form:
     - Tipo: Azienda / Associazione
     - Dati completi (nome, email, P.IVA/CF, indirizzo, telefono)
     - ✅ Spunta: **"Questa azienda proviene da segnalazione utente"**
     - Seleziona la richiesta dal dropdown
   - Click **"Crea Azienda"**

5. **Sistema genera automaticamente:**
   - 🎫 **Codice Contratto**: ORG001, ORG002, ecc.
   - 👥 **Codice Dipendenti**: ABC123 (6 caratteri random)
   - 🌍 **Codice Esterni**: ABC123_EXT

6. **Modal di successo appare:**
   ```
   ✅ Azienda Creata!
   
   🎫 Codice Contratto: ORG001
   📧 Email: info@azienda.it
   👥 Codice Dipendenti: ABC123
   🌍 Codice Esterni: ABC123_EXT
   
   [Copia Codice] [Stampa Proforma] [Chiudi]
   ```

7. **Admin** completa operazioni:
   - Copia codice contratto
   - Stampa/invia proforma contratto all'azienda
   - Azienda riceve proforma con codici

8. **Sistema automaticamente:**
   - ✅ Segna richiesta come **"completed"**
   - 💰 Assegna **50 punti** all'utente che ha segnalato
   - 📊 Aggiorna statistiche

---

### **SCENARIO 2: Admin Aggiunge Azienda** (Senza Referral)

1. **Admin** contatta azienda direttamente
   - Cold call, networking, fiere, ecc.
   - Fa firmare contratto

2. **Admin** inserisce azienda
   - Click **"Aggiungi Azienda"**
   - Compila form dati azienda
   - ❌ **NON spunta** checkbox referral
   - Click **"Crea Azienda"**

3. **Sistema genera codici**
   - Come scenario 1
   - `referred_by_id` = ID dell'admin corrente
   - **Nessun punto** assegnato (admin non guadagna punti)

4. **Modal successo e invio proforma**
   - Stesso procedimento scenario 1

---

## 🖥️ PANNELLO ADMIN - ISTRUZIONI OPERATIVE

### **Accesso Pannello**
```
URL: https://cdm86-new.vercel.app/public/admin-panel.html
Credenziali:
  - admin@cdm86.it / Admin123!
  - akirayouky@cdm86.com / Admin2025!
```

### **Tab "Richieste Aziende"**

#### **Sezione 1: Gestione Aziende**
- Pulsante: **"Aggiungi Azienda"** → Apre modal

#### **Sezione 2: Richieste Utenti**
- Mostra tutte le segnalazioni da utenti
- Stati:
  - ⏳ **Pending**: Da contattare
  - ✅ **Approved**: Contattata, in trattativa
  - 🎉 **Completed**: Azienda creata, punti assegnati
  - ❌ **Rejected**: Rifiutata

- **Filtri disponibili:**
  - Cerca per nome, email, telefono
  - Filtra per stato
  - Filtra con/senza referral

---

## 📝 FORM "AGGIUNGI AZIENDA"

### **Campi Obbligatori** (*)

#### **Tipo Organizzazione** *
- Azienda
- Associazione

**Effetto:**
- **Azienda** → Richiede P.IVA
- **Associazione** → Richiede Codice Fiscale

#### **Dati Base**
- Nome Organizzazione *
- Email *

#### **Dati Fiscali**
- P.IVA (se azienda)
- Codice Fiscale (se associazione)

#### **Indirizzo**
- Indirizzo completo
- Città
- Provincia (2 lettere)
- CAP
- Telefono

#### **Referral**
- ☐ Checkbox: "Questa azienda proviene da segnalazione utente"
- Se spuntato:
  - Dropdown con richieste pending
  - Mostra: Nome azienda - Email - (da NomeUtente)

#### **Info Automatiche**
Il sistema genererà automaticamente:
- Codice Contratto (ORG001, ORG002...)
- Codice Dipendenti (ABC123)
- Codice Esterni (ABC123_EXT)

---

## 🎫 MODAL SUCCESSO

Dopo aver creato l'azienda, appare modal con:

```
✅ Azienda Creata!

🎫 Codice Contratto: ORG001
   [Copia] ← Click per copiare negli appunti

📧 Email: info@azienda.it

👥 Codice Dipendenti: ABC123
   Da dare ai dipendenti per registrarsi

🌍 Codice Esterni: ABC123_EXT
   Per marketing/referral esterni

[Stampa Proforma] [Chiudi]
```

### **Azioni disponibili:**

1. **Copia Codice Contratto**
   - Click sul pulsante "Copia"
   - Codice copiato negli appunti
   - Usalo per proforma

2. **Stampa Proforma**
   - Apre dialogo stampa
   - Include tutti i dati
   - Da inviare all'azienda

3. **Chiudi**
   - Chiude modal
   - Ricarica pagina
   - Mostra azienda creata

---

## 💰 SISTEMA PUNTI REFERRAL

### **Quando un utente riceve punti:**

1. Admin crea azienda **DA SEGNALAZIONE**
2. Spunta checkbox referral
3. Seleziona richiesta dal dropdown
4. Crea azienda
5. **Sistema automaticamente:**
   - Assegna **50 punti** all'utente
   - Aggiorna `points` +50
   - Aggiorna `total_points_earned` +50
   - Segna richiesta come **completed**

### **Quando NON si assegnano punti:**

- Admin crea azienda senza checkbox referral
- `referred_by_id` = ID admin
- Nessun punto assegnato

---

## 🔍 VERIFICA DATI

### **Controlla aziende create:**

```sql
SELECT 
    name as "Nome",
    email as "Email",
    referral_code as "Codice Dipendenti",
    referral_code_external as "Codice Esterni",
    organization_type as "Tipo",
    created_at as "Data Creazione"
FROM organizations
ORDER BY created_at DESC;
```

### **Controlla richieste completate:**

```sql
SELECT 
    organization_name as "Azienda",
    contact_email as "Email Contatto",
    status as "Stato",
    contract_code as "Codice Contratto",
    completed_at as "Completata il"
FROM organization_requests
WHERE status = 'completed'
ORDER BY completed_at DESC;
```

### **Controlla punti assegnati:**

```sql
SELECT 
    u.first_name || ' ' || u.last_name as "Utente",
    u.email,
    u.points as "Punti Attuali",
    u.total_points_earned as "Punti Totali",
    COUNT(orq.id) as "Aziende Segnalate"
FROM users u
LEFT JOIN organization_requests orq 
    ON u.id = orq.referred_by_id 
    AND orq.status = 'completed'
GROUP BY u.id, u.first_name, u.last_name, u.email, u.points, u.total_points_earned
ORDER BY u.total_points_earned DESC;
```

---

## 📧 CREDENZIALI AZIENDA (Opzionale)

Per permettere all'azienda di accedere al proprio pannello:

### **Crea user su Supabase:**
1. Dashboard → Authentication → Users → Add User
2. Email: (email azienda)
3. Password: (genera password sicura)
4. Copia ID user generato

### **Collega user a organization:**
```sql
UPDATE organizations 
SET id = 'ID_USER_COPIATO'
WHERE email = 'email@azienda.com';
```

### **Invia credenziali all'azienda:**
```
Benvenuto in CDM86!

Le tue credenziali per accedere al pannello azienda:

URL: https://cdm86-new.vercel.app/public/organization-dashboard.html
Email: email@azienda.com
Password: [password generata]

Potrai:
- Gestire dipendenti
- Creare benefit personalizzati
- Vedere statistiche referral
- Gestire codici dipendenti/esterni
```

---

## ⚠️ TROUBLESHOOTING

### **Problema: Modal non si apre**
- Verifica console browser (F12)
- Controlla errori JavaScript
- Ricarica pagina

### **Problema: Dropdown richieste vuoto**
- Verifica che esistano richieste con status "pending"
- Query:
  ```sql
  SELECT * FROM organization_requests WHERE status = 'pending';
  ```

### **Problema: Errore creazione azienda**
- Controlla email non già esistente
- Verifica campi obbligatori compilati
- P.IVA 11 caratteri (aziende)
- Codice Fiscale 16 caratteri (associazioni)

### **Problema: Punti non assegnati**
- Verifica checkbox referral spuntato
- Controlla richiesta selezionata
- Verifica `referred_by_id` nella richiesta
- Query:
  ```sql
  SELECT id, referred_by_id FROM organization_requests WHERE id = 'ID_RICHIESTA';
  ```

---

## 📊 STATISTICHE DASHBOARD

Il tab "Richieste Aziende" mostra:

- **Totale Richieste**: Conteggio totale
- **Da Contattare**: Status pending
- **Approvate**: Status approved
- **Completate**: Status completed (azienda creata)

---

## 🎯 BEST PRACTICES

1. **Contatta SEMPRE telefonicamente** prima di creare azienda
2. **Fai firmare contratto cartaceo** prima di inserire nel sistema
3. **Spunta checkbox referral** solo se proviene da segnalazione utente
4. **Copia codice contratto** subito dopo creazione
5. **Stampa/invia proforma** all'azienda
6. **Verifica email univoca** (non duplicate)
7. **Compila indirizzo completo** per proforma corretta

---

## 📝 CHECKLIST OPERATIVA

### **Per ogni nuova azienda:**

- [ ] Contatto telefonico effettuato
- [ ] Contratto cartaceo firmato
- [ ] Dati completi raccolti
- [ ] Email verificata (univoca)
- [ ] P.IVA/CF verificati
- [ ] Indirizzo completo
- [ ] Checkbox referral (se da segnalazione)
- [ ] Richiesta selezionata (se referral)
- [ ] Azienda creata
- [ ] Codice contratto copiato
- [ ] Proforma stampata/inviata
- [ ] Punti assegnati (se referral)

---

**🚀 Sistema pronto all'uso!**

**URL Produzione:** https://cdm86-new.vercel.app/public/admin-panel.html

**Ultimo Deploy:** 7 Gennaio 2026
