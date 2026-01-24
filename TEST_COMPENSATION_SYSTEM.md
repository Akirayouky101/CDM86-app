# 🧪 TEST SISTEMA COMPENSI - Checklist

## ✅ PREREQUISITI
- [x] Script `add_company_type_field.sql` eseguito su Supabase
- [x] Script `company_reports_approval_trigger.sql` eseguito su Supabase

---

## 📝 TEST 1: Segnalazione Azienda Inserzionista

### **Step 1: Crea segnalazione**
1. Login come **utente normale** (non admin)
2. Dashboard → Click "Segnala Azienda/Associazione"
3. Modal informativo → Click "Procedi con la segnalazione"
4. **Step 1**: Compila dati azienda
   - Nome: `Test Inserzionista SRL`
   - Contatto: `Mario Rossi`
   - Email: `test@inserzionista.it`
   - Telefono: `3331234567`
   - Indirizzo: `Via Test 123, Milano`
5. Click "Avanti"
6. **Step 2**: 
   - ⭐ **IMPORTANTE**: Seleziona "💼 Azienda Inserzionista" (deve mostrare "30€ + 1 punto + MLM")
   - Settore: `Ristorazione`
   - Consapevole: `Sì`
   - Chi conosce: `Titolare`
   - Orari: `10:00 - 12:00`
   - Referral dato: `Sì`
   - Email consent: `Sì`
7. Click "Invia Segnalazione"
8. ✅ Verifica messaggio successo

### **Step 2: Verifica segnalazione creata**
Esegui su Supabase:
```sql
SELECT 
  id,
  company_name,
  company_type,  -- ⭐ DEVE ESSERE 'inserzionista'
  status,        -- DEVE ESSERE 'pending'
  reported_by_user_id,
  reported_by_referral_code
FROM company_reports
WHERE company_name = 'Test Inserzionista SRL'
ORDER BY created_at DESC
LIMIT 1;
```

**Risultato atteso:**
- `company_type` = `'inserzionista'`
- `status` = `'pending'`
- `reported_by_referral_code` = codice referral utente

---

### **Step 3: Approva come admin**
1. Logout → Login come **admin**
2. Admin Panel → Tab "Segnalazioni"
3. Trova "Test Inserzionista SRL"
4. ⭐ Verifica badge: **💼 Inserzionista (30€)**
5. Dropdown "Cambia Stato" → Seleziona "Approvata"
6. ✅ Verifica che stato cambi

### **Step 4: Verifica punti e compensi assegnati**
Esegui su Supabase:
```sql
-- Verifica record aggiornato
SELECT 
  company_name,
  company_type,
  status,
  points_awarded,        -- ⭐ DEVE ESSERE 1
  compensation_amount,   -- ⭐ DEVE ESSERE 30.00
  reported_by_user_id,
  created_at,
  updated_at
FROM company_reports
WHERE company_name = 'Test Inserzionista SRL';
```

**Risultato atteso:**
- ✅ `status` = `'approved'`
- ✅ `points_awarded` = `1`
- ✅ `compensation_amount` = `30.00`

---

### **Step 5: Verifica punti utente**
```sql
-- Verifica punti utente segnalante
SELECT 
  u.email,
  u.referral_code,
  up.points_total,      -- ⭐ DEVE ESSERE AUMENTATO DI +1
  up.points_available,  -- ⭐ DEVE ESSERE AUMENTATO DI +1
  up.approved_reports_count  -- ⭐ DEVE ESSERE +1
FROM users u
JOIN user_points up ON up.user_id = u.id
WHERE u.id = (
  SELECT reported_by_user_id 
  FROM company_reports 
  WHERE company_name = 'Test Inserzionista SRL'
);
```

**Risultato atteso:**
- ✅ `points_total` aumentato di +1
- ✅ `points_available` aumentato di +1
- ✅ `approved_reports_count` aumentato di +1

---

### **Step 6: Verifica transazioni compensi**
```sql
-- Verifica tutte le transazioni create
SELECT 
  u.email,
  u.referral_code,
  pt.transaction_type,
  pt.points,
  pt.compensation_euros,
  pt.description,
  pt.created_at
FROM points_transactions pt
JOIN users u ON pt.user_id = u.id
WHERE pt.reference_id = (
  SELECT id FROM company_reports WHERE company_name = 'Test Inserzionista SRL'
)
ORDER BY pt.created_at;
```

**Risultato atteso (4 transazioni totali):**

1. ✅ **Transazione 1 - Utente Diretto - Punti:**
   - `transaction_type` = `'company_report_approved'`
   - `points` = `1`
   - `compensation_euros` = `0` o `NULL`
   - `description` = "Segnalazione approvata: Test Inserzionista SRL (inserzionista)"

2. ✅ **Transazione 2 - Utente Diretto - Compenso:**
   - `transaction_type` = `'company_compensation'`
   - `points` = `0`
   - `compensation_euros` = `30.00`
   - `description` = "Compenso azienda inserzionista: Test Inserzionista SRL"

3. ✅ **Transazione 3 - MLM Livello 1 (se utente ha referrer):**
   - `transaction_type` = `'mlm_compensation_level1'`
   - `points` = `0`
   - `compensation_euros` = `15.00`
   - `description` = "MLM Livello 1: Inserzionista Test Inserzionista SRL segnalata da rete"
   - `user_id` = ID del referrer dell'utente

4. ✅ **Transazione 4 - MLM Livello 2 (se referrer ha referrer):**
   - `transaction_type` = `'mlm_compensation_level2'`
   - `points` = `0`
   - `compensation_euros` = `9.00`
   - `description` = "MLM Livello 2: Inserzionista Test Inserzionista SRL segnalata da rete"
   - `user_id` = ID del referrer del referrer

**Nota:** Se l'utente non ha referrer, vedrai solo le prime 2 transazioni (punti + compenso diretto)

---

### **Step 7: Verifica interfaccia admin**
1. Admin Panel → Tab "Segnalazioni"
2. Trova card "Test Inserzionista SRL"
3. ⭐ Verifica badge visibili:
   - Badge tipo: **💼 Inserzionista (30€)** (gradient viola)
   - Badge status: **Iscritta** (verde)
4. ⭐ Nel footer verifica:
   - Badge punti: **⭐ 1 punto** (sfondo verde)
   - Badge compenso: **💰 €30.00** (sfondo viola)

---

## 📝 TEST 2: Segnalazione Azienda Partner

Ripeti stessi step ma:
- **Step 1 → 6**: Seleziona "🤝 Azienda Partner"
- **Step 3**: Approva

**Risultati attesi:**
- ✅ `points_awarded` = `1`
- ✅ `compensation_amount` = `0.00`
- ✅ Solo 1 transazione (punti, nessun compenso)
- ✅ NO transazioni MLM

---

## 📝 TEST 3: Segnalazione Associazione

Ripeti stessi step ma:
- **Step 1 → 6**: Seleziona "🎗️ Associazione"
- **Step 3**: Approva

**Risultati attesi:**
- ✅ `points_awarded` = `1`
- ✅ `compensation_amount` = `0.00`
- ✅ Solo 1 transazione (punti, nessun compenso)
- ✅ NO transazioni MLM

---

## 🐛 TROUBLESHOOTING

### Problema: "company_type non può essere NULL"
**Soluzione:** Vecchie segnalazioni non hanno company_type. Aggiorna:
```sql
UPDATE company_reports 
SET company_type = 'partner' 
WHERE company_type IS NULL;
```

### Problema: "compensation_euros column does not exist"
**Soluzione:** Il trigger dovrebbe crearla automaticamente, ma se non funziona:
```sql
ALTER TABLE points_transactions
ADD COLUMN IF NOT EXISTS compensation_euros DECIMAL(10,2) DEFAULT 0.00;
```

### Problema: Nessuna transazione MLM creata
**Verifica:** L'utente ha un referrer?
```sql
SELECT id, email, referred_by_id 
FROM users 
WHERE id = (SELECT reported_by_user_id FROM company_reports WHERE company_name = 'Test Inserzionista SRL');
```
Se `referred_by_id` è `NULL`, è normale che non ci siano transazioni MLM.

---

## ✅ CHECKLIST FINALE

- [ ] Segnalazione inserzionista creata con `company_type = 'inserzionista'`
- [ ] Approvazione assegna 1 punto + 30€
- [ ] Transazioni corrette in `points_transactions`
- [ ] MLM distribuito a livello 1 (15€) e 2 (9€) - se applicabile
- [ ] Badge visibili correttamente in admin panel
- [ ] Partner e Associazione danno solo 1 punto (0€)

---

## 🎉 SE TUTTO OK

Il sistema funziona perfettamente! 
- Utenti vedono compensi chiari nel wizard
- Admin vede tipo azienda e compensi assegnati
- Database traccia tutto correttamente
- MLM distribuisce automaticamente

**Sistema pronto per produzione!** 🚀
