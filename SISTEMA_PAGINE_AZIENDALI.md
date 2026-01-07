# 🎨 SISTEMA PAGINE AZIENDALI PERSONALIZZATE - GUIDA COMPLETA

## 📋 OVERVIEW

Sistema completo per permettere alle aziende di creare pagine di presentazione personalizzate usando un page builder drag & drop.

### 🎯 Funzionalità:
- ✅ Page Builder visuale con 7 tipi di sezioni
- ✅ Salvataggio su database (non solo localStorage)
- ✅ Slug automatico generato dal nome azienda
- ✅ Pagine pubbliche accessibili via URL
- ✅ Sistema draft/published/archived
- ✅ Contatore visualizzazioni
- ✅ SEO meta tags
- ✅ Row Level Security (RLS) policies

---

## 🗄️ ARCHITETTURA DATABASE

### Tabella `organization_pages`

```sql
CREATE TABLE organization_pages (
    id UUID PRIMARY KEY,
    organization_id UUID REFERENCES organizations(id),
    slug VARCHAR(255) UNIQUE,           -- URL: /azienda/mcdonald-s
    page_data JSONB,                    -- Sezioni del page builder
    page_title VARCHAR(255),            -- Titolo pagina (meta)
    page_description TEXT,              -- Descrizione (meta)
    meta_image TEXT,                    -- Immagine social sharing
    status VARCHAR(20),                 -- draft | published | archived
    views_count INTEGER DEFAULT 0,      -- Analytics
    last_viewed_at TIMESTAMP,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    published_at TIMESTAMP
);
```

### Vincoli Importanti:
- ✅ Una sola pagina pubblicata per organizzazione
- ✅ Slug unico generato automaticamente
- ✅ Trigger per updated_at e published_at

### RLS Policies:
- 🌐 **Public**: può vedere pagine con `status = 'published'`
- 🏢 **Organizations**: possono gestire le proprie pagine
- 👑 **Admin**: può gestire tutte le pagine

---

## 🔧 EDGE FUNCTIONS

### 1. `save-organization-page`

**Endpoint**: `POST /functions/v1/save-organization-page`

**Headers**:
```javascript
{
    'Authorization': 'Bearer <user-jwt-token>',
    'apikey': '<supabase-anon-key>',
    'Content-Type': 'application/json'
}
```

**Body**:
```javascript
{
    "page_data": {
        "sections": [...],
        "style": "modern"
    },
    "page_title": "McDonald's Milano",
    "page_description": "Scopri le nostre promozioni",
    "meta_image": "https://...",
    "status": "published"  // o "draft"
}
```

**Response**:
```javascript
{
    "success": true,
    "page": {
        "id": "uuid...",
        "slug": "mcdonald-s",
        "organization_id": "uuid...",
        ...
    },
    "public_url": "/azienda/mcdonald-s"
}
```

**Logica**:
1. Verifica autenticazione utente
2. Trova organization_id dell'utente
3. Genera slug automaticamente da nome azienda
4. Se esiste già una pagina → UPDATE, altrimenti → INSERT
5. Ritorna dati + URL pubblico

---

### 2. `get-organization-page`

**Endpoint**: `GET /functions/v1/get-organization-page?slug=mcdonald-s`

**Headers**:
```javascript
{
    'apikey': '<supabase-anon-key>',
    'Content-Type': 'application/json'
}
```

**Response**:
```javascript
{
    "success": true,
    "page": {
        "id": "uuid...",
        "slug": "mcdonald-s",
        "page_data": {
            "sections": [...],
            "style": "modern"
        },
        "page_title": "McDonald's Milano",
        "organization": {
            "name": "McDonald's",
            "description": "...",
            "logo_url": "...",
            "website": "...",
            "social_links": {...}
        }
    }
}
```

**Logica**:
1. Cerca pagina con slug specificato
2. Verifica che `status = 'published'`
3. Join con dati organization
4. Incrementa views_count
5. Ritorna dati completi

---

## 🎨 FRONTEND

### 1. Page Builder (`public/page-builder.html`)

**Già esistente** - Interfaccia drag & drop per creare pagine

**Modifiche necessarie**:
```javascript
// Sostituire la funzione publishPage() con:
async function publishPage() {
    if (sections.length === 0) {
        alert('⚠️ Aggiungi almeno una sezione prima di pubblicare!');
        return;
    }
    
    const pageData = {
        page_data: {
            sections: sections,
            style: currentStyle
        },
        page_title: prompt('Titolo della pagina:', 'La mia azienda') || 'Pagina Aziendale',
        page_description: prompt('Descrizione (per SEO):') || '',
        status: 'published'
    };
    
    try {
        const response = await fetch(
            `${window.SUPABASE_URL}/functions/v1/save-organization-page`,
            {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${session.access_token}`,
                    'apikey': window.SUPABASE_ANON_KEY,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(pageData)
            }
        );

        const result = await response.json();

        if (result.success) {
            alert(`✅ Pagina pubblicata!\n\nURL: ${result.public_url}`);
            if (confirm('Vuoi visualizzarla?')) {
                window.open(`/public/azienda.html?slug=${result.page.slug}`, '_blank');
            }
        } else {
            throw new Error(result.error);
        }
    } catch (error) {
        alert('❌ Errore: ' + error.message);
    }
}
```

---

### 2. Pagina Pubblica (`public/azienda.html`)

**✅ Già creata** - Visualizza pagine pubblicate

**URL**: `/public/azienda.html?slug=nome-azienda`

**Funzionamento**:
1. Estrae `slug` dai parametri URL
2. Chiama `get-organization-page` function
3. Renderizza header azienda (logo, social, contatti)
4. Renderizza sezioni dalla `page_data`
5. Supporta tutti i tipi di sezione del page builder

**Tipi di sezione supportati**:
- ✅ `hero` - Sezione principale con CTA
- ✅ `cards-3` / `cards-4` - Griglie di card
- ✅ `stats` - Statistiche numeriche
- ✅ `cta` - Call to action finale
- ⏳ `text-image` (da implementare)
- ⏳ `animation` (da implementare)

---

### 3. Pannello Azienda (`public/organization-dashboard.html`)

**Da aggiungere**:

```html
<!-- Sezione Gestione Pagina -->
<div class="dashboard-section">
    <div class="section-header">
        <h2><i class="fas fa-paint-brush"></i> Pagina Aziendale</h2>
        <button class="btn btn-primary" onclick="openPageBuilder()">
            <i class="fas fa-plus"></i> Crea/Modifica Pagina
        </button>
    </div>

    <div id="page-status" class="page-info">
        <!-- Will be populated with page status -->
    </div>
</div>

<script>
async function loadPageStatus() {
    // Check if organization has a page
    const { data: page } = await supabase
        .from('organization_pages')
        .select('*')
        .eq('organization_id', organizationId)
        .maybeSingle();

    if (page) {
        document.getElementById('page-status').innerHTML = `
            <div class="page-card">
                <div class="page-status ${page.status}">
                    ${page.status === 'published' ? '✅ Pubblicata' : '📝 Bozza'}
                </div>
                <h3>${page.page_title}</h3>
                <p>Visualizzazioni: ${page.views_count || 0}</p>
                <p>Ultimo aggiornamento: ${new Date(page.updated_at).toLocaleDateString()}</p>
                ${page.status === 'published' ? `
                    <a href="/public/azienda.html?slug=${page.slug}" target="_blank" class="btn btn-secondary">
                        <i class="fas fa-eye"></i> Visualizza Pagina
                    </a>
                ` : ''}
            </div>
        `;
    } else {
        document.getElementById('page-status').innerHTML = `
            <div class="empty-state">
                <i class="fas fa-file-alt"></i>
                <p>Non hai ancora creato una pagina aziendale</p>
            </div>
        `;
    }
}

function openPageBuilder() {
    window.location.href = '/public/page-builder.html';
}
</script>
```

---

## 🚀 DEPLOYMENT

### 1. Deploy Database

```bash
# Su Supabase SQL Editor
# Esegui il file:
/database/CREATE_ORGANIZATION_PAGES_TABLE.sql
```

### 2. Deploy Edge Functions

```bash
cd /Users/akirayouky/Desktop/Siti/CDM86-NEW

# Deploy save function
supabase functions deploy save-organization-page

# Deploy get function  
supabase functions deploy get-organization-page

# Verifica
supabase functions list
```

### 3. Deploy Frontend

```bash
# Commit changes
git add .
git commit -m "🎨 SISTEMA PAGINE AZIENDALI: Tabella DB + Edge Functions + pagina pubblica"
git push

# Deploy su Vercel
vercel --prod
```

---

## 🧪 TESTING

### Test 1: Crea Database Table

```sql
-- Su Supabase SQL Editor
-- Verifica che la tabella esista
SELECT COUNT(*) FROM organization_pages;

-- Verifica policies
SELECT * FROM pg_policies WHERE tablename = 'organization_pages';
```

### Test 2: Deploy Functions

```bash
# Verifica che le functions siano deployate
curl https://uchrjlngfzfibcpdxtky.supabase.co/functions/v1/get-organization-page?slug=test
# Dovrebbe ritornare 404 (nessuna pagina)
```

### Test 3: Crea Pagina di Test

```javascript
// Da console browser (loggato come azienda)
const pageData = {
    page_data: {
        sections: [
            {
                type: 'hero',
                data: {
                    title: 'Benvenuti nella nostra azienda',
                    subtitle: 'Scopri le nostre offerte',
                    text: 'Siamo leader nel settore',
                    ctaText: 'Scopri di più',
                    ctaLink: '#',
                    background: '#2563eb'
                }
            }
        ],
        style: 'modern'
    },
    page_title: 'Test Azienda',
    page_description: 'Pagina di test',
    status: 'published'
};

const session = await supabase.auth.getSession();

fetch(`${window.SUPABASE_URL}/functions/v1/save-organization-page`, {
    method: 'POST',
    headers: {
        'Authorization': `Bearer ${session.data.session.access_token}`,
        'apikey': window.SUPABASE_ANON_KEY,
        'Content-Type': 'application/json'
    },
    body: JSON.stringify(pageData)
})
.then(r => r.json())
.then(console.log);
```

### Test 4: Visualizza Pagina

```
https://cdm86-xxx.vercel.app/public/azienda.html?slug=test-azienda
```

---

## 🔐 SICUREZZA

### RLS Policies Implementate:

1. **Lettura pagine pubblicate (tutti)**:
   ```sql
   status = 'published'
   ```

2. **Gestione proprie pagine (aziende)**:
   ```sql
   organization_id IN (
       SELECT id FROM organizations 
       WHERE user_id = auth.uid()
   )
   ```

3. **Admin full access**:
   ```sql
   EXISTS (
       SELECT 1 FROM auth.users
       WHERE id = auth.uid()
       AND raw_user_meta_data->>'role' = 'admin'
   )
   ```

### Validazione Input:

Edge functions validano:
- ✅ User autenticato
- ✅ Organization collegato a user
- ✅ page_data non vuoto
- ✅ Slug univoco

---

## 📊 ANALYTICS

### Metriche Tracciate:

- **views_count**: Numero visualizzazioni totali
- **last_viewed_at**: Timestamp ultima visualizzazione

### Query Utili:

```sql
-- Pagine più viste
SELECT 
    o.name,
    p.page_title,
    p.views_count,
    p.status
FROM organization_pages p
JOIN organizations o ON o.id = p.organization_id
WHERE p.status = 'published'
ORDER BY p.views_count DESC
LIMIT 10;

-- Pagine per stato
SELECT 
    status,
    COUNT(*) as count
FROM organization_pages
GROUP BY status;
```

---

## 🎯 PROSSIMI MIGLIORAMENTI

- [ ] Editor WYSIWYG per testi
- [ ] Upload immagini diretto
- [ ] Template predefiniti
- [ ] Anteprima mobile
- [ ] A/B testing
- [ ] Custom domain per aziende premium
- [ ] Analytics avanzati (Google Analytics integration)
- [ ] Sistema commenti/recensioni
- [ ] Integrazione form contatti
- [ ] Newsletter signup

---

## 🆘 TROUBLESHOOTING

### Errore: "Organization not found"
→ Verifica che l'utente loggato abbia `organization_id` in `organizations.user_id`

### Errore: "Slug già esistente"
→ La funzione genera slug unici automaticamente, verifica che il trigger funzioni

### Pagina non si carica
→ Controlla che `status = 'published'` e che le RLS policies permettano la lettura

### Edge function timeout
→ Verifica che Supabase URL e API Key siano corretti in `config.js`

---

**Creato**: 7 Gennaio 2026  
**Versione**: 1.0  
**Status**: ✅ Ready for deployment
