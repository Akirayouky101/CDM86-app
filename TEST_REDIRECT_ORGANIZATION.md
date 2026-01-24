# 🔄 TEST REDIRECT AUTOMATICO - Guida Rapida

## ✅ SISTEMA IMPLEMENTATO

Dopo il login, l'utente viene automaticamente reindirizzato:

- 👤 **Utente normale** → `/public/promotions.html` (Dashboard promozioni)
- 🏢 **Organization** → `/public/organization-dashboard.html` (Pannello azienda)
- 👑 **Admin** → `/public/admin-panel.html` (Pannello admin)

---

## 🔧 SETUP (1 volta sola)

### STEP 1: Aggiungi colonna auth_user_id

Esegui su **Supabase SQL Editor**:

```sql
-- Aggiungi campo auth_user_id alle organizations
ALTER TABLE organizations
ADD COLUMN IF NOT EXISTS auth_user_id UUID REFERENCES auth.users(id);

-- Crea indice per performance
CREATE INDEX IF NOT EXISTS idx_organizations_auth_user_id 
ON organizations(auth_user_id);
```

---

## 🧪 TEST COMPLETO

### 1️⃣ Reset dati test (opzionale)

```sql
-- Cancella organizations create automaticamente
DELETE FROM organization_temp_passwords 
WHERE organization_id IN (
  SELECT id FROM organizations WHERE referred_by_user_id IS NOT NULL
);

DELETE FROM organizations WHERE referred_by_user_id IS NOT NULL;

-- Resetta segnalazioni
DELETE FROM company_reports;

-- Reset punti
DELETE FROM points_transactions;
UPDATE user_points SET points_total = 0, points_available = 0;
```

### 2️⃣ Segnala azienda

- **Login come utente**: `mario.rossi@cdm86.com`
- **Vai su**: Dashboard → Segnala Azienda
- **Compila**:
  - Nome: `ZG Impiantisrl s.r.l.`
  - Email: `serviziomail1@gmail.com`
  - Tipo: `inserzionista` o `partner`
  - Indirizzo, città, etc.
- **Invia segnalazione**

### 3️⃣ Approva segnalazione

- **Login come admin**: `admin@cdm86.com`
- **Vai su**: Admin Panel → Segnalazioni Aziende
- **Seleziona**: "Approvata" nel dropdown
- **Verifica console**:
  ```
  📧 Invio email a organizzazione: [ID]
  ✅ Email inviata con successo!
  ```

### 4️⃣ Controlla email

- **Vai su**: `serviziomail1@gmail.com`
- **Cerca email** da "CDM86 <onboarding@resend.dev>"
- **Verifica contenuto**:
  - ✅ Nome azienda
  - ✅ Password temporanea (grande e rossa)
  - ✅ Codice Referral (box viola grande)
  - ✅ Nome utente che ha segnalato (box giallo)

### 5️⃣ Login come Organization

- **Logout** (se loggato)
- **Vai su**: https://www.cdm86.com
- **Clicca**: "Accedi"
- **Login con**:
  - Email: `serviziomail1@gmail.com`
  - Password: (quella nell'email, es. `a1436f0a`)
- **Verifica redirect**: Dovresti essere reindirizzato a `/public/organization-dashboard.html`

---

## 🎯 REDIRECT ATTESO

| Tipo Utente | Email | Redirect |
|-------------|-------|----------|
| **User** | `mario.rossi@cdm86.com` | `/public/promotions.html` |
| **Organization** | `serviziomail1@gmail.com` | `/public/organization-dashboard.html` |
| **Admin** | `admin@cdm86.com` | `/public/admin-panel.html` |

---

## 🔍 TROUBLESHOOTING

### Email non arriva?
- Controlla **Console browser** per errori
- Verifica **Edge Function logs**: https://supabase.com/dashboard/project/uchrjlngfzfibcpdxtky/functions/send-organization-email/logs
- Controlla **spam folder**

### Login non funziona?
```sql
-- Verifica account creato
SELECT 
  o.name,
  o.email,
  o.auth_user_id,
  otp.temp_password,
  otp.email_sent
FROM organizations o
LEFT JOIN organization_temp_passwords otp ON otp.organization_id = o.id
WHERE o.email = 'serviziomail1@gmail.com';
```

Se `auth_user_id` è NULL, l'account Auth non è stato creato.

### Redirect sbagliato?
- Verifica che `auth_user_id` sia salvato in organizations
- Controlla **Console browser** durante login per vedere i log

---

## ✅ CHECKLIST SUCCESSO

- [ ] SQL eseguito (colonna `auth_user_id` aggiunta)
- [ ] Segnalazione creata
- [ ] Segnalazione approvata (modale: "Approvata")
- [ ] Email ricevuta con password
- [ ] Account Auth creato (verifica SQL)
- [ ] Login funziona
- [ ] Redirect a `/public/organization-dashboard.html` ✅

---

**Pronto per il test!** 🚀
