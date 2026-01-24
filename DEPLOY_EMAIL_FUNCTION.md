# 📧 Deploy Email Function su Supabase

## Prerequisiti
- Account Resend.com creato
- API Key Resend copiata

## Opzione 1: Deploy tramite Supabase CLI (Consigliato)

```bash
# 1. Installa Supabase CLI (se non l'hai già)
npm install -g supabase

# 2. Login
supabase login

# 3. Vai nella cartella progetto
cd /Users/akirayouky/Desktop/Siti/CDM86-NEW

# 4. Link al tuo progetto Supabase
# Trova il PROJECT_REF su Supabase Dashboard → Settings → General → Reference ID
supabase link --project-ref YOUR_PROJECT_REF

# 5. Imposta il secret con la tua API Key Resend
supabase secrets set RESEND_API_KEY=re_xxxxxxxxxxxxx

# 6. Deploy della funzione
supabase functions deploy send-organization-email

# 7. Verifica deploy
supabase functions list
```

## Opzione 2: Deploy Manuale tramite Dashboard

Se non vuoi usare CLI:

1. **Vai su Supabase Dashboard → Edge Functions**
2. Clicca **Create a new function**
3. Nome: `send-organization-email`
4. Copia tutto il codice da: `supabase/functions/send-organization-email/index.ts`
5. Incolla nell'editor
6. Clicca **Deploy**

## Test della Funzione

```bash
# Testa che funzioni (sostituisci i valori)
curl -X POST 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-organization-email' \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"organizationId": "uuid-della-org"}'
```

## 🎯 Dove Trovare i Parametri

### PROJECT_REF
Supabase Dashboard → Settings → General → **Reference ID**
Esempio: `uchrjlngfzfibcpdxtky`

### ANON_KEY
Supabase Dashboard → Settings → API → **Project API keys** → `anon` `public`

### RESEND_API_KEY
Resend.com → API Keys → Quella che hai creato
Esempio: `re_123abc456def`

---

## 🔄 Integrazione Automatica

Dopo il deploy, per far sì che l'email parta automaticamente quando approvi un'azienda:

### Modifica il trigger PostgreSQL

Aggiungi questo alla FINE della funzione `handle_company_report_approval()` (prima di `RETURN NEW;`):

```sql
-- Trigger invio email automatico
BEGIN
  PERFORM net.http_post(
    url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-organization-email',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
    ),
    body := jsonb_build_object(
      'organizationId', v_organization_id
    )::text
  );
EXCEPTION
  WHEN OTHERS THEN
    -- Log errore ma non bloccare il trigger
    RAISE NOTICE 'Errore invio email: %', SQLERRM;
END;
```

---

## ✅ Verifica Completa

1. ✅ Resend account creato
2. ✅ API Key copiata
3. ✅ Secret configurato su Supabase
4. ✅ Edge Function deployata
5. ✅ Trigger aggiornato con chiamata HTTP
6. ✅ Test: Segnala azienda → Approva → Email ricevuta! 📧

---

## 🆘 Troubleshooting

**Edge Function non si deploya:**
- Verifica di aver fatto `supabase login`
- Controlla di essere nella cartella giusta
- Prova: `supabase functions deploy send-organization-email --no-verify-jwt`

**Email non arriva:**
- Controlla log Edge Function: Supabase Dashboard → Edge Functions → Logs
- Verifica API Key Resend sia corretta
- Controlla dominio email mittente (deve essere verificato su Resend)

**"net.http_post" non esiste:**
- Abilita estensione: `CREATE EXTENSION IF NOT EXISTS http;`
