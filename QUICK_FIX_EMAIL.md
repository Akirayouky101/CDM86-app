# ⚡ FIX RAPIDO: Email di Verifica Non Arriva

## 🎯 Problema
Gli utenti si registrano ma non ricevono l'email di verifica e non riescono a loggarsi.

## ✅ Soluzione Immediata (2 minuti)

### Vai nel Pannello Supabase

1. **Apri**: https://supabase.com
2. **Seleziona**: Progetto CDM86
3. **Clicca**: **Authentication** (nel menu laterale)
4. **Clicca**: **Settings** o **Providers**
5. **Trova**: Sezione **Email**
6. **DISATTIVA**: ☐ **Confirm email** (togli la spunta)
7. **Clicca**: **Save**

### Fatto! 🎉

Adesso gli utenti possono:
- ✅ Registrarsi
- ✅ Loggarsi **immediatamente** senza aspettare email
- ✅ Usare l'app normalmente

---

## 🔧 Se Hai Utenti Già Registrati

Se hai utenti che si sono già registrati ma non hanno confermato l'email:

1. Vai su **SQL Editor** in Supabase
2. Esegui questa query:

```sql
-- Conferma tutti gli utenti non verificati
UPDATE auth.users 
SET email_confirmed_at = NOW() 
WHERE email_confirmed_at IS NULL;
```

3. Clicca **Run**

Tutti gli utenti potranno ora loggarsi!

---

## 📋 Checklist Veloce

- [ ] Apri Supabase Dashboard
- [ ] Authentication → Settings
- [ ] Disattiva "Confirm email"
- [ ] Save
- [ ] (Opzionale) Esegui query SQL per utenti esistenti
- [ ] Testa registrazione + login

---

## 📚 Documentazione Completa

Per configurare SMTP e abilitare email in produzione, leggi:
- 📄 `EMAIL_SETUP.md` - Guida completa configurazione email

---

**Tempo richiesto**: ⏱️ 2 minuti  
**Difficoltà**: 🟢 Facile  
**Effetto**: ✅ Immediato
