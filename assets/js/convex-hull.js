/**
 * Convex Hull Algorithm - Graham Scan
 * Calcola il poligono convesso minimo che racchiude un insieme di punti
 */

window.ConvexHull = {
    /**
     * Calcola l'orientamento di tre punti (p, q, r)
     * @returns {number} 0 = collineari, 1 = orario, 2 = antiorario
     */
    orientation(p, q, r) {
        const val = (q.lat - p.lat) * (r.lng - q.lng) - (q.lng - p.lng) * (r.lat - q.lat);
        if (Math.abs(val) < 1e-10) return 0; // Collineari
        return (val > 0) ? 1 : 2; // Orario o Antiorario
    },

    /**
     * Distanza al quadrato tra due punti
     */
    distanceSquared(p1, p2) {
        return Math.pow(p1.lat - p2.lat, 2) + Math.pow(p1.lng - p2.lng, 2);
    },

    /**
     * Algoritmo Graham Scan per Convex Hull
     * @param {Array} points - Array di {lat, lng}
     * @returns {Array} - Array di punti che formano il convex hull
     */
    grahamScan(points) {
        if (points.length < 3) return points;

        // Trova il punto più in basso (minima latitudine)
        let lowest = points[0];
        let lowestIndex = 0;
        for (let i = 1; i < points.length; i++) {
            if (points[i].lat < lowest.lat || 
                (points[i].lat === lowest.lat && points[i].lng < lowest.lng)) {
                lowest = points[i];
                lowestIndex = i;
            }
        }

        // Sposta il punto più basso all'inizio
        [points[0], points[lowestIndex]] = [points[lowestIndex], points[0]];
        const p0 = points[0];

        // Ordina i punti per angolo polare rispetto a p0
        const sortedPoints = points.slice(1).sort((a, b) => {
            const orientation = this.orientation(p0, a, b);
            if (orientation === 0) {
                // Punti collineari: metti il più vicino prima
                return this.distanceSquared(p0, a) - this.distanceSquared(p0, b);
            }
            return (orientation === 2) ? -1 : 1;
        });

        // Rimuovi punti collineari (mantieni solo il più lontano)
        const filtered = [p0];
        for (let i = 0; i < sortedPoints.length; i++) {
            while (i < sortedPoints.length - 1 && 
                   this.orientation(p0, sortedPoints[i], sortedPoints[i + 1]) === 0) {
                i++;
            }
            filtered.push(sortedPoints[i]);
        }

        if (filtered.length < 3) return filtered;

        // Graham Scan
        const hull = [filtered[0], filtered[1], filtered[2]];

        for (let i = 3; i < filtered.length; i++) {
            // Rimuovi punti che creano turn destrorso
            while (hull.length > 1 && 
                   this.orientation(hull[hull.length - 2], hull[hull.length - 1], filtered[i]) !== 2) {
                hull.pop();
            }
            hull.push(filtered[i]);
        }

        return hull;
    },

    /**
     * Calcola convex hull e aggiunge padding per area più grande
     * @param {Array} points - Array di {lat, lng}
     * @param {number} paddingPercent - Percentuale di espansione (default 10%)
     * @returns {Array} - Convex hull con padding
     */
    calculateWithPadding(points, paddingPercent = 10) {
        if (points.length < 3) return points;

        const hull = this.grahamScan(points);

        // Calcola centro del hull
        const center = {
            lat: hull.reduce((sum, p) => sum + p.lat, 0) / hull.length,
            lng: hull.reduce((sum, p) => sum + p.lng, 0) / hull.length
        };

        // Espandi ogni punto dal centro
        const factor = 1 + (paddingPercent / 100);
        const expandedHull = hull.map(point => ({
            lat: center.lat + (point.lat - center.lat) * factor,
            lng: center.lng + (point.lng - center.lng) * factor
        }));

        return expandedHull;
    },

    /**
     * Converte array di CAP in poligono convex hull
     * @param {Array<string>} capList - Array di CAP
     * @param {number} padding - Padding percentuale (default 15%)
     * @returns {Array|null} - Array di coordinate [[lng, lat], ...] o null
     */
    fromCAPList(capList, padding = 15) {
        if (!capList || capList.length === 0) return null;

        // Ottieni coordinate per ogni CAP
        const points = capList
            .map(cap => window.getCAPCoordinates(cap))
            .filter(coord => coord !== null);

        if (points.length < 3) {
            // Se meno di 3 punti, crea un cerchio
            if (points.length === 0) return null;
            
            const center = points[0];
            const radius = 0.05; // ~5km in gradi
            return this.createCircle(center, radius);
        }

        // Calcola convex hull con padding
        const hull = this.calculateWithPadding(points, padding);

        // Converti in formato GeoJSON [lng, lat]
        return hull.map(point => [point.lng, point.lat]);
    },

    /**
     * Crea un cerchio (approssimato con poligono)
     * @param {object} center - {lat, lng}
     * @param {number} radius - Raggio in gradi
     * @param {number} segments - Numero di segmenti (default 32)
     * @returns {Array} - Array di coordinate [[lng, lat], ...]
     */
    createCircle(center, radius, segments = 32) {
        const circle = [];
        for (let i = 0; i < segments; i++) {
            const angle = (i / segments) * 2 * Math.PI;
            const lat = center.lat + radius * Math.cos(angle);
            const lng = center.lng + radius * Math.sin(angle);
            circle.push([lng, lat]);
        }
        // Chiudi il cerchio
        circle.push(circle[0]);
        return circle;
    },

    /**
     * Converte poligono in formato Leaflet LatLng
     * @param {Array} coordinates - [[lng, lat], ...]
     * @returns {Array} - Array di [lat, lng] per Leaflet
     */
    toLeafletFormat(coordinates) {
        return coordinates.map(coord => [coord[1], coord[0]]);
    }
};

console.log('✅ Convex Hull algorithm loaded');
