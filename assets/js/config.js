/**
 * CDM86 Configuration File
 */

const CDM86_CONFIG = {
    // Supabase Configuration
    supabase: {
        url: 'https://uchrjlngfzfibcpdxtky.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwMzEyMDYsImV4cCI6MjA3NTYwNzIwNn0.64JK3OhYJi2YtrErctNAp_sCcSHwB656NVLdooyceOM'
    },

    // API Configuration
    api: {
        baseUrl: window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1' 
            ? 'http://localhost:3000/api' 
            : 'https://cdm86project.vercel.app/api',
        timeout: 30000
    },

    // Branding
    branding: {
        siteName: "CDM86",
        domain: "cdm86.com",
        logoIcon: "fas fa-cube",
        tagline: "Dashboard Professionale"
    },

    // Colori personalizzati
    colors: {
        primary: "#2563eb",
        primaryDark: "#1d4ed8",
        primaryLight: "#3b82f6",
        accent: "#10b981",
        warning: "#f59e0b",
        error: "#ef4444",
        success: "#10b981"
    }
};

// Export configurazione
if (typeof window !== 'undefined') {
    window.CDM86_CONFIG = CDM86_CONFIG;
    window.SUPABASE_URL = CDM86_CONFIG.supabase.url;
    window.SUPABASE_KEY = CDM86_CONFIG.supabase.anonKey;
    window.API_URL = CDM86_CONFIG.api.baseUrl;
}

if (typeof module !== 'undefined' && module.exports) {
    module.exports = CDM86_CONFIG;
}
