/**
 * CDM86 Configuration File
 * Personalizza facilmente la tua dashboard
 */

const CDM86_CONFIG = {
    // Branding
    branding: {
        siteName: "CDM86",
        domain: "cdm86.com",
        logoIcon: "fas fa-cube",
        tagline: "Dashboard Professionale"
    },

    // Colori personalizzati (sovrascrivi le CSS custom properties)
    colors: {
        primary: "#2563eb",
        primaryDark: "#1d4ed8",
        primaryLight: "#3b82f6",
        accent: "#10b981",
        warning: "#f59e0b",
        error: "#ef4444",
        success: "#10b981"
    },

    // Configurazione pannelli
    panels: {
        users: {
            enabled: true,
            title: "Dashboard Utenti",
            description: "Pannello principale per la gestione e visualizzazione delle funzionalità utente"
        },
        admin: {
            enabled: true,
            title: "Dashboard Amministratori", 
            description: "Pannello per la gestione avanzata del sistema"
        },
        developer: {
            enabled: true,
            title: "Dashboard Sviluppatori",
            description: "Strumenti e risorse per sviluppatori"
        }
    },

    // Statistiche predefinite
    defaultStats: [
        {
            icon: "fas fa-chart-line",
            title: "Progetti Attivi",
            value: 24,
            change: 12,
            changeType: "positive"
        },
        {
            icon: "fas fa-tasks", 
            title: "Task Completati",
            value: 156,
            change: 8,
            changeType: "positive"
        },
        {
            icon: "fas fa-clock",
            title: "Ore Lavorate", 
            value: 340,
            change: 2,
            changeType: "neutral"
        },
        {
            icon: "fas fa-trophy",
            title: "Obiettivi Raggiunti",
            value: "89%",
            change: 15,
            changeType: "positive"
        }
    ],

    // Progetti esempio
    defaultProjects: [
        {
            id: 1,
            name: "Sito Web CDM86",
            description: "Sviluppo interfaccia utente",
            icon: "fas fa-globe",
            status: "active",
            statusText: "In Corso",
            progress: 75,
            date: "Aggiornato 2 ore fa"
        },
        {
            id: 2,
            name: "App Mobile", 
            description: "Ottimizzazione responsive",
            icon: "fas fa-mobile-alt",
            status: "planning",
            statusText: "Pianificazione", 
            progress: 25,
            date: "Inizia domani"
        },
        {
            id: 3,
            name: "Sistema Database",
            description: "Integrazione backend", 
            icon: "fas fa-database",
            status: "completed",
            statusText: "Completato",
            progress: 100,
            date: "Finito ieri"
        }
    ],

    // Azioni rapide
    quickActions: [
        {
            text: "Nuovo Progetto",
            icon: "fas fa-plus",
            type: "primary",
            action: "newProject"
        },
        {
            text: "Carica File",
            icon: "fas fa-upload", 
            type: "secondary",
            action: "uploadFile"
        },
        {
            text: "Condividi",
            icon: "fas fa-share",
            type: "tertiary", 
            action: "share"
        }
    ],

    // Notifiche esempio
    defaultNotifications: [
        {
            icon: "fas fa-bell",
            text: "Nuovo aggiornamento disponibile",
            time: "5 min fa"
        },
        {
            icon: "fas fa-check", 
            text: "Task completato con successo",
            time: "1 ora fa"
        }
    ],

    // Impostazioni interfaccia
    ui: {
        animationsEnabled: true,
        autoNotifications: true,
        notificationInterval: 10000, // 10 secondi
        toastDuration: 3000, // 3 secondi
        keyboardShortcuts: true,
        mobileBreakpoint: 768
    },

    // Performance
    performance: {
        lazyLoadImages: true,
        optimizeAnimations: true,
        preloadCriticalAssets: true
    }
};

// Applica configurazione personalizzata se presente
if (typeof window !== 'undefined') {
    window.CDM86_CONFIG = CDM86_CONFIG;
    
    // Applica colori personalizzati
    if (CDM86_CONFIG.colors) {
        const root = document.documentElement;
        Object.entries(CDM86_CONFIG.colors).forEach(([key, value]) => {
            const cssVar = key.replace(/([A-Z])/g, '-$1').toLowerCase();
            root.style.setProperty(`--${cssVar}`, value);
        });
    }
}

// Export per Node.js se necessario
if (typeof module !== 'undefined' && module.exports) {
    module.exports = CDM86_CONFIG;
}