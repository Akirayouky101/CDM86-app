/**
 * CDM86 Dashboard - Main JavaScript
 * Professional interface with smooth animations and interactions
 */

class CDM86Dashboard {
    constructor() {
        this.currentPanel = 'users';
        this.isTransitioning = false;
        this.init();
    }

    init() {
        this.bindEvents();
        this.initializeAnimations();
        this.setupProgressBars();
        this.initializeNotifications();
        this.setupResponsiveHandlers();
        
        // Show welcome message
        this.showWelcomeMessage();
    }

    bindEvents() {
        // Navigation buttons
        const navButtons = document.querySelectorAll('.nav-btn');
        navButtons.forEach(btn => {
            btn.addEventListener('click', (e) => this.switchPanel(e.target.closest('.nav-btn')));
        });

        // Action buttons
        const actionButtons = document.querySelectorAll('.action-btn');
        actionButtons.forEach(btn => {
            btn.addEventListener('click', (e) => this.handleAction(e.target.closest('.action-btn')));
        });

        // Project items
        const projectItems = document.querySelectorAll('.project-item');
        projectItems.forEach(item => {
            item.addEventListener('click', (e) => this.handleProjectClick(e.target.closest('.project-item')));
        });

        // User profile
        const userProfile = document.querySelector('.user-profile');
        if (userProfile) {
            userProfile.addEventListener('click', () => this.handleUserProfileClick());
        }

        // Notification items
        const notificationItems = document.querySelectorAll('.notification-item');
        notificationItems.forEach(item => {
            item.addEventListener('click', (e) => this.handleNotificationClick(e.target.closest('.notification-item')));
        });

        // Window resize
        window.addEventListener('resize', () => this.handleResize());
        
        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => this.handleKeyboardShortcuts(e));
    }

    switchPanel(button) {
        if (this.isTransitioning) return;
        
        const targetPanel = button.dataset.panel;
        if (targetPanel === this.currentPanel) return;

        this.isTransitioning = true;

        // Update navigation
        document.querySelectorAll('.nav-btn').forEach(btn => btn.classList.remove('active'));
        button.classList.add('active');

        // Hide current panel
        const currentPanelEl = document.getElementById(`${this.currentPanel}-panel`);
        const targetPanelEl = document.getElementById(`${targetPanel}-panel`);

        if (currentPanelEl) {
            currentPanelEl.style.opacity = '0';
            currentPanelEl.style.transform = 'translateY(20px)';
            
            setTimeout(() => {
                currentPanelEl.classList.remove('active');
                this.showPanel(targetPanelEl, targetPanel);
            }, 300);
        } else {
            this.showPanel(targetPanelEl, targetPanel);
        }
    }

    showPanel(panelEl, panelName) {
        if (panelEl) {
            panelEl.classList.add('active');
            panelEl.style.opacity = '0';
            panelEl.style.transform = 'translateY(20px)';
            
            // Force reflow
            panelEl.offsetHeight;
            
            // Animate in
            setTimeout(() => {
                panelEl.style.opacity = '1';
                panelEl.style.transform = 'translateY(0)';
                this.currentPanel = panelName;
                this.isTransitioning = false;
                
                // Update user role text
                this.updateUserRole(panelName);
                
                // Trigger panel-specific animations
                this.triggerPanelAnimations(panelName);
            }, 50);
        }
    }

    updateUserRole(panelName) {
        const userRole = document.querySelector('.user-role');
        if (userRole) {
            const roleMap = {
                'users': 'Pannello Principale',
                'admin': 'Amministratore',
                'developer': 'Sviluppatore'
            };
            userRole.textContent = roleMap[panelName] || 'Utente';
        }
    }

    triggerPanelAnimations(panelName) {
        const panel = document.getElementById(`${panelName}-panel`);
        if (!panel) return;

        // Re-trigger animations for elements in the new panel
        const animatedElements = panel.querySelectorAll('.stat-card, .project-item, .widget');
        animatedElements.forEach((el, index) => {
            el.style.opacity = '0';
            el.style.transform = 'translateY(20px)';
            
            setTimeout(() => {
                el.style.transition = 'all 0.5s cubic-bezier(0.4, 0, 0.2, 1)';
                el.style.opacity = '1';
                el.style.transform = 'translateY(0)';
            }, index * 100);
        });
    }

    initializeAnimations() {
        // Add intersection observer for scroll animations
        if ('IntersectionObserver' in window) {
            const observer = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        entry.target.classList.add('animate-in');
                    }
                });
            }, { threshold: 0.1 });

            const animateElements = document.querySelectorAll('.stat-card, .widget, .project-item');
            animateElements.forEach(el => observer.observe(el));
        }

        // Add loading states
        this.simulateDataLoading();
    }

    simulateDataLoading() {
        const statNumbers = document.querySelectorAll('.stat-number');
        statNumbers.forEach(el => {
            const finalValue = parseInt(el.textContent);
            let currentValue = 0;
            const increment = finalValue / 50;
            const timer = setInterval(() => {
                currentValue += increment;
                if (currentValue >= finalValue) {
                    currentValue = finalValue;
                    clearInterval(timer);
                }
                el.textContent = Math.floor(currentValue);
            }, 30);
        });
    }

    setupProgressBars() {
        const progressBars = document.querySelectorAll('.progress-fill');
        progressBars.forEach((bar, index) => {
            setTimeout(() => {
                const width = bar.style.width;
                bar.style.width = '0%';
                setTimeout(() => {
                    bar.style.transition = 'width 1.5s cubic-bezier(0.4, 0, 0.2, 1)';
                    bar.style.width = width;
                }, 100);
            }, index * 200 + 1000);
        });
    }

    handleAction(button) {
        const action = button.querySelector('span').textContent;
        
        // Add click effect
        button.style.transform = 'scale(0.95)';
        setTimeout(() => {
            button.style.transform = 'scale(1)';
        }, 150);

        // Handle specific actions
        switch(action) {
            case 'Nuovo Progetto':
                this.showToast('Apertura form nuovo progetto...', 'info');
                break;
            case 'Carica File':
                this.showToast('Apertura dialog caricamento file...', 'info');
                break;
            case 'Condividi':
                this.showToast('Apertura opzioni condivisione...', 'info');
                break;
            default:
                this.showToast('Funzionalità in sviluppo', 'warning');
        }
    }

    handleProjectClick(projectItem) {
        const projectName = projectItem.querySelector('h4').textContent;
        this.showToast(`Apertura progetto: ${projectName}`, 'success');
        
        // Add selection effect
        projectItem.style.background = 'rgba(37, 99, 235, 0.1)';
        setTimeout(() => {
            projectItem.style.background = '';
        }, 300);
    }

    handleUserProfileClick() {
        this.showToast('Apertura profilo utente', 'info');
    }

    handleNotificationClick(notificationItem) {
        const notificationText = notificationItem.querySelector('p').textContent;
        this.showToast(`Notifica: ${notificationText}`, 'info');
        
        // Mark as read
        notificationItem.style.opacity = '0.6';
    }

    initializeNotifications() {
        // Simulate real-time notifications
        setInterval(() => {
            if (Math.random() > 0.95) { // 5% chance every check
                this.addNewNotification();
            }
        }, 10000); // Check every 10 seconds
    }

    addNewNotification() {
        const notifications = [
            'Nuovo messaggio ricevuto',
            'Backup completato con successo',
            'Aggiornamento sistema disponibile',
            'Task completato da un collaboratore',
            'Nuovo commento su progetto'
        ];
        
        const randomNotification = notifications[Math.floor(Math.random() * notifications.length)];
        this.showToast(randomNotification, 'info');
    }

    showToast(message, type = 'info') {
        // Create toast element
        const toast = document.createElement('div');
        toast.className = `toast toast-${type}`;
        toast.innerHTML = `
            <div class="toast-content">
                <i class="fas fa-${this.getToastIcon(type)}"></i>
                <span>${message}</span>
            </div>
        `;

        // Add styles
        Object.assign(toast.style, {
            position: 'fixed',
            top: '20px',
            right: '20px',
            background: type === 'success' ? '#10b981' : type === 'warning' ? '#f59e0b' : type === 'error' ? '#ef4444' : '#2563eb',
            color: 'white',
            padding: '12px 20px',
            borderRadius: '8px',
            boxShadow: '0 4px 12px rgba(0, 0, 0, 0.2)',
            zIndex: '1000',
            transform: 'translateX(100%)',
            transition: 'transform 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            maxWidth: '300px',
            fontSize: '14px'
        });

        document.body.appendChild(toast);

        // Animate in
        setTimeout(() => {
            toast.style.transform = 'translateX(0)';
        }, 100);

        // Auto-remove
        setTimeout(() => {
            toast.style.transform = 'translateX(100%)';
            setTimeout(() => {
                document.body.removeChild(toast);
            }, 300);
        }, 3000);
    }

    getToastIcon(type) {
        const icons = {
            success: 'check',
            warning: 'exclamation-triangle',
            error: 'times',
            info: 'info-circle'
        };
        return icons[type] || 'info-circle';
    }

    setupResponsiveHandlers() {
        // Handle mobile menu if needed
        const mediaQuery = window.matchMedia('(max-width: 768px)');
        mediaQuery.addEventListener('change', (e) => {
            if (e.matches) {
                this.enableMobileMode();
            } else {
                this.disableMobileMode();
            }
        });

        if (mediaQuery.matches) {
            this.enableMobileMode();
        }
    }

    enableMobileMode() {
        document.body.classList.add('mobile-mode');
    }

    disableMobileMode() {
        document.body.classList.remove('mobile-mode');
    }

    handleResize() {
        // Debounce resize handler
        clearTimeout(this.resizeTimeout);
        this.resizeTimeout = setTimeout(() => {
            this.updateLayout();
        }, 250);
    }

    updateLayout() {
        // Recalculate layout if needed
        const contentGrid = document.querySelector('.content-grid');
        if (contentGrid && window.innerWidth < 1200) {
            contentGrid.style.gridTemplateColumns = '1fr';
        } else if (contentGrid) {
            contentGrid.style.gridTemplateColumns = '1fr 350px';
        }
    }

    handleKeyboardShortcuts(e) {
        // Keyboard shortcuts for accessibility
        if (e.altKey) {
            switch(e.code) {
                case 'Digit1':
                    e.preventDefault();
                    document.querySelector('[data-panel="users"]').click();
                    break;
                case 'Digit2':
                    e.preventDefault();
                    document.querySelector('[data-panel="admin"]').click();
                    break;
                case 'Digit3':
                    e.preventDefault();
                    document.querySelector('[data-panel="developer"]').click();
                    break;
            }
        }
    }

    showWelcomeMessage() {
        setTimeout(() => {
            this.showToast('Benvenuto in CDM86 Dashboard!', 'success');
        }, 1000);
    }

    // Public API methods
    switchToPanel(panelName) {
        const button = document.querySelector(`[data-panel="${panelName}"]`);
        if (button) {
            button.click();
        }
    }

    updateStatistic(statIndex, newValue, animate = true) {
        const statNumbers = document.querySelectorAll('.stat-number');
        if (statNumbers[statIndex]) {
            if (animate) {
                this.animateNumber(statNumbers[statIndex], newValue);
            } else {
                statNumbers[statIndex].textContent = newValue;
            }
        }
    }

    animateNumber(element, targetValue) {
        const startValue = parseInt(element.textContent) || 0;
        const difference = targetValue - startValue;
        const duration = 1000;
        const steps = 60;
        const stepValue = difference / steps;
        let currentStep = 0;

        const timer = setInterval(() => {
            currentStep++;
            const currentValue = startValue + (stepValue * currentStep);
            
            if (currentStep >= steps) {
                element.textContent = targetValue;
                clearInterval(timer);
            } else {
                element.textContent = Math.floor(currentValue);
            }
        }, duration / steps);
    }

    addProject(projectData) {
        // Method to dynamically add new projects
        const projectList = document.querySelector('.project-list');
        if (projectList && projectData) {
            const projectHTML = this.createProjectHTML(projectData);
            const projectElement = document.createElement('div');
            projectElement.innerHTML = projectHTML;
            projectList.appendChild(projectElement.firstElementChild);
        }
    }

    createProjectHTML(project) {
        return `
            <div class="project-item">
                <div class="project-info">
                    <div class="project-avatar">
                        <i class="fas fa-${project.icon || 'folder'}"></i>
                    </div>
                    <div class="project-details">
                        <h4>${project.name}</h4>
                        <p>${project.description}</p>
                        <div class="project-meta">
                            <span class="project-status ${project.status}">${project.statusText}</span>
                            <span class="project-date">${project.date}</span>
                        </div>
                    </div>
                </div>
                <div class="project-progress">
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: ${project.progress}%"></div>
                    </div>
                    <span class="progress-text">${project.progress}%</span>
                </div>
            </div>
        `;
    }
}

// Initialize dashboard when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.cdm86Dashboard = new CDM86Dashboard();
});

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = CDM86Dashboard;
}