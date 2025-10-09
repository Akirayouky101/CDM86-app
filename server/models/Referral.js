/**
 * Referral Model
 * Schema per il sistema referral/inviti
 */

const mongoose = require('mongoose');

const referralSchema = new mongoose.Schema({
    // Referrer (chi invita)
    referrerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: [true, 'Referrer richiesto']
    },
    
    // Referred (chi viene invitato)
    referredUserId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        default: null
    },
    referredEmail: {
        type: String,
        lowercase: true,
        trim: true
    },
    
    // Referral Code used
    codeUsed: {
        type: String,
        required: [true, 'Codice referral richiesto'],
        uppercase: true
    },
    
    // Status
    status: {
        type: String,
        enum: ['pending', 'registered', 'verified', 'completed', 'expired'],
        default: 'pending'
    },
    
    // Points & Rewards
    pointsEarned: {
        referrer: {
            type: Number,
            default: 0
        },
        referred: {
            type: Number,
            default: 0
        }
    },
    
    // Tracking
    clickedAt: {
        type: Date,
        default: Date.now
    },
    registeredAt: {
        type: Date,
        default: null
    },
    verifiedAt: {
        type: Date,
        default: null
    },
    completedAt: {
        type: Date,
        default: null
    },
    expiresAt: {
        type: Date,
        default: function() {
            // Link expires in 30 days
            return new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
        }
    },
    
    // Metadata
    source: {
        type: String,
        enum: ['link', 'email', 'social', 'direct'],
        default: 'link'
    },
    ipAddress: String,
    userAgent: String,
    referrerUrl: String,
    
    // Campaign tracking
    campaign: {
        name: String,
        medium: String,
        source: String
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
referralSchema.index({ referrerId: 1, status: 1 });
referralSchema.index({ referredUserId: 1 });
referralSchema.index({ codeUsed: 1 });
referralSchema.index({ status: 1, createdAt: -1 });
referralSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 }); // TTL index

// Virtual: Is expired
referralSchema.virtual('isExpired').get(function() {
    return this.expiresAt && this.expiresAt < new Date();
});

// Virtual: Conversion time (days)
referralSchema.virtual('conversionDays').get(function() {
    if (!this.completedAt) return null;
    const diff = this.completedAt - this.clickedAt;
    return Math.ceil(diff / (1000 * 60 * 60 * 24));
});

// Pre-save middleware: Update timestamp
referralSchema.pre('save', function(next) {
    this.updatedAt = Date.now();
    next();
});

// Method: Mark as registered
referralSchema.methods.markRegistered = async function(userId) {
    this.referredUserId = userId;
    this.status = 'registered';
    this.registeredAt = new Date();
    return this.save();
};

// Method: Mark as verified
referralSchema.methods.markVerified = async function() {
    if (this.status !== 'registered') {
        throw new Error('Referral deve essere in stato registered');
    }
    
    this.status = 'verified';
    this.verifiedAt = new Date();
    
    // Award points for verification
    const User = mongoose.model('User');
    const referred = await User.findById(this.referredUserId);
    
    if (referred) {
        const welcomePoints = 100; // Points for new user
        await referred.addPoints(welcomePoints, 'Benvenuto CDM86');
        this.pointsEarned.referred = welcomePoints;
    }
    
    return this.save();
};

// Method: Mark as completed
referralSchema.methods.markCompleted = async function() {
    if (this.status !== 'verified') {
        throw new Error('Referral deve essere in stato verified');
    }
    
    this.status = 'completed';
    this.completedAt = new Date();
    
    // Award points to referrer
    const User = mongoose.model('User');
    const referrer = await User.findById(this.referrerId);
    
    if (referrer) {
        const referralPoints = 200; // Points for successful referral
        await referrer.addPoints(referralPoints, 'Referral completato');
        this.pointsEarned.referrer = referralPoints;
        
        // Increment referral count
        referrer.referralCount += 1;
        await referrer.save();
    }
    
    return this.save();
};

// Method: Mark as expired
referralSchema.methods.markExpired = function() {
    if (this.status === 'pending') {
        this.status = 'expired';
    }
    return this.save();
};

// Static: Track referral click
referralSchema.statics.trackClick = async function(codeUsed, metadata = {}) {
    const User = mongoose.model('User');
    const referrer = await User.findByReferralCode(codeUsed);
    
    if (!referrer) {
        throw new Error('Codice referral non valido');
    }
    
    // Check if IP already used this code recently (prevent abuse)
    if (metadata.ipAddress) {
        const recentClick = await this.findOne({
            codeUsed,
            ipAddress: metadata.ipAddress,
            clickedAt: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) }
        });
        
        if (recentClick) {
            return recentClick; // Return existing click
        }
    }
    
    const referral = await this.create({
        referrerId: referrer._id,
        codeUsed,
        referredEmail: metadata.email || null,
        source: metadata.source || 'link',
        ipAddress: metadata.ipAddress,
        userAgent: metadata.userAgent,
        referrerUrl: metadata.referrerUrl,
        campaign: metadata.campaign || {}
    });
    
    return referral;
};

// Static: Get referrer stats
referralSchema.statics.getReferrerStats = async function(referrerId) {
    const stats = await this.aggregate([
        { $match: { referrerId: mongoose.Types.ObjectId(referrerId) } },
        {
            $group: {
                _id: '$status',
                count: { $sum: 1 },
                totalPoints: { $sum: '$pointsEarned.referrer' }
            }
        }
    ]);
    
    const result = {
        total: 0,
        pending: 0,
        registered: 0,
        verified: 0,
        completed: 0,
        expired: 0,
        totalPointsEarned: 0,
        conversionRate: 0
    };
    
    stats.forEach(stat => {
        result[stat._id] = stat.count;
        result.total += stat.count;
        result.totalPointsEarned += stat.totalPoints;
    });
    
    // Calculate conversion rate
    if (result.total > 0) {
        result.conversionRate = Math.round((result.completed / result.total) * 100);
    }
    
    return result;
};

// Static: Get top referrers
referralSchema.statics.getTopReferrers = async function(limit = 10) {
    const User = mongoose.model('User');
    
    const topReferrers = await this.aggregate([
        { $match: { status: 'completed' } },
        {
            $group: {
                _id: '$referrerId',
                count: { $sum: 1 },
                totalPoints: { $sum: '$pointsEarned.referrer' }
            }
        },
        { $sort: { count: -1 } },
        { $limit: limit }
    ]);
    
    // Populate user data
    for (let referrer of topReferrers) {
        const user = await User.findById(referrer._id)
            .select('firstName lastName email avatar')
            .lean();
        referrer.user = user;
    }
    
    return topReferrers;
};

// Static: Clean expired referrals
referralSchema.statics.cleanExpired = async function() {
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

module.exports = mongoose.model('Referral', referralSchema);