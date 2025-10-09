/**
 * Promotion Routes
 * Gestisce visualizzazione, ricerca e riscatto promozioni
 */

const express = require('express');
const router = express.Router();
const promotionController = require('../controllers/promotionController');
const { protect } = require('../middleware/auth');

// GET /api/promotions - Lista promozioni (public)
router.get('/', promotionController.getPromotions);

// GET /api/promotions/:id - Dettaglio promozione
router.get('/:id', promotionController.getPromotionById);

// GET /api/promotions/category/:category - Per categoria
router.get('/category/:category', promotionController.getByCategory);

// POST /api/promotions/search - Ricerca
router.post('/search', promotionController.searchPromotions);

// GET /api/promotions/user/favorites - Preferite (auth required)
router.get('/user/favorites', protect, promotionController.getFavorites);

// POST /api/promotions/:id/favorite - Aggiungi/rimuovi preferita
router.post('/:id/favorite', protect, promotionController.toggleFavorite);

// POST /api/promotions/:id/redeem - Riscatta promozione (auth required)
router.post('/:id/redeem', protect, promotionController.redeemPromotion);

module.exports = router;