/**
 * AUTH MODAL - CDM86
 * Gestisce la modal per la scelta tra Utente e Azienda/Associazione
 */

class AuthModal {
    constructor() {
        this.modalHTML = `
            <div class="auth-modal-overlay" id="authModal">
                <div class="auth-modal">
                    <!-- Header -->
                    <div class="auth-modal-header">
                        <button class="auth-modal-close" id="authModalClose">
                            ×
                        </button>
                        <div class="auth-modal-icon">🔐</div>
                        <h2 class="auth-modal-title">Benvenuto su CDM86</h2>
                        <p class="auth-modal-subtitle">Scegli come vuoi accedere alla piattaforma</p>
                    </div>

                    <!-- Body -->
                    <div class="auth-modal-body">
                        <p class="auth-modal-description">
                            Registrati per accedere alle migliori promozioni convenzionate e guadagnare punti!
                        </p>

                        <!-- Options -->
                        <div class="auth-options">
                            <!-- Opzione Utente -->
                            <div class="auth-option" data-type="user">
                                <div class="auth-option-content">
                                    <span class="auth-option-icon">👤</span>
                                    <h3 class="auth-option-title">Sono un Utente</h3>
                                    <p class="auth-option-description">
                                        Accedi alle promozioni e guadagna punti con il sistema referral
                                    </p>
                                </div>
                            </div>

                            <!-- Opzione Azienda -->
                            <div class="auth-option" data-type="organization">
                                <span class="auth-option-badge">Partner</span>
                                <div class="auth-option-content">
                                    <span class="auth-option-icon">🏢</span>
                                    <h3 class="auth-option-title">Azienda/Associazione</h3>
                                    <p class="auth-option-description">
                                        Pubblica le tue promozioni e raggiungi migliaia di clienti
                                    </p>
                                </div>
                            </div>
                        </div>

                        <!-- Divider -->
                        <div class="auth-modal-divider">oppure</div>

                        <!-- Login -->
                        <div class="auth-modal-login">
                            <p>Hai già un account?</p>
                            <button class="auth-modal-login-btn" id="authModalLoginBtn">
                                <span>🔑</span>
                                Accedi
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        this.isOpen = false;
        this.onUserSelect = null;
        this.onOrganizationSelect = null;
        this.onLogin = null;
    }

    /**
     * Inizializza la modal (inserisce HTML nel DOM)
     */
    init() {
        // Rimuovi modal esistente se presente
        const existingModal = document.getElementById('authModal');
        if (existingModal) {
            existingModal.remove();
        }

        // Inserisci modal nel body
        document.body.insertAdjacentHTML('beforeend', this.modalHTML);

        // Aggiungi event listeners
        this.attachEventListeners();

        console.log('✅ Auth Modal initialized');
    }

    /**
     * Aggiungi event listeners
     */
    attachEventListeners() {
        const overlay = document.getElementById('authModal');
        const closeBtn = document.getElementById('authModalClose');
        const loginBtn = document.getElementById('authModalLoginBtn');
        const userOption = document.querySelector('[data-type="user"]');
        const orgOption = document.querySelector('[data-type="organization"]');

        // Chiudi modal cliccando overlay
        overlay.addEventListener('click', (e) => {
            if (e.target === overlay) {
                this.close();
            }
        });

        // Chiudi con bottone X
        closeBtn?.addEventListener('click', () => this.close());

        // Opzione Utente
        userOption?.addEventListener('click', () => {
            this.handleUserSelect();
        });

        // Opzione Azienda
        orgOption?.addEventListener('click', () => {
            this.handleOrganizationSelect();
        });

        // Bottone Login
        loginBtn?.addEventListener('click', () => {
            this.handleLogin();
        });

        // Chiudi con ESC
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && this.isOpen) {
                this.close();
            }
        });
    }

    /**
     * Apri modal
     */
    open() {
        const overlay = document.getElementById('authModal');
        if (!overlay) {
            this.init();
        }

        const modal = document.getElementById('authModal');
        if (modal) {
            setTimeout(() => {
                modal.classList.add('active');
                this.isOpen = true;
                document.body.style.overflow = 'hidden'; // Blocca scroll
            }, 10);
        }
    }

    /**
     * Chiudi modal
     */
    close() {
        const modal = document.getElementById('authModal');
        if (modal) {
            modal.classList.remove('active');
            this.isOpen = false;
            document.body.style.overflow = ''; // Ripristina scroll
        }
    }

    /**
     * Handler: Utente selezionato
     */
    handleUserSelect() {
        console.log('🙋 User registration selected');
        this.close();
        
        // Callback personalizzato o redirect default
        if (this.onUserSelect) {
            this.onUserSelect();
        } else {
            // Redirect alla pagina di registrazione utente
            window.location.href = '/public/register.html?type=user';
        }
    }

    /**
     * Handler: Azienda selezionata
     */
    handleOrganizationSelect() {
        console.log('🏢 Organization registration selected');
        this.close();
        
        // Callback personalizzato o redirect default
        if (this.onOrganizationSelect) {
            this.onOrganizationSelect();
        } else {
            // Redirect alla pagina di registrazione organizzazione
            window.location.href = '/public/register-organization.html';
        }
    }

    /**
     * Handler: Login selezionato
     */
    handleLogin() {
        console.log('🔑 Login selected');
        this.close();
        
        // Callback personalizzato o apri login modal
        if (this.onLogin) {
            this.onLogin();
        } else {
            // Apri il login modal invece di redirect
            if (window.LoginModal && window.LoginModal.open) {
                window.LoginModal.open();
            } else {
                console.error('Login modal not available');
                // Fallback: redirect
                window.location.href = '/public/promotions.html';
            }
        }
    }

    /**
     * Imposta callback per selezione utente
     */
    setOnUserSelect(callback) {
        this.onUserSelect = callback;
    }

    /**
     * Imposta callback per selezione organizzazione
     */
    setOnOrganizationSelect(callback) {
        this.onOrganizationSelect = callback;
    }

    /**
     * Imposta callback per login
     */
    setOnLogin(callback) {
        this.onLogin = callback;
    }
}

// Istanza globale
window.authModal = new AuthModal();

// Auto-inizializza quando il DOM è pronto
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        window.authModal.init();
    });
} else {
    window.authModal.init();
}

// Export per uso come modulo
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AuthModal;
}

console.log('✅ Auth Modal script loaded');
