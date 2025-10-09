/**
 * Authentication Routes
 * Gestisce registrazione, login, logout
 */

const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const authController = require('../controllers/authController');

// Validation rules
const registerValidation = [
    body('email').isEmail().normalizeEmail().withMessage('Email non valida'),
    body('password').isLength({ min: 6 }).withMessage('Password min 6 caratteri'),
    body('firstName').trim().notEmpty().withMessage('Nome richiesto'),
    body('lastName').trim().notEmpty().withMessage('Cognome richiesto'),
    body('referralCode').trim().notEmpty().withMessage('Codice referral obbligatorio') // 🚨 OBBLIGATORIO
];

const loginValidation = [
    body('email').isEmail().normalizeEmail().withMessage('Email non valida'),
    body('password').notEmpty().withMessage('Password richiesta')
];

// Routes
router.post('/register', registerValidation, authController.register);
router.post('/login', loginValidation, authController.login);
router.post('/logout', authController.logout);
router.post('/refresh', authController.refreshToken);
router.post('/validate-referral', authController.validateReferral); // Valida referral PRIMA di registrazione

// TODO: Implementare dopo
router.post('/forgot-password', async (req, res) => {
    res.json({ message: 'Forgot password endpoint - da implementare' });
});

router.post('/reset-password', async (req, res) => {
    res.json({ message: 'Reset password endpoint - da implementare' });
});

router.post('/verify-email', async (req, res) => {
    res.json({ message: 'Verify email endpoint - da implementare' });
});

module.exports = router;