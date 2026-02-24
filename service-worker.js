// =====================================================
// CDM86 SERVICE WORKER - AGGRESSIVE NO-CACHE MODE
// =====================================================
// Bypassa COMPLETAMENTE la cache del browser
// Risolve problemi di dati stantii dopo modifiche DB
// =====================================================

const VERSION = 'v4-fix-cdn-' + Date.now();

console.log('🚀 CDM86 Service Worker loaded:', VERSION);

// =====================================================
// INSTALL - Attiva immediatamente
// =====================================================
self.addEventListener('install', (event) => {
  console.log('🔧 [SW] Installing:', VERSION);
  
  // Skippa waiting e attiva subito
  self.skipWaiting();
});

// =====================================================
// ACTIVATE - Pulisci TUTTE le cache e prendi controllo
// =====================================================
self.addEventListener('activate', (event) => {
  console.log('✅ [SW] Activating:', VERSION);
  
  event.waitUntil(
    // Cancella TUTTE le cache esistenti
    caches.keys().then((cacheNames) => {
      console.log('🗑️ [SW] Deleting all caches:', cacheNames);
      return Promise.all(
        cacheNames.map((cacheName) => caches.delete(cacheName))
      );
    })
    .then(() => {
      console.log('✅ [SW] All caches deleted');
      return self.clients.claim();
    })
    .then(() => {
      console.log('✅ [SW] Claimed all clients - ready');
      // NON ricaricare automaticamente per evitare loop
    })
  );
});

// =====================================================
// FETCH - SEMPRE dalla rete, MAI dalla cache
// =====================================================
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  
  // Skippa protocolli non-HTTP
  if (!url.protocol.startsWith('http')) {
    return;
  }
  
  // Skippa Chrome extensions
  if (url.protocol === 'chrome-extension:') {
    return;
  }
  
  // Skippa richieste a Supabase e API esterne - usa fetch normale
  if (url.hostname.includes('supabase.co') || 
      url.hostname.includes('unpkg.com') ||
      url.hostname.includes('jsdelivr.net') ||
      url.hostname.includes('googleapis.com') ||
      url.hostname.includes('cloudflare.com') ||
      url.hostname.includes('cdnjs.cloudflare.com') ||
      url.hostname.includes('fonts.gstatic.com') ||
      url.hostname.includes('vercel-storage.com')) {
    return; // Lascia che il browser gestisca normalmente
  }

  event.respondWith(
    // Fetch SENZA headers custom per evitare CORS
    fetch(event.request.clone(), {
      cache: 'no-store'
    })
    .then((response) => {
      // NON salvare nella cache, restituisci direttamente
      
      // Log per debug (solo file importanti)
      if (url.pathname.includes('.html') || 
          url.pathname.includes('.js') ||
          url.pathname === '/' ||
          url.pathname.includes('dashboard') ||
          url.pathname.includes('admin')) {
        console.log('🌐 [SW] Fetched from network (NO CACHE):', url.pathname);
      }
      
      return response;
    })
    .catch((error) => {
      console.error('❌ [SW] Fetch failed for:', url.pathname, error.message);
      
      // Restituisci errore 503
      return new Response(
        JSON.stringify({
          error: 'Network Error',
          message: 'Unable to fetch resource. Please check your internet connection.',
          url: url.href
        }),
        {
          status: 503,
          statusText: 'Service Unavailable',
          headers: new Headers({
            'Content-Type': 'application/json',
            'Cache-Control': 'no-store'
          })
        }
      );
    })
  );
});

// =====================================================
// MESSAGE - Gestisci comandi dal client
// =====================================================
self.addEventListener('message', (event) => {
  console.log('📨 [SW] Message received:', event.data);
  
  if (event.data && event.data.type === 'SKIP_WAITING') {
    console.log('⏩ [SW] Skip waiting on demand');
    self.skipWaiting();
  }
  
  if (event.data && event.data.type === 'CLEAR_CACHE') {
    console.log('🗑️ [SW] Clearing all caches on demand');
    event.waitUntil(
      caches.keys().then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            console.log('🗑️ [SW] Deleting cache:', cacheName);
            return caches.delete(cacheName);
          })
        );
      })
      .then(() => {
        console.log('✅ [SW] All caches cleared on demand');
        // Notifica il client
        event.ports[0].postMessage({ success: true });
      })
    );
  }
  
  if (event.data && event.data.type === 'GET_VERSION') {
    event.ports[0].postMessage({ version: VERSION });
  }
});

console.log('✅ CDM86 Service Worker ready - NO CACHE MODE ACTIVE');
