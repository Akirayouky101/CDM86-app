/**
 * User Model
 * Schema per utenti della piattaforma
 */

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
    // Basic Info
    email: {
        type: String,
        required: [true, 'Email richiesta'],
        unique: true,
        lowercase: true,
        trim: true,
        match: [/^\S+@\S+\.\S+$/, 'Email non valida']
    },
    password: {
        type: String,
        required: [true, 'Password richiesta'],
        minlength: [6, 'Password minimo 6 caratteri'],
        select: false
    },
    firstName: {
        type: String,
        required: [true, 'Nome richiesto'],
        trim: true
    },
    lastName: {
        type: String,
        required: [true, 'Cognome richiesto'],
        trim: true
    },
    phone: {
        type: String,
        trim: true
    },
    avatar: {
        type: String,
        default: null
    },

    // Referral System
    referralCode: {
        type: String,
        unique: true,
        required: true,
        uppercase: true
    },
    referredBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        default: null
    },
    referralCount: {
        type: Number,
        default: 0
    },
    
    // Points & Rewards
    points: {
        type: Number,
        default: 0,
        min: 0
    },
    totalPointsEarned: {
        type: Number,
        default: 0
    },
    totalPointsSpent: {
        type: Number,
        default: 0
    },

    // Favorites
    favoritePromotions: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Promotion'
    }],

    // Status & Role
    isVerified: {
        type: Boolean,
        default: false
    },
    isActive: {
        type: Boolean,
        default: true
    },
    role: {
        type: String,
        enum: ['user', 'partner', 'admin'],
        default: 'user'
    },

    // Security
    verificationToken: String,
    verificationExpires: Date,
    resetPasswordToken: String,
    resetPasswordExpires: Date,
    loginAttempts: {
        type: Number,
        default: 0
    },
    lockUntil: Date,

    // Metadata
    lastLogin: Date,
    createdAt: {
        type: Date,
        default: Date.now
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true }
});

// Indexes
userSchema.index({ email: 1 });
userSchema.index({ referralCode: 1 });
userSchema.index({ referredBy: 1 });
userSchema.index({ createdAt: -1 });

// Virtual for full name
userSchema.virtual('fullName').get(function() {
    return `${this.firstName} ${this.lastName}`;
});

// Virtual for account lock status
userSchema.virtual('isLocked').get(function() {
    return !!(this.lockUntil && this.lockUntil > Date.now());
});

// Pre-save middleware: Hash password
userSchema.pre('save', async function(next) {
    if (!this.isModified('password')) return next();
    
    try {
        const salt = await bcrypt.genSalt(10);
        this.password = await bcrypt.hash(this.password, salt);
        next();
    } catch (error) {
        next(error);
    }
});

// Pre-save middleware: Update timestamp
userSchema.pre('save', function(next) {
    this.updatedAt = Date.now();
    next();
});

// Method: Compare password
userSchema.methods.comparePassword = async function(candidatePassword) {
    try {
        return await bcrypt.compare(candidatePassword, this.password);
    } catch (error) {
        throw new Error('Errore confronto password');
    }
};

// Method: Generate referral code
userSchema.methods.generateReferralCode = function() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code = '';
    for (let i = 0; i < 8; i++) {
        code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
};

// Method: Add points
userSchema.methods.addPoints = function(amount, reason) {
    this.points += amount;
    this.totalPointsEarned += amount;
    return this.save();
};

// Method: Deduct points
userSchema.methods.deductPoints = function(amount, reason) {
    if (this.points < amount) {
        throw new Error('Punti insufficienti');
    }
    this.points -= amount;
    this.totalPointsSpent += amount;
    return this.save();
};

// Method: Increment login attempts
userSchema.methods.incLoginAttempts = function() {
    // Reset attempts if lock has expired
    if (this.lockUntil && this.lockUntil < Date.now()) {
        return this.updateOne({
            $set: { loginAttempts: 1 },
            $unset: { lockUntil: 1 }
        });
    }
    
    const updates = { $inc: { loginAttempts: 1 } };
    const maxAttempts = 5;
    const lockTime = 15 * 60 * 1000; // 15 minutes
    
    if (this.loginAttempts + 1 >= maxAttempts && !this.isLocked) {
        updates.$set = { lockUntil: Date.now() + lockTime };
    }
    
    return this.updateOne(updates);
};

// Static: Find by referral code
userSchema.statics.findByReferralCode = function(code) {
    return this.findOne({ referralCode: code.toUpperCase() });
};

// Static: Get user stats
userSchema.statics.getUserStats = async function(userId) {
    const user = await this.findById(userId)
        .populate('favoritePromotions')
        .lean();
    
    if (!user) throw new Error('Utente non trovato');
    
    // Count referrals
    const referrals = await this.countDocuments({ referredBy: userId });
    
    // Get transaction count
    const Transaction = mongoose.model('Transaction');
    const transactions = await Transaction.countDocuments({ userId });
    
    return {
        user,
        stats: {
            referrals,
            transactions,
            points: user.points,
            favorites: user.favoritePromotions.length
        }
    };
};

module.exports = mongoose.model('User', userSchema);