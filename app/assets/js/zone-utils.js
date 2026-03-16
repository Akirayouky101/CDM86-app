/**
 * Zone Utils - Funzioni utility per gestione zone
 * Include: calcolo aree, statistiche, export GeoJSON
 */

window.ZoneUtils = {
    
    /**
     * Crea cerchio per CAP singolo (ritorna array coordinate Leaflet)
     * @param {string} cap - Codice CAP
     * @param {number} radiusMeters - Raggio in metri (default 2000 = 2km)
     * @returns {Array} Array di coordinate [lat, lng]
     */
    createCAPCircle(cap, radiusMeters = 2000) {
        const coords = window.CAPGeoData.getCAPCoordinates([cap]);
        if (coords.length === 0) {
            console.warn(`⚠️ CAP ${cap} non trovato in database`);
            return [];
        }
        
        const center = coords[0];
        const circle = [];
        const earthRadius = 6371000; // metri
        const radLat = center.lat * Math.PI / 180;
        
        // 32 punti per un cerchio smooth
        for (let i = 0; i <= 32; i++) {
            const angle = (i / 32) * 2 * Math.PI;
            const dx = radiusMeters * Math.cos(angle);
            const dy = radiusMeters * Math.sin(angle);
            
            const deltaLat = dy / earthRadius;
            const deltaLng = dx / (earthRadius * Math.cos(radLat));
            
            const lat = center.lat + (deltaLat * 180 / Math.PI);
            const lng = center.lng + (deltaLng * 180 / Math.PI);
            
            circle.push([lat, lng]);
        }
        
        return circle;
    },

    /**
     * Calcola area poligono in km² (formula Shoelace + Haversine)
     * @param {Array} coords - Array coordinate [[lat, lng], ...]
     * @returns {number} Area in km²
     */
    calculateArea(coords) {
        if (!coords || coords.length < 3) return 0;
        
        let area = 0;
        const n = coords.length;
        
        for (let i = 0; i < n; i++) {
            const j = (i + 1) % n;
            const lat1 = coords[i][0] * Math.PI / 180;
            const lng1 = coords[i][1] * Math.PI / 180;
            const lat2 = coords[j][0] * Math.PI / 180;
            const lng2 = coords[j][1] * Math.PI / 180;
            
            area += (lng2 - lng1) * (2 + Math.sin(lat1) + Math.sin(lat2));
        }
        
        area = Math.abs(area * 6371000 * 6371000 / 2); // m²
        return area / 1000000; // km²
    },

    /**
     * Conta utenti in una zona specifica
     * @param {Array} capList - Lista CAP della zona
     * @param {Object} supabase - Client Supabase
     * @returns {Promise<number>} Numero utenti
     */
    async countUsersInZone(capList, supabase) {
        try {
            const { data: users, error } = await supabase
                .from('users')
                .select('id')
                .in('cap_residenza', capList);
            
            if (error) {
                console.warn('Errore conteggio utenti:', error);
                return 0;
            }
            
            return users ? users.length : 0;
        } catch (e) {
            console.log('Info: user count non disponibile');
            return 0;
        }
    },

    /**
     * Genera colore per zona basato su indice (palette 6 colori)
     * @param {number} index - Indice zona
     * @param {boolean} active - Zona attiva/disattiva
     * @returns {string} Colore esadecimale
     */
    getZoneColor(index, active = true) {
        if (!active) return '#6b7280'; // Grigio per zone disattive
        
        const colors = [
            '#3b82f6', // Blu
            '#10b981', // Verde
            '#f59e0b', // Arancio
            '#ef4444', // Rosso
            '#8b5cf6', // Viola
            '#ec4899'  // Rosa
        ];
        
        return colors[index % colors.length];
    },

    /**
     * Export zona come file GeoJSON
     * @param {Object} zone - Oggetto zona
     * @param {Array} polygonCoords - Coordinate poligono (opzionale)
     */
    async exportGeoJSON(zone, polygonCoords = null) {
        let geoJSONCoords;
        
        if (zone.geometry && zone.geometry.coordinates) {
            // Usa geometry salvato
            geoJSONCoords = zone.geometry.coordinates;
        } else if (polygonCoords) {
            // Converti coordinate Leaflet in GeoJSON [lng, lat]
            const coords = polygonCoords.map(coord => [coord[1], coord[0]]);
            coords.push(coords[0]); // Chiudi poligono
            geoJSONCoords = [coords];
        } else {
            // Calcola convex hull
            const hullCoords = window.ConvexHull.fromCAPList(zone.cap_list || [], 15);
            if (!hullCoords) {
                console.error('Impossibile generare GeoJSON senza coordinate');
                return;
            }
            geoJSONCoords = [hullCoords.map(c => [c[1], c[0]])];
            geoJSONCoords[0].push(geoJSONCoords[0][0]); // Chiudi
        }
        
        const geoJSON = {
            type: "Feature",
            properties: {
                name: zone.name,
                description: zone.description || '',
                cap_list: zone.cap_list || [],
                active: zone.active,
                zone_id: zone.id,
                created_at: zone.created_at,
                updated_at: zone.updated_at
            },
            geometry: {
                type: "Polygon",
                coordinates: geoJSONCoords
            }
        };

        // Download file
        const blob = new Blob([JSON.stringify(geoJSON, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `zona_${zone.name.toLowerCase().replace(/\s+/g, '_')}_${Date.now()}.geojson`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);

        console.log(`✅ GeoJSON esportato: ${zone.name}`);
        return true;
    },

    /**
     * Statistiche complete zona
     * @param {Object} zone - Oggetto zona
     * @param {Object} supabase - Client Supabase
     * @returns {Promise<Object>} Stats object
     */
    async getZoneStats(zone, supabase) {
        const capList = zone.cap_list || [];
        const userCount = await this.countUsersInZone(capList, supabase);
        
        // Calcola area (se hai geometry o CAP)
        let areaKm2 = 0;
        if (zone.geometry && zone.geometry.coordinates) {
            const coords = window.ConvexHull.toLeafletFormat(zone.geometry.coordinates[0]);
            areaKm2 = this.calculateArea(coords);
        } else if (capList.length === 1) {
            areaKm2 = Math.PI * 2 * 2; // Cerchio 2km raggio
        } else if (capList.length > 1) {
            const hullCoords = window.ConvexHull.fromCAPList(capList, 15);
            if (hullCoords) {
                const coords = window.ConvexHull.toLeafletFormat(hullCoords);
                areaKm2 = this.calculateArea(coords);
            }
        }
        
        return {
            userCount,
            areaKm2: areaKm2.toFixed(1),
            capCount: capList.length,
            density: areaKm2 > 0 ? (userCount / areaKm2).toFixed(1) : 0
        };
    },

    /**
     * Genera popup HTML avanzato con statistiche
     * @param {Object} zone - Oggetto zona
     * @param {Object} stats - Statistiche {userCount, areaKm2, capCount, density}
     * @param {string} color - Colore zona
     * @param {string} mapMode - Modalità mappa ('markers' | 'polygons')
     * @returns {string} HTML popup
     */
    createPopup(zone, stats, color, mapMode = 'polygons') {
        const capList = zone.cap_list || [];
        const capPreview = capList.slice(0, 10).join(', ');
        const moreCAPs = capList.length > 10 ? ` <span style="color: ${color};">+${capList.length - 10} altri</span>` : '';
        const statusIcon = zone.active ? '✅' : '⏸️';
        
        return `
            <div style="min-width: 300px; font-family: system-ui, -apple-system, sans-serif;">
                <div style="background: linear-gradient(135deg, ${color}15 0%, ${color}25 100%); padding: 12px; margin: -12px -12px 12px -12px; border-bottom: 2px solid ${color};">
                    <h4 style="margin: 0; color: ${color}; font-size: 16px; font-weight: 700; display: flex; align-items: center; gap: 8px;">
                        <span style="font-size: 20px;">${mapMode === 'polygons' ? '🗺️' : '📍'}</span>
                        ${zone.name}
                    </h4>
                </div>
                
                <!-- Statistiche Grid -->
                <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px; margin-bottom: 12px;">
                    <div style="background: linear-gradient(135deg, #f3f4f6 0%, #e5e7eb 100%); padding: 10px; border-radius: 8px; text-align: center; border: 1px solid #d1d5db;">
                        <div style="font-size: 24px; font-weight: 700; color: ${color};">${stats.areaKm2}</div>
                        <div style="font-size: 10px; color: #6b7280; text-transform: uppercase; letter-spacing: 0.5px;">km² Area</div>
                    </div>
                    <div style="background: linear-gradient(135deg, #f3f4f6 0%, #e5e7eb 100%); padding: 10px; border-radius: 8px; text-align: center; border: 1px solid #d1d5db;">
                        <div style="font-size: 24px; font-weight: 700; color: ${color};">${stats.userCount}</div>
                        <div style="font-size: 10px; color: #6b7280; text-transform: uppercase; letter-spacing: 0.5px;">Utenti</div>
                    </div>
                </div>
                
                <!-- Stato -->
                <div style="margin-bottom: 10px; padding: 10px; background: ${zone.active ? '#d1fae5' : '#fee2e2'}; border-radius: 8px; border-left: 4px solid ${zone.active ? '#10b981' : '#ef4444'};">
                    <div style="font-size: 12px; color: #374151; font-weight: 600;">
                        ${statusIcon} Stato: <span style="color: ${zone.active ? '#10b981' : '#ef4444'};">${zone.active ? 'Zona Attiva' : 'Zona Disattivata'}</span>
                    </div>
                </div>

                <!-- CAP List -->
                <div style="margin-bottom: 10px;">
                    <div style="font-size: 11px; color: #6b7280; margin-bottom: 4px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px;">
                        📮 CAP Inclusi (${capList.length})
                    </div>
                    <div style="font-size: 11px; color: #374151; background: #f9fafb; padding: 8px; border-radius: 6px; border: 1px solid #e5e7eb; line-height: 1.6;">
                        ${capPreview}${moreCAPs}
                    </div>
                </div>

                <!-- Descrizione -->
                ${zone.description ? `
                    <div style="margin-bottom: 10px; padding: 8px; background: #fffbeb; border-left: 3px solid #f59e0b; border-radius: 4px;">
                        <div style="font-size: 11px; color: #92400e; font-style: italic;">${zone.description}</div>
                    </div>
                ` : ''}

                <!-- Metrics Extra -->
                <div style="display: flex; gap: 8px; margin-bottom: 12px; padding: 8px; background: #f3f4f6; border-radius: 6px;">
                    <div style="flex: 1; text-align: center;">
                        <div style="font-size: 14px; font-weight: 700; color: ${color};">${stats.density}</div>
                        <div style="font-size: 9px; color: #6b7280;">utenti/km²</div>
                    </div>
                    <div style="border-left: 1px solid #d1d5db;"></div>
                    <div style="flex: 1; text-align: center;">
                        <div style="font-size: 14px; font-weight: 700; color: ${color};">${capList.length}</div>
                        <div style="font-size: 9px; color: #6b7280;">CAP totali</div>
                    </div>
                </div>

                <!-- Buttons -->
                <div style="display: flex; gap: 6px; margin-top: 12px; padding-top: 12px; border-top: 2px solid #e5e7eb;">
                    <button onclick="editZone(${zone.id})" class="btn btn-sm btn-primary" style="flex: 1; padding: 8px 12px; font-size: 12px; font-weight: 600; border-radius: 6px;">
                        <i class="fas fa-edit"></i> Modifica
                    </button>
                    <button onclick="exportZoneGeoJSON(${zone.id})" class="btn btn-sm btn-success" style="flex: 1; padding: 8px 12px; font-size: 12px; font-weight: 600; border-radius: 6px;">
                        <i class="fas fa-download"></i> Export
                    </button>
                </div>
            </div>
        `;
    }
};

console.log('✅ Zone Utils loaded');
