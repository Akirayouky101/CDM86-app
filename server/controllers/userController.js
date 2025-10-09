/**
 * User Controller - Supabase Version
 * Gestisce profilo utente, dashboard, statistiche
 */

const { supabase } = require('../utils/supabase');

/**
 * GET /api/users/profile
 * Ottieni profilo utente completo
 */
exports.getProfile = async (req, res) => {
    try {
        const userId = req.user.id; // Viene da middleware auth

        // Query user con info referrer
        const { data: user, error } = await supabase
            .from('users')
            .select(`
                *,
                referrer:referred_by_id (
                    id,
                    first_name,
                    last_name,
                    referral_code
                )
            `)
            .eq('id', userId)
            .single();

        if (error || !user) {
            return res.status(404).json({
                success: false,
                message: 'Utente non trovato'
            });
        }

        // Response
        const userProfile = {
            id: user.id,
            email: user.email,
            firstName: user.first_name,
            lastName: user.last_name,
            phone: user.phone,
            referralCode: user.referral_code,
            referredBy: user.referrer ? {
                id: user.referrer.id,
                name: `${user.referrer.first_name} ${user.referrer.last_name}`,
                code: user.referrer.referral_code
            } : null,
            role: user.role,
            points: user.points,
            referralCount: user.referral_count,
            isVerified: user.is_verified,
            isActive: user.is_active,
            createdAt: user.created_at,
            lastLogin: user.last_login
        };

        res.json({
            success: true,
            data: userProfile
        });

    } catch (error) {
        console.error('Errore get profile:', error);
        res.status(500).json({
            success: false,
            message: 'Errore durante il recupero del profilo'
        });
    }
};

/**
 * GET /api/users/dashboard
 * Dashboard utente con info referral complete
 * 🚨 IMPORTANTE: Mostra chi mi ha invitato + lista persone che HO invitato
 */
exports.getDashboard = async (req, res) => {
    try {
        const userId = req.user.id;

        // 1. Info utente base
        const { data: user, error: userError } = await supabase
            .from('users')
            .select('*')
            .eq('id', userId)
            .single();

        if (userError || !user) {
            return res.status(404).json({
                success: false,
                message: 'Utente non trovato'
            });
        }

        // 2. Chi mi ha invitato (referrer)
        let referredBy = null;
        if (user.referred_by_id) {
            const { data: referrer } = await supabase
                .from('users')
                .select('id, first_name, last_name, referral_code, email')
                .eq('id', user.referred_by_id)
                .single();

            if (referrer) {
                referredBy = {
                    id: referrer.id,
                    name: `${referrer.first_name} ${referrer.last_name}`,
                    email: referrer.email,
                    code: referrer.referral_code
                };
            }
        }

        // 3. 🚨 Persone che HO invitato (referred users) - con i loro codici referral
        const { data: referredUsers, error: referredError } = await supabase
            .from('users')
            .select('id, first_name, last_name, email, referral_code, points, is_verified, created_at')
            .eq('referred_by_id', userId)
            .order('created_at', { ascending: false });

        if (referredError) {
            console.error('Errore caricamento referred users:', referredError);
        }

        // 4. Statistiche referral
        const { data: referralStats, error: statsError } = await supabase
            .from('referrals')
            .select('status')
            .eq('referrer_id', userId);

        const stats = {
            totalReferrals: referralStats?.length || 0,
            pending: referralStats?.filter(r => r.status === 'pending').length || 0,
            registered: referralStats?.filter(r => r.status === 'registered').length || 0,
            verified: referralStats?.filter(r => r.status === 'verified').length || 0,
            completed: referralStats?.filter(r => r.status === 'completed').length || 0
        };

        // 5. Promozioni preferite
        const { data: favorites } = await supabase
            .from('user_favorites')
            .select(`
                promotion:promotions (
                    id,
                    title,
                    slug,
                    short_description,
                    image_thumbnail,
                    partner_name,
                    discount_type,
                    discount_value
                )
            `)
            .eq('user_id', userId)
            .limit(5);

        // 6. Ultime transazioni
        const { data: recentTransactions } = await supabase
            .from('transactions')
            .select('id, promotion_id, status, points_used, qr_code, created_at')
            .eq('user_id', userId)
            .order('created_at', { ascending: false })
            .limit(5);

        // Response dashboard completa
        res.json({
            success: true,
            data: {
                user: {
                    id: user.id,
                    email: user.email,
                    firstName: user.first_name,
                    lastName: user.last_name,
                    referralCode: user.referral_code,
                    points: user.points,
                    referralCount: user.referral_count,
                    role: user.role,
                    isVerified: user.is_verified
                },
                referredBy, // Chi mi ha invitato
                referredUsers: referredUsers?.map(u => ({ // Persone che HO invitato
                    id: u.id,
                    name: `${u.first_name} ${u.last_name}`,
                    email: u.email,
                    referralCode: u.referral_code, // 🚨 Codice referral della persona invitata
                    points: u.points,
                    isVerified: u.is_verified,
                    joinedAt: u.created_at
                })) || [],
                referralStats: stats,
                favorites: favorites?.map(f => f.promotion).filter(Boolean) || [],
                recentTransactions: recentTransactions || []
            }
        });

    } catch (error) {
        console.error('Errore dashboard:', error);
        res.status(500).json({
            success: false,
            message: 'Errore durante il caricamento della dashboard'
        });
    }
};

/**
 * GET /api/users/stats
 * Statistiche dettagliate utente
 */
exports.getStats = async (req, res) => {
    try {
        const userId = req.user.id;

        // Usa la view user_stats creata nel database
        const { data: stats, error } = await supabase
            .from('user_stats')
            .select('*')
            .eq('user_id', userId)
            .single();

        if (error) {
            console.error('Errore stats:', error);
            return res.status(500).json({
                success: false,
                message: 'Errore durante il recupero delle statistiche'
            });
        }

        res.json({
            success: true,
            data: stats
        });

    } catch (error) {
        console.error('Errore get stats:', error);
        res.status(500).json({
            success: false,
            message: 'Errore durante il recupero delle statistiche'
        });
    }
};

/**
 * PUT /api/users/profile
 * Aggiorna profilo utente
 */
exports.updateProfile = async (req, res) => {
    try {
        const userId = req.user.id;
        const { firstName, lastName, phone } = req.body;

        const updates = {};
        if (firstName) updates.first_name = firstName;
        if (lastName) updates.last_name = lastName;
        if (phone !== undefined) updates.phone = phone;

        const { data: updatedUser, error } = await supabase
            .from('users')
            .update(updates)
            .eq('id', userId)
            .select()
            .single();

        if (error) {
            return res.status(500).json({
                success: false,
                message: 'Errore durante l\'aggiornamento del profilo'
            });
        }

        res.json({
            success: true,
            message: 'Profilo aggiornato con successo',
            data: {
                firstName: updatedUser.first_name,
                lastName: updatedUser.last_name,
                phone: updatedUser.phone
            }
        });

    } catch (error) {
        console.error('Errore update profile:', error);
        res.status(500).json({
            success: false,
            message: 'Errore durante l\'aggiornamento'
        });
    }
};

/**
 * GET /api/users/points
 * Saldo punti utente
 */
exports.getPoints = async (req, res) => {
    try {
        const userId = req.user.id;

        const { data: user, error } = await supabase
            .from('users')
            .select('points')
            .eq('id', userId)
            .single();

        if (error || !user) {
            return res.status(404).json({
                success: false,
                message: 'Utente non trovato'
            });
        }

        res.json({
            success: true,
            data: {
                points: user.points
            }
        });

    } catch (error) {
        console.error('Errore get points:', error);
        res.status(500).json({
            success: false,
            message: 'Errore durante il recupero dei punti'
        });
    }
};

/**
 * GET /api/users/transactions
 * Storico transazioni utente
 */
exports.getTransactions = async (req, res) => {
    try {
        const userId = req.user.id;
        const { status, limit = 20, offset = 0 } = req.query;

        let query = supabase
            .from('transactions')
            .select(`
                *,
                promotion:promotions (
                    id,
                    title,
                    partner_name,
                    image_thumbnail
                )
            `)
            .eq('user_id', userId)
            .order('created_at', { ascending: false })
            .range(offset, offset + limit - 1);

        if (status) {
            query = query.eq('status', status);
        }

        const { data: transactions, error } = await query;

        if (error) {
            return res.status(500).json({
                success: false,
                message: 'Errore durante il recupero delle transazioni'
            });
        }

        res.json({
            success: true,
            data: transactions,
            pagination: {
                limit: parseInt(limit),
                offset: parseInt(offset)
            }
        });

    } catch (error) {
        console.error('Errore get transactions:', error);
        res.status(500).json({
            success: false,
            message: 'Errore durante il recupero delle transazioni'
        });
    }
};

/**
 * GET /api/users/referral-link
 * Ottieni link di invito personalizzato
 */
exports.getReferralLink = async (req, res) => {
    try {
        const userId = req.user.id;

        const { data: user, error } = await supabase
            .from('users')
            .select('referral_code')
            .eq('id', userId)
            .single();

        if (error || !user) {
            return res.status(404).json({
                success: false,
                message: 'Utente non trovato'
            });
        }

        const appUrl = process.env.APP_URL || 'http://localhost:3000';
        const referralLink = `${appUrl}/register?ref=${user.referral_code}`;

        res.json({
            success: true,
            data: {
                referralCode: user.referral_code,
                referralLink,
                shareMessage: `Iscriviti a CDM86 usando il mio codice ${user.referral_code} e ottieni 100 punti! ${referralLink}`
            }
        });

    } catch (error) {
        console.error('Errore get referral link:', error);
        res.status(500).json({
            success: false,
            message: 'Errore durante il recupero del link'
        });
    }
};

module.exports = exports;
