/**
 * CDM86 Promotions Interface
 * Gestisce interazioni, filtri, preferiti
 */

class PromotionsApp {
    constructor() {
        this.currentCategory = 'all';
        this.currentView = 'grid';
        this.favorites = this.loadFavorites();
        this.init();
    }

    init() {
        this.bindEvents();
        this.updateFavorites();
        this.initAnimations();
    }

    bindEvents() {
        // Category filters
        document.querySelectorAll('.category-chip').forEach(chip => {
            chip.addEventListener('click', (e) => this.filterByCategory(e.target.closest('.category-chip')));
        });

        // View toggle
        document.querySelectorAll('.toggle-btn').forEach(btn => {
            btn.addEventListener('click', (e) => this.toggleView(e.target.closest('.toggle-btn')));
        });

        // Favorite buttons
        document.querySelectorAll('.promo-favorite').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                this.toggleFavorite(e.target.closest('.promo-favorite'));
            });
        });

        // Promo cards
        document.querySelectorAll('.promo-card').forEach(card => {
            card.addEventListener('click', (e) => {
                if (!e.target.closest('.promo-favorite') && !e.target.closest('.btn-promo')) {
                    this.showPromoDetail(card);
                }
            });
        });

        // Redeem buttons
        document.querySelectorAll('.btn-promo').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                this.redeemPromo(e.target.closest('.promo-card'));
            });
        });

        // Load more
        document.querySelector('.btn-load-more')?.addEventListener('click', () => {
            this.loadMore();
        });

        // Bottom nav
        document.querySelectorAll('.bottom-nav-btn').forEach(btn => {
            btn.addEventListener('click', (e) => this.handleBottomNav(e.target.closest('.bottom-nav-btn')));
        });

        // Search
        document.getElementById('search-btn')?.addEventListener('click', () => {
            this.showSearch();
        });

        // Filter
        document.getElementById('filter-btn')?.addEventListener('click', () => {
            this.showFilters();
        });

        // Login
        document.getElementById('login-btn')?.addEventListener('click', () => {
            this.showLogin();
        });
    }

    filterByCategory(chip) {
        const category = chip.dataset.category;
        this.currentCategory = category;

        // Update active state
        document.querySelectorAll('.category-chip').forEach(c => c.classList.remove('active'));
        chip.classList.add('active');

        // Filter cards
        const cards = document.querySelectorAll('.promo-card');
        cards.forEach(card => {
            if (category === 'all' || card.dataset.category === category) {
                card.style.display = 'block';
                card.style.animation = 'fadeInUp 0.5s ease';
            } else {
                card.style.display = 'none';
            }
        });

        this.showToast(`Filtro: ${chip.querySelector('span').textContent}`, 'info');
    }

    toggleView(btn) {
        const view = btn.dataset.view;
        this.currentView = view;

        // Update active state
        document.querySelectorAll('.toggle-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');

        // Update grid layout
        const grid = document.getElementById('promotions-grid');
        if (view === 'list') {
            grid.style.gridTemplateColumns = '1fr';
        } else {
            grid.style.gridTemplateColumns = 'repeat(auto-fill, minmax(320px, 1fr))';
        }
    }

    toggleFavorite(btn) {
        const card = btn.closest('.promo-card');
        const promoId = Array.from(card.parentElement.children).indexOf(card);
        
        btn.classList.toggle('active');
        
        if (btn.classList.contains('active')) {
            this.favorites.add(promoId);
            this.showToast('Aggiunto ai preferiti', 'success');
        } else {
            this.favorites.delete(promoId);
            this.showToast('Rimosso dai preferiti', 'info');
        }
        
        this.saveFavorites();
    }

    updateFavorites() {
        document.querySelectorAll('.promo-card').forEach((card, index) => {
            const favoriteBtn = card.querySelector('.promo-favorite');
            if (this.favorites.has(index)) {
                favoriteBtn?.classList.add('active');
            }
        });
    }

    loadFavorites() {
        const saved = localStorage.getItem('cdm86_favorites');
        return saved ? new Set(JSON.parse(saved)) : new Set();
    }

    saveFavorites() {
        localStorage.setItem('cdm86_favorites', JSON.stringify([...this.favorites]));
    }

    showPromoDetail(card) {
        const title = card.querySelector('.promo-title').textContent;
        this.showToast(`Apertura dettaglio: ${title}`, 'info');
        // TODO: Aprire modal dettaglio promozione
    }

    redeemPromo(card) {
        const title = card.querySelector('.promo-title').textContent;
        
        // Check if user is logged in
        const isLoggedIn = false; // TODO: Check real auth status
        
        if (!isLoggedIn) {
            this.showToast('Accedi per riscattare questa promozione', 'warning');
            setTimeout(() => this.showLogin(), 1000);
            return;
        }
        
        this.showToast(`Riscatto: ${title}`, 'success');
        // TODO: Open redemption modal with QR code
    }

    loadMore() {
        this.showToast('Caricamento altre promozioni...', 'info');
        // TODO: Load more promotions from API
    }

    handleBottomNav(btn) {
        // Update active state
        document.querySelectorAll('.bottom-nav-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        
        const text = btn.querySelector('span').textContent;
        this.showToast(`Navigazione: ${text}`, 'info');
        // TODO: Implement navigation
    }

    showSearch() {
        this.showToast('Ricerca promozioni', 'info');
        // TODO: Show search modal/overlay
    }

    showFilters() {
        this.showToast('Filtri avanzati', 'info');
        // TODO: Show filters modal
    }

    showLogin() {
        this.showToast('Apertura login', 'info');
        // TODO: Redirect to login page or show modal
        setTimeout(() => {
            window.location.href = '/login.html';
        }, 500);
    }

    initAnimations() {
        // Intersection Observer for scroll animations
        if ('IntersectionObserver' in window) {
            const observer = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        entry.target.style.opacity = '1';
                        entry.target.style.transform = 'translateY(0)';
                    }
                });
            }, { threshold: 0.1 });

            document.querySelectorAll('.promo-card').forEach(card => {
                card.style.opacity = '0';
                card.style.transform = 'translateY(20px)';
                card.style.transition = 'all 0.5s cubic-bezier(0.4, 0, 0.2, 1)';
                observer.observe(card);
            });
        }
    }

    showToast(message, type = 'info') {
        const toast = document.createElement('div');
        toast.className = `toast toast-${type}`;
        
        const icons = {
            success: 'check-circle',
            warning: 'exclamation-triangle',
            error: 'times-circle',
            info: 'info-circle'
        };
        
        toast.innerHTML = `
            <i class="fas fa-${icons[type]}"></i>
            <span>${message}</span>
        `;

        Object.assign(toast.style, {
            position: 'fixed',
            top: '20px',
            right: '20px',
            background: type === 'success' ? '#10b981' : 
                       type === 'warning' ? '#f59e0b' : 
                       type === 'error' ? '#ef4444' : '#2563eb',
            color: 'white',
            padding: '12px 20px',
            borderRadius: '12px',
            boxShadow: '0 4px 12px rgba(0, 0, 0, 0.2)',
            zIndex: '10000',
            transform: 'translateX(400px)',
            transition: 'transform 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
            display: 'flex',
            alignItems: 'center',
            gap: '10px',
            maxWidth: '300px',
            fontSize: '14px',
            fontWeight: '500'
        });

        document.body.appendChild(toast);

        setTimeout(() => {
            toast.style.transform = 'translateX(0)';
        }, 100);

        setTimeout(() => {
            toast.style.transform = 'translateX(400px)';
            setTimeout(() => {
                document.body.removeChild(toast);
            }, 300);
        }, 3000);
    }
}

// Initialize app
document.addEventListener('DOMContentLoaded', () => {
    window.promotionsApp = new PromotionsApp();
    
    // Show welcome message
    setTimeout(() => {
        window.promotionsApp.showToast('Benvenuto in CDM86! 🎉', 'success');
    }, 500);
});

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = PromotionsApp;
}