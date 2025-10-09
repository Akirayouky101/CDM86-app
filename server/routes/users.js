/**
 * User Routes
 * Gestisce profilo utente, statistiche, transazioni
 */

const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { protect } = require('../middleware/auth'); // Middleware autenticazione

// Applica middleware autenticazione a tutte le route
router.use(protect);

// GET /api/users/profile - Profilo utente
router.get('/profile', userController.getProfile);

// PUT /api/users/profile - Aggiorna profilo
router.put('/profile', userController.updateProfile);

// GET /api/users/dashboard - Dashboard con referral info
router.get('/dashboard', userController.getDashboard);

// GET /api/users/stats - Statistiche utente
router.get('/stats', userController.getStats);

// GET /api/users/points - Saldo punti
router.get('/points', userController.getPoints);

// GET /api/users/transactions - Storico transazioni
router.get('/transactions', userController.getTransactions);

// GET /api/users/referral-link - Link di invito
router.get('/referral-link', userController.getReferralLink);

module.exports = router;