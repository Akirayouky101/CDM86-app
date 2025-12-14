# 🔍 DIAGNOSI: Query Fallite

## ❌ Query che Non Funzionano

### Query 9: Sample Users
```sql
SELECT id, email, first_name, last_name, referral_code, referred_by_id, total_points, role, created_at
FROM users
ORDER BY created_at DESC
LIMIT 5;
```
**Errore**: Probabilmente `total_points` non esiste - la colonna si chiama `points`

### Query 10-14: Tutte usano campi che potrebbero non esistere

---

## 🔧 FIX QUERY CORRETTE

### ✅ Query 9 FIX: Sample Users
```sql
SELECT 
    id,
    email,
    first_name,
    last_name,
    referral_code,
    referred_by_id,
    points as total_points,  -- ✅ Corretto
    role,
    created_at
FROM users
ORDER BY created_at DESC
LIMIT 10;
```

### ✅ Query 12 FIX: Verifica Referral System
```sql
SELECT 
    u.id,
    u.email,
    u.referral_code as my_code,
    u.referred_by_id,
    ref.email as referred_by_email,
    ref.referral_code as referred_by_code,
    u.points as total_points  -- ✅ Corretto
FROM users u
LEFT JOIN users ref ON u.referred_by_id = ref.id
ORDER BY u.created_at DESC
LIMIT 20;
```

### ✅ Query 14 FIX: Statistiche Referral
```sql
SELECT 
    referrer.email as referrer_email,
    referrer.referral_code,
    COUNT(referred.id) as total_referrals,
    SUM(referred.points) as total_points_of_referrals  -- ✅ Corretto
FROM users referrer
LEFT JOIN users referred ON referred.referred_by_id = referrer.id
GROUP BY referrer.id, referrer.email, referrer.referral_code
HAVING COUNT(referred.id) > 0
ORDER BY total_referrals DESC
LIMIT 10;
```

---

## 📊 QUERY CONTEGGIO RECORD (Esegui Questa)

```sql
-- Conta record in tutte le tabelle principali
SELECT 
    'users' as table_name, 
    COUNT(*) as count,
    COUNT(*) FILTER (WHERE referred_by_id IS NOT NULL) as with_referral
FROM users

UNION ALL

SELECT 
    'promotions' as table_name, 
    COUNT(*) as count,
    COUNT(*) FILTER (WHERE is_active = true) as active
FROM promotions

UNION ALL

SELECT 
    'organizations' as table_name, 
    COUNT(*) as count,
    COUNT(*) FILTER (WHERE active = true) as active
FROM organizations

UNION ALL

SELECT 
    'organization_requests' as table_name, 
    COUNT(*) as count,
    COUNT(*) FILTER (WHERE status = 'pending') as pending
FROM organization_requests

UNION ALL

SELECT 
    'referral_network' as table_name, 
    COUNT(*) as count,
    COUNT(*) FILTER (WHERE level = 1) as direct_referrals
FROM referral_network

UNION ALL

SELECT 
    'points_transactions' as table_name, 
    COUNT(*) as count,
    COUNT(*) FILTER (WHERE transaction_type = 'referral_completed') as referral_points
FROM points_transactions

UNION ALL

SELECT 
    'user_points' as table_name, 
    COUNT(*) as count,
    COALESCE(SUM(points_total), 0) as total_points_in_system
FROM user_points

UNION ALL

SELECT 
    'contracts' as table_name, 
    COUNT(*) as count,
    COUNT(*) FILTER (WHERE status = 'active') as active
FROM contracts

UNION ALL

SELECT 
    'promotion_redemptions' as table_name, 
    COUNT(*) as count,
    COUNT(*) FILTER (WHERE is_used = false) as unused_codes
FROM promotion_redemptions;
```

---

## 🎯 PROSSIMI STEP

1. **Esegui la query conteggio** sopra
2. **Inviami i risultati** così vedo quanti dati ci sono
3. **Poi esegui le query FIX** corrette
4. **Inviami anche questi risultati**

Questo ci dirà:
- ✅ Quanti utenti ci sono
- ✅ Se il referral system funziona
- ✅ Quante promozioni attive
- ✅ Se ci sono organizations
- ✅ Stato del sistema punti

**Nel frattempo, dimmi l'ERRORE che stai vedendo ora sul sito!** 🐛
