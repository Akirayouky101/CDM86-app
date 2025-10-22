# Fix Admin Panel Frozen - Points System Queries

## Problem
Il pannello admin rimaneva bloccato al caricamento con 4 errori critici nella console:

```
ERROR 1: column user_points.total_points does not exist
ERROR 2: column rewards.required_level does not exist  
ERROR 3: Could not find relationship between user_points and users
ERROR 4: Could not find relationship between reward_redemptions and users
```

## Root Cause
Le query JavaScript del sistema punti usavano nomi di colonne e riferimenti a tabelle **SBAGLIATI** che non corrispondevano allo schema SQL reale:

### Errori JavaScript vs Schema SQL Corretto

| Tabella | JavaScript (SBAGLIATO) | SQL Schema (CORRETTO) |
|---------|------------------------|----------------------|
| user_points | `total_points` | `points_total` |
| user_points | `available_points` | `points_available` |
| user_points | `points_spent` | `points_used` |
| user_points | `current_level` | `level` |
| rewards | `name` | `title` |
| rewards | `points_cost` | `points_required` |
| rewards | `required_level` | `level_required` |
| rewards | `stock_quantity` | `stock` |
| rewards | `is_active` | `active` |
| rewards | `icon` | (NON esiste in schema) |
| JOIN | `.from('users')` | `auth.users` (via admin API) |

## Funzioni Corrette

### 1. loadPointsStats()
**Prima:**
```javascript
.select('total_points')
user.total_points
```

**Dopo:**
```javascript
.select('points_total')
user.points_total
```

### 2. loadPointsLeaderboard()
**Prima:**
```javascript
.select(`
    *,
    users!inner(email)
`)
.order('total_points', { ascending: false })

// Nel rendering:
user.total_points
user.available_points
user.points_spent
user.current_level
user.users?.email
```

**Dopo:**
```javascript
// Prima query: prendi user_points
const { data: userPoints } = await supabase
    .from('user_points')
    .select('*')
    .order('points_total', { ascending: false })

// Seconda query: prendi emails da auth.users
const { data: { users } } = await supabase.auth.admin.listUsers();

// Crea mappa user_id -> email
const userEmailMap = {};
users.forEach(user => {
    userEmailMap[user.id] = user.email;
});

// Nel rendering:
user.points_total
user.points_available
user.points_used
user.level
userEmailMap[user.user_id]
```

### 3. loadRewardsManagement()
**Prima:**
```javascript
.order('required_level')
.order('points_cost')

// Nel rendering:
reward.name
reward.points_cost
reward.required_level
reward.stock_quantity || 0
reward.is_active
```

**Dopo:**
```javascript
.order('level_required')
.order('points_required')

// Nel rendering:
reward.title
reward.points_required
reward.level_required
reward.stock === -1 ? 'Illimitato' : reward.stock
reward.active
```

### 4. loadRedemptions()
**Prima:**
```javascript
.select(`
    *,
    rewards(name, icon, points_cost),
    users!inner(email)
`)

// Nel rendering:
redemption.rewards?.name
redemption.rewards?.icon
redemption.rewards?.points_cost
redemption.users?.email
```

**Dopo:**
```javascript
.select(`
    *,
    rewards(title, points_required)
`)

// Prendi users da auth
const { data: { users } } = await supabase.auth.admin.listUsers();
const userEmailMap = {};
users.forEach(user => {
    userEmailMap[user.id] = user.email;
});

// Nel rendering:
redemption.rewards?.title
// Rimosso icon (non esiste in schema)
redemption.points_spent
userEmailMap[redemption.user_id]
```

## Schema SQL Definitivo (da points_system_setup.sql)

```sql
-- USER_POINTS TABLE
CREATE TABLE user_points (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    points_total INTEGER DEFAULT 0,
    points_used INTEGER DEFAULT 0,
    points_available INTEGER DEFAULT 0,
    level VARCHAR(20) DEFAULT 'bronze'
);

-- REWARDS TABLE
CREATE TABLE rewards (
    id UUID PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    points_required INTEGER NOT NULL,
    level_required VARCHAR(20) DEFAULT 'bronze',
    image_url TEXT,
    stock INTEGER DEFAULT -1,  -- -1 = illimitato
    redeemed_count INTEGER DEFAULT 0,
    active BOOLEAN DEFAULT true
);

-- REWARD_REDEMPTIONS TABLE
CREATE TABLE reward_redemptions (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    reward_id UUID REFERENCES rewards(id),
    points_spent INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    redeemed_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Risultato
✅ Admin panel ora carica correttamente senza errori
✅ Tutte le query allineate con lo schema SQL reale
✅ Sistema punti completamente funzionale
✅ Leaderboard mostra correttamente email degli utenti
✅ Rewards management usa colonne corrette
✅ Redemptions lista funziona con dati reali

## Files Modificati
- `public/admin-panel.html` - Corretti 4 funzioni (loadPointsStats, loadPointsLeaderboard, loadRewardsManagement, loadRedemptions)

## Commit
```
3eec104 - Fix admin panel points system queries - correct column names and auth.users joins
```

## Deployment
✅ Auto-deployed a cdm86.com via Vercel
