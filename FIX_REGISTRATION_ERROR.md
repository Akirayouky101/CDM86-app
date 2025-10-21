# 🔧 Fix Registration Error

## Errore: "Database error saving new user"

Questo errore si verifica quando il trigger del database non è configurato correttamente su Supabase.

## ✅ Soluzione

### 1. Vai su Supabase Dashboard
- Apri https://supabase.com/dashboard
- Seleziona il progetto CDM86
- Vai su **SQL Editor** nel menu laterale

### 2. Esegui il file SQL
- Copia tutto il contenuto del file `database/fix_registration_trigger.sql`
- Incollalo nell'SQL Editor di Supabase
- Clicca su **Run** (▶️)

### 3. Verifica il risultato
Dovresti vedere un output simile a questo:

```
check_name                              | exists
----------------------------------------|-------
Function generate_referral_code exists  | 1
Function handle_new_user exists         | 1
Trigger on_auth_user_created exists     | 1
```

Se tutti i valori sono `1`, il fix è stato applicato correttamente!

### 4. Testa la registrazione
- Vai su https://cdm-86-app.vercel.app/
- Clicca su "Accedi"
- Seleziona "Utente"
- Prova a registrare un nuovo utente

## 📝 Note

Il trigger `on_auth_user_created` esegue automaticamente queste azioni quando un utente si registra:

1. ✅ Genera un codice referral univoco
2. ✅ Crea un record nella tabella `public.users`
3. ✅ Assegna 100 punti bonus
4. ✅ Imposta il ruolo 'user'
5. ✅ Collega al referrer se è stato usato un codice

## 🐛 Se l'errore persiste

Controlla i log di Supabase:
1. Vai su **Database** → **Logs**
2. Cerca messaggi di errore recenti
3. Manda screenshot per debug ulteriore
