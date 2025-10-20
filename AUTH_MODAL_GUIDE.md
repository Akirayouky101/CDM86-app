# 🔐 Auth Modal - Guida Completa

## 📋 Descrizione

La **Auth Modal** è una modal animata che appare quando un utente non loggato cerca di accedere a contenuti protetti. Offre due opzioni di registrazione:

1. **👤 Utente** - Accesso alle promozioni e sistema referral
2. **🏢 Azienda/Associazione** - Pubblicazione promozioni come partner

---

## ✅ Installazione

### 1. Includi i file CSS e JS

Nel `<head>` della tua pagina HTML:

```html
<!-- CSS -->
<link rel="stylesheet" href="/assets/css/auth-modal.css">

<!-- JS (prima della chiusura </body>) -->
<script src="/assets/js/auth-modal.js"></script>
```

### 2. La modal si inizializza automaticamente

Non serve fare nulla! Il file `auth-modal.js` crea automaticamente l'istanza globale `window.authModal`.

---

## 🚀 Utilizzo

### Metodo 1: Apri Modal Manualmente

```javascript
// Apri la modal
window.authModal.open();

// Chiudi la modal
window.authModal.close();
```

### Metodo 2: Con Callbacks Personalizzati

```javascript
// Imposta cosa fare quando l'utente sceglie "Utente"
authModal.setOnUserSelect(() => {
    console.log('Utente registrazione selezionata');
    window.location.href = '/public/register.html?type=user';
});

// Imposta cosa fare quando l'utente sceglie "Azienda"
authModal.setOnOrganizationSelect(() => {
    console.log('Azienda registrazione selezionata');
    window.location.href = '/public/register-organization.html';
});

// Imposta cosa fare quando l'utente sceglie "Login"
authModal.setOnLogin(() => {
    console.log('Login selezionato');
    window.location.href = '/public/login.html';
});

// Apri modal
authModal.open();
```

### Metodo 3: Mostra Modal se Utente Non Loggato

Nel file `auth.js` è disponibile una funzione helper:

```javascript
import { showAuthModalIfNotLoggedIn } from '/assets/js/auth.js';

// Controlla se utente è loggato, altrimenti mostra modal
const isLoggedIn = await showAuthModalIfNotLoggedIn();

if (!isLoggedIn) {
    // Modal aperta, utente non loggato
    console.log('Mostrando auth modal');
} else {
    // Utente loggato, continua normalmente
    console.log('Utente loggato!');
}
```

---

## 📝 Esempi Pratici

### Esempio 1: Proteggere una Pagina

```javascript
// In qualsiasi pagina che richiede login
import { showAuthModalIfNotLoggedIn } from '/assets/js/auth.js';

document.addEventListener('DOMContentLoaded', async () => {
    // Mostra modal se non loggato
    const needsLogin = await showAuthModalIfNotLoggedIn();
    
    if (needsLogin) {
        // Blocca accesso al contenuto
        document.body.classList.add('blurred');
        return;
    }
    
    // Utente loggato, carica contenuto
    loadContent();
});
```

### Esempio 2: Proteggere Azioni Specifiche

```javascript
// Quando l'utente clicca "Aggiungi ai Preferiti"
favoriteBtn.addEventListener('click', async () => {
    // Controlla se loggato
    const needsLogin = await showAuthModalIfNotLoggedIn();
    
    if (needsLogin) {
        // Modal aperta, interrompi azione
        return;
    }
    
    // Utente loggato, esegui azione
    await addToFavorites(promotionId);
});
```

### Esempio 3: Custom Redirect Dopo Selezione

```javascript
// Redirect personalizzati
authModal.setOnUserSelect(() => {
    // Salva dove l'utente voleva andare
    sessionStorage.setItem('redirect_after_login', window.location.href);
    
    // Vai alla registrazione
    window.location.href = '/public/register.html';
});

authModal.setOnOrganizationSelect(() => {
    // Traccia evento analytics
    gtag('event', 'organization_signup_intent');
    
    // Vai alla registrazione organizzazione
    window.location.href = '/public/register-organization.html';
});

authModal.setOnLogin(() => {
    // Salva intent per dopo login
    localStorage.setItem('post_login_action', 'view_promotions');
    
    // Vai al login
    window.location.href = '/public/login.html';
});

authModal.open();
```

---

## 🎨 Personalizzazione

### Modificare Testo e Icone

Modifica direttamente nel file `auth-modal.js`:

```javascript
this.modalHTML = `
    <div class="auth-modal-icon">🔐</div> <!-- Cambia icona -->
    <h2 class="auth-modal-title">Benvenuto su CDM86</h2> <!-- Cambia titolo -->
    <p class="auth-modal-subtitle">...</p> <!-- Cambia sottotitolo -->
`;
```

### Modificare Stili

Modifica il file `/assets/css/auth-modal.css`:

```css
/* Cambia colore principale */
.auth-modal-header {
    background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%);
}

/* Cambia animazione */
.auth-modal {
    animation: slideInFromTop 0.5s ease;
}
```

---

## 🎯 Redirect Automatici

La modal ha redirect di default:

| Selezione | Redirect Default |
|-----------|------------------|
| **👤 Utente** | `/public/register.html?type=user` |
| **🏢 Azienda** | `/public/register-organization.html` |
| **🔑 Login** | `/public/login.html` |

Puoi sovrascriverli con i callback (vedi sopra).

---

## 🔧 API Reference

### Metodi Pubblici

```javascript
// Apri modal
authModal.open()

// Chiudi modal
authModal.close()

// Imposta callback utente
authModal.setOnUserSelect(callback)

// Imposta callback organizzazione
authModal.setOnOrganizationSelect(callback)

// Imposta callback login
authModal.setOnLogin(callback)

// Re-inizializza modal (se necessario)
authModal.init()
```

### Proprietà

```javascript
// Verifica se modal è aperta
authModal.isOpen // true/false

// Accedi ai callback
authModal.onUserSelect
authModal.onOrganizationSelect
authModal.onLogin
```

---

## 📱 Responsive Design

La modal è completamente responsive:

- **Desktop**: Layout a due colonne
- **Mobile**: Layout a colonna singola
- **Tablet**: Layout adattivo

---

## ⌨️ Scorciatoie Tastiera

- **ESC** - Chiude la modal
- **Click fuori** - Chiude la modal

---

## 🧪 Test

### Test Manuale

1. Apri `/test-auth-modal.html` nel browser
2. Clicca "Apri Auth Modal"
3. Testa tutte le opzioni
4. Verifica animazioni e redirect

### Test con Dev Tools

```javascript
// Nella console del browser
window.authModal.open();           // Apri
window.authModal.close();          // Chiudi
console.log(window.authModal);     // Ispeziona oggetto
```

---

## 🐛 Troubleshooting

### Modal non appare

**Soluzione 1**: Verifica che i file siano inclusi

```html
<link rel="stylesheet" href="/assets/css/auth-modal.css">
<script src="/assets/js/auth-modal.js"></script>
```

**Soluzione 2**: Controlla la console per errori

```javascript
console.log('Auth Modal:', window.authModal);
```

**Soluzione 3**: Reinizializza manualmente

```javascript
window.authModal.init();
window.authModal.open();
```

### Modal appare ma non si chiude

Verifica che non ci siano errori JavaScript che bloccano gli event listeners.

### Animazioni non funzionano

Assicurati che il CSS sia caricato PRIMA del JavaScript.

---

## 📚 File Coinvolti

| File | Descrizione |
|------|-------------|
| `/assets/css/auth-modal.css` | Stili della modal |
| `/assets/js/auth-modal.js` | Logica della modal |
| `/assets/js/auth.js` | Helper functions per auth |
| `/test-auth-modal.html` | Pagina di test |

---

## 🎬 Demo

Visita `/test-auth-modal.html` per vedere la modal in azione!

---

## 📄 Licenza

Parte del progetto CDM86 Platform
