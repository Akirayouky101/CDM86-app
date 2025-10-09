/**
 * Transaction Model
 * Schema per le transazioni (riscatto promozioni)
 */

const mongoose = require('mongoose');
const crypto = require('crypto');

const transactionSchema = new mongoose.Schema({
    // User & Promotion
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: [true, 'User richiesto']
    },
    promotionId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Promotion',
        required: [true, 'Promotion richiesta']
    },
    
    // Transaction Details
    transactionCode: {
        type: String,
        unique: true,
        required: true,
        uppercase: true
    },
    qrCode: {
        type: String, // Base64 encoded QR code image
        required: true
    },
    barcode: {
        type: String, // EAN-13 or Code128
        default: null
    },
    
    // Status & Lifecycle
    status: {
        type: String,
        enum: ['pending', 'verified', 'completed', 'expired', 'cancelled', 'refunded'],
        default: 'pending'
    },
    
    // Redemption Info
    redemptionMethod: {
        type: String,
        enum: ['qr', 'code', 'online', 'instore'],
        default: 'qr'
    },
    redemptionLocation: {
        type: String,
        default: null
    },
    redeemedAt: {
        type: Date,
        default: null
    },
    redeemedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        default: null // Partner/Staff who verified
    },
    
    // Expiration
    expiresAt: {
        type: Date,
        required: true
    },
    
    // Points
    pointsUsed: {
        type: Number,
        default: 0,
        min: 0
    },
    pointsEarned: {
        type: Number,
        default: 0,
        min: 0
    },
    
    // Discount Applied
    discount: {
        type: {
            type: String,
            enum: ['percentage', 'fixed', 'code']
        },
        value: Number,
        appliedAmount: Number
    },
    
    // Pricing (if applicable)
    originalAmount: {
        type: Number,
        default: 0
    },
    discountedAmount: {
        type: Number,
        default: 0
    },
    finalAmount: {
        type: Number,
        default: 0
    },
    
    // Verification
    verificationCode: {
        type: String,
        select: false
    },
    verifiedAt: {
        type: Date,
        default: null
    },
    
    // Rating & Feedback
    rating: {
        score: {
            type: Number,
            min: 1,
            max: 5,
            default: null
        },
        comment: {
            type: String,
            maxlength: 500
        },
        createdAt: Date
    },
    
    // Metadata
    metadata: {
        userAgent: String,
        ipAddress: String,
        deviceType: {
            type: String,
            enum: ['mobile', 'tablet', 'desktop']
        }
    },
    
    // Notes
    notes: {
        type: String,
        maxlength: 1000
    },
    internalNotes: {
        type: String,
        maxlength: 1000,
        select: false
    },
    
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
transactionSchema.index({ userId: 1, createdAt: -1 });
transactionSchema.index({ promotionId: 1, status: 1 });
transactionSchema.index({ transactionCode: 1 });
transactionSchema.index({ status: 1, expiresAt: 1 });
transactionSchema.index({ redeemedAt: -1 });

// Virtual: Is expired
transactionSchema.virtual('isExpired').get(function() {
    return this.expiresAt && this.expiresAt < new Date() && this.status === 'pending';
});

// Virtual: Is redeemable
transactionSchema.virtual('isRedeemable').get(function() {
    return (
        this.status === 'pending' &&
        this.expiresAt > new Date()
    );
});

// Virtual: Days until expiration
transactionSchema.virtual('daysUntilExpiration').get(function() {
    if (this.status !== 'pending') return null;
    const now = new Date();
    const diff = Math.ceil((this.expiresAt - now) / (1000 * 60 * 60 * 24));
    return diff > 0 ? diff : 0;
});

// Pre-save middleware: Generate transaction code
transactionSchema.pre('save', async function(next) {
    if (!this.isNew) {
        this.updatedAt = Date.now();
        return next();
    }
    
    // Generate unique transaction code
    let code;
    let exists = true;
    
    while (exists) {
        code = crypto.randomBytes(6).toString('hex').toUpperCase();
        exists = await this.constructor.findOne({ transactionCode: code });
    }
    
    this.transactionCode = code;
    
    // Generate verification code
    this.verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
    
    next();
});

// Pre-save middleware: Generate QR code
transactionSchema.pre('save', async function(next) {
    if (!this.isNew || this.qrCode) return next();
    
    try {
        const QRCode = require('qrcode');
        
        // QR code data
        const qrData = {
            code: this.transactionCode,
            userId: this.userId,
            promotionId: this.promotionId,
            expiresAt: this.expiresAt,
            url: `${process.env.APP_URL}/verify/${this.transactionCode}`
        };
        
        // Generate QR code as data URL
        this.qrCode = await QRCode.toDataURL(JSON.stringify(qrData), {
            errorCorrectionLevel: 'H',
            type: 'image/png',
            width: 512,
            margin: 2
        });
        
        next();
    } catch (error) {
        next(error);
    }
});

// Method: Mark as verified
transactionSchema.methods.markVerified = async function(verifiedBy) {
    if (this.status !== 'pending') {
        throw new Error('Transaction già processata');
    }
    
    if (this.isExpired) {
        throw new Error('Transaction scaduta');
    }
    
    this.status = 'verified';
    this.verifiedAt = new Date();
    this.redeemedBy = verifiedBy;
    
    return this.save();
};

// Method: Mark as completed
transactionSchema.methods.markCompleted = async function(location = null) {
    if (this.status !== 'verified') {
        throw new Error('Transaction deve essere verificata prima');
    }
    
    this.status = 'completed';
    this.redeemedAt = new Date();
    this.redemptionLocation = location;
    
    // Award points to user
    if (this.pointsEarned > 0) {
        const User = mongoose.model('User');
        const user = await User.findById(this.userId);
        if (user) {
            await user.addPoints(this.pointsEarned, `Promozione riscattata: ${this.transactionCode}`);
        }
    }
    
    // Update promotion stats
    const Promotion = mongoose.model('Promotion');
    const promotion = await Promotion.findById(this.promotionId);
    if (promotion) {
        await promotion.incrementRedemption();
    }
    
    return this.save();
};

// Method: Cancel transaction
transactionSchema.methods.cancel = async function(reason) {
    if (this.status !== 'pending') {
        throw new Error('Solo transaction pending possono essere cancellate');
    }
    
    this.status = 'cancelled';
    this.internalNotes = reason;
    
    // Refund points if used
    if (this.pointsUsed > 0) {
        const User = mongoose.model('User');
        const user = await User.findById(this.userId);
        if (user) {
            await user.addPoints(this.pointsUsed, `Rimborso: ${this.transactionCode}`);
        }
    }
    
    return this.save();
};

// Method: Add rating
transactionSchema.methods.addRating = function(score, comment = '') {
    if (this.status !== 'completed') {
        throw new Error('Puoi valutare solo transaction completate');
    }
    
    if (this.rating.score) {
        throw new Error('Hai già valutato questa transaction');
    }
    
    this.rating = {
        score,
        comment,
        createdAt: new Date()
    };
    
    // Update promotion rating
    this.updatePromotionRating();
    
    return this.save();
};

// Method: Update promotion rating
transactionSchema.methods.updatePromotionRating = async function() {
    if (!this.rating.score) return;
    
    const Promotion = mongoose.model('Promotion');
    const promotion = await Promotion.findById(this.promotionId);
    
    if (promotion) {
        const totalRating = (promotion.stats.rating.average * promotion.stats.rating.count) + this.rating.score;
        promotion.stats.rating.count += 1;
        promotion.stats.rating.average = totalRating / promotion.stats.rating.count;
        await promotion.save();
    }
};

// Static: Get user transactions
transactionSchema.statics.getUserTransactions = function(userId, filters = {}) {
    const query = { userId, ...filters };
    return this.find(query)
        .populate('promotionId', 'title images.thumbnail partner discount')
        .sort({ createdAt: -1 })
        .lean();
};

// Static: Verify transaction
transactionSchema.statics.verifyTransaction = async function(code, verificationCode) {
    const transaction = await this.findOne({ transactionCode: code })
        .select('+verificationCode')
        .populate('promotionId')
        .populate('userId', 'firstName lastName email');
    
    if (!transaction) {
        throw new Error('Transaction non trovata');
    }
    
    if (transaction.status !== 'pending') {
        throw new Error('Transaction già utilizzata o scaduta');
    }
    
    if (transaction.isExpired) {
        throw new Error('Transaction scaduta');
    }
    
    if (transaction.verificationCode !== verificationCode) {
        throw new Error('Codice verifica non valido');
    }
    
    return transaction;
};

// Static: Get transaction stats
transactionSchema.statics.getStats = async function(filters = {}) {
    const stats = await this.aggregate([
        { $match: filters },
        {
            $group: {
                _id: '$status',
                count: { $sum: 1 },
                totalPoints: { $sum: '$pointsEarned' },
                totalSavings: { $sum: { $subtract: ['$originalAmount', '$finalAmount'] } }
            }
        }
    ]);
    
    const result = {
        total: 0,
        pending: 0,
        verified: 0,
        completed: 0,
        expired: 0,
        cancelled: 0,
        totalPointsEarned: 0,
        totalSavings: 0
    };
    
    stats.forEach(stat => {
        result[stat._id] = stat.count;
        result.total += stat.count;
        result.totalPointsEarned += stat.totalPoints;
        result.totalSavings += stat.totalSavings;
    });
    
    return result;
};

// Static: Clean expired transactions
transactionSchema.statics.cleanExpired = async function() {
    const now = new Date();
    const result = await this.updateMany(
        {
            status: 'pending',
            expiresAt: { $lt: now }
        },
        {
            $set: { status: 'expired' }
        }
    );
    
    return result.modifiedCount;
};

module.exports = mongoose.model('Transaction', transactionSchema);