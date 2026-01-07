# 🚀 AZIONI IMMEDIATE DA FARE

## 1️⃣ Aggiungi campi al database

### Su Supabase SQL Editor:
1. Vai su: https://supabase.com/dashboard/project/uchrjlngfzfibcpdxtky/editor
2. Click su SQL Editor
3. **PRIMO** - Esegui questo per aggiungere user_id:

```sql
-- Aggiungi colonna user_id
ALTER TABLE organizations 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- Crea indice
CREATE INDEX IF NOT EXISTS idx_organizations_user_id ON organizations(user_id);

-- Vincolo unicità
ALTER TABLE organizations 
ADD CONSTRAINT IF NOT EXISTS unique_organization_user_id UNIQUE (user_id);
```

4. **SECONDO** - Esegui questo per aggiungere campi pagina aziendale:

```sql
-- Descrizione azienda
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS description TEXT;

-- URL logo
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS logo_url TEXT;

-- URL copertina
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS cover_url TEXT;

-- Sito web
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS website TEXT;

-- Social media (JSON)
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS social_links JSONB;
```

5. **Verifica** che tutto sia ok:

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'organizations'
ORDER BY ordinal_position;
```

✅ Dovresti vedere le colonne: `user_id`, `description`, `logo_url`, `cover_url`, `website`, `social_links`

---

## 2️⃣ Installa e configura Supabase CLI

### Installa CLI:
```bash
brew install supabase/tap/supabase
```

### Login:
```bash
supabase login
```
(Si aprirà il browser, autorizza l'accesso)

### Link al progetto:
```bash
cd /Users/akirayouky/Desktop/Siti/CDM86-NEW
supabase link --project-ref uchrjlngfzfibcpdxtky
```

Quando richiesto:
- **Database password**: La password del database Supabase
  (La trovi su: Supabase Dashboard → Settings → Database → Password)

---

## 3️⃣ Deploy Edge Function per creare utenti

```bash
cd /Users/akirayouky/Desktop/Siti/CDM86-NEW
supabase functions deploy create-organization-user
```

✅ Dovresti vedere:
```
Deploying create-organization-user (project ref: uchrjlngfzfibcpdxtky)
✓ Deployed Function create-organization-user successfully
```

### Verifica deployment:
La function sarà disponibile su:
```
https://uchrjlngfzfibcpdxtky.supabase.co/functions/v1/create-organization-user
```

---

## 4️⃣ TEST - Crea la prima azienda

### 1. Login admin:
- URL: https://cdm86-3qaudqpc5-akirayoukys-projects.vercel.app/public/admin-panel.html
- Email: `admin@cdm86.it`
- Password: `Admin123!`

### 2. Vai su "Gestione Aziende"
- Click su card "Gestione Aziende"
- Click bottone "Aggiungi Azienda"

### 3. Compila il form:
```
Nome Azienda: Test SRL
Email: test@cdm86.com
P.IVA: 12345678901
Codice Fiscale: (lascia vuoto)
Indirizzo: Via Test 1
Città: Milano
Provincia: MI
CAP: 20100
Telefono: 0212345678
```

### 4. Salva e controlla modale di successo

Dovresti vedere:

```
✅ Azienda Creata!

Informazioni Azienda:
Codice Contratto: ORG001
Email: test@cdm86.com
Codice Dipendenti: ABC123 (esempio)
Codice Esterni: ABC123_EXT

🔑 CREDENZIALI DI ACCESSO:
Email Login: test@cdm86.com
Password: xK9@mB2!aZ7p (esempio - sarà diversa)
```

### 5. IMPORTANTE: Copia le credenziali!
- Click su pulsante "Copia" accanto alla password
- Salvale in un posto sicuro
- **NON saranno più visibili** dopo aver chiuso la modale

---

## 5️⃣ TEST LOGIN AZIENDA

### 1. Apri pannello azienda:
```
https://cdm86-3qaudqpc5-akirayoukys-projects.vercel.app/public/organization-dashboard.html
```

### 2. Login con credenziali generate:
- Email: `test@cdm86.com`
- Password: (quella copiata prima)

### 3. ✅ Dovresti vedere:
- Dashboard con informazioni azienda
- Statistiche (dipendenti, punti)
- Codice referral con QR code
- Lista dipendenti registrati
- **NUOVE SEZIONI:**
  - **Gestione Promozioni** con bottone "Nuova Promozione"
  - **Modifica Pagina Aziendale** con bottone per editare

---

## 6️⃣ TEST CREAZIONE PROMOZIONI

### 1. Nel pannello azienda, click "Nuova Promozione"

### 2. Compila il form:
```
Titolo: Sconto 20% su tutti i prodotti
Descrizione: Approfitta dello sconto del 20% valido per tutto il mese
URL Immagine: (opzionale)
Punti Richiesti: 10
Data Scadenza: (opzionale)
Stato: Attiva
```

### 3. Click "Crea Promozione"

### 4. ✅ Verifica:
- La promozione appare nella griglia sotto
- Mostra immagine (se inserita), titolo, descrizione, punti, stato

### 5. Verifica su database:
```sql
SELECT 
    title,
    description,
    points_required,
    active,
    organization_id
FROM promotions
WHERE organization_id = (
    SELECT id FROM organizations WHERE email = 'test@cdm86.com'
);
```

---

## 7️⃣ TEST PAGINA AZIENDALE

### 1. Nel pannello azienda, click "Modifica Pagina Aziendale"

### 2. Compila il form:
```
Descrizione Azienda: Siamo una azienda leader nel settore...
URL Logo: https://esempio.com/logo.png (opzionale)
URL Copertina: https://esempio.com/cover.jpg (opzionale)
Sito Web: https://www.esempio.com
Social Media: 
{
  "facebook": "https://facebook.com/esempio",
  "instagram": "https://instagram.com/esempio",
  "linkedin": "https://linkedin.com/company/esempio"
}
```

### 3. Click "Salva Pagina"

### 4. ✅ Verifica su database:
```sql
SELECT 
    name,
    description,
    logo_url,
    cover_url,
    website,
    social_links
FROM organizations
WHERE email = 'test@cdm86.com';
```

✅ Dovresti vedere i dati inseriti

---

## 8️⃣ Verifica sul database

### Su Supabase SQL Editor:
```sql
-- Verifica azienda creata
SELECT 
    name,
    email,
    referral_code,
    referral_code_external,
    user_id
FROM organizations
WHERE email = 'test@cdm86.com';
```

✅ Dovresti vedere:
- name: `Test SRL`
- email: `test@cdm86.com`
- referral_code: `ABC123` (esempio)
- referral_code_external: `ABC123_EXT`
- user_id: `uuid-dell-utente-auth`

### Verifica utente auth:
```sql
SELECT 
    email,
    email_confirmed_at,
    raw_user_meta_data->'role' as role,
    raw_user_meta_data->'organization_id' as org_id
FROM auth.users
WHERE email = 'test@cdm86.com';
```

✅ Dovresti vedere:
- email: `test@cdm86.com`
- email_confirmed_at: `<timestamp>` (non NULL)
- role: `"organization"`
- org_id: `<uuid dell'azienda>`

---

## ✅ CHECKLIST COMPLETAMENTO

- [ ] Campo user_id aggiunto a organizations
- [ ] Campi pagina aziendale aggiunti (description, logo_url, cover_url, website, social_links)
- [ ] Supabase CLI installato
- [ ] Link al progetto fatto
- [ ] Edge Function deployata
- [ ] Test creazione azienda completato
- [ ] Credenziali salvate
- [ ] Test login azienda fatto
- [ ] Test creazione promozione fatto
- [ ] Test modifica pagina aziendale fatto
- [ ] Database verificato
- [ ] organization-dashboard.html sistemato ✅

---

## 🐛 SE QUALCOSA NON FUNZIONA

### Edge Function non trovata (404):
```bash
# Re-deploy
supabase functions deploy create-organization-user
```

### user_id rimane NULL:
1. Controlla console browser (F12) per errori
2. Verifica che la colonna esista sul database
3. Prova a redeployare la function

### Login azienda non funziona:
1. Verifica su Supabase → Authentication → Users che l'utente esista
2. Controlla che `email_confirmed_at` sia popolato
3. Prova a resettare la password su Supabase Dashboard

### organization-dashboard.html corrotto:
Dobbiamo sistemare il file (ha doppio DOCTYPE/HEAD)
Dimmi e lo fisso subito.

---

## 📞 PROSSIMI STEP

Dopo aver completato questo test:
1. ✅ organization-dashboard.html sistemato
2. ✅ Implementata creazione promozioni
3. ✅ Implementata pagina presentazione aziendale
4. 🔄 Creare pagina pubblica per visualizzare aziende e promozioni
5. 🔄 Sistema referral dipendenti/esterni
6. 🔄 Fix sistema favoriti (se necessario)

---

**URL Production**: https://cdm86-3qaudqpc5-akirayoukys-projects.vercel.app
**Pannello Admin**: /public/admin-panel.html
**Pannello Azienda**: /public/organization-dashboard.html

## 🆕 NUOVE FUNZIONALITÀ IMPLEMENTATE

### Nel Pannello Admin:
✅ Generazione automatica credenziali azienda (email + password casuale)
✅ Modale di successo mostra le credenziali con pulsante copia
✅ Edge Function per creare utente auth automaticamente

### Nel Pannello Azienda:
✅ Sezione "Gestione Promozioni" 
✅ Form per creare nuove promozioni (titolo, descrizione, immagine, punti, scadenza)
✅ Griglia di visualizzazione promozioni con stato (attiva/disattivata)
✅ Form per editare pagina aziendale (descrizione, logo, copertina, sito web, social)
✅ Salvataggio dati personalizzazione azienda nel database

### Database:
✅ Campo `user_id` su organizations (collega all'utente auth)
✅ Campi pagina aziendale: `description`, `logo_url`, `cover_url`, `website`, `social_links`
✅ File corrotto `organization-dashboard.html` sistemato

