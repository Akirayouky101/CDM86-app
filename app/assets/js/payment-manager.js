// =====================================================
// PAYMENT MANAGER - Frontend Integration
// =====================================================

class PaymentManager {
    constructor() {
        this.stripePublicKey = 'pk_test_YOUR_STRIPE_PUBLIC_KEY'; // SOSTITUISCI CON CHIAVE VERA
        this.apiBaseUrl = window.location.hostname === 'localhost' 
            ? 'http://localhost:3000/api'
            : '/api';
    }

    /**
     * Inizializza pagamento Stripe
     */
    async createCheckoutSession(planId) {
        try {
            const user = await this.getCurrentUser();
            if (!user) {
                throw new Error('Utente non autenticato');
            }

            const response = await fetch(`${this.apiBaseUrl}/create-checkout-session`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${localStorage.getItem('access_token')}`
                },
                body: JSON.stringify({
                    userId: user.id,
                    planId: planId,
                    successUrl: `${window.location.origin}/dashboard?payment=success`,
                    cancelUrl: `${window.location.origin}/dashboard?payment=cancelled`
                })
            });

            if (!response.ok) {
                throw new Error('Errore durante la creazione della sessione di pagamento');
            }

            const { url } = await response.json();
            
            // Reindirizza a Stripe Checkout
            window.location.href = url;

        } catch (error) {
            console.error('Errore creazione checkout:', error);
            this.showError('Errore durante l\'avvio del pagamento. Riprova.');
            throw error;
        }
    }

    /**
     * Ottieni piani disponibili
     */
    async getSubscriptionPlans() {
        try {
            const { data, error } = await window.supabase
                .from('subscription_plans')
                .select('*')
                .eq('active', true)
                .order('sort_order');

            if (error) throw error;
            return data;

        } catch (error) {
            console.error('Errore caricamento piani:', error);
            return [];
        }
    }

    /**
     * Verifica stato abbonamento utente
     */
    async getUserSubscription(userId) {
        try {
            const { data, error } = await window.supabase
                .from('subscriptions')
                .select(`
                    *,
                    subscription_plans (
                        name,
                        description,
                        features
                    )
                `)
                .eq('user_id', userId)
                .eq('status', 'active')
                .single();

            if (error && error.code !== 'PGRST116') throw error;
            return data;

        } catch (error) {
            console.error('Errore verifica abbonamento:', error);
            return null;
        }
    }

    /**
     * Gestisci redirect dopo pagamento
     */
    async handlePaymentCallback() {
        const urlParams = new URLSearchParams(window.location.search);
        const paymentStatus = urlParams.get('payment');
        const sessionId = urlParams.get('session_id');

        if (paymentStatus === 'success' && sessionId) {
            this.showSuccess('Pagamento completato! Il tuo account è ora attivo.');
            
            // Ricarica dati utente
            setTimeout(() => {
                window.location.href = '/dashboard';
            }, 2000);

        } else if (paymentStatus === 'cancelled') {
            this.showWarning('Pagamento annullato. Puoi riprovare quando vuoi.');
        }
    }

    /**
     * Cancella abbonamento
     */
    async cancelSubscription(subscriptionId) {
        if (!confirm('Sei sicuro di voler cancellare l\'abbonamento? Rimarrà attivo fino alla fine del periodo corrente.')) {
            return;
        }

        try {
            const response = await fetch(`${this.apiBaseUrl}/cancel-subscription`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${localStorage.getItem('access_token')}`
                },
                body: JSON.stringify({ subscriptionId })
            });

            if (!response.ok) throw new Error('Errore cancellazione abbonamento');

            this.showSuccess('Abbonamento cancellato. Rimarrà attivo fino alla fine del periodo corrente.');
            
            // Ricarica pagina
            setTimeout(() => location.reload(), 2000);

        } catch (error) {
            console.error('Errore:', error);
            this.showError('Impossibile cancellare l\'abbonamento. Riprova.');
        }
    }

    /**
     * Ottieni utente corrente
     */
    async getCurrentUser() {
        const { data: { user } } = await window.supabase.auth.getUser();
        return user;
    }

    /**
     * Mostra messaggio successo
     */
    showSuccess(message) {
        this.showNotification(message, 'success');
    }

    /**
     * Mostra messaggio errore
     */
    showError(message) {
        this.showNotification(message, 'error');
    }

    /**
     * Mostra messaggio warning
     */
    showWarning(message) {
        this.showNotification(message, 'warning');
    }

    /**
     * Sistema di notifiche
     */
    showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 15px 20px;
            background: ${type === 'success' ? '#10b981' : type === 'error' ? '#ef4444' : '#f59e0b'};
            color: white;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            z-index: 10000;
            animation: slideIn 0.3s ease-out;
        `;
        notification.textContent = message;
        document.body.appendChild(notification);

        setTimeout(() => {
            notification.style.animation = 'slideOut 0.3s ease-out';
            setTimeout(() => notification.remove(), 300);
        }, 5000);
    }
}

// Esporta istanza globale
window.paymentManager = new PaymentManager();

// Gestisci callback al caricamento pagina
document.addEventListener('DOMContentLoaded', () => {
    window.paymentManager.handlePaymentCallback();
});
