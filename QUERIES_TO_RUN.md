# 🔍 QUERY DA ESEGUIRE SUL DATABASE

Copia e incolla queste query nel SQL Editor di Supabase per completare l'analisi.

---

## 1️⃣ CONTEGGIO RECORD PER OGNI TABELLA

```sql
SELECT 
    'users' as table_name,
    COUNT(*) as total_records
FROM users
UNION ALL
SELECT 
    'promotions',
    COUNT(*)
FROM promotions
UNION ALL
SELECT 
    'organizations',
    COUNT(*)
FROM organizations
UNION ALL
SELECT 
    'organization_requests',
    COUNT(*)
FROM organization_requests
UNION ALL
SELECT 
    'referrals',
    COUNT(*)
FROM referrals
UNION ALL
SELECT 
    'transactions',
    COUNT(*)
FROM transactions
UNION ALL
SELECT 
    'redemptions',
    COUNT(*)
FROM redemptions
UNION ALL
SELECT 
    'contracts',
    COUNT(*)
FROM contracts
ORDER BY table_name;
```

**Cosa cercare:**
- Quanti record totali in ogni tabella
- Se `referrals` ha 13 record come previsto
- Se `transactions` ha i movimenti punti

---

## 2️⃣ DETTAGLI REFERRALS (tabella referrals)

```sql
SELECT 
    r.id,
    r.referrer_id,
    ref.email as referrer_email,
    ref.referral_code as referrer_code,
    r.referred_id,
    referred.email as referred_email,
    referred.referral_code as referred_code,
    r.level,
    r.points_earned,
    r.created_at
FROM referrals r
JOIN users ref ON r.referrer_id = ref.id
JOIN users referred ON r.referred_id = referred.id
ORDER BY r.created_at DESC;
```

**Cosa cercare:**
- Se ci sono 13 referrals come mostrato nelle tabelle users
- I livelli (level 1 = diretto, level 2 = secondo livello)
- Quanti punti sono stati guadagnati per ogni referral

---

## 3️⃣ TRANSAZIONI PUNTI

```sql
SELECT 
    t.id,
    t.user_id,
    u.email,
    t.type,
    t.amount,
    t.description,
    t.created_at
FROM transactions t
JOIN users u ON t.user_id = u.id
ORDER BY t.created_at DESC;
```

**Cosa cercare:**
- Tipo di transazione (referral_bonus, redemption, ecc.)
- Importi dei punti
- Se i 100 punti iniziali sono transazioni registrate

---

## 4️⃣ VERIFICA INTEGRITÀ REFERRAL SYSTEM

```sql
-- Controlla se ci sono incoerenze tra users.referred_by_id e tabella referrals
SELECT 
    u.email,
    u.referred_by_id,
    CASE 
        WHEN u.referred_by_id IS NOT NULL AND r.id IS NULL THEN '❌ Referral mancante in tabella referrals'
        WHEN u.referred_by_id IS NULL AND r.id IS NOT NULL THEN '❌ Referral presente ma referred_by_id nullo'
        ELSE '✅ OK'
    END as status
FROM users u
LEFT JOIN referrals r ON u.id = r.referred_id
WHERE u.role = 'user'
ORDER BY u.created_at DESC;
```

**Cosa cercare:**
- Tutti gli utenti con referred_by_id devono avere un record in `referrals`
- Gli admin (ADMIN001, ADMIN002) NON devono avere referrals

---

## 5️⃣ ALBERO REFERRAL COMPLETO (Chi ha portato chi)

```sql
WITH RECURSIVE referral_tree AS (
    -- Livello 0: Admin/utenti senza referrer
    SELECT 
        id,
        email,
        referral_code,
        referred_by_id,
        0 as level,
        email as path
    FROM users
    WHERE referred_by_id IS NULL
    
    UNION ALL
    
    -- Livelli successivi
    SELECT 
        u.id,
        u.email,
        u.referral_code,
        u.referred_by_id,
        rt.level + 1,
        rt.path || ' → ' || u.email
    FROM users u
    JOIN referral_tree rt ON u.referred_by_id = rt.id
)
SELECT 
    level,
    email,
    referral_code,
    path as referral_chain
FROM referral_tree
ORDER BY level, email;
```

**Cosa cercare:**
- Livello 0 = Admin (akirayouky, claudio)
- Livello 1 = Diretti (serviziomail1@gmail.com)
- Livello 2 = Riferiti dai diretti (vittoria, giovanni, ginevra, marianna)
- Livello 3 = Riferiti dai livello 2 (giuseppe, marco)

---

## 6️⃣ STATISTICHE REFERRAL PER UTENTE

```sql
SELECT 
    u.email,
    u.referral_code,
    COUNT(DISTINCT r1.referred_id) as diretti_livello_1,
    COUNT(DISTINCT r2.referred_id) as indiretti_livello_2,
    u.points as punti_totali,
    SUM(DISTINCT r1.points_earned) as punti_da_livello_1,
    SUM(DISTINCT r2.points_earned) as punti_da_livello_2
FROM users u
LEFT JOIN referrals r1 ON u.id = r1.referrer_id AND r1.level = 1
LEFT JOIN referrals r2 ON u.id = r2.referrer_id AND r2.level = 2
GROUP BY u.id, u.email, u.referral_code, u.points
HAVING COUNT(DISTINCT r1.referred_id) > 0 OR COUNT(DISTINCT r2.referred_id) > 0
ORDER BY diretti_livello_1 DESC, indiretti_livello_2 DESC;
```

**Cosa cercare:**
- Chi ha più referrals diretti
- Chi guadagna più punti dal sistema MLM
- Se i punti guadagnati corrispondono ai punti in users.points

---

## 7️⃣ REDEMPTIONS (Se presenti)

```sql
SELECT 
    red.id,
    u.email as user_email,
    p.title as promotion_title,
    red.points_spent,
    red.status,
    red.created_at
FROM redemptions red
JOIN users u ON red.user_id = u.id
JOIN promotions p ON red.promotion_id = p.id
ORDER BY red.created_at DESC;
```

**Cosa cercare:**
- Quanti utenti hanno riscattato promozioni
- Status delle redemption (pending, completed, rejected)

---

## 8️⃣ PROMOZIONI ATTIVE VS INATTIVE

```sql
SELECT 
    is_active,
    COUNT(*) as total,
    SUM(points_required) as total_points_needed
FROM promotions
GROUP BY is_active;
```

**Cosa cercare:**
- Quante promozioni sono attive vs inattive
- Totale punti necessari per tutte le promozioni

---

## 9️⃣ ROW LEVEL SECURITY (Policies attive)

```sql
SELECT
    tablename,
    policyname,
    permissive,
    roles,
    cmd as command
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

**Cosa cercare:**
- Quali tabelle hanno RLS abilitato
- Policies per SELECT, INSERT, UPDATE, DELETE
- Se ci sono policy per `authenticated` e `anon`

---

## 🔟 TRIGGERS ATTIVI

```sql
SELECT
    event_object_table as table_name,
    trigger_name,
    event_manipulation as event,
    action_timing as timing
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;
```

**Cosa cercare:**
- Trigger che sincronizzano auth.users → public.users
- Trigger per calcolo automatico punti
- Trigger per aggiornamento created_at/updated_at

---

## ✅ ESEGUI NELL'ORDINE

1. **Query 1** - Conta tutti i record
2. **Query 2** - Dettagli referrals
3. **Query 3** - Transazioni punti
4. **Query 4** - Verifica integrità
5. **Query 5** - Albero referral (IMPORTANTE!)
6. **Query 6** - Statistiche per utente
7. **Query 7** - Redemptions
8. **Query 8** - Promozioni
9. **Query 9** - RLS Policies
10. **Query 10** - Triggers

---

## 📋 RISULTATI DA CONDIVIDERE

Dopo aver eseguito tutte le query, inviami:

1. **Conteggio tabelle** (Query 1)
2. **Albero referral completo** (Query 5) ⭐ IMPORTANTE
3. **Statistiche referral** (Query 6)
4. **Eventuali errori** nelle query 4, 9, 10

Questo mi permetterà di capire:
- ✅ Se il sistema referral funziona correttamente
- ✅ Se i punti vengono assegnati
- ✅ Se le security policies sono attive
- ✅ Se ci sono problemi di integrità dati
