/**
 * Referral Controller - Supabase Version
 * Gestisce sistema referral, tracking, validazione
 */

const { supabase } = require('../utils/supabase');

/**
 * GET /api/referrals/my-code
 * Ottieni codice referral personale e link
 */
exports.getMyCode = async (req, res) => {
    try {
        const userId = req.user.id;

        const { data: user, error } = await supabase
            .from('users')
            .select('referral_code, first_name, last_name, referral_count')
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
                code: user.referral_code,
                link: referralLink,
                totalReferrals: user.referral_count,
                shareMessage: `Iscriviti a CDM86 con il mio codice ${user.referral_code} e ricevi 100 punti bonus! 🎁\n${referralLink}`
            }
        });

    } catch (error) {
        console.error('Errore get my code:', error);
        res.status(500).json({
            success: false,
            message: 'Errore del server'
        });
    }
};

/**
 * GET /api/referrals/stats
 * Statistiche referral dettagliate
 */
exports.getStats = async (req, res) => {
    try {
        const userId = req.user.id;

        // Totali per status
        const { data: referrals, error } = await supabase
            .from('referrals')
            .select('*')
            .eq('referrer_id', userId);

        if (error) {
            return res.status(500).json({
                success: false,
                message: 'Errore durante il recupero delle statistiche'
            });
        }

        // Calcola stats
        const stats = {
            total: referrals.length,
            pending: referrals.filter(r => r.status === 'pending').length,
            registered: referrals.filter(r => r.status === 'registered').length,
            verified: referrals.filter(r => r.status === 'verified').length,
            completed: referrals.filter(r => r.status === 'completed').length,
            totalPointsEarned: referrals.reduce((sum, r) => sum + (r.points_earned_referrer || 0), 0),
            sources: {}
        };

        // Raggruppa per source
        referrals.forEach(r => {
            const source = r.source || 'unknown';
            stats.sources[source] = (stats.sources[source] || 0) + 1;
        });

        // Ultimi 7 giorni
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
        
        stats.last7Days = referrals.filter(r => 
            new Date(r.created_at) > sevenDaysAgo
        ).length;

        res.json({
            success: true,
            data: stats
        });

    } catch (error) {
        console.error('Errore get stats:', error);
        res.status(500).json({
            success: false,
            message: 'Errore del server'
        });
    }
};

/**
 * GET /api/referrals/invited
 * Lista persone invitate con dettagli
 */
exports.getInvited = async (req, res) => {
    try {
        const userId = req.user.id;
        const { status, limit = 50, offset = 0 } = req.query;

        let query = supabase
            .from('referrals')
            .select(`
                *,
                referred_user:referred_user_id (
                    id,
                    first_name,
                    last_name,
                    email,
                    referral_code,
                    points,
                    is_verified,
                    created_at
                )
            `)
            .eq('referrer_id', userId)
            .order('created_at', { ascending: false })
            .range(offset, offset + limit - 1);

        if (status) {
            query = query.eq('status', status);
        }

        const { data: referrals, error } = await query;

        if (error) {
            return res.status(500).json({
                success: false,
                message: 'Errore durante il recupero degli invitati'
            });
        }

        const invitedList = referrals.map(r => ({
            id: r.id,
            email: r.referred_email,
            status: r.status,
            codeUsed: r.code_used,
            source: r.source,
            pointsEarned: r.points_earned_referrer,
            clickedAt: r.clicked_at,
            registeredAt: r.registered_at,
            verifiedAt: r.verified_at,
            completedAt: r.completed_at,
            user: r.referred_user ? {
                id: r.referred_user.id,
                name: `${r.referred_user.first_name} ${r.referred_user.last_name}`,
                email: r.referred_user.email,
                referralCode: r.referred_user.referral_code,
                points: r.referred_user.points,
                isVerified: r.referred_user.is_verified,
                joinedAt: r.referred_user.created_at
            } : null
        }));

        res.json({
            success: true,
            data: invitedList
        });

    } catch (error) {
        console.error('Errore get invited:', error);
        res.status(500).json({
            success: false,
            message: 'Errore del server'
        });
    }
};

/**
 * GET /api/referrals/history
 * Storico completo referral con filtri
 */
exports.getHistory = async (req, res) => {
    try {
        const userId = req.user.id;
        const { 
            startDate, 
            endDate, 
            status,
            limit = 100,
            offset = 0 
        } = req.query;

        let query = supabase
            .from('referrals')
            .select('*', { count: 'exact' })
            .eq('referrer_id', userId)
            .order('created_at', { ascending: false })
            .range(offset, offset + limit - 1);

        if (status) {
            query = query.eq('status', status);
        }

        if (startDate) {
            query = query.gte('created_at', startDate);
        }

        if (endDate) {
            query = query.lte('created_at', endDate);
        }

        const { data: history, error, count } = await query;

        if (error) {
            return res.status(500).json({
                success: false,
                message: 'Errore durante il recupero dello storico'
            });
        }

        res.json({
            success: true,
            data: history,
            pagination: {
                total: count,
                limit: parseInt(limit),
                offset: parseInt(offset)
            }
        });

    } catch (error) {
        console.error('Errore get history:', error);
        res.status(500).json({
            success: false,
            message: 'Errore del server'
        });
    }
};

/**
 * POST /api/referrals/track-click
 * Traccia click su link referral
 */
exports.trackClick = async (req, res) => {
    try {
        const { referralCode, source = 'unknown', email } = req.body;

        if (!referralCode) {
            return res.status(400).json({
                success: false,
                message: 'Codice referral richiesto'
            });
        }

        // Trova referrer
        const { data: referrer, error: refError } = await supabase
            .from('users')
            .select('id')
            .eq('referral_code', referralCode.toUpperCase())
            .single();

        if (refError || !referrer) {
            return res.status(404).json({
                success: false,
                message: 'Codice referral non valido'
            });
        }

        // Crea record referral pending
        const { data: referral, error: insertError } = await supabase
            .from('referrals')
            .insert([{
                referrer_id: referrer.id,
                referred_email: email || null,
                code_used: referralCode.toUpperCase(),
                status: 'pending',
                source,
                clicked_at: new Date().toISOString(),
                ip_address: req.ip
            }])
            .select()
            .single();

        if (insertError) {
            console.error('Errore track click:', insertError);
            return res.status(500).json({
                success: false,
                message: 'Errore durante il tracking'
            });
        }

        res.json({
            success: true,
            message: 'Click tracciato',
            data: {
                referralId: referral.id
            }
        });

    } catch (error) {
        console.error('Errore track click:', error);
        res.status(500).json({
            success: false,
            message: 'Errore del server'
        });
    }
};

/**
 * POST /api/referrals/validate
 * Valida codice referral (usato in fase di registrazione)
 */
exports.validateCode = async (req, res) => {
    try {
        const { code } = req.body;

        if (!code) {
            return res.status(400).json({
                success: false,
                message: 'Codice referral richiesto'
            });
        }

        // Cerca referrer
        const { data: referrer, error } = await supabase
            .from('users')
            .select('id, first_name, last_name, referral_code, is_active')
            .eq('referral_code', code.toUpperCase())
            .single();

        if (error || !referrer) {
            return res.status(404).json({
                success: false,
                valid: false,
                message: 'Codice referral non valido'
            });
        }

        if (!referrer.is_active) {
            return res.status(400).json({
                success: false,
                valid: false,
                message: 'Questo codice non è più attivo'
            });
        }

        res.json({
            success: true,
            valid: true,
            message: 'Codice referral valido',
            data: {
                referrerName: `${referrer.first_name} ${referrer.last_name}`,
                code: referrer.referral_code
            }
        });

    } catch (error) {
        console.error('Errore validate code:', error);
        res.status(500).json({
            success: false,
            message: 'Errore del server'
        });
    }
};

/**
 * GET /api/referrals/leaderboard
 * Classifica top referrers
 */
exports.getLeaderboard = async (req, res) => {
    try {
        const { limit = 10 } = req.query;

        // Usa la view top_referrers
        const { data: leaderboard, error } = await supabase
            .from('top_referrers')
            .select('*')
            .limit(limit);

        if (error) {
            return res.status(500).json({
                success: false,
                message: 'Errore durante il recupero della classifica'
            });
        }

        res.json({
            success: true,
            data: leaderboard
        });

    } catch (error) {
        console.error('Errore leaderboard:', error);
        res.status(500).json({
            success: false,
            message: 'Errore del server'
        });
    }
};

module.exports = exports;
