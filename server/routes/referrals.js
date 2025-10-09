/**
 * Referral Routes
 * Gestisce sistema referral, codici, tracking
 */

const express = require('express');
const router = express.Router();
const referralController = require('../controllers/referralController');
const { protect } = require('../middleware/auth');

// Applica auth a tutte le route tranne validate e track-click
router.post('/validate', referralController.validateCode); // Public
router.post('/track-click', referralController.trackClick); // Public

// Route protette
router.use(protect);

// GET /api/referrals/my-code - Codice referral personale
router.get('/my-code', referralController.getMyCode);

// GET /api/referrals/stats - Statistiche referral
router.get('/stats', referralController.getStats);

// GET /api/referrals/invited - Lista persone invitate
router.get('/invited', referralController.getInvited);

// GET /api/referrals/history - Storico referral
router.get('/history', referralController.getHistory);

// GET /api/referrals/leaderboard - Top referrers
router.get('/leaderboard', referralController.getLeaderboard);

module.exports = router;