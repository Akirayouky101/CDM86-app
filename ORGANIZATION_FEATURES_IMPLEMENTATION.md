# Implementazione Features Organizzazioni - Dashboard Unificata

## 📋 Riepilogo

Dopo l'unificazione delle dashboard (21 ottobre 2025), le funzionalità di creazione card e gestione promozioni per le organizzazioni erano mancanti. Questa implementazione le reintegra nella dashboard unificata con visibilità basata sul ruolo.

---

## ✅ COMPLETATO

### 1. HTML Structure (Linee 934-995)
Aggiunta sezione `company-management-section` con 3 blocchi:

#### **Card Promozione**
- Titolo: "📣 Card Promozione"
- Badge status: `#card-status-badge` (✅ Pubblicata / 📝 Bozza)
- Anteprima: `#card-preview`
- Pulsante: `openCardEditor()`

#### **Gestione Promozioni**
- Titolo: "🎁 Promozioni e Offerte"
- Pulsante: `openCreatePromotionModal()` (verde)
- Griglia: `#promotions-grid` (auto-fill 280px)

#### **Statistiche Azienda**
- 3 Card Stats:
  - `#card-views` (visualizzazioni card)
  - `#active-promotions` (promozioni attive)
  - `#total-redemptions` (utilizzi totali)

---

### 2. CSS Styles (Linee 566-704)
Aggiunti 138 linee di stili completi:

```css
.company-card              /* Container card con shadow */
.company-card-header       /* Header con border-bottom */
.company-card-description  /* Descrizione grigio chiaro */
#card-status-badge         /* Badge stato pubblicazione */
#card-preview              /* Anteprima card con min-height */
#promotions-grid           /* Grid responsive 280px */
.promotion-card            /* Card singola promozione */
.promotion-card-image      /* Immagine 160px gradient */
.promotion-card-footer     /* Footer con punti/stato */
.btn-primary               /* Gradient viola hover scale */
.btn-success               /* Gradient verde hover scale */
.hidden                    /* display: none !important */
```

---

### 3. JavaScript Functions (Linee 1620-1745)

#### **loadOrganizationCard()**
- Query `organization_pages` table by `organization_id`
- Mostra badge ✅ Pubblicata / 📝 Bozza
- Rendering anteprima card con titolo/descrizione
- Gestione errore PGRST116 (nessuna riga)

#### **loadOrganizationPromotions()**
- Query `promotions` table by `organization_id`
- Rendering griglia promozioni con:
  - Immagine/gradient
  - Titolo e descrizione
  - Punti richiesti
  - Badge ✅ Attiva / ❌ Inattiva

#### **openCardEditor()**
- Alert placeholder (TODO: modal completo)
- Funzionalità previste:
  - Upload immagine/logo
  - Campi titolo/descrizione
  - Color picker gradient
  - CTA button (testo + link)
  - Anteprima live
  - Salvataggio su `organization_pages`

#### **openCreatePromotionModal()**
- Alert placeholder (TODO: modal completo)
- Funzionalità previste:
  - Form titolo/descrizione/immagine
  - Input punti richiesti
  - Date picker scadenza
  - Toggle attiva/inattiva
  - Salvataggio su `promotions`
  - Refresh griglia automatico

---

### 4. Conditional Display Logic (Linee 1443-1449)
Nella funzione `loadDashboardData()`:

```javascript
if (user.is_organization) {
    console.log('🏢 User is organization, loading card and promotions...');
    const companySection = document.getElementById('company-management-section');
    if (companySection) {
        companySection.classList.remove('hidden');
        companySection.style.display = 'block';
    }
    await loadOrganizationCard();
    await loadOrganizationPromotions();
}
```

---

## ❌ DA COMPLETARE

### 1. Modal Card Editor
**File:** `public/dashboard.html` (da aggiungere prima `</body>`)

**Struttura HTML necessaria:**
```html
<div id="cardEditorModal" class="modal-overlay hidden">
    <div class="modal-container" style="max-width: 800px;">
        <div class="modal-header">
            <h2>📣 Editor Card Aziendale</h2>
            <button onclick="closeCardEditor()">×</button>
        </div>
        <div class="modal-body">
            <!-- Upload Immagine -->
            <div class="form-group">
                <label>Immagine/Logo Aziendale</label>
                <input type="file" id="card-image" accept="image/*">
                <div id="image-preview"></div>
            </div>
            
            <!-- Titolo -->
            <div class="form-group">
                <label>Titolo Card</label>
                <input type="text" id="card-title" maxlength="60">
            </div>
            
            <!-- Descrizione -->
            <div class="form-group">
                <label>Descrizione</label>
                <textarea id="card-description" rows="4" maxlength="200"></textarea>
            </div>
            
            <!-- Gradient Color -->
            <div class="form-group">
                <label>Colore Gradiente</label>
                <select id="card-gradient">
                    <option value="purple">Viola</option>
                    <option value="blue">Blu</option>
                    <option value="green">Verde</option>
                    <option value="orange">Arancione</option>
                </select>
            </div>
            
            <!-- CTA Button -->
            <div class="form-group">
                <label>Testo Pulsante</label>
                <input type="text" id="cta-text" placeholder="Es: Scopri di più">
            </div>
            <div class="form-group">
                <label>Link Pulsante</label>
                <input type="url" id="cta-link" placeholder="https://">
            </div>
            
            <!-- Live Preview -->
            <div class="card-preview-live" id="live-preview"></div>
            
            <!-- Publish Toggle -->
            <div class="form-group">
                <label>
                    <input type="checkbox" id="card-published">
                    Pubblica card sulla homepage
                </label>
            </div>
        </div>
        <div class="modal-footer">
            <button class="btn-secondary" onclick="closeCardEditor()">Annulla</button>
            <button class="btn-primary" onclick="saveOrganizationCard()">Salva Card</button>
        </div>
    </div>
</div>
```

**Funzioni JavaScript necessarie:**
```javascript
function openCardEditor() {
    const modal = document.getElementById('cardEditorModal');
    modal.classList.remove('hidden');
    loadExistingCard(); // Carica dati se card già esistente
}

function closeCardEditor() {
    const modal = document.getElementById('cardEditorModal');
    modal.classList.add('hidden');
}

async function loadExistingCard() {
    const { data } = await window.supabaseClient
        .from('organization_pages')
        .select('card_data, card_published')
        .eq('organization_id', currentUser.organization_data.id)
        .single();
    
    if (data && data.card_data) {
        document.getElementById('card-title').value = data.card_data.title || '';
        document.getElementById('card-description').value = data.card_data.description || '';
        document.getElementById('card-published').checked = data.card_published;
        // ... altri campi
    }
}

async function saveOrganizationCard() {
    const cardData = {
        title: document.getElementById('card-title').value,
        description: document.getElementById('card-description').value,
        image_url: document.getElementById('card-image-preview-url').value,
        gradient: document.getElementById('card-gradient').value,
        cta_text: document.getElementById('cta-text').value,
        cta_link: document.getElementById('cta-link').value
    };
    
    const published = document.getElementById('card-published').checked;
    
    const { error } = await window.supabaseClient
        .from('organization_pages')
        .upsert({
            organization_id: currentUser.organization_data.id,
            card_data: cardData,
            card_published: published,
            updated_at: new Date()
        });
    
    if (!error) {
        alert('Card salvata con successo!');
        closeCardEditor();
        await loadOrganizationCard(); // Refresh preview
    }
}
```

---

### 2. Modal Crea Promozione
**File:** `public/dashboard.html` (da aggiungere prima `</body>`)

**Struttura HTML necessaria:**
```html
<div id="createPromotionModal" class="modal-overlay hidden">
    <div class="modal-container" style="max-width: 700px;">
        <div class="modal-header">
            <h2>🎁 Nuova Promozione</h2>
            <button onclick="closePromotionModal()">×</button>
        </div>
        <div class="modal-body">
            <!-- Titolo -->
            <div class="form-group">
                <label>Titolo Promozione *</label>
                <input type="text" id="promo-title" required maxlength="80">
            </div>
            
            <!-- Descrizione -->
            <div class="form-group">
                <label>Descrizione *</label>
                <textarea id="promo-description" rows="4" required maxlength="250"></textarea>
            </div>
            
            <!-- Immagine URL -->
            <div class="form-group">
                <label>URL Immagine (opzionale)</label>
                <input type="url" id="promo-image">
            </div>
            
            <!-- Punti Richiesti -->
            <div class="form-group">
                <label>Punti Richiesti *</label>
                <input type="number" id="promo-points" min="0" required>
            </div>
            
            <!-- Data Scadenza -->
            <div class="form-group">
                <label>Data Scadenza (opzionale)</label>
                <input type="date" id="promo-expiry">
            </div>
            
            <!-- Attiva -->
            <div class="form-group">
                <label>
                    <input type="checkbox" id="promo-active" checked>
                    Attiva immediatamente
                </label>
            </div>
        </div>
        <div class="modal-footer">
            <button class="btn-secondary" onclick="closePromotionModal()">Annulla</button>
            <button class="btn-success" onclick="savePromotion()">Crea Promozione</button>
        </div>
    </div>
</div>
```

**Funzioni JavaScript necessarie:**
```javascript
function openCreatePromotionModal() {
    const modal = document.getElementById('createPromotionModal');
    modal.classList.remove('hidden');
}

function closePromotionModal() {
    const modal = document.getElementById('createPromotionModal');
    modal.classList.add('hidden');
    // Reset form
    document.getElementById('promo-title').value = '';
    document.getElementById('promo-description').value = '';
    document.getElementById('promo-image').value = '';
    document.getElementById('promo-points').value = '';
    document.getElementById('promo-expiry').value = '';
}

async function savePromotion() {
    const promoData = {
        organization_id: currentUser.organization_data.id,
        title: document.getElementById('promo-title').value,
        description: document.getElementById('promo-description').value,
        image_url: document.getElementById('promo-image').value || null,
        points_required: parseInt(document.getElementById('promo-points').value),
        expiry_date: document.getElementById('promo-expiry').value || null,
        active: document.getElementById('promo-active').checked
    };
    
    const { error } = await window.supabaseClient
        .from('promotions')
        .insert(promoData);
    
    if (!error) {
        alert('Promozione creata con successo!');
        closePromotionModal();
        await loadOrganizationPromotions(); // Refresh grid
    } else {
        alert('Errore: ' + error.message);
    }
}
```

---

### 3. Upload Immagini
**Opzioni:**

#### **Opzione A - Supabase Storage**
1. Creare bucket `organization-images` su Supabase
2. Configurare RLS policies
3. Implementare upload:

```javascript
async function uploadCardImage(file) {
    const fileName = `card_${currentUser.organization_data.id}_${Date.now()}.jpg`;
    const { data, error } = await window.supabaseClient.storage
        .from('organization-images')
        .upload(fileName, file);
    
    if (!error) {
        const { data: { publicUrl } } = window.supabaseClient.storage
            .from('organization-images')
            .getPublicUrl(fileName);
        return publicUrl;
    }
}
```

#### **Opzione B - Servizio Esterno (Cloudinary)**
1. Registrare account Cloudinary
2. Ottenerecloudinary_url e upload_preset
3. Upload diretto via API

---

### 4. Statistiche Azienda
Implementare query per popolare i 3 stat-card:

```javascript
async function loadOrganizationStats() {
    const orgId = currentUser.organization_data.id;
    
    // Card Views (da analytics se implementato)
    const { count: viewsCount } = await window.supabaseClient
        .from('card_analytics')
        .select('*', { count: 'exact', head: true })
        .eq('organization_id', orgId);
    
    // Active Promotions
    const { data: activePromos } = await window.supabaseClient
        .from('promotions')
        .select('id')
        .eq('organization_id', orgId)
        .eq('active', true);
    
    // Total Redemptions (da redemptions se implementato)
    const { count: redemptionsCount } = await window.supabaseClient
        .from('promotion_redemptions')
        .select('*', { count: 'exact', head: true })
        .eq('organization_id', orgId);
    
    document.getElementById('card-views').textContent = viewsCount || 0;
    document.getElementById('active-promotions').textContent = activePromos?.length || 0;
    document.getElementById('total-redemptions').textContent = redemptionsCount || 0;
}
```

**Tabelle DB necessarie:**
- `card_analytics` (organization_id, viewed_at, user_id)
- `promotion_redemptions` (promotion_id, user_id, redeemed_at)

---

## 🗄️ Database Schema

### Tabella `organization_pages` (esistente)
```sql
CREATE TABLE organization_pages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id),
    card_data JSONB,              -- {title, description, image_url, gradient, cta_text, cta_link}
    card_published BOOLEAN DEFAULT false,
    page_data JSONB,
    slug TEXT UNIQUE,
    status TEXT DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### Tabella `promotions` (verificare esistenza)
```sql
CREATE TABLE promotions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id),
    title TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    points_required INTEGER NOT NULL,
    expiry_date DATE,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### Tabelle Analytics (da creare)
```sql
-- Card Analytics
CREATE TABLE card_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id),
    user_id UUID REFERENCES users(id),
    viewed_at TIMESTAMP DEFAULT NOW()
);

-- Promotion Redemptions
CREATE TABLE promotion_redemptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    promotion_id UUID REFERENCES promotions(id),
    user_id UUID REFERENCES users(id),
    redeemed_at TIMESTAMP DEFAULT NOW(),
    status TEXT DEFAULT 'pending' -- pending, approved, rejected
);
```

---

## 🚀 Prossimi Passi

1. **Immediate:**
   - [ ] Implementare modal Card Editor completo
   - [ ] Implementare modal Crea Promozione completo
   - [ ] Testare con utente organizzazione (test@cdm86.com)

2. **Short-term:**
   - [ ] Setup Supabase Storage per upload immagini
   - [ ] Creare tabelle analytics (card_analytics, promotion_redemptions)
   - [ ] Implementare funzione loadOrganizationStats()

3. **Mid-term:**
   - [ ] Mostrare card aziendali sulla homepage `/public/promotions.html`
   - [ ] Integrare promozioni nel sistema punti utenti
   - [ ] Implementare sistema riscatto promozioni

4. **Long-term:**
   - [ ] Dashboard analytics avanzata per organizzazioni
   - [ ] Sistema notifiche utilizzo promozioni
   - [ ] Export reports CSV/PDF

---

## 📝 Note Tecniche

### File Modificati
- `public/dashboard.html` (4106 linee totali)
  - Linee 566-704: CSS styles
  - Linee 934-995: HTML structure
  - Linee 1443-1449: Conditional display logic
  - Linee 1620-1745: JavaScript functions

### Classi CSS Chiave
- `.company-card` - Container principale
- `.hidden` - Nasconde sezione di default
- `#company-management-section` - ID sezione principale

### Funzioni JavaScript Chiave
- `loadOrganizationCard()` - Carica card pubblicata
- `loadOrganizationPromotions()` - Carica lista promozioni
- `openCardEditor()` - Apre modal editor (placeholder)
- `openCreatePromotionModal()` - Apre modal promozione (placeholder)

### Detection Organizzazione
```javascript
// In loadDashboardData()
if (user.is_organization) {
    // user.organization_data contiene i dati da organizations table
    // Mostra company-management-section
    // Carica card e promozioni
}
```

---

## 🐛 Known Issues
- Gli errori lint CSS inline sono cosmetici (non funzionali)
- Mancano modal completi (attualmente placeholder alert)
- Statistiche hardcoded a 0 (mancano query DB)
- Upload immagini non implementato

---

## 📚 Documentazione Correlata
- `IMPLEMENTAZIONE_CARD_PAGE_BUILDER.md` - Sistema Page Builder completo
- `SISTEMA_PAGINE_AZIENDALI.md` - Guida page builder aziendali
- `TODO_IMMEDIATE.md` - Lista task pendenti
- `DATABASE_IMPLEMENTATION_COMPLETE.md` - Schema database

---

**Ultima modifica:** 3 Febbraio 2025  
**Autore:** GitHub Copilot  
**Stato:** ✅ HTML/CSS/JS Base Implementato | ❌ Modal e Upload Mancanti
