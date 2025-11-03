// API per impostare password admin
// Solo per uso temporaneo - da rimuovere dopo setup iniziale

import { createClient } from '@supabase/supabase-js';

export default async function handler(req, res) {
    // Solo POST
    if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
    }

    const { email, password, adminSecret } = req.body;

    // Secret key per proteggere l'API (da rimuovere dopo l'uso)
    const ADMIN_SECRET = 'CDM86_TEMP_ADMIN_SETUP_2025';
    
    if (adminSecret !== ADMIN_SECRET) {
        return res.status(403).json({ error: 'Invalid admin secret' });
    }

    if (!email || !password) {
        return res.status(400).json({ error: 'Email and password required' });
    }

    // Solo per email admin autorizzate
    const allowedEmails = ['akirayouky@cdm86.com', 'claudio@cdm86.com', 'diegomarruchi@outlook.it'];
    if (!allowedEmails.includes(email)) {
        return res.status(403).json({ error: 'Not an admin email' });
    }

    try {
        // TEMPORANEO: Hardcoded per setup iniziale - DA RIMUOVERE DOPO
        const SUPABASE_URL = 'https://uchrjlngfzfibcpdxtky.supabase.co';
        const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjaHJqbG5nZnpmaWJjcGR4dGt5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDAzMTIwNiwiZXhwIjoyMDc1NjA3MjA2fQ.lK0csqtGl2zREC3YsHLfQ_gt4XUAQTQr3bx0CXt96L0';

        const supabaseAdmin = createClient(
            SUPABASE_URL,
            SUPABASE_SERVICE_KEY
        );

        // Trova l'utente
        const { data: users, error: listError } = await supabaseAdmin.auth.admin.listUsers();
        if (listError) throw listError;

        const user = users.users.find(u => u.email === email);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Aggiorna la password
        const { data, error } = await supabaseAdmin.auth.admin.updateUserById(
            user.id,
            { password: password }
        );

        if (error) throw error;

        return res.status(200).json({ 
            success: true, 
            message: `Password updated for ${email}`,
            user: {
                id: user.id,
                email: user.email
            }
        });

    } catch (error) {
        console.error('Set password error:', error);
        return res.status(500).json({ 
            error: error.message || 'Internal server error' 
        });
    }
}
