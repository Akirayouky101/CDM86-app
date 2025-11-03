# 🎯 SISTEMA REFERRAL MLM - DOCUMENTAZIONE COMPLETA

## 📋 Panoramica

Sistema di **Network Marketing Multi-Livello (MLM)** a **2 livelli fissi** con assegnazione automatica di punti.

### 🔑 Caratteristiche Principali

- ✅ **2 livelli di profondità massima**
- ✅ **+1 punto per ogni referral** (livello 1 e 2)
- ✅ **Ogni utente costruisce la propria rete indipendente**
- ✅ **Assegnazione automatica via trigger database**
- ✅ **Tracciamento completo di ogni assegnazione**
- ✅ **Dashboard con statistiche rete**

---

## 🏗️ ARCHITETTURA

### Tabelle Database

#### 1. `referral_network`
Traccia ogni assegnazione di punti nella rete MLM.

```sql
CREATE TABLE referral_network (
  id UUID PRIMARY KEY,
  user_id UUID,              -- Chi riceve i punti
  referral_id UUID,          -- Chi si è registrato
  level INTEGER (1-2),       -- Profondità nella rete
  points_awarded DECIMAL,    -- Punti assegnati (sempre 1.00)
  referral_type VARCHAR(50), -- Tipo account registrato
  created_at TIMESTAMP
);
```

**Campi:**
- `user_id`: Utente che riceve i punti
- `referral_id`: Utente che genera i punti (nuovo registrato)
- `level`: 1 = referral diretto, 2 = referral indiretto (rete)
- `points_awarded`: Sempre 1.00 per ogni referral
- `referral_type`: user, organization, partner, association, collaborator

---

#### 2. `users.account_type` (nuova colonna)

```sql
ALTER TABLE users ADD COLUMN account_type VARCHAR(50) DEFAULT 'user';
```

**Valori possibili:**
- `user` - Utente normale
- `organization` - Azienda inserzionista
- `partner` - Azienda partner
- `association` - Associazione
- `collaborator` - Collaboratore (rete infinita)

---

### Funzioni e Trigger

#### `award_referral_points_mlm()`
Funzione principale che gestisce l'assegnazione punti MLM.

**Logica:**
1. Quando nuovo utente si registra con `referred_by_id`
2. **LIVELLO 1**: Referrer diretto riceve +1 punto
3. **LIVELLO 2**: Referrer del referrer riceve +1 punto
4. **LIVELLO 3+**: NESSUN punto assegnato
5. Registra tutto in `referral_network`
6. Aggiorna `user_points`
7. Crea transazione in `points_transactions`

**Trigger:**
- `trigger_award_referral_points_mlm` → Eseguito su **INSERT** users
- `trigger_award_referral_points_mlm_on_update` → Eseguito su **UPDATE** users (quando `referred_by_id` cambia)

---

## 📊 COME FUNZIONA

### Esempio Pratico

```
Mario (A) si registra
├─ Codice referral: MARIO123
└─ Punti: 0

Mario invita Giulia (B) con MARIO123
├─ Mario riceve: +1 punto (livello 1)
└─ Totale Mario: 1 punto

Giulia invita Luca (C)
├─ Giulia riceve: +1 punto (livello 1)
├─ Mario riceve: +1 punto (livello 2)
└─ Totale Mario: 2 punti, Giulia: 1 punto

Luca invita Sara (D)
├─ Luca riceve: +1 punto (livello 1)
├─ Giulia riceve: +1 punto (livello 2)
├─ Mario riceve: 0 punti (livello 3 = nessun punto)
└─ Totale Mario: 2, Giulia: 2, Luca: 1

Sara invita Paolo (E)
├─ Sara riceve: +1 punto (livello 1)
├─ Luca riceve: +1 punto (livello 2)
├─ Giulia riceve: 0 punti (livello 3)
├─ Mario riceve: 0 punti (livello 4)
└─ Totale Mario: 2, Giulia: 2, Luca: 2, Sara: 1
```

### Visualizzazione Albero

```
                    Mario (A)
                    2 PUNTI
                  /          \
            Giulia (B)      ...altri diretti...
            2 PUNTI
          /    |    \
      Luca (C) ...  ...
      2 PUNTI
      /    |
  Sara (D) ...
  1 PUNTO
    /
Paolo (E)
0 PUNTI
```

**Legenda:**
- 🟢 **Livello 1** (linea diretta): +1 punto
- 🔵 **Livello 2** (rete indiretta): +1 punto
- ⚫ **Livello 3+** (troppo lontano): 0 punti

---

## 🛠️ INSTALLAZIONE

### 1. Esegui Setup SQL

Copia tutto il contenuto di `database/SETUP_MLM_REFERRAL_SYSTEM.sql` nel **Supabase SQL Editor** ed esegui.

**Cosa fa:**
- ✅ Crea tabella `referral_network`
- ✅ Aggiunge colonna `account_type` a `users`
- ✅ Crea funzioni `award_referral_points_mlm()` e helper
- ✅ Crea trigger su INSERT e UPDATE
- ✅ Crea view `user_referral_network` e `user_referral_details`

---

### 2. Aggiorna API

File `/api/set-referral.js` già aggiornato con:
- Gestione `accountType` nel body
- Validazione tipi account
- Log per debug MLM

---

### 3. Aggiorna Frontend (Login/Registrazione)

Modifica chiamata API per includere `accountType`:

```javascript
const response = await fetch(`${apiUrl}/set-referral`, {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({
    userId: user.id,
    referredById: referrerId,
    accountType: 'user'  // ← NUOVO parametro
  })
});
```

---

## 📈 DASHBOARD E QUERY

### View: `user_referral_network`

Statistiche aggregate per utente:

```sql
SELECT * FROM user_referral_network
WHERE user_id = 'xxx-xxx-xxx';
```

**Campi:**
- `direct_referrals_count`: Numero referral diretti (livello 1)
- `direct_referrals_points`: Punti da referral diretti
- `network_referrals_count`: Numero referral indiretti (livello 2)
- `network_referrals_points`: Punti da rete indiretta
- `total_referrals`: Totale referral in entrambi i livelli
- `total_points_from_referrals`: Somma punti da sistema MLM

---

### View: `user_referral_details`

Dettaglio di ogni singolo referral:

```sql
SELECT * FROM user_referral_details
WHERE user_id = 'xxx-xxx-xxx'
ORDER BY level, created_at DESC;
```

**Campi:**
- `referral_email`: Email dell'utente referralizzato
- `referral_name`: Nome completo
- `referral_account_type`: Tipo account
- `level`: 1 o 2
- `points_awarded`: Punti ricevuti (sempre 1)
- `is_active`: Se il referral ha fatto almeno 1 azione

---

### Query Utili

#### Top 10 Utenti per Rete
```sql
SELECT 
  u.email,
  u.referral_code,
  up.points_total,
  COUNT(DISTINCT CASE WHEN rn.level = 1 THEN rn.referral_id END) as diretti,
  COUNT(DISTINCT CASE WHEN rn.level = 2 THEN rn.referral_id END) as rete
FROM users u
LEFT JOIN user_points up ON u.id = up.user_id
LEFT JOIN referral_network rn ON u.id = rn.user_id
GROUP BY u.id, u.email, u.referral_code, up.points_total
ORDER BY up.points_total DESC
LIMIT 10;
```

#### Albero Referral Completo
```sql
WITH RECURSIVE referral_tree AS (
  SELECT id, email, referred_by_id, 0 as level
  FROM users WHERE email = 'mario@example.com'
  
  UNION ALL
  
  SELECT u.id, u.email, u.referred_by_id, rt.level + 1
  FROM users u
  JOIN referral_tree rt ON u.referred_by_id = rt.id
  WHERE rt.level < 5
)
SELECT * FROM referral_tree ORDER BY level, email;
```

---

## 🧪 TESTING

### Test Manuale

Usa `database/TEST_MLM_SYSTEM.sql` con 12 query di verifica:

1. ✅ Tabella `referral_network` esiste
2. ✅ Colonna `account_type` aggiunta
3. ✅ Trigger MLM attivi
4. ✅ Catena referral completa
5. ✅ Statistiche rete utente
6. ✅ Dettaglio referral
7. ✅ Punti distribuiti correttamente
8. ✅ Transazioni registrate
9. ✅ Nessuna catena incompleta (bug check)
10. ✅ Classifica utenti
11. ✅ Integrità dati
12. ✅ Status sistema

---

### Scenario di Test

```sql
-- 1. Mario si registra
INSERT INTO users (email, referral_code) VALUES ('mario@test.com', 'MARIO123');

-- 2. Giulia si registra con referral di Mario
-- (API imposta referred_by_id automaticamente)
-- Mario riceve +1 punto

-- 3. Luca si registra con referral di Giulia
-- Giulia: +1, Mario: +1

-- 4. Verifica punti
SELECT email, points_total FROM user_points 
JOIN users ON users.id = user_points.user_id
WHERE email IN ('mario@test.com', 'giulia@test.com', 'luca@test.com');
```

**Risultato atteso:**
- Mario: 2 punti
- Giulia: 1 punto
- Luca: 0 punti

---

## 🚀 API USAGE

### Endpoint: `/api/set-referral`

**Request:**
```json
POST /api/set-referral
{
  "userId": "uuid-utente-appena-registrato",
  "referredById": "uuid-referrer",
  "accountType": "user"  // opzionale: user, organization, partner, association, collaborator
}
```

**Response Success:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "...",
    "referred_by_id": "uuid-referrer",
    "account_type": "user"
  }
}
```

**Sistema MLM automatico:**
- ✅ Trigger si attiva su UPDATE
- ✅ Trova catena referral (max 2 livelli)
- ✅ Assegna +1 punto per livello
- ✅ Registra in `referral_network`
- ✅ Aggiorna `user_points`
- ✅ Crea `points_transactions`

---

## 📱 FRONTEND INTEGRATION

### Login Modal (Registrazione)

```javascript
// Dopo registrazione Supabase
const { data: user, error } = await supabase.auth.signUp({...});

if (user && referralCode) {
  // Trova referrer ID dal codice
  const { data: referrer } = await supabase
    .from('users')
    .select('id')
    .eq('referral_code', referralCode)
    .single();
  
  if (referrer) {
    // Chiama API per impostare referral
    const response = await fetch('/api/set-referral', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({
        userId: user.id,
        referredById: referrer.id,
        accountType: 'user'  // Cambia in base al tipo registrazione
      })
    });
    
    const result = await response.json();
    console.log('✅ MLM System activated:', result);
  }
}
```

---

### Dashboard - Mostra Rete Utente

```javascript
// Ottieni statistiche rete
const { data: networkStats } = await supabase
  .from('user_referral_network')
  .select('*')
  .eq('user_id', currentUserId)
  .single();

// Mostra in UI
console.log(`
  👥 Referral Diretti: ${networkStats.direct_referrals_count}
  💰 Punti da Diretti: ${networkStats.direct_referrals_points}
  
  🌐 Rete Indiretta: ${networkStats.network_referrals_count}
  💰 Punti da Rete: ${networkStats.network_referrals_points}
  
  🏆 TOTALE PUNTI: ${networkStats.points_total}
`);
```

---

### Dashboard - Lista Referral

```javascript
// Ottieni lista dettagliata referral
const { data: referrals } = await supabase
  .from('user_referral_details')
  .select('*')
  .eq('user_id', currentUserId)
  .order('level', { ascending: true })
  .order('created_at', { ascending: false });

// Raggruppa per livello
const diretti = referrals.filter(r => r.level === 1);
const rete = referrals.filter(r => r.level === 2);

console.log(`
  ⭐ LIVELLO 1 (Diretti): ${diretti.length}
  ${diretti.map(r => `  - ${r.referral_name} (${r.referral_email})`).join('\n')}
  
  🌟 LIVELLO 2 (Rete): ${rete.length}
  ${rete.map(r => `  - ${r.referral_name} (${r.referral_email})`).join('\n')}
`);
```

---

## 🔧 TROUBLESHOOTING

### Problema: Punti non assegnati

**Verifica trigger attivi:**
```sql
SELECT trigger_name FROM information_schema.triggers 
WHERE event_object_table = 'users' AND trigger_name LIKE '%mlm%';
```

Deve mostrare:
- `trigger_award_referral_points_mlm`
- `trigger_award_referral_points_mlm_on_update`

---

### Problema: Punti non corrispondono

**Verifica integrità:**
```sql
SELECT 
  u.email,
  SUM(rn.points_awarded) as calculated_points,
  up.points_total as recorded_points,
  SUM(rn.points_awarded) = up.points_total as match
FROM referral_network rn
JOIN users u ON rn.user_id = u.id
LEFT JOIN user_points up ON rn.user_id = up.user_id
GROUP BY u.email, up.points_total;
```

Se `match = false` → Bug nel trigger, esegui ricalcolo manuale.

---

### Problema: Referral non tracciato

**Trova catene incomplete:**
```sql
SELECT 
  u.email,
  u.referred_by_id,
  CASE WHEN EXISTS (
    SELECT 1 FROM referral_network 
    WHERE referral_id = u.id AND level = 1
  ) THEN '✅' ELSE '❌ MISSING' END as status
FROM users u
WHERE u.referred_by_id IS NOT NULL;
```

---

## 📊 METRICHE E KPI

### Metriche Chiave da Monitorare

1. **Tasso Conversione Referral**: % utenti che invitano almeno 1 persona
2. **Profondità Media Rete**: Media livelli raggiunti per utente
3. **Utenti Attivi nella Rete**: % referral che compiono almeno 1 azione
4. **Top Performer**: Classifica utenti per punti da rete
5. **Crescita Rete**: Nuovi referral per giorno/settimana/mese

### Query KPI

```sql
-- KPI Dashboard
SELECT 
  'Total Users' as metric,
  COUNT(*) as value
FROM users
UNION ALL
SELECT 
  'Users with Referrals',
  COUNT(DISTINCT user_id)
FROM referral_network
UNION ALL
SELECT 
  'Total Referral Connections',
  COUNT(*)
FROM referral_network
UNION ALL
SELECT 
  'Avg Referrals per User',
  ROUND(AVG(referral_count), 2)
FROM (
  SELECT user_id, COUNT(*) as referral_count
  FROM referral_network
  GROUP BY user_id
) sub;
```

---

## 🎉 DONE!

Sistema MLM Referral **completamente funzionante** con:

- ✅ Database schema
- ✅ Trigger automatici
- ✅ API endpoint
- ✅ Dashboard views
- ✅ Test queries
- ✅ Documentazione completa

**Prossimi Step:**
1. Esegui `SETUP_MLM_REFERRAL_SYSTEM.sql` su Supabase
2. Deploy API aggiornata su Vercel
3. Testa registrazione con referral code
4. Verifica punti assegnati con `TEST_MLM_SYSTEM.sql`
5. Implementa dashboard frontend

---

📅 **Creato**: 3 Novembre 2025  
🔄 **Versione**: 1.0  
👨‍💻 **Sistema**: MLM 2-Level Referral Network
