# Guida Creazione Utenti Azienda

## Panoramica Sistema
Quando un admin crea un'azienda nel pannello admin, il sistema:
1. ✅ Crea il record nella tabella `organizations`
2. ✅ Genera codici (contratto, referral dipendenti, referral esterni)
3. ✅ Genera credenziali di accesso (email + password casuale)
4. ⚙️ Crea l'utente auth su Supabase (tramite Edge Function)
5. ✅ Mostra le credenziali nella modale di successo

## Setup Edge Function

### 1. Installare Supabase CLI
```bash
brew install supabase/tap/supabase
```

### 2. Login a Supabase
```bash
supabase login
```

### 3. Link al progetto
```bash
supabase link --project-ref uchrjlngfzfibcpdxtky
```

### 4. Deploy della Edge Function
```bash
cd /Users/akirayouky/Desktop/Siti/CDM86-NEW
supabase functions deploy create-organization-user
```

### 5. Verifica deployment
La function sarà disponibile su:
```
https://uchrjlngfzfibcpdxtky.supabase.co/functions/v1/create-organization-user
```

## Come Funziona

### 1. Admin crea azienda
- Compila il form "Aggiungi Azienda"
- Il sistema genera automaticamente:
  - Codice contratto: `ORG001`, `ORG002`, ecc.
  - Codice dipendenti: es. `ABC123`
  - Codice esterni: es. `ABC123_EXT`
  - **Password casuale**: es. `aB3!xYz9@K2`

### 2. Chiamata Edge Function
```javascript
POST /functions/v1/create-organization-user
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "email": "azienda@example.com",
  "password": "aB3!xYz9@K2",
  "organizationId": "uuid-dell-azienda",
  "organizationName": "Nome Azienda SRL",
  "organizationType": "company"
}
```

### 3. Edge Function crea utente
- Verifica che il chiamante sia un admin
- Usa `auth.admin.createUser()` con service role
- Auto-conferma l'email (no verification needed)
- Imposta metadata:
  ```json
  {
    "name": "Nome Azienda SRL",
    "role": "organization",
    "organization_id": "uuid",
    "organization_type": "company"
  }
  ```
- Aggiorna `organizations.user_id` con l'ID dell'utente creato

### 4. Modale di successo
L'admin vede:
- ✅ Codice contratto (da copiare)
- ✅ Email azienda
- ✅ Codici referral
- 🔑 **Credenziali di accesso**:
  - Email: `azienda@example.com`
  - Password: `aB3!xYz9@K2` (con pulsante copia)

### 5. Azienda fa login
1. Va su `/public/organization-dashboard.html`
2. Inserisce email e password ricevute
3. Viene autenticata da Supabase Auth
4. Accede al pannello azienda

## Struttura Database

### Tabella organizations
Deve avere il campo `user_id`:
```sql
-- Esegui su Supabase SQL Editor
ALTER TABLE organizations 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_organizations_user_id ON organizations(user_id);
ALTER TABLE organizations 
ADD CONSTRAINT IF NOT EXISTS unique_organization_user_id UNIQUE (user_id);
```

Oppure esegui il file:
```bash
database/ADD_USER_ID_TO_ORGANIZATIONS.sql
```

## Formato Password Generata

La password viene generata con queste caratteristiche:
- **Lunghezza**: 12 caratteri
- **Contenuto**:
  - Almeno 1 maiuscola: `A-Z`
  - Almeno 1 minuscola: `a-z`
  - Almeno 1 numero: `0-9`
  - Almeno 1 simbolo: `!@#$%&*`
- **Esempio**: `xK9@mB2!aZ7p`
- **Casualità**: Caratteri mescolati casualmente

## Flusso Completo

```
┌─────────────────────────────────────────┐
│ 1. Admin compila form "Aggiungi Azienda"│
└─────────────┬───────────────────────────┘
              │
              v
┌─────────────────────────────────────────┐
│ 2. Sistema genera:                      │
│    - Codice contratto: ORG001           │
│    - Codice dipendenti: ABC123          │
│    - Codice esterni: ABC123_EXT         │
│    - Password: aB3!xYz9@K2              │
└─────────────┬───────────────────────────┘
              │
              v
┌─────────────────────────────────────────┐
│ 3. Crea record in organizations table   │
└─────────────┬───────────────────────────┘
              │
              v
┌─────────────────────────────────────────┐
│ 4. Chiama Edge Function:                │
│    create-organization-user             │
│    (crea utente auth)                   │
└─────────────┬───────────────────────────┘
              │
              v
┌─────────────────────────────────────────┐
│ 5. Edge Function:                       │
│    - Verifica privilegi admin           │
│    - Crea utente auth                   │
│    - Auto-conferma email                │
│    - Aggiorna organizations.user_id     │
└─────────────┬───────────────────────────┘
              │
              v
┌─────────────────────────────────────────┐
│ 6. Se da referral:                      │
│    - Assegna 50 punti a utente          │
│    - Segna richiesta come "completed"   │
└─────────────┬───────────────────────────┘
              │
              v
┌─────────────────────────────────────────┐
│ 7. Mostra modale successo con:          │
│    ✓ Codice contratto                   │
│    ✓ Email azienda                      │
│    ✓ Codici referral                    │
│    🔑 CREDENZIALI (email + password)     │
│       con pulsanti copia                │
└─────────────┬───────────────────────────┘
              │
              v
┌─────────────────────────────────────────┐
│ 8. Admin comunica credenziali all'azienda│
└─────────────────────────────────────────┘
              │
              v
┌─────────────────────────────────────────┐
│ 9. Azienda fa login su:                 │
│    /public/organization-dashboard.html  │
└─────────────────────────────────────────┘
```

## Errori Comuni

### Edge Function non deployata
**Sintomo**: Console mostra errore 404 su `/functions/v1/create-organization-user`  
**Soluzione**: Deploy della function con `supabase functions deploy create-organization-user`

### user_id non aggiornato
**Sintomo**: Campo `organizations.user_id` rimane NULL  
**Soluzione**: 
1. Verifica che la colonna esista: `SELECT * FROM organizations LIMIT 1`
2. Esegui migration: `database/ADD_USER_ID_TO_ORGANIZATIONS.sql`

### Azienda non riesce a fare login
**Sintomo**: Email/password non funzionano  
**Soluzione**:
1. Verifica su Supabase Dashboard → Authentication → Users
2. Controlla che l'utente esista con l'email corretta
3. Verifica che `email_confirmed_at` sia popolato
4. Se necessario, ricrea l'utente manualmente:
   ```sql
   -- Su Supabase Dashboard → SQL Editor
   -- Poi usa UI: Authentication → Users → Invite User
   ```

### Password non copiabile
**Sintomo**: Pulsante "Copia" non funziona  
**Soluzione**: Usa browser moderno con supporto `navigator.clipboard.writeText()`

## Test Manuale

### 1. Crea azienda di test
1. Login admin: `admin@cdm86.it` / `Admin123!`
2. Vai su "Gestione Aziende"
3. Click "Aggiungi Azienda"
4. Compila form:
   - Nome: `Test SRL`
   - Email: `test@cdm86.com`
   - P.IVA: `12345678901`
   - ecc.
5. Salva

### 2. Verifica credenziali
Nella modale di successo dovresti vedere:
```
Codice Contratto: ORG001
Email: test@cdm86.com
Codice Dipendenti: ABC123
Codice Esterni: ABC123_EXT

CREDENZIALI DI ACCESSO:
Email Login: test@cdm86.com
Password: xK9@mB2!aZ7p [Copia]
```

### 3. Test login azienda
1. Apri `/public/organization-dashboard.html`
2. Inserisci:
   - Email: `test@cdm86.com`
   - Password: `xK9@mB2!aZ7p` (quella mostrata)
3. Login
4. Dovresti vedere il pannello azienda

### 4. Verifica database
```sql
-- 1. Verifica azienda creata
SELECT id, name, email, referral_code, referral_code_external, user_id
FROM organizations
WHERE email = 'test@cdm86.com';

-- 2. Verifica utente auth
SELECT id, email, email_confirmed_at, raw_user_meta_data
FROM auth.users
WHERE email = 'test@cdm86.com';

-- 3. Verifica collegamento
SELECT 
    o.name as organization_name,
    o.email as org_email,
    u.email as auth_email,
    o.user_id = u.id as correctly_linked
FROM organizations o
LEFT JOIN auth.users u ON o.user_id = u.id
WHERE o.email = 'test@cdm86.com';
```

## Troubleshooting

### Edge Function non risponde
```bash
# Verifica logs della function
supabase functions logs create-organization-user

# Re-deploy
supabase functions deploy create-organization-user --no-verify-jwt
```

### Utente non viene creato
Controlla la risposta della fetch in console browser:
```javascript
// Nel browser DevTools → Console
// Cerca errori dopo aver creato un'azienda
```

### Password non sicura
La password generata ha sempre:
- Min 12 caratteri
- Mix maiuscole/minuscole/numeri/simboli
- Totalmente casuale

Se Supabase Auth richiede password più forte, modifica in `admin-panel.html`:
```javascript
function generatePassword(length = 16) { // Aumenta lunghezza
    // ... resto del codice
}
```

## Prossimi Step

1. ✅ Deploy Edge Function
2. ✅ Esegui migration database (ADD_USER_ID_TO_ORGANIZATIONS.sql)
3. ✅ Test creazione azienda
4. ✅ Test login azienda
5. 🔄 Sistemare organization-dashboard.html (file corrotto)
6. 🔄 Implementare creazione card/promozioni nel pannello azienda
