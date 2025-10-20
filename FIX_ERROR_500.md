# 🔴 ERRORE 500 DURANTE REGISTRAZIONE - SOLUZIONE

## 🐛 Problema
Quando provi a registrarti, ricevi:
```
POST https://uchrjlngfzfibcpdxtky.supabase.co/auth/v1/signup
HTTP/1.1 500
```

## ⚠️ Causa
**Manca il trigger Supabase** che crea automaticamente l'utente nella tabella `public.users` quando qualcuno si registra tramite `auth.users`.

---

## ✅ SOLUZIONE (3 passi)

### Passo 1: Apri Supabase SQL Editor

1. Vai su https://supabase.com
2. Seleziona il progetto **CDM86**
3. Clicca su **SQL Editor** (icona </> nella sidebar)
4. Clicca **"New query"**

### Passo 2: Esegui il Trigger SQL

1. Apri il file **`database/supabase_auth_trigger.sql`** (che ho appena creato)
2. **Copia TUTTO il contenuto** (Ctrl+A / Cmd+A)
3. Incolla nell'editor SQL di Supabase
4. Clicca **"Run"** (o Ctrl+Enter)

✅ **Output atteso:**
```
Success. No rows returned.
```

### Passo 3: Verifica che il Trigger sia Attivo

Esegui questa query in SQL Editor:

```sql
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';
```

✅ **Dovresti vedere:**
```
trigger_name           | event_manipulation | event_object_table
on_auth_user_created  | INSERT             | users
```

---

## 🧪 Testa la Registrazione

1. Vai sulla pagina di registrazione
2. Registra un nuovo utente:
   - Email: `test@example.com`
   - Password: `Test123!`
   - Nome: `Mario`
   - Cognome: `Rossi`
   - Referral Code: `ADMIN001`
3. Clicca **Registrati**

✅ **Risultato atteso:**
- Registrazione completata con successo
- L'utente viene creato in `auth.users` E `public.users`
- Se hai disabilitato email confirmation, puoi loggarti subito

---

## 🔍 Come Funziona il Trigger

```
1. Utente si registra → Supabase crea record in auth.users
2. Trigger "on_auth_user_created" viene eseguito
3. Function handle_new_user():
   - Genera referral code univoco
   - Cerca il referrer (se codice fornito)
   - Crea utente in public.users
   - Crea record referral (se c'è un referrer)
   - Assegna 100 punti bonus
4. Registrazione completata ✅
```

---

## 🛠️ Troubleshooting

### Errore: "function public.generate_referral_code() does not exist"

**Causa**: Non hai eseguito lo schema completo prima del trigger.

**Soluzione**:
```sql
-- Prima esegui schema.sql, POI supabase_auth_trigger.sql
```

**Ordine corretto:**
1. ✅ `database/schema.sql` (crea tabelle e funzioni base)
2. ✅ `database/supabase_auth_trigger.sql` (crea trigger auth)
3. ✅ `database/seed.sql` (popola dati iniziali)

---

### Errore: "permission denied for schema auth"

**Causa**: La function deve essere SECURITY DEFINER.

**Soluzione**: Il file `supabase_auth_trigger.sql` già include `SECURITY DEFINER`, quindi dovrebbe funzionare.

---

### Errore continua dopo aver eseguito il trigger

**Controlla i log**:
1. Supabase → **Logs** → **Database**
2. Filtra per errori recenti
3. Cerca messaggi tipo "trigger error" o "function error"

---

## 📋 Checklist Completa Setup Database

- [ ] Eseguito `database/schema.sql` in Supabase SQL Editor
- [ ] Eseguito `database/supabase_auth_trigger.sql` (NUOVO!)
- [ ] Eseguito `database/seed.sql` 
- [ ] Verificato che trigger esista (query sopra)
- [ ] Disabilitato "Confirm email" in Authentication Settings
- [ ] Testato registrazione con email reale

---

## 📁 File Coinvolti

1. **`database/schema.sql`** - Schema completo database
2. **`database/supabase_auth_trigger.sql`** - 🆕 Trigger auth (NUOVO)
3. **`database/seed.sql`** - Dati iniziali

---

**Tempo richiesto**: ⏱️ 3 minuti  
**Difficoltà**: 🟡 Media (copia-incolla SQL)  
**Effetto**: ✅ Fix definitivo errore 500
