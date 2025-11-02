# 🔧 FIX REFERRAL SYSTEM - Configurazione Vercel

## 🔴 PROBLEMA IDENTIFICATO

Le RLS policies su Supabase richiedono `auth.uid() = id` per UPDATE.
Dopo `signUp()`, l'utente NON è loggato (richiede conferma email).
Quindi l'UPDATE di `referred_by_id` fallisce perché `auth.uid()` è NULL.

## ✅ SOLUZIONE

Creato endpoint API `/api/set-referral.js` che usa **service_role** per bypassare RLS in modo sicuro.

## 📋 CONFIGURAZIONE VERCEL

### 1. Trova la tua Service Role Key

1. Vai su **Supabase Dashboard**
2. Clicca sul tuo progetto
3. Settings → API
4. Copia **service_role** key (⚠️ NON anon key!)

### 2. Configura Environment Variables su Vercel

1. Vai su **Vercel Dashboard**
2. Seleziona il progetto `CDM86-app`
3. Settings → Environment Variables
4. Aggiungi queste variabili:

```
Name: SUPABASE_URL
Value: https://uchrjlngfzfibcpdxtky.supabase.co
```

```
Name: SUPABASE_SERVICE_ROLE_KEY
Value: [LA TUA SERVICE ROLE KEY QUI]
```

5. **IMPORTANTE**: Seleziona **Production, Preview, Development** per entrambe
6. Clicca **Save**

### 3. Redeploy

Dopo aver salvato le variabili:

1. Vai su **Deployments**
2. Clicca sui `...` dell'ultimo deploy
3. Clicca **Redeploy**

OPPURE fai semplicemente:
```bash
git push origin main
```

## 🧪 TEST

Dopo il deploy:

1. Vai su `https://cdm86.com/?ref=06AC519C`
2. Registra nuovo utente
3. Apri Console (F12)
4. Dovresti vedere:
   ```
   🔄 Inizio aggiornamento referral tramite API...
   ✅ Referral impostato via API: {...}
   🎉 SUCCESS! referred_by_id impostato correttamente!
   ```

5. Verifica su Supabase:
   ```sql
   SELECT id, email, referred_by_id 
   FROM users 
   ORDER BY created_at DESC 
   LIMIT 1;
   ```

## 📊 VERIFICA COMPLETA

```sql
-- 1. Check ultimo utente
SELECT * FROM users ORDER BY created_at DESC LIMIT 1;

-- 2. Check punti assegnati
SELECT * FROM points_transactions 
WHERE transaction_type = 'referral_completed'
ORDER BY created_at DESC 
LIMIT 5;

-- 3. Check referrer
SELECT 
    u.first_name || ' ' || u.last_name as referrer,
    up.points_total,
    up.referrals_count
FROM users u
JOIN user_points up ON u.id = up.user_id
WHERE u.referral_code = '06AC519C';
```

## ⚠️ IMPORTANTE

**MAI esporre la service_role key nel frontend!**
- ✅ Usala solo in `/api/*` serverless functions
- ✅ Le env vars di Vercel sono sicure (server-side only)
- ❌ Non metterla in `config.js` o file frontend
- ❌ Non commitarla in `.env` (usa `.env.example`)

## 🔍 DEBUGGING

Se l'API non funziona:

1. **Check Vercel Logs**:
   - Deployments → Function Logs
   - Cerca errori `set-referral`

2. **Check Network**:
   - F12 → Network
   - Cerca `set-referral`
   - Status dovrebbe essere 200

3. **Check Response**:
   - Se 404: API non deploiata
   - Se 500: Errore server (check logs)
   - Se 400: Validazione fallita (check body)

## 📁 FILE MODIFICATI

- ✅ `/api/set-referral.js` (NEW)
- ✅ `/assets/js/login-modal.js` (usa API invece di UPDATE diretto)
- ✅ `.env.example` (aggiunto SUPABASE_SERVICE_ROLE_KEY)
- ✅ `database/CHECK_RLS_POLICIES.sql` (diagnostica RLS)

## 🚀 PROSSIMI STEP

1. Configura Vercel env vars
2. Redeploy
3. Testa registrazione con referral
4. Verifica punti assegnati
5. Se funziona: esegui `FIX_ALL_REFERRALS_RETROACTIVE.sql` per utenti esistenti
