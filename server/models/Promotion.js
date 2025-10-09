/**
 * Promotion Model
 * Schema per le promozioni convenzionate
 */

const mongoose = require('mongoose');

const promotionSchema = new mongoose.Schema({
    // Basic Info
    title: {
        type: String,
        required: [true, 'Titolo richiesto'],
        trim: true,
        maxlength: [100, 'Titolo troppo lungo']
    },
    slug: {
        type: String,
        unique: true,
        lowercase: true,
        trim: true
    },
    description: {
        type: String,
        required: [true, 'Descrizione richiesta'],
        maxlength: [1000, 'Descrizione troppo lunga']
    },
    shortDescription: {
        type: String,
        maxlength: [200, 'Descrizione breve troppo lunga']
    },

    // Partner Info
    partner: {
        name: {
            type: String,
            required: [true, 'Nome partner richiesto']
        },
        logo: String,
        website: String,
        address: String,
        city: String,
        province: String,
        zipCode: String,
        phone: String,
        email: String
    },

    // Category & Tags
    category: {
        type: String,
        required: [true, 'Categoria richiesta'],
        enum: [
            'ristoranti',
            'shopping',
            'viaggi',
            'intrattenimento',
            'salute',
            'tecnologia',
            'sport',
            'servizi',
            'altro'
        ]
    },
    tags: [{
        type: String,
        lowercase: true,
        trim: true
    }],

    // Images
    images: {
        main: {
            type: String,
            required: [true, 'Immagine principale richiesta']
        },
        gallery: [{
            type: String
        }],
        thumbnail: String
    },

    // Discount & Pricing
    discount: {
        type: {
            type: String,
            enum: ['percentage', 'fixed', 'code'],
            required: true
        },
        value: {
            type: Number,
            required: true
        },
        maxAmount: Number, // Max discount for percentage
        minPurchase: Number // Minimum purchase required
    },
    originalPrice: Number,
    discountedPrice: Number,
    
    // Validity & Limits
    validity: {
        startDate: {
            type: Date,
            required: [true, 'Data inizio richiesta']
        },
        endDate: {
            type: Date,
            required: [true, 'Data fine richiesta']
        },
        days: [{
            type: String,
            enum: ['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom']
        }],
        hours: {
            from: String, // HH:MM
            to: String    // HH:MM
        }
    },
    
    limits: {
        totalRedemptions: {
            type: Number,
            default: null // null = unlimited
        },
        perUser: {
            type: Number,
            default: 1
        },
        perDay: Number
    },

    // Status & Stats
    isActive: {
        type: Boolean,
        default: true
    },
    isFeatured: {
        type: Boolean,
        default: false
    },
    isExclusive: {
        type: Boolean,
        default: false
    },
    
    stats: {
        views: {
            type: Number,
            default: 0
        },
        favorites: {
            type: Number,
            default: 0
        },
        redemptions: {
            type: Number,
            default: 0
        },
        clicks: {
            type: Number,
            default: 0
        },
        rating: {
            average: {
                type: Number,
                default: 0,
                min: 0,
                max: 5
            },
            count: {
                type: Number,
                default: 0
            }
        }
    },

    // Points & Rewards
    pointsCost: {
        type: Number,
        default: 0,
        min: 0
    },
    pointsReward: {
        type: Number,
        default: 0,
        min: 0
    },

    // Terms & Conditions
    terms: {
        type: String,
        maxlength: [2000, 'Termini troppo lunghi']
    },
    howToRedeem: {
        type: String,
        maxlength: [500, 'Istruzioni troppo lunghe']
    },

    // SEO
    seo: {
        metaTitle: String,
        metaDescription: String,
        keywords: [String]
    },

    // Metadata
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    updatedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
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
promotionSchema.index({ slug: 1 });
promotionSchema.index({ category: 1, isActive: 1 });
promotionSchema.index({ 'validity.startDate': 1, 'validity.endDate': 1 });
promotionSchema.index({ isActive: 1, isFeatured: -1, 'stats.redemptions': -1 });
promotionSchema.index({ 'partner.name': 1 });
promotionSchema.index({ tags: 1 });

// Text search index
promotionSchema.index({
    title: 'text',
    description: 'text',
    shortDescription: 'text',
    'partner.name': 'text',
    tags: 'text'
});

// Virtual: Is valid now
promotionSchema.virtual('isValid').get(function() {
    const now = new Date();
    return (
        this.isActive &&
        this.validity.startDate <= now &&
        this.validity.endDate >= now &&
        (!this.limits.totalRedemptions || this.stats.redemptions < this.limits.totalRedemptions)
    );
});

// Virtual: Days remaining
promotionSchema.virtual('daysRemaining').get(function() {
    const now = new Date();
    const end = new Date(this.validity.endDate);
    const diff = Math.ceil((end - now) / (1000 * 60 * 60 * 24));
    return diff > 0 ? diff : 0;
});

// Virtual: Discount label
promotionSchema.virtual('discountLabel').get(function() {
    if (this.discount.type === 'percentage') {
        return `-${this.discount.value}%`;
    } else if (this.discount.type === 'fixed') {
        return `-€${this.discount.value}`;
    } else {
        return 'CODICE';
    }
});

// Pre-save middleware: Generate slug
promotionSchema.pre('save', function(next) {
    if (!this.isModified('title')) return next();
    
    this.slug = this.title
        .toLowerCase()
        .replace(/[àáâãäå]/g, 'a')
        .replace(/[èéêë]/g, 'e')
        .replace(/[ìíîï]/g, 'i')
        .replace(/[òóôõö]/g, 'o')
        .replace(/[ùúûü]/g, 'u')
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-+|-+$/g, '');
    
    next();
});

// Pre-save middleware: Update timestamp
promotionSchema.pre('save', function(next) {
    this.updatedAt = Date.now();
    next();
});

// Method: Increment view
promotionSchema.methods.incrementView = function() {
    this.stats.views += 1;
    return this.save();
};

// Method: Increment click
promotionSchema.methods.incrementClick = function() {
    this.stats.clicks += 1;
    return this.save();
};

// Method: Increment redemption
promotionSchema.methods.incrementRedemption = function() {
    this.stats.redemptions += 1;
    return this.save();
};

// Method: Toggle favorite
promotionSchema.methods.toggleFavorite = function(increment = true) {
    this.stats.favorites += increment ? 1 : -1;
    if (this.stats.favorites < 0) this.stats.favorites = 0;
    return this.save();
};

// Method: Can be redeemed by user
promotionSchema.methods.canRedeem = async function(userId) {
    if (!this.isValid) {
        return { canRedeem: false, reason: 'Promozione non valida o scaduta' };
    }
    
    // Check total redemptions
    if (this.limits.totalRedemptions && this.stats.redemptions >= this.limits.totalRedemptions) {
        return { canRedeem: false, reason: 'Limite promozioni raggiunto' };
    }
    
    // Check user redemptions
    const Transaction = mongoose.model('Transaction');
    const userRedemptions = await Transaction.countDocuments({
        userId,
        promotionId: this._id,
        status: { $in: ['pending', 'completed'] }
    });
    
    if (userRedemptions >= this.limits.perUser) {
        return { canRedeem: false, reason: 'Hai già utilizzato questa promozione' };
    }
    
    // Check today's redemptions
    if (this.limits.perDay) {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const todayRedemptions = await Transaction.countDocuments({
            userId,
            promotionId: this._id,
            createdAt: { $gte: today },
            status: { $in: ['pending', 'completed'] }
        });
        
        if (todayRedemptions >= this.limits.perDay) {
            return { canRedeem: false, reason: 'Limite giornaliero raggiunto' };
        }
    }
    
    return { canRedeem: true };
};

// Static: Get active promotions
promotionSchema.statics.getActive = function(filters = {}) {
    const now = new Date();
    const query = {
        isActive: true,
        'validity.startDate': { $lte: now },
        'validity.endDate': { $gte: now },
        ...filters
    };
    
    return this.find(query)
        .sort({ isFeatured: -1, 'stats.redemptions': -1 })
        .lean();
};

// Static: Search promotions
promotionSchema.statics.search = function(searchText, filters = {}) {
    const query = {
        $text: { $search: searchText },
        isActive: true,
        'validity.endDate': { $gte: new Date() },
        ...filters
    };
    
    return this.find(query, { score: { $meta: 'textScore' } })
        .sort({ score: { $meta: 'textScore' } })
        .lean();
};

module.exports = mongoose.model('Promotion', promotionSchema);