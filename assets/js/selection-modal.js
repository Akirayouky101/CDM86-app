/* ==========================================
   SELECTION MODAL - Standalone JavaScript
   Modale indipendente per selezione User/Business
   ========================================== */

const CDMSelection = {
    overlay: null,
    
    init() {
        this.overlay = document.getElementById('cdmSelectionOverlay');
        
        // Click outside per chiudere (opzionale)
        if (this.overlay) {
            this.overlay.addEventListener('click', (e) => {
                if (e.target === this.overlay) {
                    this.close();
                }
            });
        }
    },
    
    show() {
        if (this.overlay) {
            this.overlay.classList.add('active');
            // NON bloccare mai lo scroll del body
            // L'overlay stesso è scrollabile su mobile
        }
    },
    
    close() {
        if (this.overlay) {
            this.overlay.classList.remove('active');
        }
    },
    
    selectUser() {
        this.close();
        // Apri il login modal normale
        if (typeof showLoginModal === 'function') {
            setTimeout(() => showLoginModal(), 100);
        }
    },
    
    selectBusiness() {
        this.close();
        // Apri il form per aziende
        if (typeof showCompanyRequestModal === 'function') {
            setTimeout(() => showCompanyRequestModal(), 100);
        }
    }
};

// Inizializza quando il DOM è pronto
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => CDMSelection.init());
} else {
    CDMSelection.init();
}

// Mostra automaticamente all'avvio (se necessario)
window.addEventListener('load', () => {
    // Verifica se l'utente NON è già loggato
    const isLoggedIn = localStorage.getItem('isLoggedIn') === 'true';
    if (!isLoggedIn) {
        CDMSelection.show();
    }
});
