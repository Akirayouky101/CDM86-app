# 🎯 ISTRUZIONI: Setup Sistema Compensi Aziende

## 📋 COSA È STATO IMPLEMENTATO

Sistema completo per segnalazione aziende con:
- **3 tipi di azienda**: Inserzionista, Partner, Associazione
- **Compensi differenziati**: 30€ per inserzionista, 0€ per partner/associazione
- **Punti fissi**: 1 punto per qualsiasi tipo
- **MLM compensi**: Distribuzione automatica a livello 1 (50%) e 2 (30%)

---

## ⚡ ESEGUI QUESTI SCRIPT SU SUPABASE (IN ORDINE!)

### **Step 1: Aggiungi colonne al database**

```sql
-- File: database/add_company_type_field.sql
-- Vai su Supabase → SQL Editor → Copia e incolla questo file → Run
```

Questo aggiunge:
- `company_type` (inserzionista/partner/associazione)
- `compensation_amount` (€ assegnati)
- `points_awarded` (punti assegnati)

---

### **Step 2: Crea trigger compensi**

```sql
-- File: database/company_reports_approval_trigger.sql
-- Vai su Supabase → SQL Editor → Copia e incolla questo file → Run
```

Questo crea:
- Trigger automatico quando admin approva segnalazione
- Assegna 1 punto all'utente (sempre)
- Assegna 30€ se inserzionista (+ MLM: 15€ livello 1, 9€ livello 2)
- Assegna 0€ se partner o associazione

---

## 📊 SCHEMA COMPENSI FINALE

### **Azienda Inserzionista Approvata:**
| Livello | Punti | Compenso € |
|---------|-------|------------|
| Utente diretto | +1 | +30€ |
| MLM Livello 1 | 0 | +15€ (50%) |
| MLM Livello 2 | 0 | +9€ (30%) |
| **TOTALE** | **1 punto** | **54€ distribuiti** |

### **Azienda Partner Approvata:**
| Livello | Punti | Compenso € |
|---------|-------|------------|
| Utente diretto | +1 | 0€ |

### **Associazione Approvata:**
| Livello | Punti | Compenso € |
|---------|-------|------------|
| Utente diretto | +1 | 0€ |

---

## ✅ TESTING

### **1. Segnala un'azienda inserzionista**
1. Login come utente normale
2. Dashboard → "Segnala Azienda/Associazione"
3. **Step 2**: Seleziona "💼 Azienda Inserzionista"
4. Completa wizard → Invia

### **2. Approva dall'admin**
1. Login come admin
2. Admin Panel → Tab "Segnalazioni"
3. Trova segnalazione → Cambia stato → "Approvata"

### **3. Verifica compensi**
Controlla su Supabase:

```sql
-- Verifica punti assegnati
SELECT 
  cr.company_name,
  cr.company_type,
  cr.status,
  cr.points_awarded,
  cr.compensation_amount,
  u.email as utente_segnalante,
  u.points as punti_totali_utente
FROM company_reports cr
JOIN users u ON cr.reported_by_user_id = u.id
WHERE cr.status = 'approved'
ORDER BY cr.created_at DESC;

-- Verifica transazioni compensi
SELECT 
  u.email,
  pt.transaction_type,
  pt.points,
  pt.compensation_euros,
  pt.description,
  pt.created_at
FROM points_transactions pt
JOIN users u ON pt.user_id = u.id
WHERE pt.transaction_type IN ('company_report_approved', 'company_compensation', 'mlm_compensation_level1', 'mlm_compensation_level2')
ORDER BY pt.created_at DESC;
```

### **Risultati attesi:**
1. ✅ `company_reports.points_awarded` = 1
2. ✅ `company_reports.compensation_amount` = 30.00 (se inserzionista)
3. ✅ `users.points` aumentati di +1
4. ✅ 3 transazioni in `points_transactions`:
   - Tipo `company_report_approved`: +1 punto
   - Tipo `company_compensation`: 0 punti, 30€
   - Tipo `mlm_compensation_level1`: 0 punti, 15€ (se utente ha referrer)
   - Tipo `mlm_compensation_level2`: 0 punti, 9€ (se referrer ha referrer)

---

## 🎨 INTERFACCIA UTENTE

### **Wizard Step 2 - Selezione Tipo**
Adesso nello Step 2 appare:
```
┌─────────────────────────────────────────┐
│ 🏢 Tipo di Azienda/Associazione *       │
├─────────────────────────────────────────┤
│ ⚪ 💼 Azienda Inserzionista             │
│    ✅ Compenso: 30€ + 1 punto + MLM     │
├─────────────────────────────────────────┤
│ ⚪ 🤝 Azienda Partner                    │
│    ✅ Compenso: 0€ + 1 punto            │
├─────────────────────────────────────────┤
│ ⚪ 🎗️ Associazione                      │
│    ✅ Compenso: 0€ + 1 punto            │
└─────────────────────────────────────────┘
```

### **Admin Panel - Card Segnalazione**
Badge visibili:
- `💼 Inserzionista (30€)` (gradient viola)
- `🤝 Partner` (gradient rosa)
- `🎗️ Associazione` (gradient azzurro)

Footer mostra (quando approvata):
- ⭐ 1 punto (badge verde)
- 💰 €30.00 (badge viola) - solo per inserzionista

---

## 🚨 NOTE IMPORTANTI

1. **Colonna compensation_euros**: Il trigger aggiunge automaticamente questa colonna a `points_transactions` se non esiste
2. **MLM cascade**: I compensi MLM vengono distribuiti SOLO per aziende inserzioniste
3. **Punti sempre fissi**: Indipendentemente dal tipo, l'utente riceve sempre e solo 1 punto
4. **Compensi solo all'approvazione**: Se la segnalazione viene rifiutata, nessun compenso/punto viene assegnato

---

## 📚 FILES COINVOLTI

### Database:
- `database/add_company_type_field.sql` - Migration campi
- `database/company_reports_approval_trigger.sql` - Trigger compensi

### Frontend:
- `public/dashboard.html` - Wizard con selezione tipo
- `assets/js/login-modal.js` - JavaScript salvataggio company_type
- `public/admin-panel.html` - Visualizzazione tipo e compensi

---

## ✨ DEPLOY

Tutto già deployato su Vercel! 🚀
URL: https://cdm86-c6wgclum8-akirayoukys-projects.vercel.app

**MANCA SOLO**: Eseguire i 2 script SQL su Supabase (Step 1 e Step 2 sopra)
