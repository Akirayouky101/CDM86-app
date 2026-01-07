# 🎨 IMPLEMENTAZIONE COMPLETA: Card Builder + Page Builder Potenziato

## 📋 PANORAMICA
Sistema completo per permettere alle organizzazioni di creare:
1. **Card Promozione** - Appare in `/public/promotions.html`
2. **Pagina Aziendale Completa** - Accessibile tramite `/public/azienda.html?slug=xxx`

---

## 🗄️ DATABASE

### Tabella: `organization_pages`
Nuove colonne aggiunte:
```sql
card_data JSONB DEFAULT '{"title": "", "description": "", "image": "", "badge": "", "features": []}'
card_published BOOLEAN DEFAULT false
```

**card_data** contiene:
- `title`: Titolo card
- `description`: Descrizione breve (max 150 caratteri)
- `image`: URL immagine copertina
- `badge`: Badge/tag (es. "NUOVO", "TOP", "OFFERTA")
- `features`: Array di caratteristiche [{ icon: "fa-star", text: "Feature 1" }]
- `ctaText`: Testo pulsante (default: "Scopri di più")
- `gradient`: Colore gradiente card

---

## 🎯 NUOVI FILE DA CREARE

### 1. `/public/card-builder.html`
**Builder visuale per creare card promozione**

**Funzionalità:**
- Upload immagine copertina (drag & drop)
- Editor titolo e descrizione
- Selezione badge predefiniti
- Aggiunta features con icone FontAwesome
- Personalizzazione colori e gradiente
- Preview live della card
- Salvataggio automatico
- Pubblicazione card (mostra in promotions)

**Sezioni del builder:**
1. **Immagine**: Upload + crop
2. **Info Base**: Titolo, descrizione, badge
3. **Features**: Lista di caratteristiche (max 6)
4. **Stile**: Colori, gradiente, effetti
5. **CTA**: Testo e stile pulsante
6. **Preview**: Anteprima card live

---

### 2. Potenziamento `/public/page-builder.html`

**Nuove sezioni da aggiungere:**

#### 📸 Gallery
- Grid di immagini (2, 3, 4 colonne)
- Lightbox integrato
- Didascalie opzionali

#### 💬 Testimonials
- Card testimonianze clienti
- Avatar, nome, ruolo
- Rating stelle
- Layout: grid o carousel

#### ❓ FAQ
- Accordion espandibile
- Icone personalizzate
- Ricerca FAQ

#### 🎥 Video
- Embed YouTube/Vimeo
- Video locale con controlli
- Autoplay opzionale

#### 📧 Contact Form
- Campi personalizzabili
- Integrazione email
- Validazione client-side

#### 🗺️ Map
- Google Maps embed
- Marker personalizzato
- Info location

#### 📊 Timeline
- Eventi cronologici
- Stile verticale/orizzontale
- Icone milestone

#### 🎨 Features Advanced
- Grid features con hover effects
- Icone animate
- Link a sezioni pagina

**Miglioramenti generali:**
- **Editor colori**: Color picker per ogni sezione
- **Font selector**: Scelta font da Google Fonts
- **Spacing controls**: Margin e padding personalizzabili
- **Animations**: Scelta animazioni entrata (fade, slide, zoom)
- **Mobile preview**: Toggle vista mobile/desktop
- **Templates**: 5 template predefiniti da cui partire

---

## 🔄 MODIFICHE FILE ESISTENTI

### `/public/organization-dashboard.html`

**Nuova sezione "Marketing & Visibilità":**
```html
<div class="card">
    <h2>📣 Marketing & Visibilità</h2>
    
    <!-- Card Promozione -->
    <div class="marketing-item">
        <h3>Card Promozione</h3>
        <p>Crea la card che apparirà nella pagina Promozioni</p>
        <div id="card-status"></div>
        <button onclick="openCardBuilder()">Crea/Modifica Card</button>
    </div>
    
    <!-- Pagina Aziendale -->
    <div class="marketing-item">
        <h3>Pagina Aziendale</h3>
        <p>Crea la tua pagina aziendale completa</p>
        <div id="page-status"></div>
        <button onclick="openPageBuilder()">Crea/Modifica Pagina</button>
    </div>
</div>
```

**Nuove funzioni JavaScript:**
- `loadCardStatus()`: Carica stato card (pubblicata/bozza)
- `openCardBuilder()`: Apre card-builder.html
- `loadPageStatus()`: Già esistente, mostra stato pagina

---

### `/public/promotions.html`

**Modifica sezione promozioni:**

Invece di card statiche HTML, carica dinamicamente da database:

```javascript
async function loadOrganizationCards() {
    const { data: cards } = await supabaseClient
        .from('organization_pages')
        .select(`
            *,
            organizations (
                id,
                name,
                description,
                logo_url
            )
        `)
        .eq('card_published', true)
        .order('created_at', { ascending: false });
    
    const container = document.getElementById('organization-cards');
    container.innerHTML = cards.map(card => renderCard(card)).join('');
}

function renderCard(card) {
    const data = card.card_data;
    return `
        <div class="promo-card" style="background: ${data.gradient || 'linear-gradient(135deg, #667eea, #764ba2)'}">
            ${data.badge ? `<div class="badge">${data.badge}</div>` : ''}
            <img src="${data.image}" alt="${data.title}">
            <h3>${data.title}</h3>
            <p>${data.description}</p>
            <div class="features">
                ${data.features.map(f => `
                    <span><i class="fas ${f.icon}"></i> ${f.text}</span>
                `).join('')}
            </div>
            <a href="/public/azienda.html?slug=${card.slug}" class="cta-btn">
                ${data.ctaText || 'Scopri di più'}
            </a>
        </div>
    `;
}
```

---

## 🎨 STRUTTURA CARD BUILDER

### Layout:
```
┌─────────────────────────────────────────────┐
│  CARD BUILDER - CDM86                       │
├─────────────────┬───────────────────────────┤
│                 │                           │
│  EDITOR PANEL   │    LIVE PREVIEW          │
│                 │                           │
│  1. Immagine    │    ┌─────────────────┐   │
│  2. Titolo      │    │  [Badge]        │   │
│  3. Descrizione │    │  ┌───────────┐  │   │
│  4. Badge       │    │  │  IMAGE    │  │   │
│  5. Features    │    │  └───────────┘  │   │
│  6. Stile       │    │  Titolo Card    │   │
│  7. CTA         │    │  Descrizione... │   │
│                 │    │  ✓ Feature 1    │   │
│  [Salva Bozza]  │    │  ✓ Feature 2    │   │
│  [Pubblica]     │    │  [CTA Button]   │   │
│                 │    └─────────────────┘   │
└─────────────────┴───────────────────────────┘
```

---

## 📦 EDGE FUNCTIONS

Già esistenti:
- ✅ `save-organization-page` - Salva page_data
- ✅ `get-organization-page` - Carica page_data

Da modificare:
- `save-organization-page`: Aggiungere supporto per salvare anche `card_data` e `card_published`

---

## 🚀 FLUSSO UTENTE

### Organizzazione crea Card:
1. Login → Organization Dashboard
2. Click "Crea/Modifica Card"
3. Apre Card Builder
4. Personalizza card (immagine, testo, features, stile)
5. Preview live
6. Salva bozza (card_published = false)
7. Pubblica (card_published = true)
8. Card appare in Promotions

### Organizzazione crea Pagina:
1. Dashboard → "Crea/Modifica Pagina"
2. Apre Page Builder (potenziato)
3. Drag & drop sezioni
4. Personalizza contenuti
5. Preview + Pubblica
6. Pagina accessibile via slug

### Utente vede promozione:
1. Va su `/public/promotions.html`
2. Vede card organizzazioni pubblicate
3. Click su card → va su `/public/azienda.html?slug=xxx`
4. Vede pagina aziendale completa

---

## 📝 CHECKLIST IMPLEMENTAZIONE

### Database
- [ ] Eseguire `ADD_CARD_DATA_COLUMN.sql` su Supabase

### Card Builder
- [ ] Creare `/public/card-builder.html`
- [ ] Sistema upload immagini
- [ ] Editor features con icone
- [ ] Live preview
- [ ] Salvataggio su database

### Page Builder Potenziato
- [ ] Aggiungere sezione Gallery
- [ ] Aggiungere sezione Testimonials
- [ ] Aggiungere sezione FAQ
- [ ] Aggiungere sezione Video
- [ ] Aggiungere sezione Contact Form
- [ ] Aggiungere sezione Map
- [ ] Aggiungere sezione Timeline
- [ ] Color picker globale
- [ ] Font selector
- [ ] Animations selector
- [ ] Mobile/Desktop preview toggle
- [ ] 5 Template predefiniti

### Organization Dashboard
- [ ] Aggiungere sezione "Marketing & Visibilità"
- [ ] Pulsante "Crea/Modifica Card"
- [ ] Mostra status card (pubblicata/bozza/views)
- [ ] Link a card builder

### Promotions.html
- [ ] Rimuovere card statiche
- [ ] Caricare card dinamicamente da DB
- [ ] Funzione renderCard()
- [ ] Link a pagina aziendale
- [ ] Filtri per categorie

### Edge Functions
- [ ] Modificare `save-organization-page` per card_data
- [ ] Test salvataggio card + page insieme

### Testing
- [ ] Test creazione card
- [ ] Test pubblicazione card
- [ ] Test visualizzazione in promotions
- [ ] Test link a pagina aziendale
- [ ] Test responsive mobile
- [ ] Test performance caricamento

---

## 🎯 RISULTATO FINALE

Le organizzazioni avranno:
- ✅ Dashboard centralizzato
- ✅ Card Builder visual per promozioni
- ✅ Page Builder completo per pagina aziendale
- ✅ Visibilità in pagina Promotions
- ✅ Pagina aziendale personalizzata
- ✅ Analytics base (views)
- ✅ Sistema tutto integrato con Supabase

---

**Tempo stimato implementazione:** 2-3 ore
**Complessità:** Media-Alta
**Priorità:** Alta (feature fondamentale per monetizzazione)
