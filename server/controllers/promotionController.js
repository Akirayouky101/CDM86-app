/**
 * Promotion Controller - Supabase Version
 * Gestisce promozioni, favorites, redemption
 */

const { supabase } = require('../utils/supabase');
const QRCode = require('qrcode');

/**
 * GET /api/promotions
 * Lista promozioni con filtri
 */
exports.getPromotions = async (req, res) => {
    try {
        const {
            category,
            search,
            featured,
            active,
            limit = 20,
            offset = 0,
            sortBy = 'created_at',
            sortOrder = 'desc'
        } = req.query;

        // Convert to numbers
        const numLimit = parseInt(limit) || 20;
        const numOffset = parseInt(offset) || 0;

        console.log('📊 Promotions query:', { numLimit, numOffset, category, featured, active });

        let query = supabase
            .from('promotions')
            .select('*', { count: 'exact' });

        // Filtri
        if (category) {
            query = query.eq('category', category);
        }

        if (featured === 'true') {
            query = query.eq('is_featured', true);
        }

        if (active !== 'false') {
            query = query.eq('is_active', true);
        }

        if (search) {
            query = query.or(`title.ilike.%${search}%,description.ilike.%${search}%,partner_name.ilike.%${search}%`);
        }

        // Ordinamento
        query = query.order(sortBy, { ascending: sortOrder === 'asc' });

        // Paginazione
        query = query.range(numOffset, numOffset + numLimit - 1);

        const { data: promotions, error, count } = await query;

        if (error) {
            return res.status(500).json({
                success: false,
                message: 'Errore durante il recupero delle promozioni'
            });
        }

        console.log('✅ Promotions returned:', { count: promotions?.length, total: count, hasMore: numOffset + numLimit < count });

        res.json({
            success: true,
            data: promotions,
            pagination: {
                total: count,
                limit: numLimit,
                offset: numOffset,
                hasMore: numOffset + numLimit < count
            }
        });

    } catch (error) {
        console.error('Errore get promotions:', error);
        res.status(500).json({
            success: false,
            message: 'Errore del server'
        });
    }
};

/**
 * GET /api/promotions/:id
 * Dettaglio promozione singola
 */
exports.getPromotionById = async (req, res) => {
    try {
        const { id } = req.params;

        const { data: promotion, error } = await supabase
            .from('promotions')
            .select('*')
            .eq('id', id)
            .single();

        if (error || !promotion) {
            return res.status(404).json({
                success: false,
                message: 'Promozione non trovata'
            });
        }

        // Incrementa views
        await supabase
            .from('promotions')
            .update({ stat_views: promotion.stat_views + 1 })
            .eq('id', id);

        // Se utente autenticato, verifica se è nei preferiti
        let isFavorite = false;
        if (req.user) {
            const { data: favorite } = await supabase
                .from('user_favorites')
                .select('id')
                .eq('user_id', req.user.id)
                .eq('promotion_id', id)
                .single();

            isFavorite = !!favorite;
        }

        res.json({
            success: true,
            data: {
                ...promotion,
                isFavorite
            }
        });

    } catch (error) {
        console.error('Errore get promotion:', error);
        res.status(500).json({
            success: false,
            message: 'Errore del server'
        });
    }
};

/**
 * GET /api/promotions/category/:category
 * Promozioni per categoria
 */
exports.getByCategory = async (req, res) => {
    try {
        const { category } = req.params;
        const { limit = 20, offset = 0 } = req.query;

        const { data: promotions, error } = await supabase
            .from('promotions')
            .select('*')
            .eq('category', category)
            .eq('is_active', true)
            .order('is_featured', { ascending: false })
            .order('created_at', { ascending: false })
            .range(offset, offset + limit - 1);

        if (error) {
            return res.status(500).json({
                success: false,
                message: 'Errore durante il recupero delle promozioni'
            });
        }

        res.json({
            success: true,
            data: promotions
        });

    } catch (error) {
        console.error('Errore get by category:', error);
        res.status(500).json({
            success: false,
            message: 'Errore del server'
        });
    }
};

/**
 * POST /api/promotions/search
 * Ricerca avanzata promozioni
 */
exports.searchPromotions = async (req, res) => {
    try {
        const { query: searchQuery, categories, tags, city, minDiscount, maxDiscount } = req.body;

        let query = supabase
            .from('promotions')
            .select('*')
            .eq('is_active', true);

        // Full-text search
        if (searchQuery) {
            query = query.textSearch('search_vector', searchQuery, {
                type: 'websearch',
                config: 'italian'
            });
        }

        // Filtro categorie
        if (categories && categories.length > 0) {
            query = query.in('category', categories);
        }

        // Filtro tags
        if (tags && tags.length > 0) {
            query = query.contains('tags', tags);
        }

        // Filtro città
        if (city) {
            query = query.ilike('partner_city', `%${city}%`);
        }

        // Filtro sconto
        if (minDiscount) {
            query = query.gte('discount_value', minDiscount);
        }
        if (maxDiscount) {
            query = query.lte('discount_value', maxDiscount);
        }

        const { data: results, error } = await query.limit(50);

        if (error) {
            return res.status(500).json({
                success: false,
                message: 'Errore durante la ricerca'
            });
        }

        res.json({
            success: true,
            data: results,
            count: results.length
        });

    } catch (error) {
        console.error('Errore search:', error);
        res.status(500).json({
            success: false,
            message: 'Errore del server'
        });
    }
};

/**
 * GET /api/promotions/user/favorites
 * Promozioni preferite dell'utente
 */
exports.getFavorites = async (req, res) => {
    try {
        const userId = req.user.id;

        const { data: favorites, error } = await supabase
            .from('user_favorites')
            .select(`
                promotion_id,
                created_at,
                promotions (*)
            `)
            .eq('user_id', userId)
            .order('created_at', { ascending: false });

        if (error) {
            console.error('Supabase error in getFavorites:', error);
            return res.status(500).json({
                success: false,
                message: 'Errore durante il recupero dei preferiti'
            });
        }

        const promotions = favorites.map(f => ({
            ...f.promotions,
            favoritedAt: f.created_at
        }));

        res.json({
            success: true,
            data: promotions
        });

    } catch (error) {
        console.error('Errore get favorites:', error);
        res.status(500).json({
            success: false,
            message: 'Errore del server'
        });
    }
};

/**
 * POST /api/promotions/:id/favorite
 * Aggiungi/rimuovi promozione dai preferiti (toggle)
 */
exports.toggleFavorite = async (req, res) => {
    try {
        const userId = req.user.id;
        const { id: promotionId } = req.params;

        console.log('Toggle favorite:', { userId, promotionId });

        // Verifica se promozione esiste
        const { data: promotion, error: promoError } = await supabase
            .from('promotions')
            .select('id')
            .eq('id', promotionId)
            .single();

        if (promoError || !promotion) {
            console.error('Promotion not found:', promoError);
            return res.status(404).json({
                success: false,
                message: 'Promozione non trovata'
            });
        }

        // Verifica se già nei preferiti
        const { data: existing, error: checkError } = await supabase
            .from('user_favorites')
            .select('user_id, promotion_id')
            .eq('user_id', userId)
            .eq('promotion_id', promotionId)
            .maybeSingle();

        console.log('Check existing favorite:', { existing, checkError });

        if (existing) {
            // Rimuovi dai preferiti
            console.log('Removing from favorites...');
            const { error: deleteError } = await supabase
                .from('user_favorites')
                .delete()
                .eq('user_id', userId)
                .eq('promotion_id', promotionId);

            if (deleteError) {
                console.error('Delete error:', deleteError);
                return res.status(500).json({
                    success: false,
                    message: 'Errore durante la rimozione dai preferiti',
                    error: deleteError.message
                });
            }

            console.log('Removed successfully');
            return res.json({
                success: true,
                message: 'Promozione rimossa dai preferiti',
                data: { isFavorite: false }
            });
        } else {
            // Aggiungi ai preferiti
            console.log('Adding to favorites...');
            const { error: insertError } = await supabase
                .from('user_favorites')
                .insert([{
                    user_id: userId,
                    promotion_id: promotionId
                }]);

            if (insertError) {
                console.error('Insert error:', insertError);
                return res.status(500).json({
                    success: false,
                    message: 'Errore durante l\'aggiunta ai preferiti',
                    error: insertError.message
                });
            }

            console.log('Added successfully');
            return res.json({
                success: true,
                message: 'Promozione aggiunta ai preferiti',
                data: { isFavorite: true }
            });
        }

    } catch (error) {
        console.error('Errore toggle favorite:', error);
        res.status(500).json({
            success: false,
            message: 'Errore del server',
            error: error.message
        });
    }
};

/**
 * POST /api/promotions/:id/redeem
 * Riscatta promozione - genera QR code
 */
exports.redeemPromotion = async (req, res) => {
    try {
        const userId = req.user.id;
        const { id: promotionId } = req.params;

        // Verifica promozione
        const { data: promotion, error: promoError } = await supabase
            .from('promotions')
            .select('*')
            .eq('id', promotionId)
            .single();

        if (promoError || !promotion) {
            return res.status(404).json({
                success: false,
                message: 'Promozione non trovata'
            });
        }

        if (!promotion.is_active) {
            return res.status(400).json({
                success: false,
                message: 'Promozione non attiva'
            });
        }

        // Verifica punti utente se richiesti
        if (promotion.points_cost > 0) {
            const { data: user } = await supabase
                .from('users')
                .select('points')
                .eq('id', userId)
                .single();

            if (user.points < promotion.points_cost) {
                return res.status(400).json({
                    success: false,
                    message: 'Punti insufficienti'
                });
            }
        }

        // Genera codice transazione unico
        const transactionCode = `TRX-${Date.now()}-${Math.random().toString(36).substring(2, 8).toUpperCase()}`;

        // Genera QR code
        const qrData = JSON.stringify({
            transactionCode,
            promotionId,
            userId,
            timestamp: new Date().toISOString()
        });

        const qrCodeUrl = await QRCode.toDataURL(qrData);

        // Crea transazione
        const { data: transaction, error: txError } = await supabase
            .from('transactions')
            .insert([{
                user_id: userId,
                promotion_id: promotionId,
                transaction_code: transactionCode,
                qr_code: qrCodeUrl,
                points_used: promotion.points_cost || 0,
                status: 'pending'
            }])
            .select()
            .single();

        if (txError) {
            return res.status(500).json({
                success: false,
                message: 'Errore durante la creazione della transazione'
            });
        }

        // Decrementa punti se necessario
        if (promotion.points_cost > 0) {
            await supabase.rpc('decrement_user_points', {
                user_id_param: userId,
                points_param: promotion.points_cost
            });
        }

        // Incrementa stat_redemptions
        await supabase
            .from('promotions')
            .update({ stat_redemptions: promotion.stat_redemptions + 1 })
            .eq('id', promotionId);

        res.json({
            success: true,
            message: 'Promozione riscattata con successo',
            data: {
                transaction: {
                    id: transaction.id,
                    transactionCode: transaction.transaction_code,
                    qrCode: transaction.qr_code,
                    status: transaction.status,
                    createdAt: transaction.created_at
                },
                promotion: {
                    id: promotion.id,
                    title: promotion.title,
                    partnerName: promotion.partner_name
                }
            }
        });

    } catch (error) {
        console.error('Errore redeem promotion:', error);
        res.status(500).json({
            success: false,
            message: 'Errore del server'
        });
    }
};

module.exports = exports;
