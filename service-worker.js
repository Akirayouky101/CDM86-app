/**
 * CDM86 Service Worker - DISABLED FOR DEVELOPMENT
 * Cache disabilitata per evitare problemi durante lo sviluppo
 */

const CACHE_NAME = 'cdm86-v4-nocache';
const DYNAMIC_CACHE = 'cdm86-dynamic-v4';

// NO FILES TO CACHE - Development mode
const STATIC_ASSETS = [];

// Install event - Skip caching in development mode
self.addEventListener('install', (event) => {
    console.log('[Service Worker] Installing (no cache)...');
    self.skipWaiting();
});

// Activate event - DELETE ALL OLD CACHES
self.addEventListener('activate', (event) => {
    console.log('[Service Worker] Activating and clearing all caches...');
    event.waitUntil(
        caches.keys().then(cacheNames => {
            return Promise.all(
                cacheNames.map(cacheName => {
                    console.log('[Service Worker] Deleting cache:', cacheName);
                    return caches.delete(cacheName);
                })
            );
        }).then(() => {
            console.log('[Service Worker] All caches cleared!');
            return self.clients.claim();
        })
    );
});

// Fetch event - NO CACHING, always network
self.addEventListener('fetch', (event) => {
    event.respondWith(
        fetch(event.request)
            .then(response => {
                return response;
            })
            .catch(error => {
                console.log('[Service Worker] Fetch failed:', error);
                throw error;
            })
    );
});

// Activate Event - Clean old caches
self.addEventListener('activate', (event) => {
    console.log('[Service Worker] Activating...');
    event.waitUntil(
        caches.keys().then((cacheNames) => {
            return Promise.all(
                cacheNames
                    .filter((name) => name !== CACHE_NAME && name !== DYNAMIC_CACHE)
                    .map((name) => {
                        console.log('[Service Worker] Deleting old cache:', name);
                        return caches.delete(name);
                    })
            );
        })
    );
    return self.clients.claim();
});

// Fetch Event - Network first, fallback to cache
self.addEventListener('fetch', (event) => {
    const { request } = event;
    const url = new URL(request.url);

    // Skip non-GET requests
    if (request.method !== 'GET') {
        return;
    }

    // API requests - Network only with offline fallback
    if (url.pathname.startsWith('/api/')) {
        event.respondWith(
            fetch(request)
                .then((response) => {
                    // Clone and cache successful responses
                    if (response.ok) {
                        const responseClone = response.clone();
                        caches.open(DYNAMIC_CACHE).then((cache) => {
                            cache.put(request, responseClone);
                        });
                    }
                    return response;
                })
                .catch(() => {
                    // Return cached version if offline
                    return caches.match(request).then((cached) => {
                        if (cached) {
                            return cached;
                        }
                        // Return offline page for API requests
                        return new Response(
                            JSON.stringify({
                                error: 'Offline',
                                message: 'Sei offline. Controlla la connessione.'
                            }),
                            {
                                headers: { 'Content-Type': 'application/json' },
                                status: 503
                            }
                        );
                    });
                })
        );
        return;
    }

    // Static assets - Cache first, fallback to network
    event.respondWith(
        caches.match(request).then((cached) => {
            if (cached) {
                // Return cached version and update in background
                fetch(request).then((response) => {
                    if (response.ok) {
                        caches.open(CACHE_NAME).then((cache) => {
                            cache.put(request, response);
                        });
                    }
                });
                return cached;
            }

            // Not in cache, fetch from network
            return fetch(request)
                .then((response) => {
                    if (!response || response.status !== 200) {
                        return response;
                    }

                    // Cache the new resource
                    const responseClone = response.clone();
                    caches.open(DYNAMIC_CACHE).then((cache) => {
                        cache.put(request, responseClone);
                    });

                    return response;
                })
                .catch(() => {
                    // Network failed, show offline page
                    if (request.destination === 'document') {
                        return caches.match('/offline.html');
                    }
                });
        })
    );
});

// Background Sync - Sync data when connection returns
self.addEventListener('sync', (event) => {
    console.log('[Service Worker] Background sync:', event.tag);
    
    if (event.tag === 'sync-promotions') {
        event.waitUntil(syncPromotions());
    }
    
    if (event.tag === 'sync-referrals') {
        event.waitUntil(syncReferrals());
    }
});

// Push Notifications
self.addEventListener('push', (event) => {
    console.log('[Service Worker] Push notification received');
    
    const data = event.data ? event.data.json() : {};
    const title = data.title || 'CDM86';
    const options = {
        body: data.body || 'Nuova notifica disponibile',
        icon: '/assets/images/icon-192x192.png',
        badge: '/assets/images/icon-72x72.png',
        vibrate: [200, 100, 200],
        data: data.url || '/',
        actions: [
            { action: 'open', title: 'Apri', icon: '/assets/images/icon-72x72.png' },
            { action: 'close', title: 'Chiudi', icon: '/assets/images/icon-72x72.png' }
        ]
    };

    event.waitUntil(
        self.registration.showNotification(title, options)
    );
});

// Notification Click
self.addEventListener('notificationclick', (event) => {
    console.log('[Service Worker] Notification clicked');
    
    event.notification.close();
    
    if (event.action === 'open' || !event.action) {
        const urlToOpen = event.notification.data || '/';
        
        event.waitUntil(
            clients.matchAll({ type: 'window', includeUncontrolled: true })
                .then((clientList) => {
                    // Check if window is already open
                    for (let client of clientList) {
                        if (client.url === urlToOpen && 'focus' in client) {
                            return client.focus();
                        }
                    }
                    // Open new window
                    if (clients.openWindow) {
                        return clients.openWindow(urlToOpen);
                    }
                })
        );
    }
});

// Helper Functions
async function syncPromotions() {
    try {
        const response = await fetch('/api/promotions/sync', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        });
        return response.json();
    } catch (error) {
        console.error('[Service Worker] Sync promotions failed:', error);
    }
}

async function syncReferrals() {
    try {
        const response = await fetch('/api/referrals/sync', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        });
        return response.json();
    } catch (error) {
        console.error('[Service Worker] Sync referrals failed:', error);
    }
}

// Message handling
self.addEventListener('message', (event) => {
    console.log('[Service Worker] Message received:', event.data);
    
    if (event.data.action === 'skipWaiting') {
        self.skipWaiting();
    }
    
    if (event.data.action === 'clearCache') {
        event.waitUntil(
            caches.keys().then((names) => {
                return Promise.all(names.map((name) => caches.delete(name)));
            })
        );
    }
});