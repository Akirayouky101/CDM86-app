/* ============================================
   LOGIN MODAL HANDLER - CDM86
   Gestisce login/registrazione nell'homepage
   ============================================ */

// Import Supabase
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

// Inizializza Supabase
const supabaseUrl = 'https://uchrjlngfzfibcpdxtky.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwMzEyMDYsImV4cCI6MjA3NTYwNzIwNn0.64JK3OhYJi2YtrErctNAp_sCcSHwB656NVLdooyceOM';
const supabase = createClient(supabaseUrl, supabaseKey);

// Variabili globali
let currentWizardStep = 1;
let companyHasReferral = false;

// ==========================================
// SELECTION MODAL (Prima schermata)
// ==========================================

export function showSelectionModal() {
    const overlay = document.getElementById('selectionModalOverlay');
    if (overlay) {
        overlay.classList.add('active');
        document.body.style.overflow = 'hidden';
    }
}

export function closeSelectionModal() {
    const overlay = document.getElementById('selectionModalOverlay');
    if (overlay) {
        overlay.classList.remove('active');
        document.body.style.overflow = '';
    }
}

export function selectUser() {
    closeSelectionModal();
    showReferralModal();
}

export function selectCompany() {
    closeSelectionModal();
    showCompanyRequestModal();
}

export function showExistingUserLogin() {
    closeSelectionModal();
    showLoginModal();
}

// ==========================================
// COMPANY REQUEST MODAL
// ==========================================

export function showCompanyRequestModal() {
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

export function closeCompanyRequestModal() {
    const overlay = document.getElementById('companyRequestModalOverlay');
    if (overlay) {
        overlay.classList.remove('active');
        document.getElementById('companyRequestForm')?.reset();
        document.getElementById('companyRequestFormNoRef')?.reset();
    }
}

export function companyHasReferralYes() {
    document.getElementById('companyReferralQuestion').style.display = 'none';
    document.getElementById('companyFormWithReferral').classList.add('active');
    companyHasReferral = true;
}

export function companyHasReferralNo() {
    document.getElementById('companyReferralQuestion').style.display = 'none';
    document.getElementById('companyFormWithoutReferral').classList.add('active');
    companyHasReferral = false;
}

// ==========================================
// COMPANY REQUEST SUBMISSION
// ==========================================

export async function handleCompanyRequest(event) {
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

export async function handleCompanyRequestNoRef(event) {
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

export function showLoginModal() {
    const overlay = document.getElementById('loginModalOverlay');
    if (overlay) {
        overlay.classList.add('active');
        document.body.style.overflow = 'hidden';
    }
}

export function closeLoginModal() {
    const overlay = document.getElementById('loginModalOverlay');
    if (overlay) {
        overlay.classList.remove('active');
        document.body.style.overflow = '';
    }
}

export function showReferralModal() {
    const overlay = document.getElementById('referralModalOverlay');
    if (overlay) {
        overlay.classList.add('active');
        document.getElementById('referralModalQuestion').style.display = 'block';
        document.getElementById('referralModalWizard').classList.remove('active');
        currentWizardStep = 1;
    }
}

export function closeReferralModal() {
    const overlay = document.getElementById('referralModalOverlay');
    if (overlay) {
        overlay.classList.remove('active');
    }
}

// ==========================================
// TAB SWITCHING
// ==========================================

export function switchLoginTab(tabName) {
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

export function handleHasCode() {
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

export function showWizard() {
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

export function wizardBack() {
    if (currentWizardStep > 1) {
        currentWizardStep--;
        updateWizardStep();
    }
}

export function wizardNext() {
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

export async function handleLogin(event) {
    event.preventDefault();

    const email = document.getElementById('loginEmail').value.trim();
    const password = document.getElementById('loginPassword').value;

    const loading = document.getElementById('loginLoading');
    const form = document.getElementById('loginForm');

    if (form && loading) {
        form.style.display = 'none';
        loading.classList.add('show');
    }

    try {
        const { data, error } = await supabase.auth.signInWithPassword({
            email: email,
            password: password
        });

        if (error) throw error;

        if (data.user) {
            showAlert('✅ Login effettuato! Reindirizzamento...', 'success');

            // Check if user is an organization
            const { data: orgData } = await supabase
                .from('organizations')
                .select('id')
                .eq('id', data.user.id)
                .single();

            // Redirect based on user type
            setTimeout(() => {
                if (orgData) {
                    window.location.href = '/public/organization-dashboard.html';
                } else {
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

export async function handleRegister(event) {
    event.preventDefault();

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
                const { data: orgData, error: orgError } = await supabase
                    .from('organizations')
                    .select('id, referral_code, name')
                    .eq('referral_code', referralCode)
                    .single();

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
                    .single();

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
                    last_name: lastName
                }
            }
        });

        if (authError) throw authError;

        // Aggiorna referred_by_id o organization_id
        if ((referrer || referrerOrgId) && authData.user) {
            console.log('🔄 Inizio aggiornamento referral...');
            console.log('👤 User ID:', authData.user.id);
            console.log('🎯 Referrer:', referrer);
            console.log('🏢 Org ID:', referrerOrgId);
            
            // Aspetta che il trigger crei l'entry in users
            await new Promise(resolve => setTimeout(resolve, 1500));

            const updateData = {};
            if (referrer) {
                updateData.referred_by_id = referrer.id;
                console.log('✅ Imposto referred_by_id:', referrer.id);
            }
            if (referrerOrgId) {
                updateData.organization_id = referrerOrgId;
                console.log('✅ Imposto organization_id:', referrerOrgId);
            }

            console.log('📝 UpdateData:', updateData);

            const { data: updateResult, error: updateError } = await supabase
                .from('users')
                .update(updateData)
                .eq('id', authData.user.id)
                .select();

            if (updateError) {
                console.error('❌ ERRORE aggiornamento referral:', updateError);
            } else {
                console.log('✅ UPDATE riuscito:', updateResult);
            }
            
            // Verifica che l'update sia andato a buon fine
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
                    console.error('⚠️ PROBLEMA: referred_by_id è ancora NULL dopo UPDATE!');
                }
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

export async function checkAuthStatus() {
    const { data: { session } } = await supabase.auth.getSession();
    
    const loginBtn = document.getElementById('login-btn');
    if (!loginBtn) return;

    if (session && session.user) {
        // User is logged in
        const { data: userData } = await supabase
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
// INITIALIZE
// ==========================================

// Wait for DOM to load
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        checkAuthStatus();
    });
} else {
    checkAuthStatus();
}

// Export per uso globale
window.LoginModal = {
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
    handleRegister
};
