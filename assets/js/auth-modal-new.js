/**
 * AUTH MODAL NEW - CDM86
 * Gestisce la modal per la scelta tra Utente e Azienda/Associazione
 * con richiesta contatto per aziende
 */

(function() {
    'use strict';

    console.log('Auth Modal Script: Starting initialization...');

    class AuthModalNew {
        constructor() {
            this.isOpen = false;
            this.initModal();
        }

        initModal() {
            // Aggiungi CSS
            this.addStyles();

            // Aggiungi HTML modal al body
            this.addModalHTML();

            // Setup event listeners
            this.setupEventListeners();

            console.log('✅ Auth Modal New initialized');
        }

        addStyles() {
            const styleId = 'auth-modal-styles';
            if (document.getElementById(styleId)) return;

            const styles = document.createElement('style');
            styles.id = styleId;
            styles.innerHTML = `
                .auth-modal-overlay {
                    display: none;
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    background: rgba(0, 0, 0, 0.7);
                    z-index: 9999;
                    align-items: center;
                    justify-content: center;
                }

                .auth-modal-overlay.active {
                    display: flex;
                }

                .auth-modal {
                    background: white;
                    border-radius: 20px;
                    padding: 40px;
                    max-width: 500px;
                    width: 90%;
                    max-height: 90vh;
                    overflow-y: auto;
                    box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                    animation: modalSlideIn 0.3s ease;
                }

                @keyframes modalSlideIn {
                    from {
                        opacity: 0;
                        transform: translateY(-50px);
                    }
                    to {
                        opacity: 1;
                        transform: translateY(0);
                    }
                }

                .auth-modal-header {
                    text-align: center;
                    margin-bottom: 30px;
                    position: relative;
                }

                .auth-modal-close {
                    position: absolute;
                    right: -20px;
                    top: -20px;
                    background: none;
                    border: none;
                    font-size: 32px;
                    color: #999;
                    cursor: pointer;
                    width: 40px;
                    height: 40px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    border-radius: 50%;
                    transition: all 0.3s;
                }

                .auth-modal-close:hover {
                    background: #f5f5f5;
                    color: #333;
                    transform: rotate(90deg);
                }

                .auth-modal-icon {
                    font-size: 48px;
                    margin-bottom: 15px;
                }

                .auth-modal-title {
                    color: #333;
                    font-size: 28px;
                    font-weight: bold;
                    margin: 0 0 10px 0;
                }

                .auth-modal-subtitle {
                    color: #666;
                    font-size: 16px;
                    margin: 0;
                }

                .auth-modal-description {
                    text-align: center;
                    color: #666;
                    margin-bottom: 30px;
                }

                .auth-options {
                    display: flex;
                    flex-direction: column;
                    gap: 15px;
                    margin-bottom: 20px;
                }

                .auth-option {
                    border: 2px solid #e0e0e0;
                    border-radius: 12px;
                    padding: 20px;
                    cursor: pointer;
                    transition: all 0.3s;
                    position: relative;
                }

                .auth-option:hover {
                    border-color: #667eea;
                    transform: translateY(-2px);
                    box-shadow: 0 5px 15px rgba(102, 126, 234, 0.2);
                }

                .auth-option-badge {
                    position: absolute;
                    top: 10px;
                    right: 10px;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    padding: 4px 10px;
                    border-radius: 20px;
                    font-size: 12px;
                    font-weight: bold;
                }

                .auth-option-content {
                    text-align: center;
                }

                .auth-option-icon {
                    font-size: 36px;
                    margin-bottom: 10px;
                }

                .auth-option-title {
                    font-size: 18px;
                    font-weight: bold;
                    color: #333;
                    margin: 10px 0;
                }

                .auth-option-description {
                    color: #666;
                    font-size: 14px;
                    margin: 0;
                }

                .auth-modal-divider {
                    text-align: center;
                    color: #999;
                    margin: 20px 0;
                    position: relative;
                }

                .auth-modal-divider::before,
                .auth-modal-divider::after {
                    content: '';
                    position: absolute;
                    top: 50%;
                    width: 45%;
                    height: 1px;
                    background: #e0e0e0;
                }

                .auth-modal-divider::before {
                    left: 0;
                }

                .auth-modal-divider::after {
                    right: 0;
                }

                .auth-modal-login {
                    text-align: center;
                }

                .auth-modal-login p {
                    color: #666;
                    margin-bottom: 10px;
                }

                .auth-modal-login-btn {
                    background: #f5f5f5;
                    border: none;
                    color: #333;
                    padding: 12px 30px;
                    border-radius: 8px;
                    font-size: 16px;
                    font-weight: 600;
                    cursor: pointer;
                    transition: all 0.3s;
                    display: inline-flex;
                    align-items: center;
                    gap: 8px;
                }

                .auth-modal-login-btn:hover {
                    background: #e0e0e0;
                    transform: translateY(-2px);
                }

                .auth-modal-step {
                    display: none;
                }

                .auth-modal-step.active {
                    display: block;
                }

                .auth-modal-back {
                    position: absolute;
                    left: -20px;
                    top: -20px;
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
                    box-sizing: border-box;
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
                    width: 100%;
                }

                .btn-primary:hover {
                    transform: translateY(-2px);
                    box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
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
            `;
            document.head.appendChild(styles);
        }

        addModalHTML() {
            // Remove existing modal if present
            const existingModal = document.getElementById('authModal');
            if (existingModal) {
                existingModal.remove();
            }

            const modalHTML = `
                <div class="auth-modal-overlay" id="authModal">
                    <div class="auth-modal" id="authModalContent">
                        <!-- Step 1: Scelta iniziale -->
                        <div class="auth-modal-step active" id="step-choice">
                            <div class="auth-modal-header">
                                <button class="auth-modal-close" id="closeModalBtn">×</button>
                                <div class="auth-modal-icon">🔐</div>
                                <h2 class="auth-modal-title">Benvenuto su CDM86</h2>
                                <p class="auth-modal-subtitle">Scegli come vuoi accedere alla piattaforma</p>
                            </div>

                            <div class="auth-modal-body">
                                <p class="auth-modal-description">
                                    Per accedere alle promozioni devi essere registrato
                                </p>

                                <div class="auth-options">
                                    <div class="auth-option" id="selectUser">
                                        <div class="auth-option-content">
                                            <span class="auth-option-icon">👤</span>
                                            <h3 class="auth-option-title">Sono un Utente</h3>
                                            <p class="auth-option-description">
                                                Accedi alle promozioni e guadagna punti con il sistema referral
                                            </p>
                                        </div>
                                    </div>

                                    <div class="auth-option" id="selectOrganization">
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

                                <div class="auth-modal-divider">oppure</div>

                                <div class="auth-modal-login">
                                    <p>Hai già un account?</p>
                                    <button class="auth-modal-login-btn" id="goToLogin">
                                        <span>🔑</span>
                                        Accedi
                                    </button>
                                </div>
                            </div>
                        </div>

                        <!-- Step 2: Form Richiesta Contatto Azienda -->
                        <div class="auth-modal-step" id="step-organization">
                            <div class="auth-modal-header">
                                <button class="auth-modal-close" id="closeModalBtn2">×</button>
                                <button class="auth-modal-back" id="backToChoice">← Indietro</button>
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

                                    <div class="form-group referral-question">
                                        <label class="checkbox-label">
                                            <input type="checkbox" id="org-has-referral">
                                            <span>Ho un codice referral</span>
                                        </label>
                                    </div>

                                    <div class="form-group" id="org-referral-group" style="display: none;">
                                        <label>Codice Referral</label>
                                        <input type="text" id="org-referral-code" placeholder="CODICE123" style="text-transform: uppercase;">
                                    </div>

                                    <div class="alert info" style="margin-top: 15px;">
                                        <strong>📞 Ti contatteremo entro 24 ore</strong><br>
                                        Un nostro operatore ti fornirà tutte le informazioni per diventare partner CDM86
                                    </div>

                                    <button type="submit" class="btn btn-primary" style="margin-top: 20px;">
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
                                    <button class="btn btn-primary" id="closeSuccessBtn" style="margin-top: 20px;">
                                        Chiudi
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            `;

            document.body.insertAdjacentHTML('beforeend', modalHTML);
        }

        setupEventListeners() {
            // Close buttons
            document.getElementById('closeModalBtn').addEventListener('click', () => this.close());
            document.getElementById('closeModalBtn2').addEventListener('click', () => this.close());

            // Click overlay to close
            document.getElementById('authModal').addEventListener('click', (e) => {
                if (e.target.id === 'authModal') {
                    this.close();
                }
            });

            // User option
            document.getElementById('selectUser').addEventListener('click', () => {
                this.close();
                window.location.href = '/index.html#register';
            });

            // Organization option
            document.getElementById('selectOrganization').addEventListener('click', () => {
                this.showStep('organization');
            });

            // Login button
            document.getElementById('goToLogin').addEventListener('click', () => {
                this.close();
                window.location.href = '/index.html';
            });

            // Back button
            document.getElementById('backToChoice').addEventListener('click', () => {
                this.showStep('choice');
            });

            // Referral checkbox
            document.getElementById('org-has-referral').addEventListener('change', (e) => {
                const referralGroup = document.getElementById('org-referral-group');
                if (e.target.checked) {
                    referralGroup.style.display = 'block';
                } else {
                    referralGroup.style.display = 'none';
                    document.getElementById('org-referral-code').value = '';
                }
            });

            // Form submit
            document.getElementById('organizationContactForm').addEventListener('submit', (e) => {
                e.preventDefault();
                this.submitOrganizationRequest();
            });

            // Close success
            const closeSuccessBtn = document.getElementById('closeSuccessBtn');
            if (closeSuccessBtn) {
                closeSuccessBtn.addEventListener('click', () => this.close());
            }
        }

        showStep(stepName) {
            document.querySelectorAll('.auth-modal-step').forEach(step => {
                step.classList.remove('active');
            });
            document.getElementById(`step-${stepName}`).classList.add('active');
        }

        open() {
            const modal = document.getElementById('authModal');
            if (!modal) {
                this.initModal();
            }

            // Reset to initial step
            this.showStep('choice');

            // Show modal
            document.getElementById('authModal').classList.add('active');
            document.body.style.overflow = 'hidden';
            this.isOpen = true;
        }

        close() {
            document.getElementById('authModal').classList.remove('active');
            document.body.style.overflow = '';
            this.isOpen = false;

            // Reset form
            const form = document.getElementById('organizationContactForm');
            if (form) form.reset();
            document.getElementById('org-referral-group').style.display = 'none';
        }

        async submitOrganizationRequest() {
            const form = document.getElementById('organizationContactForm');
            const loading = document.getElementById('org-loading');
            const success = document.getElementById('org-success');

            // Collect data
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

            // Show loading
            form.style.display = 'none';
            loading.style.display = 'block';

            try {
                // Initialize Supabase if available
                if (window.supabase) {
                    const { error } = await window.supabase
                        .from('organization_requests')
                        .insert([data]);

                    if (error) {
                        console.error('Error saving to database:', error);
                        // Continue anyway - we'll save locally
                    }
                }

                // Save to localStorage as backup
                const existingRequests = JSON.parse(localStorage.getItem('org_requests') || '[]');
                existingRequests.push(data);
                localStorage.setItem('org_requests', JSON.stringify(existingRequests));

                // Show success
                loading.style.display = 'none';
                success.style.display = 'block';

            } catch (error) {
                console.error('Error submitting organization request:', error);
                loading.style.display = 'none';
                form.style.display = 'block';
                alert('Si è verificato un errore. Riprova più tardi.');
            }
        }
    }

    // Create global instance when DOM is ready
    function initializeModal() {
        if (!window.authModalNew) {
            window.authModalNew = new AuthModalNew();
            console.log('✅ Auth Modal New loaded and ready');
            console.log('Modal instance:', window.authModalNew);
        }
    }

    // Initialize immediately if DOM is ready, otherwise wait
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initializeModal);
        console.log('Waiting for DOMContentLoaded to initialize modal...');
    } else {
        initializeModal();
    }
})();