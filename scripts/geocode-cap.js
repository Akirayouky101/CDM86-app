/**
 * Geocoding Script - Converte CAP CSV in cap-geodata.js
 * Usa Nominatim API (OpenStreetMap) per ottenere coordinate GPS
 */

const fs = require('fs');
const https = require('https');

// Configurazione
const INPUT_FILE = './database/cap.csv';
const OUTPUT_FILE = './assets/js/cap-geodata-full.js';
const DELAY_MS = 1000; // 1 secondo tra richieste (rispetta rate limit Nominatim)
const BATCH_SIZE = 100; // Salva ogni 100 CAP

// Risultati
const geoData = {};
let processed = 0;
let failed = 0;
let skipped = 0;

// Leggi CSV
console.log('📖 Lettura file CSV...');
const csvContent = fs.readFileSync(INPUT_FILE, 'utf-8');
const lines = csvContent.split('\n').slice(1); // Skip header
const totalLines = lines.filter(l => l.trim()).length;

console.log(`✅ Trovati ${totalLines} comuni da geocodificare\n`);

// Funzione geocoding con Nominatim
function geocode(comune, provincia, regione) {
    return new Promise((resolve, reject) => {
        // Query: comune + provincia + regione + italia
        const query = encodeURIComponent(`${comune}, ${provincia}, ${regione}, Italia`);
        const url = `https://nominatim.openstreetmap.org/search?q=${query}&format=json&limit=1&countrycodes=it`;
        
        const options = {
            headers: {
                'User-Agent': 'CDM86-App-Geocoding/1.0'
            }
        };

        https.get(url, options, (res) => {
            let data = '';
            
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const result = JSON.parse(data);
                    if (result.length > 0) {
                        resolve({
                            lat: parseFloat(result[0].lat),
                            lng: parseFloat(result[0].lon)
                        });
                    } else {
                        resolve(null);
                    }
                } catch (e) {
                    reject(e);
                }
            });
        }).on('error', reject);
    });
}

// Processa CAP in batch
async function processBatch(startIndex) {
    const batch = lines.slice(startIndex, startIndex + BATCH_SIZE);
    
    for (let i = 0; i < batch.length; i++) {
        const line = batch[i].trim();
        if (!line) continue;

        const parts = line.split(/\s+/);
        if (parts.length < 4) continue;

        // Parse: COMUNE CAP PROVINCIA REGIONE
        const cap = parts[parts.length - 3];
        const provincia = parts[parts.length - 2];
        const regione = parts[parts.length - 1];
        const comune = parts.slice(0, parts.length - 3).join(' ');

        // Valida CAP (5 cifre)
        if (!/^\d{5}$/.test(cap)) {
            skipped++;
            continue;
        }

        // Skip se già esiste
        if (geoData[cap]) {
            skipped++;
            processed++;
            continue;
        }

        try {
            const coords = await geocode(comune, provincia, regione);
            
            if (coords) {
                geoData[cap] = {
                    lat: coords.lat,
                    lng: coords.lng,
                    city: comune,
                    area: provincia
                };
                
                processed++;
                const percent = ((processed / totalLines) * 100).toFixed(1);
                console.log(`✅ [${percent}%] ${cap} - ${comune} (${provincia}) → ${coords.lat.toFixed(4)}, ${coords.lng.toFixed(4)}`);
            } else {
                failed++;
                console.log(`❌ ${cap} - ${comune} (${provincia}) → Coordinate non trovate`);
            }
            
            // Delay per rispettare rate limit
            await new Promise(resolve => setTimeout(resolve, DELAY_MS));
            
        } catch (error) {
            failed++;
            console.log(`⚠️ ${cap} - ${comune} → Errore: ${error.message}`);
        }
    }

    // Salva progresso ogni batch
    saveProgress();
    
    // Continua con prossimo batch
    const nextIndex = startIndex + BATCH_SIZE;
    if (nextIndex < lines.length) {
        console.log(`\n📊 Progresso: ${processed}/${totalLines} (${failed} falliti, ${skipped} skipped)\n`);
        await processBatch(nextIndex);
    } else {
        // Finito!
        finalizeOutput();
    }
}

// Salva progresso parziale
function saveProgress() {
    const tempFile = OUTPUT_FILE.replace('.js', '-progress.json');
    fs.writeFileSync(tempFile, JSON.stringify(geoData, null, 2));
    console.log(`💾 Progresso salvato: ${Object.keys(geoData).length} CAP`);
}

// Genera file JavaScript finale
function finalizeOutput() {
    console.log('\n🎉 Geocoding completato!\n');
    console.log('📊 Statistiche:');
    console.log(`   ✅ Successi: ${processed - failed}`);
    console.log(`   ❌ Falliti: ${failed}`);
    console.log(`   ⏭️  Skipped: ${skipped}`);
    console.log(`   📍 CAP unici: ${Object.keys(geoData).length}`);

    // Ordina CAP
    const sortedCaps = Object.keys(geoData).sort();
    
    // Genera JavaScript
    let jsContent = `/**
 * CAP GeoData - Database completo CAP italiani
 * Generato automaticamente da geocode-cap.js
 * Totale CAP: ${sortedCaps.length}
 * Data: ${new Date().toISOString()}
 */

window.CAPGeoData = {\n`;

    sortedCaps.forEach((cap, index) => {
        const data = geoData[cap];
        const comma = index < sortedCaps.length - 1 ? ',' : '';
        jsContent += `    '${cap}': { lat: ${data.lat}, lng: ${data.lng}, city: '${data.city.replace(/'/g, "\\'")}', area: '${data.area}' }${comma}\n`;
    });

    jsContent += `};

/**
 * Ottieni coordinate da lista CAP
 */
window.CAPGeoData.getCAPCoordinates = function(capList) {
    if (!Array.isArray(capList)) return [];
    
    const coords = [];
    capList.forEach(cap => {
        if (this[cap]) {
            coords.push(this[cap]);
        }
    });
    return coords;
};

/**
 * Calcola centro geografico da lista CAP
 */
window.CAPGeoData.calculateCAPCenter = function(capList) {
    const coords = this.getCAPCoordinates(capList);
    if (coords.length === 0) {
        return { lat: 41.8719, lng: 12.5674, count: 0 }; // Italia centro
    }
    
    let totalLat = 0, totalLng = 0;
    coords.forEach(c => {
        totalLat += c.lat;
        totalLng += c.lng;
    });
    
    return {
        lat: totalLat / coords.length,
        lng: totalLng / coords.length,
        count: coords.length
    };
};

console.log('✅ CAP GeoData loaded:', Object.keys(window.CAPGeoData).length, 'CAP codes');
`;

    // Salva file finale
    fs.writeFileSync(OUTPUT_FILE, jsContent);
    console.log(`\n✅ File generato: ${OUTPUT_FILE}`);
    console.log(`📦 Dimensione: ${(fs.statSync(OUTPUT_FILE).size / 1024).toFixed(2)} KB\n`);
}

// Avvia processo
console.log('🚀 Inizio geocoding...\n');
processBatch(0).catch(error => {
    console.error('❌ Errore fatale:', error);
    process.exit(1);
});
