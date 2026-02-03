# 🎨 Sistema Promo Creator + Landing Page

## ✅ Implementazione Completa

Sistema per creare card promozioni professionali con landing page dedicate e condivisione social.

---

## 📁 File Creati

### 1. **`/public/promo-creator.html`** 
Editor visuale per creare promo card:
- ✅ Upload immagine su Vercel Blob (`cdm86project-blob`)
- ✅ Form completo (titolo, descrizione, prezzi, CTA)
- ✅ Anteprima live della card
- ✅ Selezione categoria (Food, Beauty, Wellness, etc.)
- ✅ Pubblicazione su DB con slug automatico

### 2. **`/public/promo-landing.html`**
Landing page dinamica per ogni promo:
- ✅ URL: `/promo/{slug}`
- ✅ Card full-screen responsive
- ✅ Meta tags OpenGraph/Twitter per share
- ✅ Pulsante CTA riscatto
- ✅ Condivisione social (WhatsApp, Facebook, Twitter)
- ✅ Badge categoria
- ✅ Calcolo automatico risparmio %

### 3. **`/database/update_promotions_landing.sql`**
Aggiornamento schema DB:
- ✅ Colonne: `landing_slug`, `cta_text`, `original_price`, `category`
- ✅ Tabella `promotion_redemptions` per tracciare riscatti
- ✅ RLS policies complete
- ✅ Indici per performance

### 4. **Aggiornato `/vercel.json`**
- ✅ Route `/promo/:slug` → landing page

---

## 🚀 Setup Necessario

### 1. Esegui SQL su Supabase

```bash
# Vai su Supabase SQL Editor e esegui:
database/update_promotions_landing.sql
```

### 2. Configura Vercel Blob

Il progetto è già collegato a `cdm86project-blob`. Verifica che il token sia configurato:

```bash
# Da Vercel Dashboard:
# 1. Vai su https://vercel.com/dashboard/stores
# 2. Seleziona "cdm86project-blob"
# 3. Copia "Read-Write Token"
# 4. Aggiungi alle Environment Variables del progetto
```

### 3. Deploy su Vercel

```bash
cd /Users/akirayouky/Desktop/Siti/CDM86-NEW
vercel --prod
```

---

## 🎯 Come Funziona

### 1. **Creazione Promo**

1. Vai su `/public/promo-creator.html`
2. Carica immagine (va su Vercel Blob `cdm86project-blob`)
3. Compila titolo, descrizione, prezzi
4. Seleziona categoria
5. Click "Pubblica Promo"
6. ✅ Ottieni URL landing page: `/promo/{slug}`

### 2. **Landing Page**

Ogni promo ha URL dedicato:
```
https://cdm86.vercel.app/promo/pizza-margherita-gratis
```

Features:
- 📱 **Responsive** - perfetta su mobile
- 🎨 **Design accattivante** - card full-screen
- 📊 **SEO ottimizzato** - meta tags completi
- 📤 **Social sharing** - pulsanti condivisione
- 💰 **Prezzi chiari** - con calcolo risparmio %
- 🎯 **CTA personalizzato** - pulsante riscatto

### 3. **Condivisione**

Ogni landing ha pulsanti per:
- **WhatsApp** - messaggio precompilato
- **Facebook** - share con OpenGraph
- **Twitter** - tweet con card
- **Copia link** - clipboard

---

## 📊 Struttura DB

### Tabella `promotions` (aggiornata)

```sql
-- Nuove colonne
landing_slug TEXT UNIQUE       -- es: "pizza-margherita-gratis"
cta_text TEXT                  -- es: "RISCATTA ORA!"
original_price DECIMAL(10,2)   -- Prezzo prima dello sconto
category TEXT                  -- food, beauty, wellness, etc.
```

### Tabella `promotion_redemptions` (nuova)

```sql
id UUID PRIMARY KEY
promotion_id UUID              -- FK promotions
user_id UUID                   -- FK users (nullable)
redeemed_at TIMESTAMP
redemption_code TEXT
status TEXT                    -- pending, completed, expired, cancelled
```

---

## 🎨 Categorie Disponibili

| Categoria | Icona | Descrizione |
|-----------|-------|-------------|
| `food` | 🍕 | Cibo & Drink |
| `beauty` | 💇 | Bellezza |
| `wellness` | 🧘 | Benessere |
| `shopping` | 🛍️ | Shopping |
| `entertainment` | 🎭 | Intrattenimento |
| `travel` | ✈️ | Viaggi |

---

## 🔧 Personalizzazioni

### Cambio Colori Tema

In `promo-creator.html` e `promo-landing.html`:

```css
/* Colore primario */
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);

/* Colore CTA */
background: linear-gradient(135deg, #fbbf24 0%, #f59e0b 100%);
```

### Template Card Diversi

Puoi creare template multipli modificando `.card-preview` in `promo-creator.html`:
- **Minimalista** - solo testo su sfondo
- **Bold** - immagine grande + overlay
- **Elegant** - gradiente soft
- **Dark** - tema scuro

---

## 📈 Analytics & Tracking

### Eventi da Tracciare

1. **Creazione promo** → Log in `promotions`
2. **Visualizzazioni landing** → Google Analytics o custom
3. **Click CTA** → `promotion_redemptions`
4. **Condivisioni social** → Custom events

### Query Utili

```sql
-- Promo più visualizzate
SELECT landing_slug, COUNT(*) as views
FROM promotion_redemptions
GROUP BY landing_slug
ORDER BY views DESC;

-- Promo per categoria
SELECT category, COUNT(*) as total
FROM promotions
WHERE is_active = true
GROUP BY category;

-- Tasso di conversione
SELECT 
    p.title,
    COUNT(DISTINCT pr.id) as redemptions
FROM promotions p
LEFT JOIN promotion_redemptions pr ON p.id = pr.promotion_id
GROUP BY p.id;
```

---

## 🐛 Troubleshooting

### Upload Immagini Non Funziona

1. Verifica token Vercel Blob:
   ```bash
   vercel env ls
   # Deve contenere BLOB_READ_WRITE_TOKEN
   ```

2. Check API `/api/upload-org`:
   ```bash
   curl -X POST http://localhost:3000/api/upload-org \
     -F "file=@test.jpg" \
     -F "type=card" \
     -F "userId=test"
   ```

### Landing Page 404

1. Verifica `vercel.json` rewrites:
   ```json
   {
     "source": "/promo/:slug",
     "destination": "/public/promo-landing.html"
   }
   ```

2. Check che slug sia in DB:
   ```sql
   SELECT landing_slug FROM promotions WHERE is_active = true;
   ```

### Promo Non Si Carica

1. Apri Console Browser (F12)
2. Verifica errori Supabase
3. Check che RLS policies siano corrette:
   ```sql
   SELECT * FROM promotions WHERE landing_slug = 'YOUR_SLUG';
   ```

---

## 🎉 Test Completo

### 1. Test Creator

```bash
# Apri browser
http://localhost:3000/public/promo-creator.html

# 1. Carica immagine JPG
# 2. Inserisci dati:
   Titolo: Pizza Margherita Gratis!
   Descrizione: Ordina 2 pizze, la 3° è gratis!
   Prezzo: 0
   Prezzo originale: 12.99
   CTA: RISCATTA SUBITO
   Categoria: Cibo & Drink

# 3. Click "Pubblica Promo"
# 4. Copia URL generato
```

### 2. Test Landing

```bash
# Apri l'URL della promo
http://localhost:3000/promo/pizza-margherita-gratis

# Verifica:
- ✅ Immagine caricata
- ✅ Titolo/descrizione corretti
- ✅ Prezzo barrato
- ✅ Badge categoria
- ✅ Pulsante CTA funzionante
- ✅ Share buttons attivi
```

### 3. Test Share

```bash
# Click su ogni pulsante:
- WhatsApp → Apre chat precompilata
- Facebook → Dialog share
- Twitter → Tweet con URL
- Copia → Clipboard con URL
```

---

## 🚀 Deploy Produzione

```bash
cd /Users/akirayouky/Desktop/Siti/CDM86-NEW

# 1. Esegui SQL su Supabase
# 2. Verifica Blob token su Vercel
# 3. Deploy
vercel --prod

# 4. Test URL produzione
https://cdm86.vercel.app/public/promo-creator.html
```

---

## 📝 TODO Futuri

- [ ] Template multipli per card
- [ ] Countdown timer su offerte limitate
- [ ] QR code per riscatto offline
- [ ] Email notification su riscatto
- [ ] Dashboard analytics per organizzazioni
- [ ] A/B testing differenti CTA
- [ ] Integrazione pagamenti Stripe
- [ ] Sistema di coupon codes

---

## ✅ Riepilogo

**Sistema completo pronto per:**
1. ✅ Creare promo card visualmente
2. ✅ Upload immagini su Vercel Blob
3. ✅ Generare landing page automatiche
4. ✅ Condivisione social ottimizzata
5. ✅ Tracciamento riscatti su DB
6. ✅ SEO e meta tags completi

**Pronto per il deploy! 🚀**
