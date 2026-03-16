/**
 * Console Logger - Cattura TUTTI gli errori della console
 * Usa questo per debuggare errori che appaiono e scompaiono velocemente
 */

// Array per salvare tutti i log
window.consoleHistory = {
    errors: [],
    warnings: [],
    logs: [],
    all: []
};

// Salva il console.error originale
const originalError = console.error;
const originalWarn = console.warn;
const originalLog = console.log;

// Override console.error
console.error = function(...args) {
    const timestamp = new Date().toISOString();
    const errorObj = {
        timestamp,
        type: 'ERROR',
        message: args.map(arg => 
            typeof arg === 'object' ? JSON.stringify(arg, null, 2) : String(arg)
        ).join(' ')
    };
    
    window.consoleHistory.errors.push(errorObj);
    window.consoleHistory.all.push(errorObj);
    
    // Chiama il console.error originale
    originalError.apply(console, args);
};

// Override console.warn
console.warn = function(...args) {
    const timestamp = new Date().toISOString();
    const warnObj = {
        timestamp,
        type: 'WARNING',
        message: args.map(arg => 
            typeof arg === 'object' ? JSON.stringify(arg, null, 2) : String(arg)
        ).join(' ')
    };
    
    window.consoleHistory.warnings.push(warnObj);
    window.consoleHistory.all.push(warnObj);
    
    originalWarn.apply(console, args);
};

// Override console.log
console.log = function(...args) {
    const timestamp = new Date().toISOString();
    const logObj = {
        timestamp,
        type: 'LOG',
        message: args.map(arg => 
            typeof arg === 'object' ? JSON.stringify(arg, null, 2) : String(arg)
        ).join(' ')
    };
    
    window.consoleHistory.logs.push(logObj);
    window.consoleHistory.all.push(logObj);
    
    originalLog.apply(console, args);
};

// Funzioni helper per visualizzare la history
window.showErrors = function() {
    console.table(window.consoleHistory.errors);
    return window.consoleHistory.errors;
};

window.showWarnings = function() {
    console.table(window.consoleHistory.warnings);
    return window.consoleHistory.warnings;
};

window.showAllLogs = function() {
    console.table(window.consoleHistory.all);
    return window.consoleHistory.all;
};

window.clearHistory = function() {
    window.consoleHistory = {
        errors: [],
        warnings: [],
        logs: [],
        all: []
    };
    console.log('✅ Console history cleared');
};

window.exportErrors = function() {
    const errors = window.consoleHistory.errors.map(e => e.message).join('\n\n---\n\n');
    console.log('📋 TUTTI GLI ERRORI:\n\n' + errors);
    return errors;
};

console.log('🔍 Console Logger attivo! Usa: showErrors(), showWarnings(), showAllLogs(), exportErrors()');
