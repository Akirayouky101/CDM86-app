/* ============================================
   LOGIN MODAL HANDLER - CDM86
   Gestisce login/registrazione nell'homepage
   ============================================ */

// Wait for Supabase to be initialized
function getSupabase() {
    return new Promise((resolve) => {
        const check = () => {
            if (window.supabaseClient) {
                console.log('✅ Supabase client found');
                resolve(window.supabaseClient);
            } else {
                console.warn('⚠️ Waiting for Supabase client...');
                setTimeout(check, 100);
            }
        };
        
        // Listen for supabase-ready event
        window.addEventListener('supabase-ready', () => {
            if (window.supabaseClient) {
                resolve(window.supabaseClient);
            }
        }, { once: true });
        
        // Also check immediately
        check();
    });
}

// Global supabase instance (will be set after initialization)
let supabaseInstance = null;

// Initialize supabase
(async () => {
    console.log('🔄 LoginModal: Initializing Supabase...');
    supabaseInstance = await getSupabase();
    console.log('✅ LoginModal: Supabase ready');
})();

// Helper to ensure supabase is ready
async function ensureSupabase() {
    if (!supabaseInstance) {
        console.log('⏳ ensureSupabase: Getting instance...');
        supabaseInstance = await getSupabase();
    }
    return supabaseInstance;
}

// Variabili globali
let currentWizardStep = 1;
let companyHasReferral = false;

// ==========================================
// SELECTION MODAL (Prima schermata)
// ==========================================

function showSelectionModal() {
    const overlay = document.getElementById('selectionModalOverlay');
    if (overlay) {
        overlay.classList.add('active');
        document.body.style.overflow = 'hidden';
    }
}

function closeSelectionModal() {
    const overlay = document.getElementById('selectionModalOverlay');
    if (overlay) {
        overlay.classList.remove('active');
        document.body.style.overflow = '';
    }
}

function selectUser() {
    closeSelectionModal();
    showReferralModal();
}

function selectCompany() {
    closeSelectionModal();
    OrgRegWizard.open();
}

function showExistingUserLogin() {
    closeSelectionModal();
    showLoginModal();
}

// ==========================================
// COMPANY REQUEST MODAL
// ==========================================

function showCompanyRequestModal() {
    if (typeof CompanyWizard !== 'undefined') {
        CompanyWizard.open();
    } else {
        // Fallback se CompanyWizard non è ancora disponibile
        const overlay = document.getElementById('companyRequestModalOverlay');
        if (overlay) overlay.classList.add('active');
    }
}

function closeCompanyRequestModal() {
    const overlay = document.getElementById('companyRequestModalOverlay');
    if (overlay) {
        overlay.classList.remove('active');
        document.getElementById('companyRequestForm')?.reset();
        document.getElementById('companyRequestFormNoRef')?.reset();
    }
}

function companyHasReferralYes() {
    document.getElementById('companyReferralQuestion').style.display = 'none';
    document.getElementById('companyFormWithReferral').classList.add('active');
    companyHasReferral = true;
}

function companyHasReferralNo() {
    document.getElementById('companyReferralQuestion').style.display = 'none';
    document.getElementById('companyFormWithoutReferral').classList.add('active');
    companyHasReferral = false;
}

// ==========================================
// COMPANY REQUEST SUBMISSION
// ==========================================

async function handleCompanyRequest(event) {
    event.preventDefault();

    const loading = document.getElementById('companyRequestLoading');
    const form = document.getElementById('companyRequestForm');

    if (!form || !loading) return;

    form.style.display = 'none';
    loading.classList.add('show');

    try {
        const organizationName = document.getElementById('companyOrgName').value.trim();
        const firstName = document.getElementById('companyFirstName').value.trim();
        const lastName = document.getElementById('companyLastName').value.trim();
        const email = document.getElementById('companyEmail').value.trim();
        const phone = document.getElementById('companyPhone').value.trim();
        const referralCode = document.getElementById('companyReferralCode').value.toUpperCase().trim();

        // Valida referral code
        const { data: referrerData, error: referrerError } = await supabase
            .rpc('create_organization_request', {
                p_referred_by_code: referralCode,
                p_organization_name: organizationName,
                p_contact_first_name: firstName,
                p_contact_last_name: lastName,
                p_contact_email: email,
                p_contact_phone: phone
            });

        if (referrerError) throw referrerError;

        showAlert('✅ Richiesta inviata con successo! Verrai contattato a breve.', 'success');

        setTimeout(() => {
            closeCompanyRequestModal();
            form.reset();
        }, 2000);

    } catch (error) {
        console.error('Company request error:', error);
        showAlert(error.message || 'Errore durante l\'invio della richiesta');
        form.style.display = 'block';
        loading.classList.remove('show');
    }
}

async function handleCompanyRequestNoRef(event) {
    event.preventDefault();

    const loading = document.getElementById('companyRequestLoadingNoRef');
    const form = document.getElementById('companyRequestFormNoRef');

    if (!form || !loading) return;

    form.style.display = 'none';
    loading.classList.add('show');

    try {
        const organizationName = document.getElementById('companyOrgNameNoRef').value.trim();
        const firstName = document.getElementById('companyFirstNameNoRef').value.trim();
        const lastName = document.getElementById('companyLastNameNoRef').value.trim();
        const email = document.getElementById('companyEmailNoRef').value.trim();
        const phone = document.getElementById('companyPhoneNoRef').value.trim();

        // Invia email di richiesta contatto
        const subject = encodeURIComponent('Richiesta Contatto Azienda - CDM86');
        const body = encodeURIComponent(`Nuova richiesta di contatto da un'azienda:

Organizzazione: ${organizationName}
Nome Referente: ${firstName} ${lastName}
Email: ${email}
Telefono: ${phone}

L'azienda NON ha un codice referral.`);

        // Invia anche al database (senza referral)
        const { error } = await supabase
            .from('organization_requests')
            .insert({
                organization_name: organizationName,
                contact_first_name: firstName,
                contact_last_name: lastName,
                contact_email: email,
                contact_phone: phone,
                referred_by_id: null,
                referred_by_code: null,
                status: 'pending'
            });

        if (error) throw error;

        showAlert('✅ Richiesta inviata! Ti contatteremo presto.', 'success');

        // Apri client email
        window.location.href = `mailto:referralcdm86@appdataconnect.it?subject=${subject}&body=${body}`;

        setTimeout(() => {
            closeCompanyRequestModal();
            form.reset();
        }, 2000);

    } catch (error) {
        console.error('Company request error:', error);
        showAlert(error.message || 'Errore durante l\'invio della richiesta');
        form.style.display = 'block';
        loading.classList.remove('show');
    }
}

// ==========================================
// MODAL MANAGEMENT
// ==========================================

function showLoginModal() {
    const overlay = document.getElementById('loginModalOverlay');
    if (overlay) {
        overlay.classList.add('active');
        document.body.style.overflow = 'hidden';
    }
}

function closeLoginModal() {
    const overlay = document.getElementById('loginModalOverlay');
    if (overlay) {
        overlay.classList.remove('active');
        document.body.style.overflow = '';
    }
}

function showReferralModal() {
    const overlay = document.getElementById('referralModalOverlay');
    if (overlay) {
        overlay.classList.add('active');
        document.getElementById('referralModalQuestion').style.display = 'block';
        document.getElementById('referralModalWizard').classList.remove('active');
        currentWizardStep = 1;
    }
}

function closeReferralModal() {
    const overlay = document.getElementById('referralModalOverlay');
    if (overlay) {
        overlay.classList.remove('active');
    }
}

// ==========================================
// TAB SWITCHING
// ==========================================

function switchLoginTab(tabName) {
    // Se si clicca su "Registrati", mostra il modal referral
    if (tabName === 'register') {
        closeLoginModal();
        showReferralModal();
        return;
    }

    // Aggiorna tabs
    document.querySelectorAll('.login-tab').forEach(tab => {
        tab.classList.remove('active');
        if (tab.dataset.tab === tabName) {
            tab.classList.add('active');
        }
    });

    // Aggiorna panels
    document.querySelectorAll('.login-form-panel').forEach(panel => {
        panel.classList.remove('active');
        if (panel.id === `${tabName}Panel`) {
            panel.classList.add('active');
        }
    });

    hideAlert();
}

// ==========================================
// REFERRAL MODAL HANDLERS
// ==========================================

function handleHasCode() {
    closeReferralModal();
    showLoginModal();
    // Attiva il tab di registrazione
    document.querySelectorAll('.login-tab').forEach(tab => {
        tab.classList.remove('active');
        if (tab.dataset.tab === 'register') {
            tab.classList.add('active');
        }
    });
    document.querySelectorAll('.login-form-panel').forEach(panel => {
        panel.classList.remove('active');
    });
    document.getElementById('registerPanel').classList.add('active');
    // Inizializza/resetta wizard al primo step
    _rwStep = 1;
    rwUpdateUI('next');
}

function showWizard() {
    document.getElementById('referralModalQuestion').style.display = 'none';
    document.getElementById('referralModalWizard').classList.add('active');
    currentWizardStep = 1;
    updateWizardStep();
}

function updateWizardStep() {
    // Update progress bar
    for (let i = 1; i <= 3; i++) {
        const progress = document.getElementById(`refWizardProgress${i}`);
        if (progress) {
            if (i <= currentWizardStep) {
                progress.classList.add('active');
            } else {
                progress.classList.remove('active');
            }
        }
    }

    // Update step content — solo quelli del referral wizard
    const refWizard = document.getElementById('referralModalWizard');
    if (refWizard) {
        refWizard.querySelectorAll('.wizard-step-content').forEach(step => {
            step.classList.remove('active');
        });
    }

    if (currentWizardStep === 4) {
        document.getElementById('refWizardStepSuccess').classList.add('active');
        document.getElementById('refWizardBtnBack').style.display = 'none';
        document.getElementById('refWizardBtnNext').textContent = 'Chiudi';
    } else {
        const currentStep = document.getElementById(`refWizardStep${currentWizardStep}`);
        if (currentStep) {
            currentStep.classList.add('active');
        }
        document.getElementById('refWizardBtnBack').style.display = currentWizardStep === 1 ? 'none' : 'block';
        document.getElementById('refWizardBtnNext').textContent = currentWizardStep === 3 ? 'Invia' : 'Avanti';
    }
}

function wizardBack() {
    if (currentWizardStep > 1) {
        currentWizardStep--;
        updateWizardStep();
    }
}

function wizardNext() {
    if (currentWizardStep === 4) {
        closeReferralModal();
        return;
    }

    // Validazione
    if (currentWizardStep === 1) {
        const firstname = document.getElementById('refWizardFirstname').value.trim();
        const lastname = document.getElementById('refWizardLastname').value.trim();
        if (!firstname || !lastname) {
            alert('Inserisci nome e cognome');
            return;
        }
    } else if (currentWizardStep === 2) {
        const email = document.getElementById('refWizardEmail').value.trim();
        if (!email || !email.includes('@')) {
            alert('Inserisci una email valida');
            return;
        }
    } else if (currentWizardStep === 3) {
        // Conferma e invia
        const firstname = document.getElementById('refWizardFirstname').value.trim();
        const lastname = document.getElementById('refWizardLastname').value.trim();
        const email = document.getElementById('refWizardEmail').value.trim();

        document.getElementById('refWizardConfirmName').textContent = `${firstname} ${lastname}`;
        document.getElementById('refWizardConfirmEmail').textContent = email;

        // Invia richiesta
        sendReferralRequest(firstname, lastname, email);
        currentWizardStep++;
        updateWizardStep();
        return;
    }

    currentWizardStep++;
    updateWizardStep();

    // Se siamo allo step 3, popola i dati di conferma
    if (currentWizardStep === 3) {
        const firstname = document.getElementById('refWizardFirstname').value.trim();
        const lastname = document.getElementById('refWizardLastname').value.trim();
        const email = document.getElementById('refWizardEmail').value.trim();
        document.getElementById('refWizardConfirmName').textContent = `${firstname} ${lastname}`;
        document.getElementById('refWizardConfirmEmail').textContent = email;
    }
}

function sendReferralRequest(firstName, lastName, email) {
    const subject = encodeURIComponent('Richiesta Codice Referral - CDM86');
    const body = encodeURIComponent(`Nuova richiesta di codice referral:

Nome: ${firstName} ${lastName}
Email: ${email}

Per favore, invia un codice referral a questo utente.`);

    window.location.href = `mailto:referralcdm86@appdataconnect.it?subject=${subject}&body=${body}`;
}

// ==========================================
// ALERT MANAGEMENT
// ==========================================

function showAlert(message, type = 'error') {
    const alert = document.getElementById('loginAlert');
    if (alert) {
        alert.textContent = message;
        alert.className = `form-alert ${type} show`;
        setTimeout(() => hideAlert(), 5000);
    }
}

function hideAlert() {
    const alert = document.getElementById('loginAlert');
    if (alert) {
        alert.classList.remove('show');
    }
}

// ==========================================
// LOGIN HANDLER
// ==========================================

async function handleLogin(event) {
    event.preventDefault();
    
    // Ensure Supabase is ready
    const sb = await ensureSupabase();

    const email = document.getElementById('loginEmail').value.trim();
    const password = document.getElementById('loginPassword').value;

    const loading = document.getElementById('loginLoading');
    const form = document.getElementById('loginForm');

    if (form && loading) {
        form.style.display = 'none';
        loading.classList.add('show');
    }

    try {
        const { data, error } = await sb.auth.signInWithPassword({
            email: email,
            password: password
        });

        if (error) throw error;

        if (data.user) {
            showAlert('✅ Login effettuato! Reindirizzamento...', 'success');

            // Check if user is an organization
            const { data: orgData } = await sb
                .from('organizations')
                .select('id, name')
                .eq('auth_user_id', data.user.id)
                .maybeSingle();

            // Check user role
            const { data: userData } = await sb
                .from('users')
                .select('role')
                .eq('auth_user_id', data.user.id)
                .maybeSingle();

            // Check if user is a collaborator — redirect to cdm86.io
            const { data: collabData } = await sb
                .from('collaborators')
                .select('id')
                .eq('auth_user_id', data.user.id)
                .maybeSingle();

            // Redirect based on user type
            setTimeout(() => {
                if (collabData) {
                    // It's a collaborator — send to dedicated portal
                    console.log('✅ Collaborator login — redirecting to collaborator dashboard');
                    window.location.href = '/public/collaborator-dashboard.html';
                } else if (orgData) {
                    // It's an organization
                    console.log('✅ Organization login:', orgData.name);
                    window.location.href = '/public/dashboard.html';
                } else if (userData && userData.role === 'admin') {
                    // It's an admin user
                    console.log('✅ Admin login');
                    window.location.href = '/public/admin-panel.html';
                } else {
                    // It's a regular user
                    console.log('✅ User login');
                    window.location.href = '/public/promotions.html';
                }
            }, 1500);
        }
    } catch (error) {
        console.error('Login error:', error);
        showAlert(error.message || 'Errore di connessione');
        if (form && loading) {
            form.style.display = 'block';
            loading.classList.remove('show');
        }
    }
}

// ==========================================
// REGISTER HANDLER (legacy — ora gestito da rwSubmit)
// ==========================================

async function handleRegister(event) {
    if (event) event.preventDefault();
    return rwSubmit();
}

// ==========================================
// CHECK IF USER IS LOGGED IN
// ==========================================

async function checkAuthStatus() {
    const sb = await ensureSupabase();
    const { data: { session } } = await sb.auth.getSession();
    
    const loginBtn = document.getElementById('login-btn');
    if (!loginBtn) return;

    if (session && session.user) {
        // User is logged in
        const { data: userData } = await sb
            .from('users')
            .select('first_name, last_name')
            .eq('auth_user_id', session.user.id)
            .single();

        const firstName = userData?.first_name || 'User';
        
        loginBtn.innerHTML = `
            <i class="fas fa-user-circle"></i>
            <span>${firstName}</span>
        `;
        
        loginBtn.onclick = () => {
            window.location.href = '/public/promotions.html';
        };
    } else {
        // User not logged in - show selection modal
        loginBtn.onclick = () => {
            showSelectionModal();
        };
    }
}

// ==========================================
// FORGOT PASSWORD HANDLER
// ==========================================

function showForgotPassword(event) {
    event.preventDefault();
    
    // Chiudi login modal
    closeLoginModal();
    
    // Apri forgot password modal
    const overlay = document.getElementById('forgotPasswordOverlay');
    if (overlay) {
        overlay.classList.add('active');
        document.body.style.overflow = 'hidden';
        
        // Focus sull'input email
        setTimeout(() => {
            const emailInput = document.getElementById('forgotPasswordEmail');
            if (emailInput) emailInput.focus();
        }, 300);
    }
}

function closeForgotPassword() {
    const overlay = document.getElementById('forgotPasswordOverlay');
    if (overlay) {
        overlay.classList.remove('active');
        document.body.style.overflow = '';
        
        // Reset form
        const form = document.getElementById('forgotPasswordForm');
        if (form) form.reset();
    }
}

async function handleForgotPassword(event) {
    event.preventDefault();
    
    const emailInput = document.getElementById('forgotPasswordEmail');
    const email = emailInput.value.trim();
    
    if (!email) {
        showLoginAlert('❌ Inserisci un\'email valida', 'error');
        return false;
    }
    
    try {
        // Disabilita il form durante l'invio
        const submitBtn = event.target.querySelector('button[type="submit"]');
        const originalText = submitBtn.textContent;
        submitBtn.disabled = true;
        submitBtn.textContent = 'Invio in corso...';
        
        // Assicurati che supabase sia pronto
        const sb = await ensureSupabase();
        
        // Invia email di recupero password
        const { error } = await sb.auth.resetPasswordForEmail(email, {
            redirectTo: `${window.location.origin}/public/reset-password.html`
        });
        
        if (error) throw error;
        
        // Chiudi modale e mostra successo
        closeForgotPassword();
        
        // Riapri login modal con messaggio di successo
        setTimeout(() => {
            showLoginModal();
            showLoginAlert(`✅ Email inviata! Controlla la tua casella di posta (${email})`, 'success');
        }, 300);
        
    } catch (error) {
        console.error('Forgot password error:', error);
        showLoginAlert(`❌ Errore: ${error.message}`, 'error');
        
        // Riabilita il pulsante
        const submitBtn = event.target.querySelector('button[type="submit"]');
        submitBtn.disabled = false;
        submitBtn.textContent = 'Invia Email';
    }
    
    return false;
}

// ==========================================
// VALIDAZIONE FORM REGISTRAZIONE
// ==========================================

function setFieldState(inputEl, errorEl, msg) {
    if (!inputEl) return;
    if (msg) {
        inputEl.classList.remove('input-ok');
        inputEl.classList.add('input-err');
        if (errorEl) errorEl.textContent = msg;
    } else {
        inputEl.classList.remove('input-err');
        inputEl.classList.add('input-ok');
        if (errorEl) errorEl.textContent = '';
    }
}

function clearFieldState(inputEl, errorEl) {
    if (!inputEl) return;
    inputEl.classList.remove('input-ok', 'input-err');
    if (errorEl) errorEl.textContent = '';
}

function checkCFLive(input) {
    const cf = input.value.toUpperCase().trim();
    const statusEl = document.getElementById('cfStatus');
    const errEl = document.getElementById('err-cf');
    const nextBtn = document.getElementById('rwNextFromCF');
    const cfOkBox = document.getElementById('rwCFOk');
    const cfOkSummary = document.getElementById('rwCFOkSummary');

    input.value = cf; // forza maiuscolo
    if (cfOkBox) cfOkBox.style.display = 'none';
    if (nextBtn) nextBtn.disabled = true;

    if (cf.length === 0) {
        if (statusEl) statusEl.textContent = '';
        input.classList.remove('input-ok', 'input-err');
        if (errEl) errEl.textContent = '';
        return;
    }

    if (cf.length < 16) {
        if (statusEl) statusEl.textContent = '';
        input.classList.remove('input-ok', 'input-err');
        if (errEl) errEl.textContent = `${cf.length}/16 caratteri`;
        return;
    }

    // CF a 16 caratteri: valida formato base con regex
    const cfRegex = /^[A-Z]{6}[0-9LMNPQRSTUV]{2}[ABCDEHLMPRST]{1}[0-9LMNPQRSTUV]{2}[A-Z]{1}[0-9LMNPQRSTUV]{3}[A-Z]{1}$/;
    if (!cfRegex.test(cf)) {
        if (statusEl) statusEl.textContent = '❌';
        setFieldState(input, errEl, 'Formato codice fiscale non valido');
        return;
    }

    // Formato ok — valida incrociato con nome/cognome/data/sesso se disponibili
    const firstName = document.getElementById('registerFirstname')?.value.trim() || '';
    const lastName  = document.getElementById('registerLastname')?.value.trim() || '';
    const birthdate = document.getElementById('registerBirthdate')?.value || '';
    const sesso     = document.getElementById('registerSex')?.value || '';

    if (firstName && lastName && birthdate && sesso) {
        const dataNascita = new Date(birthdate);
        const validation = CodiceFiscale.valida(cf, firstName, lastName, dataNascita, sesso);
        if (validation.valid) {
            if (statusEl) statusEl.textContent = '✅';
            setFieldState(input, errEl, null);
            // Mostra box inline "verificato" e abilita Avanti
            const sessoLabel = sesso === 'M' ? 'Maschio' : 'Femmina';
            const dataFmt = new Date(birthdate).toLocaleDateString('it-IT', { day: '2-digit', month: 'long', year: 'numeric' });
            if (cfOkSummary) cfOkSummary.textContent = `${firstName} ${lastName} · ${dataFmt} · ${sessoLabel}`;
            if (cfOkBox) cfOkBox.style.display = 'flex';
            if (nextBtn) nextBtn.disabled = false;
        } else {
            if (statusEl) statusEl.textContent = '❌';
            setFieldState(input, errEl, validation.error || 'CF non corrisponde ai dati inseriti');
        }
    } else {
        // Dati incompleti (non dovrebbe succedere nello step 3) — permetti avanzamento
        if (statusEl) statusEl.textContent = '✅';
        setFieldState(input, errEl, null);
        if (nextBtn) nextBtn.disabled = false;
    }
}

// ==========================================
// REGISTRATION WIZARD — 4 STEP
// ==========================================

let _rwStep = 1; // step corrente (1-4)
const RW_TOTAL = 4;

function rwUpdateUI(direction) {
    // Aggiorna classi step
    for (let i = 1; i <= RW_TOTAL; i++) {
        const el = document.getElementById(`rwStep${i}`);
        if (!el) continue;
        el.classList.remove('active', 'slide-back');
        if (i === _rwStep) {
            el.classList.add('active');
            if (direction === 'back') el.classList.add('slide-back');
        }
    }

    // Aggiorna dot
    for (let i = 1; i <= RW_TOTAL; i++) {
        const dot = document.getElementById(`rwDot${i}`);
        if (!dot) continue;
        dot.classList.remove('active', 'done');
        if (i < _rwStep)  dot.classList.add('done');
        if (i === _rwStep) dot.classList.add('active');
    }

    // Aggiorna barra progresso (0% su step1, 33% su 2, 66% su 3, 100% su 4)
    const fill = document.getElementById('rwProgressFill');
    if (fill) fill.style.width = `${((_rwStep - 1) / (RW_TOTAL - 1)) * 100}%`;

    // Aggiorna recap CF quando si arriva allo step 3
    if (_rwStep === 3) {
        rwUpdateCFRecap();
        // Reset stato CF e bottone
        const nextBtn = document.getElementById('rwNextFromCF');
        if (nextBtn) nextBtn.disabled = true;
        const cfOkBox = document.getElementById('rwCFOk');
        if (cfOkBox) cfOkBox.style.display = 'none';
        const statusEl = document.getElementById('cfStatus');
        if (statusEl) statusEl.textContent = '';
        const cfInput = document.getElementById('registerCodiceFiscale');
        if (cfInput) {
            cfInput.classList.remove('input-ok', 'input-err');
        }
        const errCF = document.getElementById('err-cf');
        if (errCF) errCF.textContent = '';
    }

    // Aggiorna riepilogo allo step 4
    if (_rwStep === 4) rwBuildSummary();
}

function rwUpdateCFRecap() {
    const recap = document.getElementById('rwCFRecap');
    if (!recap) return;
    const fn  = document.getElementById('registerFirstname')?.value.trim() || '—';
    const ln  = document.getElementById('registerLastname')?.value.trim() || '—';
    const bd  = document.getElementById('registerBirthdate')?.value || '';
    const sx  = document.getElementById('registerSex')?.value || '';
    const com = document.getElementById('registerComune')?.value.trim() || '—';
    const bdFmt = bd ? new Date(bd).toLocaleDateString('it-IT', { day:'2-digit', month:'long', year:'numeric' }) : '—';
    const sxLabel = sx === 'M' ? 'Maschio' : sx === 'F' ? 'Femmina' : '—';
    recap.innerHTML = `
        <strong>Dati usati per il calcolo:</strong><br>
        👤 ${fn} ${ln} &nbsp;·&nbsp; 📅 ${bdFmt} &nbsp;·&nbsp; ${sxLabel} &nbsp;·&nbsp; 📍 ${com}
    `;
}

function rwBuildSummary() {
    const summary = document.getElementById('rwSummary');
    if (!summary) return;
    const fn  = document.getElementById('registerFirstname')?.value.trim() || '';
    const ln  = document.getElementById('registerLastname')?.value.trim() || '';
    const bd  = document.getElementById('registerBirthdate')?.value || '';
    const sx  = document.getElementById('registerSex')?.value || '';
    const com = document.getElementById('registerComune')?.value.trim() || '';
    const prov= document.getElementById('registerProvincia')?.value.trim() || '';
    const cap = document.getElementById('registerCAP')?.value.trim() || '';
    const cf  = document.getElementById('registerCodiceFiscale')?.value.trim() || '';
    const ref = document.getElementById('registerReferral')?.value.trim() || '';
    const bdFmt = bd ? new Date(bd).toLocaleDateString('it-IT', { day:'2-digit', month:'long', year:'numeric' }) : '';
    const sxLabel = sx === 'M' ? 'Maschio' : sx === 'F' ? 'Femmina' : '';

    const row = (label, value) => value
        ? `<div class="rw-summary-row"><span>${label}</span><span>${value}</span></div>`
        : '';

    summary.innerHTML = `
        ${row('Nome', `${fn} ${ln}`)}
        ${row('Data nascita', bdFmt)}
        ${row('Sesso', sxLabel)}
        ${row('Residenza', `${com} (${prov}) ${cap}`)}
        ${row('Codice fiscale', cf)}
        ${row('Referral', ref)}
    `;
}

function validateRwStep(step) {
    let valid = true;

    const setErr = (id, errId, msg) => {
        const el  = document.getElementById(id);
        const err = document.getElementById(errId);
        if (!el) return;
        if (!el.value.trim()) {
            setFieldState(el, err, msg);
            valid = false;
        } else {
            setFieldState(el, err, null);
        }
    };

    if (step === 1) {
        setErr('registerFirstname', 'err-firstname', 'Inserisci il nome');
        setErr('registerLastname',  'err-lastname',  'Inserisci il cognome');
        setErr('registerSex',       'err-sex',       'Seleziona il sesso');

        // Birthdate: obbligatoria + maggiorenne
        const bdEl  = document.getElementById('registerBirthdate');
        const bdErr = document.getElementById('err-birthdate');
        if (!bdEl?.value) {
            setFieldState(bdEl, bdErr, 'Inserisci la data di nascita');
            valid = false;
        } else {
            const dt = new Date(bdEl.value);
            if (!CodiceFiscale.isMaggiorenne(dt)) {
                setFieldState(bdEl, bdErr, 'Devi essere maggiorenne per registrarti');
                valid = false;
            } else {
                setFieldState(bdEl, bdErr, null);
            }
        }
    }

    if (step === 2) {
        setErr('registerComune',    'err-comune',    'Inserisci il comune di residenza');
        setErr('registerProvincia', 'err-provincia', 'Inserisci la provincia (2 lettere)');

        // CAP: 5 cifre
        const capEl  = document.getElementById('registerCAP');
        const capErr = document.getElementById('err-cap');
        if (!capEl?.value.trim()) {
            setFieldState(capEl, capErr, 'Inserisci il CAP (5 cifre)');
            valid = false;
        } else if (!/^\d{5}$/.test(capEl.value.trim())) {
            setFieldState(capEl, capErr, 'Il CAP deve essere di 5 cifre numeriche');
            valid = false;
        } else {
            setFieldState(capEl, capErr, null);
        }

        // Provincia: 2 lettere
        const provEl  = document.getElementById('registerProvincia');
        const provErr = document.getElementById('err-provincia');
        if (provEl && provEl.value.trim() && provEl.value.trim().length !== 2) {
            setFieldState(provEl, provErr, 'La provincia deve avere 2 lettere (es. RM)');
            valid = false;
        }
    }

    if (step === 3) {
        // CF già validato in tempo reale — controlla solo che sia presente e valido
        const cfEl  = document.getElementById('registerCodiceFiscale');
        const cfErr = document.getElementById('err-cf');
        const cf = cfEl?.value.trim() || '';
        const cfRegex = /^[A-Z]{6}[0-9LMNPQRSTUV]{2}[ABCDEHLMPRST]{1}[0-9LMNPQRSTUV]{2}[A-Z]{1}[0-9LMNPQRSTUV]{3}[A-Z]{1}$/;
        if (!cf) {
            setFieldState(cfEl, cfErr, 'Inserisci il codice fiscale');
            valid = false;
        } else if (!cfRegex.test(cf)) {
            setFieldState(cfEl, cfErr, 'Formato codice fiscale non valido');
            valid = false;
        } else {
            // Valida incrociato
            const fn = document.getElementById('registerFirstname')?.value.trim() || '';
            const ln = document.getElementById('registerLastname')?.value.trim() || '';
            const bd = document.getElementById('registerBirthdate')?.value || '';
            const sx = document.getElementById('registerSex')?.value || '';
            if (fn && ln && bd && sx) {
                const res = CodiceFiscale.valida(cf, fn, ln, new Date(bd), sx);
                if (!res.valid) {
                    setFieldState(cfEl, cfErr, res.error || 'CF non corrisponde ai dati inseriti');
                    valid = false;
                } else {
                    setFieldState(cfEl, cfErr, null);
                }
            }
        }
    }

    if (step === 4) {
        // Email
        const emailEl  = document.getElementById('registerEmail');
        const emailErr = document.getElementById('err-email');
        if (!emailEl?.value.trim()) {
            setFieldState(emailEl, emailErr, 'Inserisci la tua email');
            valid = false;
        } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailEl.value.trim())) {
            setFieldState(emailEl, emailErr, 'Inserisci un\'email valida (es. mario@esempio.it)');
            valid = false;
        } else {
            setFieldState(emailEl, emailErr, null);
        }

        // Password
        const pwEl  = document.getElementById('registerPassword');
        const pwErr = document.getElementById('err-password');
        if (!pwEl?.value) {
            setFieldState(pwEl, pwErr, 'Inserisci una password');
            valid = false;
        } else if (pwEl.value.length < 8) {
            setFieldState(pwEl, pwErr, 'La password deve avere almeno 8 caratteri');
            valid = false;
        } else {
            setFieldState(pwEl, pwErr, null);
        }

        // Referral
        setErr('registerReferral', 'err-referral', 'Inserisci il codice referral');
    }

    return valid;
}

function rwNext() {
    if (!validateRwStep(_rwStep)) {
        // Scrolla al primo errore nel step corrente
        const firstErr = document.querySelector(`#rwStep${_rwStep} .input-err`);
        if (firstErr) firstErr.scrollIntoView({ behavior: 'smooth', block: 'center' });
        return;
    }
    if (_rwStep < RW_TOTAL) {
        _rwStep++;
        rwUpdateUI('next');
    }
}

function rwBack() {
    if (_rwStep > 1) {
        _rwStep--;
        rwUpdateUI('back');
    }
}

async function rwSubmit() {
    if (!validateRwStep(4)) return;

    // Leggi tutti i valori
    const firstName     = document.getElementById('registerFirstname').value.trim();
    const lastName      = document.getElementById('registerLastname').value.trim();
    const birthdate     = document.getElementById('registerBirthdate').value;
    const sesso         = document.getElementById('registerSex').value;
    const codiceFiscale = document.getElementById('registerCodiceFiscale').value.toUpperCase().trim();
    const comune        = document.getElementById('registerComune').value.trim();
    const provincia     = document.getElementById('registerProvincia').value.toUpperCase().trim();
    const cap           = document.getElementById('registerCAP').value.trim();
    const telefono      = document.getElementById('registerTelefono')?.value.trim() || '';
    const email         = document.getElementById('registerEmail').value.trim();
    const password      = document.getElementById('registerPassword').value;
    const referralCode  = (document.getElementById('registerReferral')?.value || '').toUpperCase().trim();

    const dataNascita = new Date(birthdate);

    // Valida CF incrociato
    const cfValidation = CodiceFiscale.valida(codiceFiscale, firstName, lastName, dataNascita, sesso);
    if (!cfValidation.valid) {
        // Rimanda allo step 3
        _rwStep = 3;
        rwUpdateUI('back');
        const cfEl  = document.getElementById('registerCodiceFiscale');
        const cfErr = document.getElementById('err-cf');
        setFieldState(cfEl, cfErr, cfValidation.error || 'CF non corrisponde ai dati inseriti');
        return;
    }

    // Mostra loading
    const loading = document.getElementById('registerLoading');
    const submitBtn = document.getElementById('registerSubmitBtn');
    if (loading) loading.classList.add('show');
    if (submitBtn) submitBtn.disabled = true;

    const sb = await ensureSupabase();

    try {
        // Valida referral code
        let referrer = null;
        let referrerOrgId = null;
        let referrerOrgName = null;
        let referrerCollaboratorId = null;
        let referralType = null;

        if (referralCode) {
            // Cerca in users
            const { data: userData, error: userError } = await sb
                .from('users')
                .select('id, referral_code, first_name, last_name')
                .eq('referral_code', referralCode)
                .maybeSingle();
            if (userError) throw new Error('ERRORE DATABASE: ' + userError.message);

            if (userData) {
                referrer = userData;
                referralType = 'user';
            } else {
                // Cerca in organizations
                const { data: orgData, error: orgError } = await sb
                    .from('organizations')
                    .select('id, name, referral_code, referral_code_employees, referral_code_external')
                    .or(`referral_code.eq.${referralCode},referral_code_employees.eq.${referralCode},referral_code_external.eq.${referralCode}`)
                    .maybeSingle();
                if (orgError) throw new Error('ERRORE DATABASE: ' + orgError.message);

                if (orgData) {
                    referrerOrgId = orgData.id;
                    referrerOrgName = orgData.name;
                    referralType = orgData.referral_code_employees === referralCode ? 'org_employee'
                                 : orgData.referral_code_external  === referralCode ? 'org_external'
                                 : 'org_employee';
                } else {
                    // Cerca in collaborators
                    const { data: collabData, error: collabError } = await sb
                        .from('collaborators')
                        .select('id, first_name, last_name, referral_code')
                        .eq('referral_code', referralCode)
                        .eq('status', 'active')
                        .maybeSingle();
                    if (collabError) throw new Error('ERRORE DATABASE: ' + collabError.message);

                    if (collabData) {
                        referrerCollaboratorId = collabData.id;
                        referralType = 'collaborator';
                    } else {
                        throw new Error('CODICE REFERRAL NON VALIDO!');
                    }
                }
            }
        }

        // Registra su Supabase Auth
        const { data: authData, error: authError } = await sb.auth.signUp({
            email,
            password,
            options: {
                data: {
                    first_name:          firstName,
                    last_name:           lastName,
                    data_nascita:        birthdate,
                    sesso,
                    codice_fiscale:      codiceFiscale,
                    cap_residenza:       cap,
                    comune_residenza:    comune,
                    provincia_residenza: provincia,
                    telefono:            telefono,
                    referral_code_used:  referralCode,
                }
            }
        });
        if (authError) throw authError;

        // Imposta referral via API
        if ((referrer || referrerOrgId || referrerCollaboratorId) && authData.user) {
            await new Promise(resolve => setTimeout(resolve, 1500));
            const accessToken = authData.session?.access_token;
            if (accessToken) {
                try {
                    const response = await fetch(
                        'https://uchrjlngfzfibcpdxtky.supabase.co/functions/v1/set-user-referral',
                        {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                                'Authorization': `Bearer ${accessToken}`
                            },
                            body: JSON.stringify({
                                userId:         authData.user.id,
                                referrerId:     referrer?.id || null,
                                organizationId: referrerOrgId || null,
                                collaboratorId: referrerCollaboratorId || null,
                                referralType
                            })
                        }
                    );
                    const result = await response.json();
                    if (!response.ok) throw new Error(result.error || 'Failed to set referral');
                    console.log('✅ Referral impostato:', result.data);
                } catch (err) {
                    console.error('⚠️ Errore set-referral (non critico):', err);
                }
            } else {
                console.warn('⚠️ Nessun access token — conferma email richiesta');
            }
        }

        // Invia email di benvenuto
        try {
            const referredByName = referrer
                ? `${referrer.first_name} ${referrer.last_name}`
                : (referrerOrgName || null);
            await fetch('https://uchrjlngfzfibcpdxtky.supabase.co/functions/v1/send-welcome-email', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email, firstName, lastName, referredBy: referredByName })
            });
        } catch (err) {
            console.error('⚠️ Email benvenuto non inviata (non critico):', err);
        }

        showAlert('✅ Registrazione completata! Benvenuto su CDM86!', 'success');

        setTimeout(() => {
            const modal = document.getElementById('loginModal');
            if (modal) modal.classList.remove('show');
            // Redirect a pagamento Stripe
            // Su Stripe Dashboard → Payment Link → Edit → After payment:
            //   success URL: https://www.cdm86.it/public/promotions.html?payment=success
            // Se l'utente torna indietro senza pagare → vedrà il banner "Completa iscrizione"
            window.location.href = 'https://buy.stripe.com/test_9B6dR902Z1s22Eb438gMw00';
        }, 1500);

    } catch (error) {
        console.error('❌ Errore registrazione:', error);
        showAlert(error.message || 'Errore durante la registrazione');
        if (loading) loading.classList.remove('show');
        if (submitBtn) submitBtn.disabled = false;
    }
}

// Chiamato quando il tab "Registrati" diventa visibile: resetta wizard allo step 1
function rwReset() {
    _rwStep = 1;
    rwUpdateUI('next');
}

// Flag che indica che la modale CF è stata confermata
let _cfConfirmed = false;

function togglePwd(inputId, btn) {
    const input = document.getElementById(inputId);
    if (!input) return;
    if (input.type === 'password') {
        input.type = 'text';
        btn.textContent = '🙈';
    } else {
        input.type = 'password';
        btn.textContent = '👁️';
    }
}

function cfConfirmOk() {
    _cfConfirmed = true;
    const overlay = document.getElementById('cfConfirmOverlay');
    if (overlay) overlay.classList.remove('active');
    // Ri-sottometti il form
    document.getElementById('registerForm')?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
}

function cfConfirmCancel() {
    _cfConfirmed = false;
    const overlay = document.getElementById('cfConfirmOverlay');
    if (overlay) overlay.classList.remove('active');
    document.getElementById('registerCodiceFiscale')?.focus();
}

function showCFConfirmModal(cf, firstName, lastName, birthdate, sesso) {
    const overlay = document.getElementById('cfConfirmOverlay');
    const dataEl = document.getElementById('cfConfirmData');
    if (!overlay || !dataEl) return;

    const sessoLabel = sesso === 'M' ? 'Maschio' : 'Femmina';
    const dataFormatted = new Date(birthdate).toLocaleDateString('it-IT', { day: '2-digit', month: 'long', year: 'numeric' });

    dataEl.innerHTML = `
        <div><strong>Nome:</strong> ${firstName} ${lastName}</div>
        <div><strong>Data di nascita:</strong> ${dataFormatted}</div>
        <div><strong>Sesso:</strong> ${sessoLabel}</div>
        <div style="margin-top:10px"><strong>Codice Fiscale:</strong></div>
        <div class="cf-code">${cf}</div>
    `;
    overlay.classList.add('active');
}

function validateRegisterForm() {
    let valid = true;

    const fields = [
        { id: 'registerFirstname', err: 'err-firstname', msg: 'Inserisci il nome' },
        { id: 'registerLastname',  err: 'err-lastname',  msg: 'Inserisci il cognome' },
        { id: 'registerBirthdate', err: 'err-birthdate', msg: 'Inserisci la data di nascita' },
        { id: 'registerSex',       err: 'err-sex',       msg: 'Seleziona il sesso' },
        { id: 'registerCodiceFiscale', err: 'err-cf',    msg: 'Inserisci il codice fiscale' },
        { id: 'registerCAP',       err: 'err-cap',       msg: 'Inserisci il CAP (5 cifre)' },
        { id: 'registerEmail',     err: 'err-email',     msg: 'Inserisci un\'email valida' },
        { id: 'registerPassword',  err: 'err-password',  msg: 'La password deve avere almeno 8 caratteri' },
        { id: 'registerReferral',  err: 'err-referral',  msg: 'Inserisci il codice referral' },
    ];

    fields.forEach(f => {
        const el = document.getElementById(f.id);
        const errEl = document.getElementById(f.err);
        if (!el) return;

        const val = el.value.trim();

        if (!val) {
            setFieldState(el, errEl, f.msg);
            valid = false;
            return;
        }

        // Validazioni specifiche
        if (f.id === 'registerBirthdate') {
            const dt = new Date(val);
            if (!CodiceFiscale.isMaggiorenne(dt)) {
                setFieldState(el, errEl, 'Devi essere maggiorenne per registrarti');
                valid = false;
                return;
            }
        }
        if (f.id === 'registerCAP' && !/^\d{5}$/.test(val)) {
            setFieldState(el, errEl, 'Il CAP deve essere di 5 cifre numeriche');
            valid = false;
            return;
        }
        if (f.id === 'registerEmail' && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(val)) {
            setFieldState(el, errEl, 'Inserisci un\'email valida (es. mario@esempio.it)');
            valid = false;
            return;
        }
        if (f.id === 'registerPassword' && val.length < 8) {
            setFieldState(el, errEl, 'La password deve avere almeno 8 caratteri');
            valid = false;
            return;
        }
        if (f.id === 'registerCodiceFiscale') {
            const cfRegex = /^[A-Z]{6}[0-9LMNPQRSTUV]{2}[ABCDEHLMPRST]{1}[0-9LMNPQRSTUV]{2}[A-Z]{1}[0-9LMNPQRSTUV]{3}[A-Z]{1}$/;
            if (!cfRegex.test(val)) {
                setFieldState(el, errEl, 'Formato codice fiscale non valido');
                valid = false;
                return;
            }
        }

        setFieldState(el, errEl, null);
    });

    return valid;
}

// Export per uso globale
window.LoginModal = {
    // Alias per compatibilità
    open: showLoginModal,
    
    // Selection Modal
    showSelection: showSelectionModal,
    closeSelection: closeSelectionModal,
    selectUser,
    selectCompany,
    showExistingUserLogin,
    
    // Company Request Modal
    showCompanyRequest: showCompanyRequestModal,
    closeCompanyRequest: closeCompanyRequestModal,
    companyHasReferralYes,
    companyHasReferralNo,
    handleCompanyRequest,
    handleCompanyRequestNoRef,
    
    // Login Modal
    show: showLoginModal,
    close: closeLoginModal,
    showReferral: showReferralModal,
    closeReferral: closeReferralModal,
    switchTab: switchLoginTab,
    handleHasCode,
    showWizard,
    wizardBack,
    wizardNext,
    handleLogin,
    handleRegister,
    showForgotPassword,
    closeForgotPassword,
    handleForgotPassword,

    // Registrazione
    checkCFLive,
    togglePwd,
    cfConfirmOk,
    cfConfirmCancel,

    // Wizard registrazione
    rwNext,
    rwBack,
    rwSubmit,
    rwReset,
};

// ==========================================
// COMPANY WIZARD (2-STEP REPORT)
// ==========================================

const CompanyWizard = {
    currentStep: 1,
    
    open() {
        const overlay = document.getElementById('companyRequestModalOverlay');
        const loading = document.getElementById('companyRequestLoading');
        
        if (overlay) {
            overlay.classList.add('active');
            this.currentStep = 1;
            this.updateUI();
            
            // Mostra il referral code dell'utente
            this.displayUserReferralCode();
            
            // Assicurati che il loading sia nascosto
            if (loading) {
                loading.classList.remove('show');
            }
        }
    },
    
    close() {
        const overlay = document.getElementById('companyRequestModalOverlay');
        const loading = document.getElementById('companyRequestLoading');
        
        if (overlay) {
            overlay.classList.remove('active');
            this.resetForm();
            
            // Nascondi loading quando chiudi
            if (loading) {
                loading.classList.remove('show');
            }
        }
    },
    
    resetForm() {
        document.getElementById('companyDataForm')?.reset();
        document.getElementById('companySurveyForm')?.reset();
        this.currentStep = 1;
        this.updateUI();
    },
    
    updateUI() {
        // Update header
        const title = document.getElementById('wizardTitle');
        const subtitle = document.getElementById('wizardSubtitle');
        
        if (this.currentStep === 1) {
            if (title) title.textContent = 'Segnala Azienda/Associazione';
            if (subtitle) subtitle.textContent = 'Passo 1 di 2 - Dati Azienda';
        } else {
            if (title) title.textContent = 'Informazioni Aggiuntive';
            if (subtitle) subtitle.textContent = 'Passo 2 di 2 - Sondaggio';
        }
        
        // Update progress bar
        const progressBar = document.getElementById('wizardProgressBar');
        if (progressBar) {
            progressBar.style.width = this.currentStep === 1 ? '50%' : '100%';
        }
        
        // Show/hide steps
        const step1 = document.getElementById('wizardStep1');
        const step2 = document.getElementById('wizardStep2');
        
        if (step1) step1.classList.toggle('active', this.currentStep === 1);
        if (step2) step2.classList.toggle('active', this.currentStep === 2);
    },
    
    nextStep() {
        const form = document.getElementById('companyDataForm');
        if (!form || !form.checkValidity()) {
            form?.reportValidity();
            return;
        }
        
        this.currentStep = 2;
        this.updateUI();
    },
    
    prevStep() {
        this.currentStep = 1;
        this.updateUI();
    },
    
    async displayUserReferralCode() {
        try {
            const supabase = await ensureSupabase();
            const { data: { user } } = await supabase.auth.getUser();
            if (!user) return;
            
            const { data: userData } = await supabase
                .from('users')
                .select('referral_code')
                .eq('auth_user_id', user.id)
                .single();
            
            const displayElement = document.getElementById('userReferralCodeDisplay');
            if (displayElement && userData?.referral_code) {
                displayElement.textContent = userData.referral_code;
            }
        } catch (error) {
            console.error('Error loading referral code:', error);
        }
    },
    
    toggleSectorOther() {
        const select = document.getElementById('companySector');
        const otherGroup = document.getElementById('sectorOtherGroup');
        const otherInput = document.getElementById('sectorOther');
        
        if (select?.value === 'other') {
            otherGroup?.classList.add('active');
            if (otherInput) otherInput.required = true;
        } else {
            otherGroup?.classList.remove('active');
            if (otherInput) {
                otherInput.required = false;
                otherInput.value = '';
            }
        }
    },
    
    toggleWhoKnowsOther() {
        const select = document.getElementById('whoKnows');
        const otherGroup = document.getElementById('whoKnowsOtherGroup');
        const otherInput = document.getElementById('whoKnowsOther');
        
        if (select?.value === 'other') {
            otherGroup?.classList.add('active');
            if (otherInput) otherInput.required = true;
        } else {
            otherGroup?.classList.remove('active');
            if (otherInput) {
                otherInput.required = false;
                otherInput.value = '';
            }
        }
    },
    
    async submitForm() {
        const surveyForm = document.getElementById('companySurveyForm');
        if (!surveyForm || !surveyForm.checkValidity()) {
            surveyForm?.reportValidity();
            return;
        }
        
        const loading = document.getElementById('companyRequestLoading');
        const step2 = document.getElementById('wizardStep2');
        
        if (step2) step2.style.display = 'none';
        if (loading) loading.classList.add('show');
        
        try {
            const supabase = await ensureSupabase();
            
            // Get current user (optional - wizard works also without login)
            const { data: { user } } = await supabase.auth.getUser();
            
            // Get user data to find referral code (only if logged in)
            let userData = null;
            if (user) {
                const { data: ud } = await supabase
                    .from('users')
                    .select('referral_code, first_name, last_name')
                    .eq('auth_user_id', user.id)
                    .single();
                userData = ud;
            }
            
            // Collect all form data
            const companyName = document.getElementById('companyName').value.trim();
            const contactName = document.getElementById('companyContact').value.trim();
            const email = document.getElementById('companyEmail').value.trim();
            const phone = document.getElementById('companyPhone').value.trim();
            const address = document.getElementById('companyAddress').value.trim();
            
            const sector = document.getElementById('companySector').value;
            const sectorOther = document.getElementById('sectorOther').value.trim();
            const finalSector = sector === 'other' ? sectorOther : sector;
            
            const companyAware = document.querySelector('input[name="companyAware"]:checked')?.value;
            
            const whoKnows = document.getElementById('whoKnows').value;
            const whoKnowsOther = document.getElementById('whoKnowsOther').value.trim();
            const finalWhoKnows = whoKnows === 'other' ? whoKnowsOther : whoKnows;
            
            const callTime = document.getElementById('callTime').value;
            
            const referralGiven = document.querySelector('input[name="referralGiven"]:checked')?.value;
            const emailConsent = document.querySelector('input[name="emailConsent"]:checked')?.value;
            
            // ⭐ NUOVO: Company Type
            const companyType = document.querySelector('input[name="companyType"]:checked')?.value;
            if (!companyType) {
                throw new Error('Seleziona il tipo di azienda/associazione');
            }
            
            // Save to database via Edge Function (bypasses RLS, works for anonymous users too)
            const { data: { session } } = await supabase.auth.getSession();
            const authHeader = session?.access_token 
                ? `Bearer ${session.access_token}`
                : `Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwMzEyMDYsImV4cCI6MjA3NTYwNzIwNn0.64JK3OhYJi2YtrErctNAp_sCcSHwB656NVLdooyceOM`;

            const submitResponse = await fetch(
                'https://uchrjlngfzfibcpdxtky.supabase.co/functions/v1/submit-company-report',
                {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': authHeader
                    },
                    body: JSON.stringify({
                        companyName,
                        contactName,
                        email,
                        phone,
                        address,
                        sector: finalSector,
                        companyAware: companyAware === 'si',
                        whoKnows: finalWhoKnows,
                        callTime,
                        referralGiven: referralGiven === 'si',
                        emailConsent: emailConsent === 'si',
                        companyType,
                        reportedByUserId: user ? user.id : null,
                        reportedByReferralCode: userData?.referral_code || null
                    })
                }
            );

            const submitResult = await submitResponse.json();
            if (!submitResponse.ok) throw new Error(submitResult.error || 'Errore durante il salvataggio');
            
            const insertedReportId = submitResult.reportId;
            
            // 📧 Invia email di notifica (utente + azienda)
            console.log('📧 Invio email di notifica per segnalazione ID:', insertedReportId);
            
            try {
                const emailResponse = await fetch(
                    'https://uchrjlngfzfibcpdxtky.supabase.co/functions/v1/send-report-notification',
                    {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'Authorization': authHeader
                        },
                        body: JSON.stringify({ reportId: insertedReportId })
                    }
                );
                
                if (!emailResponse.ok) {
                    console.error('⚠️ Errore invio email notifica:', await emailResponse.text());
                }
            } catch (emailError) {
                console.error('⚠️ Errore chiamata email function:', emailError);
                // Non blocchiamo il flusso se l'email fallisce
            }
            
            const userName = userData ? `${userData.first_name} ${userData.last_name}` : '';
            
            // Messaggio email
            const emailMessage = emailConsent === 'si' 
                ? `<p style="color: #10b981; margin-top: 16px; font-weight: 600;">📧 Ti contatteremo all'indirizzo ${email}</p>
                   ${userData?.referral_code ? `<p style="color: #64748b; font-size: 14px; margin-top: 8px;">Segnalazione da: <strong>${userData.referral_code}</strong>${userName ? ' - ' + userName : ''}</p>` : ''}`
                : '<p style="color: #f59e0b; margin-top: 16px;">📧 Riceverai una conferma a breve</p>';
            
            // Show success message
            if (loading) {
                loading.innerHTML = `
                    <div style="text-align: center; padding: 40px;">
                        <div style="font-size: 64px; margin-bottom: 20px;">✅</div>
                        <h3 style="color: #10b981; margin-bottom: 10px;">Segnalazione Inviata!</h3>
                        <p style="color: #64748b;">L'amministratore riceverà la tua segnalazione a breve.</p>
                        ${emailMessage}
                        <div style="margin-top: 28px; padding: 20px; background: linear-gradient(135deg, #f8faff, #eff6ff); border: 2px solid #6366f1; border-radius: 16px;">
                            <div style="font-size: 28px; margin-bottom: 8px;">🚀</div>
                            <h4 style="color: #0f172a; margin-bottom: 6px; font-size: 1rem;">Vuoi attivare subito il profilo aziendale?</h4>
                            <p style="color: #64748b; font-size: 0.85rem; margin-bottom: 14px;">Completa l'abbonamento e la tua azienda apparirà su CDM86 con promozioni, pagina dedicata e molto altro.</p>
                            <a href="https://buy.stripe.com/test_9B6dR902Z1s22Eb438gMw00" target="_blank"
                               style="display: inline-flex; align-items: center; gap: 8px; padding: 12px 24px; background: linear-gradient(135deg, #6366f1, #8b5cf6); color: white; border-radius: 10px; text-decoration: none; font-weight: 700; font-size: 0.9rem; transition: opacity 0.2s;">
                                💳 Attiva ora l'abbonamento
                            </a>
                            <p style="color: #94a3b8; font-size: 0.75rem; margin-top: 10px;">Puoi farlo anche in seguito dal tuo pannello aziendale</p>
                        </div>
                    </div>
                `;
            }
            
            setTimeout(() => {
                this.close();
                if (loading) {
                    loading.classList.remove('show');
                    loading.innerHTML = `
                        <div class="spinner"></div>
                        <p>Invio segnalazione in corso...</p>
                    `;
                }
                if (step2) step2.style.display = 'block';
                
                // Reload dashboard data to show new report
                if (typeof loadDashboardData === 'function') {
                    loadDashboardData();
                }
            }, 2500);
            
        } catch (error) {
            console.error('Company report error:', error);
            alert(error.message || 'Errore durante l\'invio della segnalazione');
            if (loading) loading.classList.remove('show');
            if (step2) step2.style.display = 'block';
        }
    }
};

// Make CompanyWizard globally available
window.CompanyWizard = CompanyWizard;

// ==========================================
// ORG REGISTRATION WIZARD
// ==========================================

const OrgRegWizard = {
    currentStep: 1,
    hasReferral: null,

    open() {
        const overlay = document.getElementById('orgRegModalOverlay');
        if (!overlay) return;
        this.currentStep = 1;
        this.hasReferral = null;
        this._resetForm();
        overlay.classList.add('active');
        document.body.style.overflow = 'hidden';
        this._updateUI();
    },

    close() {
        const overlay = document.getElementById('orgRegModalOverlay');
        if (overlay) overlay.classList.remove('active');
        document.body.style.overflow = '';
        setTimeout(() => this._resetForm(), 400);
    },

    _resetForm() {
        ['orgRegName','orgRegType','orgRegFirstName','orgRegLastName','orgRegEmail','orgRegPhone','orgRegReferralCode'].forEach(id => {
            const el = document.getElementById(id);
            if (el) el.value = '';
        });
        // Reset radio
        ['orgRegHasReferralYes','orgRegHasReferralNo'].forEach(id => {
            const el = document.getElementById(id);
            if (el) el.checked = false;
        });
        document.querySelectorAll('.org-reg-radio-label').forEach(l => l.classList.remove('selected'));
        const codeBox = document.getElementById('orgRegCodeBox');
        if (codeBox) codeBox.classList.remove('visible');
        const step2Next = document.getElementById('orgRegStep2Next');
        if (step2Next) step2Next.disabled = true;
        this.hasReferral = null;
        ['orgRegAlert1','orgRegAlert2','orgRegAlert3'].forEach(id => {
            const el = document.getElementById(id);
            if (el) { el.textContent = ''; el.className = 'form-alert'; }
        });
    },

    toggleReferral(hasRef) {
        this.hasReferral = hasRef;
        // Update radio label styles
        const yesLabel = document.getElementById('orgRegHasReferralYes')?.closest('.org-reg-radio-label');
        const noLabel  = document.getElementById('orgRegHasReferralNo')?.closest('.org-reg-radio-label');
        if (yesLabel) yesLabel.classList.toggle('selected', hasRef === true);
        if (noLabel)  noLabel.classList.toggle('selected', hasRef === false);
        // Show/hide code input
        const codeBox = document.getElementById('orgRegCodeBox');
        if (codeBox) codeBox.classList.toggle('visible', hasRef === true);
        // Enable Next button
        const step2Next = document.getElementById('orgRegStep2Next');
        if (step2Next) step2Next.disabled = false;
    },

    _updateUI() {
        const steps = [1, 2, 3, 4];
        steps.forEach(s => {
            const el = document.getElementById('orgRegStep' + s);
            if (el) el.classList.toggle('active', s === this.currentStep);
        });
        // Progress bar
        const progress = { 1: '33%', 2: '66%', 3: '90%', 4: '100%' };
        const bar = document.getElementById('orgRegProgressBar');
        if (bar) bar.style.width = progress[this.currentStep] || '33%';
        // Subtitle
        const subtitles = {
            1: 'Passo 1 di 3 — Dati Azienda',
            2: 'Passo 2 di 3 — Referral',
            3: 'Passo 3 di 3 — Conferma',
            4: 'Completato!'
        };
        const subtitle = document.getElementById('orgRegSubtitle');
        if (subtitle) subtitle.textContent = subtitles[this.currentStep] || '';
    },

    _showAlert(step, msg, type = 'error') {
        const el = document.getElementById('orgRegAlert' + step);
        if (!el) return;
        el.textContent = msg;
        el.className = 'form-alert form-alert-' + type;
    },

    nextStep() {
        if (this.currentStep === 1) {
            // Validate step 1
            const name  = document.getElementById('orgRegName')?.value.trim();
            const type  = document.getElementById('orgRegType')?.value;
            const fname = document.getElementById('orgRegFirstName')?.value.trim();
            const lname = document.getElementById('orgRegLastName')?.value.trim();
            const email = document.getElementById('orgRegEmail')?.value.trim();
            const phone = document.getElementById('orgRegPhone')?.value.trim();
            if (!name || !type || !fname || !lname || !email || !phone) {
                this._showAlert(1, '⚠️ Compila tutti i campi obbligatori prima di procedere.');
                return;
            }
            if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
                this._showAlert(1, '⚠️ Inserisci un indirizzo email valido.');
                return;
            }
            this._showAlert(1, '');
            this.currentStep = 2;
        } else if (this.currentStep === 2) {
            if (this.hasReferral === null) {
                this._showAlert(2, '⚠️ Seleziona una delle opzioni prima di procedere.');
                return;
            }
            if (this.hasReferral === true) {
                const code = document.getElementById('orgRegReferralCode')?.value.trim();
                if (!code) {
                    this._showAlert(2, '⚠️ Inserisci il codice referral o seleziona "No".');
                    return;
                }
            }
            this._showAlert(2, '');
            this._buildSummary();
            this.currentStep = 3;
        }
        this._updateUI();
    },

    prevStep() {
        if (this.currentStep > 1) {
            this.currentStep--;
            this._updateUI();
        }
    },

    _buildSummary() {
        const name  = document.getElementById('orgRegName')?.value.trim();
        const type  = document.getElementById('orgRegType')?.value;
        const fname = document.getElementById('orgRegFirstName')?.value.trim();
        const lname = document.getElementById('orgRegLastName')?.value.trim();
        const email = document.getElementById('orgRegEmail')?.value.trim();
        const phone = document.getElementById('orgRegPhone')?.value.trim();
        const code  = this.hasReferral ? (document.getElementById('orgRegReferralCode')?.value.trim() || '—') : 'Nessuno';
        const typeLabel = { azienda: 'Azienda', associazione: 'Associazione', altro: 'Altro' };

        const rows = [
            ['Azienda/Ente', name],
            ['Tipo', typeLabel[type] || type],
            ['Referente', fname + ' ' + lname],
            ['Email', email],
            ['Telefono', phone],
            ['Codice Referral', code],
        ];

        const summary = document.getElementById('orgRegSummary');
        if (!summary) return;
        summary.innerHTML = `
            <div class="org-reg-summary-title">Riepilogo Richiesta</div>
            ${rows.map(([label, val]) => `
                <div class="org-reg-summary-row">
                    <span>${label}</span>
                    <span>${val}</span>
                </div>
            `).join('')}
        `;
    },

    async submit() {
        const submitBtn   = document.getElementById('orgRegSubmitBtn');
        const submitLabel = document.getElementById('orgRegSubmitLabel');
        const loading     = document.getElementById('orgRegLoading');

        if (submitBtn) submitBtn.disabled = true;
        if (submitLabel) submitLabel.textContent = 'Invio in corso...';
        if (loading) loading.style.display = 'flex';

        try {
            const name  = document.getElementById('orgRegName').value.trim();
            const type  = document.getElementById('orgRegType').value;
            const fname = document.getElementById('orgRegFirstName').value.trim();
            const lname = document.getElementById('orgRegLastName').value.trim();
            const email = document.getElementById('orgRegEmail').value.trim();
            const phone = document.getElementById('orgRegPhone').value.trim();
            const code  = (this.hasReferral && document.getElementById('orgRegReferralCode')?.value.trim()) || null;

            const payload = {
                organization_name: name,
                organization_type: type,
                contact_first_name: fname,
                contact_last_name: lname,
                contact_email: email,
                contact_phone: phone,
                status: 'pending',
            };

            if (code) payload.referred_by_code = code;

            // Ottieni istanza Supabase
            const supabase = await ensureSupabase();
            if (!supabase) throw new Error('Supabase non disponibile');

            // If there's a referral code, look up the referring user
            if (code) {
                const { data: referrer } = await supabase
                    .from('users')
                    .select('id')
                    .eq('referral_code', code.toUpperCase())
                    .single();
                if (referrer?.id) {
                    payload.referred_by_id = referrer.id;
                }
            }

            const { error } = await supabase
                .from('organization_requests')
                .insert(payload);

            if (error) throw error;

            if (loading) loading.style.display = 'none';
            this.currentStep = 4;
            this._updateUI();

        } catch (err) {
            console.error('OrgRegWizard submit error:', err);
            if (loading) loading.style.display = 'none';
            if (submitBtn) submitBtn.disabled = false;
            if (submitLabel) submitLabel.textContent = 'Invia Richiesta';
            this._showAlert(3, '❌ Errore durante l\'invio. Riprova o contattaci direttamente.');
        }
    }
};

// Make OrgRegWizard globally available
window.OrgRegWizard = OrgRegWizard;




// Wait for DOM to load and check auth status
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        checkAuthStatus();
        initFormValidations();
    });
} else {
    checkAuthStatus();
    initFormValidations();
}

// Inizializza validazioni real-time del form
function initFormValidations() {
    const cfInput        = document.getElementById('registerCodiceFiscale');
    const birthdateInput = document.getElementById('registerBirthdate');
    const sexInput       = document.getElementById('registerSex');
    const firstNameInput = document.getElementById('registerFirstname');
    const lastNameInput  = document.getElementById('registerLastname');

    if (!cfInput) return; // form non presente in questa pagina

    // Aggiorna validazione CF ogni volta che cambiano i campi correlati
    const triggerCFCheck = () => checkCFLive(cfInput);

    cfInput.addEventListener('input', triggerCFCheck);
    birthdateInput?.addEventListener('change', triggerCFCheck);
    sexInput?.addEventListener('change', triggerCFCheck);
    firstNameInput?.addEventListener('input', triggerCFCheck);
    lastNameInput?.addEventListener('input', triggerCFCheck);

    // Validazione maggiorenne in tempo reale sulla data
    if (birthdateInput) {
        birthdateInput.addEventListener('change', function() {
            const errEl  = document.getElementById('err-birthdate');
            const dt     = new Date(this.value);
            if (this.value && !CodiceFiscale.isMaggiorenne(dt)) {
                setFieldState(birthdateInput, errEl, 'Devi essere maggiorenne (18+) per registrarti');
            } else if (this.value) {
                setFieldState(birthdateInput, errEl, null);
            }
        });
    }
}

