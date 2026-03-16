/**
 * AUTH MODAL ENHANCED - CDM86
 * Gestisce la modal per la scelta tra Utente e Azienda/Associazione
 * con richiesta contatto per aziende
 */

import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

// Configurazione Supabase
const supabaseUrl = 'https://uchrjlngfzfibcpdxtky.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwMzEyMDYsImV4cCI6MjA3NTYwNzIwNn0.64JK3OhYJi2YtrErctNAp_sCcSHwB656NVLdooyceOM';
const supabase = createClient(supabaseUrl, supabaseKey);

class AuthModalEnhanced {
    constructor() {
        this.modalHTML = `
            <div class="auth-modal-overlay" id="authModal">
                <div class="auth-modal" id="authModalContent">
                    <!-- Step 1: Scelta iniziale -->
                    <div class="auth-modal-step" id="step-choice">
                        <!-- Header -->
                        <div class="auth-modal-header">
                            <button class="auth-modal-close" onclick="authModalEnhanced.close()">
                                ×
                            </button>
                            <div class="auth-modal-icon">🔐</div>
                            <h2 class="auth-modal-title">Benvenuto su CDM86</h2>
                            <p class="auth-modal-subtitle">Scegli come vuoi accedere alla piattaforma</p>
                        </div>

                        <!-- Body -->
                        <div class="auth-modal-body">
                            <p class="auth-modal-description">
                                Per accedere alle promozioni devi essere registrato
                            </p>

                            <!-- Options -->
                            <div class="auth-options">
                                <!-- Opzione Utente -->
                                <div class="auth-option" onclick="authModalEnhanced.selectUser()">
                                    <div class="auth-option-content">
                                        <span class="auth-option-icon">👤</span>
                                        <h3 class="auth-option-title">Sono un Utente</h3>
                                        <p class="auth-option-description">
                                            Accedi alle promozioni e guadagna punti con il sistema referral
                                        </p>
                                    </div>
                                </div>

                                <!-- Opzione Azienda -->
                                <div class="auth-option" onclick="authModalEnhanced.selectOrganization()">
                                    <span class="auth-option-badge">Partner</span>
                                    <div class="auth-option-content">
                                        <span class="auth-option-icon">🏢</span>
                                        <h3 class="auth-option-title">Azienda/Associazione</h3>
                                        <p class="auth-option-description">
                                            Richiedi informazioni per pubblicare le tue promozioni
                                        </p>
                                    </div>
                                </div>
                            </div>

                            <!-- Divider -->
                            <div class="auth-modal-divider">oppure</div>

                            <!-- Login -->
                            <div class="auth-modal-login">
                                <p>Hai già un account?</p>
                                <button class="auth-modal-login-btn" onclick="authModalEnhanced.goToLogin()">
                                    <span>🔑</span>
                                    Accedi
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Step 2: Form Richiesta Contatto Azienda -->
                    <div class="auth-modal-step" id="step-organization" style="display: none;">
                        <div class="auth-modal-header">
                            <button class="auth-modal-close" onclick="authModalEnhanced.close()">
                                ×
                            </button>
                            <button class="auth-modal-back" onclick="authModalEnhanced.backToChoice()">
                                ← Indietro
                            </button>
                            <div class="auth-modal-icon">🏢</div>
                            <h2 class="auth-modal-title">Richiesta Informazioni Partner</h2>
                            <p class="auth-modal-subtitle">Compila il form per essere contattato</p>
                        </div>

                        <div class="auth-modal-body">
                            <form id="organizationContactForm">
                                <div class="form-group">
                                    <label>Nome Azienda/Associazione *</label>
                                    <input type="text" id="org-name" required placeholder="Nome della tua attività">
                                </div>

                                <div class="form-group">
                                    <label>Referente *</label>
                                    <input type="text" id="org-contact-name" required placeholder="Nome e Cognome">
                                </div>

                                <div class="form-group">
                                    <label>Email *</label>
                                    <input type="email" id="org-email" required placeholder="email@azienda.it">
                                </div>

                                <div class="form-group">
                                    <label>Telefono *</label>
                                    <input type="tel" id="org-phone" required placeholder="+39 123 456 7890">
                                </div>

                                <div class="form-group">
                                    <label>Tipo di Attività *</label>
                                    <select id="org-type" required>
                                        <option value="">Seleziona...</option>
                                        <option value="restaurant">Ristorante/Bar</option>
                                        <option value="shop">Negozio</option>
                                        <option value="service">Servizi</option>
                                        <option value="health">Salute e Benessere</option>
                                        <option value="entertainment">Intrattenimento</option>
                                        <option value="association">Associazione</option>
                                        <option value="other">Altro</option>
                                    </select>
                                </div>

                                <div class="form-group">
                                    <label>Messaggio (opzionale)</label>
                                    <textarea id="org-message" rows="3" placeholder="Informazioni aggiuntive..."></textarea>
                                </div>

                                <!-- Domanda Referral -->
                                <div class="form-group referral-question">
                                    <label class="checkbox-label">
                                        <input type="checkbox" id="org-has-referral" onchange="authModalEnhanced.toggleReferralInput()">
                                        <span>Ho un codice referral</span>
                                    </label>
                                </div>

                                <!-- Campo Referral (nascosto di default) -->
                                <div class="form-group" id="org-referral-group" style="display: none;">
                                    <label>Codice Referral</label>
                                    <input type="text" id="org-referral-code" placeholder="CODICE123" style="text-transform: uppercase;">
                                </div>

                                <div class="alert info" style="margin-top: 15px;">
                                    <strong>📞 Ti contatteremo entro 24 ore</strong><br>
                                    Un nostro operatore ti fornirà tutte le informazioni per diventare partner CDM86
                                </div>

                                <button type="submit" class="btn btn-primary" style="width: 100%; margin-top: 20px;">
                                    Invia Richiesta
                                </button>
                            </form>

                            <div class="loading" id="org-loading" style="display: none;">
                                <div class="spinner"></div>
                                <p>Invio richiesta in corso...</p>
                            </div>

                            <div class="success-message" id="org-success" style="display: none;">
                                <div class="icon">✅</div>
                                <h3>Richiesta Inviata!</h3>
                                <p>Ti contatteremo presto all'indirizzo email fornito.</p>
                                <button class="btn btn-primary" onclick="authModalEnhanced.close()" style="margin-top: 20px;">
                                    Chiudi
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;

        // Aggiungi stili CSS specifici
        this.styles = `
            <style>
                .auth-modal-back {
                    position: absolute;
                    left: 20px;
                    top: 20px;
                    background: none;
                    border: none;
                    color: #667eea;
                    font-size: 16px;
                    cursor: pointer;
                    display: flex;
                    align-items: center;
                    gap: 5px;
                    transition: all 0.3s;
                }

                .auth-modal-back:hover {
                    transform: translateX(-5px);
                }

                .form-group {
                    margin-bottom: 15px;
                }

                .form-group label {
                    display: block;
                    margin-bottom: 5px;
                    font-weight: 600;
                    color: #333;
                    font-size: 14px;
                }

                .form-group input,
                .form-group select,
                .form-group textarea {
                    width: 100%;
                    padding: 12px;
                    border: 2px solid #e0e0e0;
                    border-radius: 8px;
                    font-size: 14px;
                    transition: all 0.3s;
                }

                .form-group input:focus,
                .form-group select:focus,
                .form-group textarea:focus {
                    outline: none;
                    border-color: #667eea;
                }

                .checkbox-label {
                    display: flex;
                    align-items: center;
                    gap: 8px;
                    cursor: pointer;
                }

                .checkbox-label input[type="checkbox"] {
                    width: auto;
                    cursor: pointer;
                }

                .alert {
                    padding: 12px;
                    border-radius: 8px;
                    font-size: 13px;
                }

                .alert.info {
                    background: #d1ecf1;
                    color: #0c5460;
                    border: 1px solid #bee5eb;
                }

                .loading {
                    text-align: center;
                    padding: 20px;
                }

                .spinner {
                    border: 3px solid #f3f3f3;
                    border-top: 3px solid #667eea;
                    border-radius: 50%;
                    width: 40px;
                    height: 40px;
                    animation: spin 1s linear infinite;
                    margin: 0 auto;
                }

                @keyframes spin {
                    0% { transform: rotate(0deg); }
                    100% { transform: rotate(360deg); }
                }

                .success-message {
                    text-align: center;
                    padding: 30px;
                }

                .success-message .icon {
                    font-size: 60px;
                    margin-bottom: 20px;
                }

                .success-message h3 {
                    color: #667eea;
                    margin-bottom: 10px;
                }

                .btn {
                    padding: 12px 24px;
                    border: none;
                    border-radius: 8px;
                    font-size: 16px;
                    font-weight: 600;
                    cursor: pointer;
                    transition: all 0.3s;
                }

                .btn-primary {
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                }

                .btn-primary:hover {
                    transform: translateY(-2px);
                    box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
                }
            </style>
        `;

        this.isOpen = false;
    }

    /**
     * Inizializza la modal
     */
    init() {
        // Rimuovi modal esistente se presente
        const existingModal = document.getElementById('authModal');
        if (existingModal) {
            existingModal.remove();
        }

        // Rimuovi stili esistenti
        const existingStyles = document.getElementById('auth-modal-styles');
        if (existingStyles) {
            existingStyles.remove();
        }

        // Inserisci stili
        const styleElement = document.createElement('div');
        styleElement.id = 'auth-modal-styles';
        styleElement.innerHTML = this.styles;
        document.head.appendChild(styleElement);

        // Inserisci modal nel body
        document.body.insertAdjacentHTML('beforeend', this.modalHTML);

        // Setup form handler
        this.setupFormHandler();

        console.log('✅ Auth Modal Enhanced initialized');
    }

    /**
     * Setup form handler per richiesta contatto azienda
     */
    setupFormHandler() {
        const form = document.getElementById('organizationContactForm');
        if (form) {
            form.addEventListener('submit', async (e) => {
                e.preventDefault();
                await this.submitOrganizationRequest();
            });
        }
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
            // Reset to initial step
            this.showStep('choice');

            setTimeout(() => {
                modal.classList.add('active');
                this.isOpen = true;
                document.body.style.overflow = 'hidden';
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
            document.body.style.overflow = '';
        }
    }

    /**
     * Mostra uno step specifico
     */
    showStep(stepName) {
        // Nascondi tutti gli step
        document.querySelectorAll('.auth-modal-step').forEach(step => {
            step.style.display = 'none';
        });

        // Mostra lo step richiesto
        const step = document.getElementById(`step-${stepName}`);
        if (step) {
            step.style.display = 'block';
        }
    }

    /**
     * Torna alla scelta iniziale
     */
    backToChoice() {
        this.showStep('choice');
        // Reset form
        const form = document.getElementById('organizationContactForm');
        if (form) form.reset();
        document.getElementById('org-referral-group').style.display = 'none';
    }

    /**
     * Utente selezionato - vai alla registrazione classica
     */
    selectUser() {
        this.close();
        window.location.href = '/index.html#register';
    }

    /**
     * Azienda selezionata - mostra form richiesta contatto
     */
    selectOrganization() {
        this.showStep('organization');
    }

    /**
     * Vai al login
     */
    goToLogin() {
        this.close();
        window.location.href = '/index.html';
    }

    /**
     * Toggle campo referral
     */
    toggleReferralInput() {
        const checkbox = document.getElementById('org-has-referral');
        const referralGroup = document.getElementById('org-referral-group');

        if (checkbox.checked) {
            referralGroup.style.display = 'block';
        } else {
            referralGroup.style.display = 'none';
            document.getElementById('org-referral-code').value = '';
        }
    }

    /**
     * Invia richiesta contatto azienda
     */
    async submitOrganizationRequest() {
        const form = document.getElementById('organizationContactForm');
        const loading = document.getElementById('org-loading');
        const success = document.getElementById('org-success');

        // Raccogli dati
        const data = {
            organization_name: document.getElementById('org-name').value,
            contact_name: document.getElementById('org-contact-name').value,
            email: document.getElementById('org-email').value,
            phone: document.getElementById('org-phone').value,
            business_type: document.getElementById('org-type').value,
            message: document.getElementById('org-message').value,
            has_referral: document.getElementById('org-has-referral').checked,
            referral_code: document.getElementById('org-has-referral').checked ?
                          document.getElementById('org-referral-code').value.toUpperCase() : null,
            status: 'pending',
            created_at: new Date().toISOString()
        };

        // Mostra loading
        form.style.display = 'none';
        loading.style.display = 'block';

        try {
            // Salva richiesta nel database
            const { error } = await supabase
                .from('organization_requests')
                .insert([data]);

            if (error) {
                // Se la tabella non esiste, proviamo a crearla e riprovare
                if (error.code === '42P01') {
                    console.log('Creating organization_requests table...');
                    // La tabella verrà creata automaticamente dal pannello admin
                    // Per ora salviamo in una tabella generica o mostriamo successo

                    // Prova a salvare in una tabella notifications o logs se esiste
                    const { error: notifError } = await supabase
                        .from('admin_notifications')
                        .insert([{
                            type: 'organization_request',
                            data: JSON.stringify(data),
                            created_at: new Date().toISOString()
                        }]);

                    if (notifError) {
                        console.error('Error saving notification:', notifError);
                    }
                }
                throw error;
            }

            // Mostra successo
            loading.style.display = 'none';
            success.style.display = 'block';

            // Invia notifica email (opzionale)
            // await this.sendEmailNotification(data);

        } catch (error) {
            console.error('Error submitting organization request:', error);
            loading.style.display = 'none';
            form.style.display = 'block';
            alert('Si è verificato un errore. Riprova più tardi.');
        }
    }
}

// Istanza globale
window.authModalEnhanced = new AuthModalEnhanced();

// Auto-inizializza quando il DOM è pronto
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        window.authModalEnhanced.init();
    });
} else {
    window.authModalEnhanced.init();
}

// Export per uso come modulo
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AuthModalEnhanced;
}

console.log('✅ Auth Modal Enhanced loaded');