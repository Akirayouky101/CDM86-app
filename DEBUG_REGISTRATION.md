# 🔧 DEBUG: Problemi con Registrazione Supabase

## 🎯 Hai eseguito il trigger ma continui ad avere errori?

Proviamo a debuggare passo per passo.

---

## 📋 CHECKLIST DEBUG

### ✅ Step 1: Verifica che le tabelle esistano

Esegui in Supabase SQL Editor:

```sql
-- Controlla se la tabella users esiste
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'referrals', 'promotions', 'transactions');
```

**Dovresti vedere 4 tabelle:**
- users
- referrals  
- promotions
- transactions

❌ **Se NON vedi le tabelle**: Devi prima eseguire `database/schema.sql`

---

### ✅ Step 2: Verifica che la function generate_referral_code esista

```sql
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name = 'generate_referral_code';
```

**Dovresti vedere:**
```
routine_name: generate_referral_code
routine_type: FUNCTION
```

❌ **Se NON esiste**: La function è in `schema.sql`, eseguila prima

---

### ✅ Step 3: Verifica che il trigger sia attivo

```sql
SELECT trigger_name, event_object_table, action_timing
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';
```

**Dovresti vedere:**
```
trigger_name: on_auth_user_created
event_object_table: users
action_timing: AFTER
```

❌ **Se NON esiste**: Riesegui `supabase_auth_trigger.sql`

---

### ✅ Step 4: Controlla i Log di Supabase

1. Vai su **Supabase Dashboard**
2. Clicca **Logs** → **Database**
3. Cerca errori recenti (ultimi 5 minuti)

**Errori comuni:**

#### Errore: "function public.generate_referral_code() does not exist"
**Soluzione**: Esegui prima `schema.sql`, poi il trigger

#### Errore: "permission denied for table users"
**Soluzione**: Il trigger deve essere `SECURITY DEFINER` (già incluso)

#### Errore: "column does not exist"
**Soluzione**: Controlla che tutte le colonne in `schema.sql` corrispondano al trigger

---

## 🚀 SOLUZIONE RAPIDA: Usa Trigger Semplificato

Ho creato una versione **semplificata** del trigger che:
- ✅ Ha meno dipendenze
- ✅ Non gestisce referral (per ora)
- ✅ Include gestione errori
- ✅ Include la function generate_referral_code

### Come Usarlo:

1. **Apri** `database/supabase_auth_trigger_simple.sql`
2. **Copia tutto** (Cmd+A)
3. **Vai** su Supabase SQL Editor
4. **New query** → Incolla → **Run**

Questo dovrebbe farti registrare gli utenti **immediatamente**, poi possiamo aggiungere il sistema referral.

---

## 🧪 TEST MANUALE

Dopo aver eseguito uno dei trigger, testa manualmente:

```sql
-- 1. Testa la function generate_referral_code
SELECT generate_referral_code();

-- 2. Controlla se ci sono utenti
SELECT id, email, first_name, referral_code 
FROM public.users 
LIMIT 5;

-- 3. Controlla auth.users
SELECT id, email, created_at 
FROM auth.users 
LIMIT 5;
```

---

## 📊 ORDINE CORRETTO DI ESECUZIONE

**Prima volta (setup completo):**

```
1️⃣ database/schema.sql          ← Crea tabelle e funzioni base
2️⃣ database/supabase_auth_trigger_simple.sql  ← Trigger semplificato
3️⃣ database/seed.sql            ← Dati iniziali (opzionale)
4️⃣ Testa registrazione          ← Prova a registrare un utente
```

**Se hai già tabelle ma trigger non funziona:**

```
1️⃣ database/supabase_auth_trigger_simple.sql  ← Solo il trigger
2️⃣ Testa registrazione
```

---

## 🎯 QUALE ERRORE PRECISO HAI?

Per aiutarti meglio, dimmi:

### 1️⃣ Che errore vedi nella console del browser?
```
POST /auth/v1/signup
HTTP/1.1 ???
```

### 2️⃣ Cosa c'è nei log di Supabase?
**Logs → Database → Ultimi 5 minuti**

### 3️⃣ Hai eseguito schema.sql prima del trigger?
- [ ] Sì
- [ ] No
- [ ] Non ricordo

### 4️⃣ Le tabelle esistono?
Esegui:
```sql
SELECT * FROM public.users LIMIT 1;
```
- [ ] Funziona (mostra colonne)
- [ ] Errore "relation does not exist"

---

## 📁 File Disponibili

1. **`database/schema.sql`** - Schema completo (tabelle + funzioni)
2. **`database/supabase_auth_trigger.sql`** - Trigger completo con referral
3. **`database/supabase_auth_trigger_simple.sql`** - 🆕 Trigger semplificato (consigliato per debug)
4. **`database/seed.sql`** - Dati iniziali

---

## 💡 CONSIGLIO

**Usa il trigger semplificato ora** → Fai funzionare la registrazione → Poi aggiungiamo il sistema referral completo.

---

**Fammi sapere:**
- Quale errore specifico vedi?
- Cosa dicono i log di Supabase?
- Le query di verifica sopra cosa restituiscono?
