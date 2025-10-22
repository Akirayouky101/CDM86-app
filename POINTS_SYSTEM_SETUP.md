# 🎯 CDM86 - Sistema Punti - Guida Setup

## ✅ File Creati

1. **`database/points_system_setup.sql`** - Setup completo database
2. **`assets/css/points-system.css`** - Stili animati
3. **`public/dashboard.html`** - Aggiornato con UI sistema punti

---

## 📋 Installazione Database

### 1. Apri Supabase SQL Editor

1. Vai su [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Seleziona il progetto **CDM86**
3. Nel menu laterale clicca su **SQL Editor**
4. Clicca **New Query**

### 2. Esegui lo Script SQL

1. Apri il file `database/points_system_setup.sql`
2. Copia **tutto** il contenuto
3. Incolla nel SQL Editor di Supabase
4. Clicca **Run** (o premi `Ctrl+Enter`)

### 3. Verifica Installazione

Dovresti vedere il messaggio:
```
Points system setup completed successfully!
```

---

## 🎨 Funzionalità Implementate

### Sistema Punti
- ✅ **50 punti** per ogni referral completato
- ✅ **100 punti** per ogni segnalazione azienda approvata
- ✅ **0 punti** per segnalazioni rifiutate

### Livelli
- 🥉 **Bronzo**: 0-99 punti
- 🥈 **Argento**: 100-499 punti
- 🥇 **Oro**: 500-999 punti
- 💎 **Platino**: 1000+ punti

### Dashboard Utente
- Progress bar animata con livello corrente
- Contatore punti disponibili/utilizzati/totali
- Card premi riscattabili (filtrate per livello)
- Storico transazioni punti
- Animazioni confetti al riscatto premio

### Premi Pre-caricati
**Bronzo:**
- Sconto 5€ (50 punti)
- Badge Bronzo (30 punti)
- Accesso Anticipato (80 punti)

**Argento:**
- Sconto 10€ (150 punti)
- Badge Argento (100 punti)
- Promozione Esclusiva (200 punti)

**Oro:**
- Sconto 25€ (500 punti)
- Badge Oro (300 punti)
- VIP Pass Mensile (700 punti)

**Platino:**
- Sconto 50€ (1000 punti)
- Badge Platino (500 punti)
- VIP Pass Annuale (1500 punti)
- Consulenza Premium (1200 punti)

---

## 🚀 Deploy

### 1. Commit e Push

```bash
cd /Users/akirayouky/Desktop/Siti/CDM86-NEW
git add -A
git commit -m "Add animated points system with rewards"
git push origin main
```

### 2. Vercel Auto-Deploy

Vercel deployerà automaticamente su **https://cdm86.com**

---

## 🎮 Admin Panel - Prossimi Passi

Devo ancora implementare nel pannello admin:

1. **Classifica utenti** per punti
2. **Approva/Rifiuta segnalazioni** (con assegnazione punti automatica)
3. **Gestione catalogo premi** (aggiungi/modifica/disattiva)
4. **Statistiche sistema punti**

Vuoi che continui con l'admin panel ora?

---

## 🧪 Test Rapido

Dopo il deploy, prova:

1. Accedi con il tuo account
2. Vai alla Dashboard
3. Scorri fino alla sezione **Sistema Punti**
4. Dovresti vedere:
   - Livello Bronzo
   - 0 punti disponibili
   - Progress bar a 0%
   - Premi disponibili (alcuni bloccati per livello)
   - Storico vuoto

Per testare i punti:
1. Crea un nuovo utente usando il tuo codice referral
2. Aggiorna la dashboard → dovresti vedere +50 punti!
3. Prova a riscattare un premio

---

## 📝 Note Tecniche

- Le tabelle usano **Row Level Security (RLS)**
- I trigger assegnano punti **automaticamente**
- Le funzioni SQL sono **sicure** (no SQL injection)
- Le animazioni sono **performanti** (CSS only)
- Il sistema è **scalabile** (indici su tutte le query frequenti)

---

## 🆘 Troubleshooting

**Errore "relation does not exist"**
→ Lo script SQL non è stato eseguito correttamente. Riprova.

**Punti non si aggiornano dopo referral**
→ Controlla che il trigger `trigger_award_referral_points` esista:
```sql
SELECT * FROM pg_trigger WHERE tgname = 'trigger_award_referral_points';
```

**Premi non caricano**
→ Controlla la policy RLS:
```sql
SELECT * FROM rewards WHERE active = true;
```

---

Fatto! 🎉
