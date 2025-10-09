/**
 * Authentication Middleware
 * Verifica JWT tokens e protegge le route
 */

const jwt = require('jsonwebtoken');
const { supabase } = require('../utils/supabase');

// Verifica token JWT e carica user da Supabase
const protect = async (req, res, next) => {
    try {
        // Estrai token dall'header
        let token;
        if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
            token = req.headers.authorization.split(' ')[1];
        }
        
        if (!token) {
            return res.status(401).json({
                success: false,
                message: 'Accesso negato. Token non fornito.'
            });
        }

        // Verifica token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        // Carica user dal database
        const { data: user, error } = await supabase
            .from('users')
            .select('id, email, role, is_active')
            .eq('id', decoded.id)
            .single();

        if (error || !user) {
            return res.status(401).json({
                success: false,
                message: 'Utente non trovato'
            });
        }

        if (!user.is_active) {
            return res.status(403).json({
                success: false,
                message: 'Account disabilitato'
            });
        }
        
        // Aggiungi user info alla request
        req.user = {
            id: user.id,
            email: user.email,
            role: user.role
        };
        
        next();
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({
                success: false,
                message: 'Token scaduto. Effettua nuovamente il login.'
            });
        }
        
        return res.status(401).json({
            success: false,
            message: 'Token non valido'
        });
    }
};

// Alias per compatibilità
const authenticate = protect;

// Verifica ruolo
const authorize = (...roles) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({
                success: false,
                message: 'Non autenticato'
            });
        }
        
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({
                success: false,
                message: `Accesso negato. Ruolo richiesto: ${roles.join(' o ')}`
            });
        }
        
        next();
    };
};

module.exports = {
    protect,
    authenticate,
    authorize
};