/**
 * Auth Controller - Supabase Version
 * Gestisce autenticazione con PostgreSQL
 */

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { validationResult } = require('express-validator');
const { supabase } = require('../utils/supabase');

/**
 * Genera JWT token
 */
const generateToken = (userId, role) => {
    return jwt.sign(
        { id: userId, role },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );
};

/**
 * Genera refresh token
 */
const generateRefreshToken = (userId) => {
    return jwt.sign(
        { id: userId },
        process.env.JWT_REFRESH_SECRET,
        { expiresIn: process.env.JWT_REFRESH_EXPIRE || '30d' }
    );
};

/**
 * Genera codice referral unico
 */
const generateReferralCode = (firstName, lastName) => {
    const base = `${firstName.substring(0, 5)}${Math.random().toString(36).substring(2, 6)}`.toUpperCase();
    return base.padEnd(8, '0').substring(0, 8);
};

/**
 * POST /api/auth/register
 * Registrazione nuovo utente - RICHIEDE REFERRAL CODE OBBLIGATORIO
 */
exports.register = async (req, res) => {
    try {
        // Valida input
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                errors: errors.array()
            });
        }

        const { email, password, firstName, lastName, phone, referralCode } = req.body;

        // 🚨 VALIDAZIONE CRITICA: Referral code OBBLIGATORIO
        if (!referralCode) {
            return res.status(400).json({
                success: false,
                message: 'Codice referral obbligatorio. Non è possibile registrarsi senza un codice di invito.'
            });
        }

        // Verifica se email già esistente
        const { data: existingUser } = await supabase
            .from('users')
            .select('id')
            .eq('email', email)
            .single();

        if (existingUser) {
            return res.status(400).json({
                success: false,
                message: 'Email già registrata'
            });
        }

        // 🚨 VALIDA REFERRAL CODE: Deve esistere nel database
        const { data: referrer, error: referrerError } = await supabase
            .from('users')
            .select('id, first_name, last_name, referral_code')
            .eq('referral_code', referralCode.toUpperCase())
            .single();

        if (referrerError || !referrer) {
            return res.status(400).json({
                success: false,
                message: 'Codice referral non valido. Verifica di aver inserito il codice corretto.'
            });
        }

        // Hash password
        const salt = await bcrypt.genSalt(10);
        const passwordHash = await bcrypt.hash(password, salt);

        // Genera referral code unico per il nuovo utente
        let newUserReferralCode = generateReferralCode(firstName, lastName);
        
        // Verifica unicità del codice
        let isUnique = false;
        let attempts = 0;
        while (!isUnique && attempts < 10) {
            const { data: existing } = await supabase
                .from('users')
                .select('id')
                .eq('referral_code', newUserReferralCode)
                .single();

            if (!existing) {
                isUnique = true;
            } else {
                newUserReferralCode = generateReferralCode(firstName, lastName);
                attempts++;
            }
        }

        // Crea nuovo utente
        const { data: newUser, error: createError } = await supabase
            .from('users')
            .insert([{
                email: email.toLowerCase(),
                password_hash: passwordHash,
                first_name: firstName,
                last_name: lastName,
                phone: phone || null,
                referral_code: newUserReferralCode,
                referred_by_id: referrer.id, // 🚨 COLLEGAMENTO REFERRAL
                role: 'user',
                is_verified: false,
                is_active: true,
                points: 100, // Bonus registrazione
            }])
            .select()
            .single();

        if (createError) {
            console.error('Errore creazione utente:', createError);
            return res.status(500).json({
                success: false,
                message: 'Errore durante la registrazione'
            });
        }

        // Crea record referral (status: registered)
        const { error: referralError } = await supabase
            .from('referrals')
            .insert([{
                referrer_id: referrer.id,
                referred_user_id: newUser.id,
                referred_email: email.toLowerCase(),
                code_used: referralCode.toUpperCase(),
                status: 'registered',
                points_earned_referred: 100, // Bonus per chi si registra
                registered_at: new Date().toISOString(),
                source: req.body.source || 'web'
            }]);

        if (referralError) {
            console.error('Errore creazione referral:', referralError);
        }

        // Genera tokens
        const token = generateToken(newUser.id, newUser.role);
        const refreshToken = generateRefreshToken(newUser.id);

        // Response (senza password)
        const userResponse = {
            id: newUser.id,
            email: newUser.email,
            firstName: newUser.first_name,
            lastName: newUser.last_name,
            referralCode: newUser.referral_code,
            referredBy: {
                id: referrer.id,
                name: `${referrer.first_name} ${referrer.last_name}`,
                code: referrer.referral_code
            },
            role: newUser.role,
            points: newUser.points,
            isVerified: newUser.is_verified
        };

        res.status(201).json({
            success: true,
            message: 'Registrazione completata! Ti abbiamo inviato una email di verifica.',
            data: {
                user: userResponse,
                token,
                refreshToken
            }
        });

    } catch (error) {
        console.error('Errore registrazione:', error);
        res.status(500).json({
            success: false,
            message: 'Errore del server durante la registrazione'
        });
    }
};

/**
 * POST /api/auth/login
 * Login utente esistente
 */
exports.login = async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                errors: errors.array()
            });
        }

        const { email, password } = req.body;

        // Cerca utente per email
        const { data: user, error } = await supabase
            .from('users')
            .select('*')
            .eq('email', email.toLowerCase())
            .single();

        if (error || !user) {
            return res.status(401).json({
                success: false,
                message: 'Credenziali non valide'
            });
        }

        // Verifica se utente è attivo
        if (!user.is_active) {
            return res.status(403).json({
                success: false,
                message: 'Account disabilitato. Contatta il supporto.'
            });
        }

        // Verifica password
        const isPasswordValid = await bcrypt.compare(password, user.password_hash);
        if (!isPasswordValid) {
            return res.status(401).json({
                success: false,
                message: 'Credenziali non valide'
            });
        }

        // Ottieni info referrer (chi ha invitato questo utente)
        let referredBy = null;
        if (user.referred_by_id) {
            const { data: referrer } = await supabase
                .from('users')
                .select('id, first_name, last_name, referral_code')
                .eq('id', user.referred_by_id)
                .single();

            if (referrer) {
                referredBy = {
                    id: referrer.id,
                    name: `${referrer.first_name} ${referrer.last_name}`,
                    code: referrer.referral_code
                };
            }
        }

        // Aggiorna ultimo login
        await supabase
            .from('users')
            .update({ last_login: new Date().toISOString() })
            .eq('id', user.id);

        // Genera tokens
        const token = generateToken(user.id, user.role);
        const refreshToken = generateRefreshToken(user.id);

        // Response
        const userResponse = {
            id: user.id,
            email: user.email,
            firstName: user.first_name,
            lastName: user.last_name,
            phone: user.phone,
            referralCode: user.referral_code,
            referredBy,
            role: user.role,
            points: user.points,
            isVerified: user.is_verified,
            referralCount: user.referral_count
        };

        res.json({
            success: true,
            message: 'Login effettuato con successo',
            data: {
                user: userResponse,
                token,
                refreshToken
            }
        });

    } catch (error) {
        console.error('Errore login:', error);
        res.status(500).json({
            success: false,
            message: 'Errore del server durante il login'
        });
    }
};

/**
 * POST /api/auth/refresh
 * Rinnova access token usando refresh token
 */
exports.refreshToken = async (req, res) => {
    try {
        const { refreshToken } = req.body;

        if (!refreshToken) {
            return res.status(400).json({
                success: false,
                message: 'Refresh token mancante'
            });
        }

        // Verifica refresh token
        const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);

        // Genera nuovo access token
        const { data: user } = await supabase
            .from('users')
            .select('id, role, is_active')
            .eq('id', decoded.id)
            .single();

        if (!user || !user.is_active) {
            return res.status(401).json({
                success: false,
                message: 'Utente non valido'
            });
        }

        const newToken = generateToken(user.id, user.role);

        res.json({
            success: true,
            data: {
                token: newToken
            }
        });

    } catch (error) {
        res.status(401).json({
            success: false,
            message: 'Refresh token non valido o scaduto'
        });
    }
};

/**
 * POST /api/auth/validate-referral
 * Valida codice referral PRIMA della registrazione
 */
exports.validateReferral = async (req, res) => {
    try {
        const { referralCode } = req.body;

        if (!referralCode) {
            return res.status(400).json({
                success: false,
                message: 'Codice referral richiesto'
            });
        }

        // Cerca referrer
        const { data: referrer, error } = await supabase
            .from('users')
            .select('id, first_name, last_name, referral_code')
            .eq('referral_code', referralCode.toUpperCase())
            .single();

        if (error || !referrer) {
            return res.status(404).json({
                success: false,
                message: 'Codice referral non valido'
            });
        }

        res.json({
            success: true,
            message: 'Codice referral valido',
            data: {
                referrer: {
                    name: `${referrer.first_name} ${referrer.last_name}`,
                    code: referrer.referral_code
                }
            }
        });

    } catch (error) {
        console.error('Errore validazione referral:', error);
        res.status(500).json({
            success: false,
            message: 'Errore durante la validazione'
        });
    }
};

/**
 * POST /api/auth/logout
 * Logout (lato client rimuove token)
 */
exports.logout = async (req, res) => {
    res.json({
        success: true,
        message: 'Logout effettuato con successo'
    });
};

module.exports = exports;
