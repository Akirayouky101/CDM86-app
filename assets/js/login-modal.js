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
    showCompanyRequestModal();
}

function showExistingUserLogin() {
    closeSelectionModal();
    showLoginModal();
}

// ==========================================
// COMPANY REQUEST MODAL
// ==========================================

function showCompanyRequestModal() {
    const overlay = document.getElementById('companyRequestModalOverlay');
    if (overlay) {
        overlay.classList.add('active');
        companyHasReferral = false;
        // Reset form
        document.getElementById('companyReferralQuestion').style.display = 'block';
        document.getElementById('companyFormWithReferral').classList.remove('active');
        document.getElementById('companyFormWithoutReferral').classList.remove('active');
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
        const progress = document.getElementById(`wizardProgress${i}`);
        if (progress) {
            if (i <= currentWizardStep) {
                progress.classList.add('active');
            } else {
                progress.classList.remove('active');
            }
        }
    }

    // Update step content
    document.querySelectorAll('.wizard-step-content').forEach(step => {
        step.classList.remove('active');
    });

    if (currentWizardStep === 4) {
        document.getElementById('wizardStepSuccess').classList.add('active');
        document.getElementById('wizardBtnBack').style.display = 'none';
        document.getElementById('wizardBtnNext').textContent = 'Chiudi';
    } else {
        const currentStep = document.getElementById(`wizardStep${currentWizardStep}`);
        if (currentStep) {
            currentStep.classList.add('active');
        }
        document.getElementById('wizardBtnBack').style.display = currentWizardStep === 1 ? 'none' : 'block';
        document.getElementById('wizardBtnNext').textContent = currentWizardStep === 3 ? 'Invia' : 'Avanti';
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
        const firstname = document.getElementById('wizardFirstname').value.trim();
        const lastname = document.getElementById('wizardLastname').value.trim();
        if (!firstname || !lastname) {
            alert('Inserisci nome e cognome');
            return;
        }
    } else if (currentWizardStep === 2) {
        const email = document.getElementById('wizardEmail').value.trim();
        if (!email || !email.includes('@')) {
            alert('Inserisci una email valida');
            return;
        }
    } else if (currentWizardStep === 3) {
        // Conferma e invia
        const firstname = document.getElementById('wizardFirstname').value.trim();
        const lastname = document.getElementById('wizardLastname').value.trim();
        const email = document.getElementById('wizardEmail').value.trim();

        document.getElementById('wizardConfirmName').textContent = `${firstname} ${lastname}`;
        document.getElementById('wizardConfirmEmail').textContent = email;

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
        const firstname = document.getElementById('wizardFirstname').value.trim();
        const lastname = document.getElementById('wizardLastname').value.trim();
        const email = document.getElementById('wizardEmail').value.trim();
        document.getElementById('wizardConfirmName').textContent = `${firstname} ${lastname}`;
        document.getElementById('wizardConfirmEmail').textContent = email;
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
                .eq('id', data.user.id)
                .maybeSingle();

            // Redirect based on user type
            setTimeout(() => {
                if (orgData) {
                    // It's an organization
                    console.log('✅ Organization login:', orgData.name);
                    window.location.href = '/public/organization-dashboard.html';
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
// REGISTER HANDLER
// ==========================================

async function handleRegister(event) {
    event.preventDefault();
    
    // Ensure Supabase is ready
    const sb = await ensureSupabase();

    const firstName = document.getElementById('registerFirstname').value.trim();
    const lastName = document.getElementById('registerLastname').value.trim();
    const email = document.getElementById('registerEmail').value.trim();
    const password = document.getElementById('registerPassword').value;
    const referralCode = document.getElementById('registerReferral').value.toUpperCase().trim();

    const loading = document.getElementById('registerLoading');
    const form = document.getElementById('registerForm');

    if (form && loading) {
        form.style.display = 'none';
        loading.classList.add('show');
    }

    try {
        // Valida referral code PRIMA della registrazione
        let referrer = null;
        let referrerOrgId = null;

        if (referralCode) {
            // Check if it's an organization code (ORG####)
            if (referralCode.startsWith('ORG')) {
                const { data: orgData, error: orgError } = await sb
                    .from('organizations')
                    .select('id, referral_code, name')
                    .eq('referral_code', referralCode)
                    .maybeSingle();

                if (orgError || !orgData) {
                    throw new Error('CODICE ORGANIZZAZIONE NON VALIDO!');
                }
                referrerOrgId = orgData.id;
            } else {
                // Check users table for normal referral codes
                const { data: referrerData, error: referrerError } = await supabase
                    .from('users')
                    .select('id, referral_code, first_name, last_name')
                    .eq('referral_code', referralCode)
                    .maybeSingle();

                if (referrerError || !referrerData) {
                    throw new Error('CODICE REFERRAL NON VALIDO!');
                }
                referrer = referrerData;
            }
        }

        // Registra l'utente su Supabase Auth
        const { data: authData, error: authError } = await supabase.auth.signUp({
            email: email,
            password: password,
            options: {
                data: {
                    first_name: firstName,
                    last_name: lastName,
                    referral_code_used: referralCode  // 👈 AGGIUNTO!
                }
            }
        });

        if (authError) throw authError;

        // Aggiorna referred_by_id o organization_id tramite API (bypassa RLS)
        if ((referrer || referrerOrgId) && authData.user) {
            console.log('🔄 Inizio aggiornamento referral tramite API...');
            console.log('👤 User ID:', authData.user.id);
            console.log('🎯 Referrer:', referrer);
            console.log('🏢 Org ID:', referrerOrgId);
            
            // Aspetta che il trigger crei l'entry in users
            await new Promise(resolve => setTimeout(resolve, 1500));

            try {
                const apiUrl = window.CDM86_CONFIG?.api?.baseUrl || '/api';
                const response = await fetch(`${apiUrl}/set-referral`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        userId: authData.user.id,
                        referredById: referrer?.id || null,
                        organizationId: referrerOrgId || null
                    })
                });

                const result = await response.json();

                if (!response.ok) {
                    console.error('❌ ERRORE API set-referral:', result);
                    throw new Error(result.error || 'Failed to set referral');
                }

                console.log('✅ Referral impostato via API:', result.data);
                
                // Verifica finale
                const { data: verifyUser, error: verifyError } = await supabase
                    .from('users')
                    .select('id, referred_by_id, organization_id')
                    .eq('id', authData.user.id)
                    .single();
                
                if (verifyError) {
                    console.error('❌ ERRORE verifica utente:', verifyError);
                } else {
                    console.log('🔍 VERIFICA utente dopo update:', verifyUser);
                    if (referrer && !verifyUser.referred_by_id) {
                        console.error('⚠️ PROBLEMA: referred_by_id è ancora NULL dopo UPDATE API!');
                    } else if (referrer && verifyUser.referred_by_id) {
                        console.log('🎉 SUCCESS! referred_by_id impostato correttamente!');
                    }
                }

            } catch (error) {
                console.error('❌ Errore chiamata API set-referral:', error);
            }
        }

        showAlert('✅ Registrazione completata! Controlla la tua email per confermare.', 'success');

        // Switch to login tab
        setTimeout(() => {
            switchLoginTab('login');
            document.getElementById('loginEmail').value = email;
        }, 2000);
    } catch (error) {
        console.error('Register error:', error);
        showAlert(error.message || 'Errore durante la registrazione');
        if (form && loading) {
            form.style.display = 'block';
            loading.classList.remove('show');
        }
    }
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
            .eq('id', session.user.id)
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
        
        // Invia email di recupero password
        const { error } = await supabase.auth.resetPasswordForEmail(email, {
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
    handleForgotPassword
};

// ==========================================
// COMPANY WIZARD (2-STEP REPORT)
// ==========================================

const CompanyWizard = {
    currentStep: 1,
    
    open() {
        const overlay = document.getElementById('companyRequestModalOverlay');
        if (overlay) {
            overlay.classList.add('active');
            this.currentStep = 1;
            this.updateUI();
        }
    },
    
    close() {
        const overlay = document.getElementById('companyRequestModalOverlay');
        if (overlay) {
            overlay.classList.remove('active');
            this.resetForm();
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
            // Get current user
            const { data: { user } } = await supabase.auth.getUser();
            if (!user) throw new Error('Devi essere loggato per segnalare un\'azienda');
            
            // Get user data to find referral code
            const { data: userData, error: userError } = await supabase
                .from('users')
                .select('referral_code')
                .eq('auth_id', user.id)
                .single();
            
            if (userError) throw userError;
            
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
            
            // Save to database
            const { error: insertError } = await supabase
                .from('company_reports')
                .insert({
                    reported_by_user_id: user.id,
                    reported_by_referral_code: userData.referral_code,
                    company_name: companyName,
                    contact_name: contactName,
                    email: email,
                    phone: phone,
                    address: address,
                    sector: finalSector,
                    company_aware: companyAware === 'si',
                    who_knows: finalWhoKnows,
                    preferred_call_time: callTime,
                    status: 'pending'
                });
            
            if (insertError) throw insertError;
            
            // Show success message
            if (loading) {
                loading.innerHTML = `
                    <div style="text-align: center; padding: 40px;">
                        <div style="font-size: 64px; margin-bottom: 20px;">✅</div>
                        <h3 style="color: #10b981; margin-bottom: 10px;">Segnalazione Inviata!</h3>
                        <p style="color: #64748b;">L'amministratore riceverà la tua segnalazione a breve.</p>
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
// AUTO-INITIALIZE
// ==========================================

// Wait for DOM to load and check auth status
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        checkAuthStatus();
    });
} else {
    checkAuthStatus();
}

