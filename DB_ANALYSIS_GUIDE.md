# 🔍 GUIDA RAPIDA ANALISI DATABASE CDM86

## 📋 Come Usare

### Metodo 1: Supabase Dashboard (CONSIGLIATO)
1. Vai su https://supabase.com/dashboard
2. Seleziona progetto: `uchrjlngfzfibcpdxtky`
3. Clicca su **SQL Editor** (icona </> nel menu laterale)
4. Copia e incolla le query sotto una alla volta
5. Clicca **RUN** per ogni query
6. Copia i risultati e inviameli

---

## 🎯 QUERY ESSENZIALI (Copia e Incolla)

### ✅ QUERY 1: Lista tutte le tabelle
```sql
SELECT tablename 
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;
```

### ✅ QUERY 2: Struttura completa USERS
```sql
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
    AND table_name = 'users'
ORDER BY ordinal_position;
```

### ✅ QUERY 3: Foreign Keys e Relazioni
```sql
SELECT
    tc.table_name as from_table,
    kcu.column_name as from_column,
    ccu.table_name AS to_table,
    ccu.column_name AS to_column
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
ORDER BY tc.table_name;
```

### ✅ QUERY 4: RLS Policies
```sql
SELECT
    tablename,
    policyname,
    cmd as command,
    qual as using_expression
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename;
```

### ✅ QUERY 5: Conteggio Record
```sql
SELECT 'users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'promotions', COUNT(*) FROM promotions
UNION ALL
SELECT 'organizations', COUNT(*) FROM organizations
UNION ALL
SELECT 'organization_requests', COUNT(*) FROM organization_requests
UNION ALL
SELECT 'referrals', COUNT(*) FROM referrals
UNION ALL
SELECT 'transactions', COUNT(*) FROM transactions
UNION ALL
SELECT 'redemptions', COUNT(*) FROM redemptions
UNION ALL
SELECT 'contracts', COUNT(*) FROM contracts;
```

### ✅ QUERY 6: Sample Users (ultimi 10)
```sql
SELECT 
    id,
    email,
    first_name,
    last_name,
    referral_code,
    referred_by_id,
    total_points,
    role,
    created_at
FROM users
ORDER BY created_at DESC
LIMIT 10;
```

### ✅ QUERY 7: Verifica Referral System
```sql
SELECT 
    u.email as user_email,
    u.referral_code as my_code,
    u.referred_by_id,
    ref.email as referred_by_email,
    u.total_points
FROM users u
LEFT JOIN users ref ON u.referred_by_id = ref.id
ORDER BY u.created_at DESC
LIMIT 20;
```

### ✅ QUERY 8: Organizations Complete
```sql
SELECT 
    id,
    name,
    email,
    referral_code,
    referral_code_external,
    status,
    created_at
FROM organizations
ORDER BY created_at DESC;
```

### ✅ QUERY 9: Errori Integrità Referral
```sql
-- Trova users con referred_by_id non valido
SELECT 
    u.id,
    u.email,
    u.referred_by_id as invalid_referrer_id,
    'Referred_by_id points to non-existent user' as error
FROM users u
LEFT JOIN users ref ON u.referred_by_id = ref.id
WHERE u.referred_by_id IS NOT NULL 
    AND ref.id IS NULL;
```

### ✅ QUERY 10: Statistiche Referral Top 10
```sql
SELECT 
    referrer.email as referrer,
    referrer.referral_code,
    COUNT(referred.id) as total_referrals,
    SUM(referred.total_points) as total_points
FROM users referrer
LEFT JOIN users referred ON referred.referred_by_id = referrer.id
GROUP BY referrer.id, referrer.email, referrer.referral_code
HAVING COUNT(referred.id) > 0
ORDER BY total_referrals DESC
LIMIT 10;
```

### ✅ QUERY 11: Verifica Auth Sync
```sql
-- Trova discrepanze tra auth.users e public.users
SELECT 
    'In auth.users but NOT in public.users' as issue,
    au.id,
    au.email
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL
UNION ALL
SELECT 
    'In public.users but NOT in auth.users' as issue,
    pu.id,
    pu.email
FROM public.users pu
LEFT JOIN auth.users au ON pu.id = au.id
WHERE au.id IS NULL;
```

### ✅ QUERY 12: Triggers Attivi
```sql
SELECT
    trigger_name,
    event_object_table as table_name,
    action_statement,
    action_timing
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table;
```

---

## 📊 COSA CERCARE NEI RISULTATI

### 🔴 PROBLEMI COMUNI:
- ❌ Users con `referred_by_id` che punta a ID inesistente
- ❌ Discrepanze tra `auth.users` e `public.users`
- ❌ Tabelle senza RLS policies (security risk!)
- ❌ Foreign keys mancanti o rotti
- ❌ Triggers che potrebbero causare errori

### ✅ COSA DOVREBBE ESSERCI:
- ✅ Trigger `handle_new_user` su auth.users
- ✅ RLS policies su tutte le tabelle principali
- ✅ Foreign key: `users.referred_by_id` → `users.id`
- ✅ Tutti gli users hanno `referral_code` univoco
- ✅ Sync perfetto tra auth.users e public.users

---

## 🚀 PROSSIMI PASSI

Dopo aver eseguito le query:

1. **Copia i risultati** delle query 1, 2, 3, 4, 5, 6, 7, 9, 11, 12
2. **Incollali in un messaggio** o fai screenshot
3. **Segnala eventuali errori** che vedi nei risultati
4. Ti preparerò query SQL di FIX per ogni problema trovato

---

## 🆘 SE HAI ERRORI

Se una query dà errore, potrebbe essere:
- 🔐 **Permessi insufficienti**: Usa il Service Role Key invece di anon key
- 📋 **Tabella non esiste**: Normale se non l'hai creata ancora
- ⚠️ **Syntax error**: Assicurati di copiare tutta la query

In quel caso **inviami l'errore esatto** e lo risolviamo!

---

## 📁 FILE COMPLETO

Per l'analisi completa con TUTTE le query dettagliate:
👉 Apri `ANALYZE_DATABASE.sql` e esegui nel SQL Editor

---

## 💡 TIP

Puoi eseguire tutte queste query anche da **TablePlus**, **DBeaver** o **psql** se hai la connection string del database PostgreSQL di Supabase.

Connection string format:
```
postgresql://postgres:[YOUR-PASSWORD]@db.uchrjlngfzfibcpdxtky.supabase.co:5432/postgres
```

Trovi la password in: Supabase Dashboard → Settings → Database → Connection string
