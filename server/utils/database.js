/**
 * Database Connection Utility
 * MongoDB connection with retry logic
 */

const mongoose = require('mongoose');

// Connection options
const options = {
    useNewUrlParser: true,
    useUnifiedTopology: true,
    maxPoolSize: 10,
    serverSelectionTimeoutMS: 5000,
    socketTimeoutMS: 45000,
};

// Connection state
let isConnected = false;

/**
 * Connect to MongoDB
 */
const connectDB = async (retries = 5) => {
    // If already connected, return
    if (isConnected) {
        console.log('✅ MongoDB già connesso');
        return;
    }

    // Check for MongoDB URI
    if (!process.env.MONGODB_URI) {
        throw new Error('❌ MONGODB_URI non definita in .env');
    }

    let currentRetry = 0;

    while (currentRetry < retries) {
        try {
            console.log(`📡 Connessione a MongoDB... (tentativo ${currentRetry + 1}/${retries})`);
            
            await mongoose.connect(process.env.MONGODB_URI, options);
            
            isConnected = true;
            console.log('✅ MongoDB connesso con successo');
            console.log(`📊 Database: ${mongoose.connection.name}`);
            
            return;
        } catch (error) {
            currentRetry++;
            console.error(`❌ Errore connessione MongoDB (tentativo ${currentRetry}/${retries}):`, error.message);
            
            if (currentRetry >= retries) {
                throw new Error(`Impossibile connettersi a MongoDB dopo ${retries} tentativi`);
            }
            
            // Wait before retry (exponential backoff)
            const waitTime = Math.min(1000 * Math.pow(2, currentRetry), 10000);
            console.log(`⏳ Riprovo tra ${waitTime / 1000} secondi...`);
            await new Promise(resolve => setTimeout(resolve, waitTime));
        }
    }
};

/**
 * Disconnect from MongoDB
 */
const disconnectDB = async () => {
    if (!isConnected) {
        return;
    }

    try {
        await mongoose.disconnect();
        isConnected = false;
        console.log('✅ MongoDB disconnesso');
    } catch (error) {
        console.error('❌ Errore disconnessione MongoDB:', error.message);
        throw error;
    }
};

/**
 * Check connection status
 */
const isConnectedDB = () => {
    return isConnected && mongoose.connection.readyState === 1;
};

/**
 * Get connection state
 */
const getConnectionState = () => {
    const states = {
        0: 'disconnected',
        1: 'connected',
        2: 'connecting',
        3: 'disconnecting'
    };
    return states[mongoose.connection.readyState] || 'unknown';
};

// Connection event handlers
mongoose.connection.on('connected', () => {
    console.log('🔗 Mongoose connesso a MongoDB');
});

mongoose.connection.on('error', (error) => {
    console.error('❌ Errore connessione Mongoose:', error.message);
    isConnected = false;
});

mongoose.connection.on('disconnected', () => {
    console.log('🔌 Mongoose disconnesso da MongoDB');
    isConnected = false;
});

// Graceful shutdown
process.on('SIGINT', async () => {
    try {
        await mongoose.connection.close();
        console.log('🛑 MongoDB disconnesso per chiusura app');
        process.exit(0);
    } catch (error) {
        console.error('❌ Errore durante shutdown MongoDB:', error.message);
        process.exit(1);
    }
});

module.exports = {
    connectDB,
    disconnectDB,
    isConnectedDB,
    getConnectionState
};