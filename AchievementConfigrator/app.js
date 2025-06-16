/**
 * Main Application Controller
 * Handles UI interactions and manages modals
 */

class App {
    constructor() {
        this.manager = new AchievementManager();
        this.deleteId = null;
        this.initializeEventListeners();
    }

    /**
     * Initialize all event listeners
     */
    initializeEventListeners() {
        // Header actions
        document.getElementById('import-btn').addEventListener('click', () => this.importJSON());
        document.getElementById('export-btn').addEventListener('click', () => this.exportJSON());
        document.getElementById('add-btn').addEventListener('click', () => this.showAddModal());

        // Search and filters
        document.getElementById('search-input').addEventListener('input', (e) => {
            this.manager.setFilter('search', e.target.value);
        });
        document.getElementById('search-btn').addEventListener('click', () => {
            const searchTerm = document.getElementById('search-input').value;
            this.manager.setFilter('search', searchTerm);
        });

        document.getElementById('category-filter').addEventListener('change', (e) => {
            this.manager.setFilter('category', e.target.value);
        });
        document.getElementById('rarity-filter').addEventListener('change', (e) => {
            this.manager.setFilter('rarity', e.target.value);
        });
        document.getElementById('calculator-filter').addEventListener('change', (e) => {
            this.manager.setFilter('calculator', e.target.value);
        });
        document.getElementById('clear-filters').addEventListener('click', () => {
            this.manager.clearFilters();
        });

        // View toggle
        document.getElementById('grid-view').addEventListener('click', () => {
            this.manager.toggleView(true);
        });
        document.getElementById('list-view').addEventListener('click', () => {
            this.manager.toggleView(false);
        });

        // Modal events
        this.initializeModalEvents();

        // File input for import
        document.getElementById('file-input').addEventListener('change', (e) => {
            this.handleFileImport(e);
        });

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.closeAllModals();
            }
            if (e.ctrlKey || e.metaKey) {
                switch(e.key) {
                    case 'n':
                        e.preventDefault();
                        this.showAddModal();
                        break;
                    case 's':
                        e.preventDefault();
                        this.exportJSON();
                        break;
                    case 'o':
                        e.preventDefault();
                        this.importJSON();
                        break;
                }
            }
        });
    }

    /**
     * Initialize modal-related event listeners
     */
    initializeModalEvents() {
        // Achievement modal
        const achievementModal = document.getElementById('achievement-modal');
        const deleteModal = document.getElementById('delete-modal');

        // Close modal buttons
        document.querySelectorAll('.modal-close').forEach(btn => {
            btn.addEventListener('click', () => this.closeAllModals());
        });

        // Click outside modal to close
        [achievementModal, deleteModal].forEach(modal => {
            modal.addEventListener('click', (e) => {
                if (e.target === modal) {
                    this.closeAllModals();
                }
            });
        });

        // Form submission
        document.getElementById('achievement-form').addEventListener('submit', (e) => {
            e.preventDefault();
            this.saveAchievement();
        });

        // Cancel buttons
        document.getElementById('cancel-btn').addEventListener('click', () => {
            this.closeAllModals();
        });
        document.getElementById('cancel-delete').addEventListener('click', () => {
            this.closeAllModals();
        });

        // Confirm delete
        document.getElementById('confirm-delete').addEventListener('click', () => {
            if (this.deleteId) {
                this.confirmDelete();
            }
        });
    }

    /**
     * Initialize the application
     */
    init() {
        this.manager.init();
        this.showWelcomeMessage();
    }

    /**
     * Show welcome message
     */
    showWelcomeMessage() {
        // You could add a welcome toast or tutorial here
        console.log('🏆 Roqua Achievement Configurator başlatıldı!');
    }

    /**
     * Show add achievement modal
     */
    showAddModal() {
        this.manager.editingId = null;
        document.getElementById('modal-title').textContent = 'Yeni Başarım';
        this.clearForm();
        this.showModal('achievement-modal');
    }

    /**
     * Edit achievement
     */
    editAchievement(id) {
        const achievement = this.manager.getAchievement(id);
        if (!achievement) {
            this.showError('Başarım bulunamadı');
            return;
        }

        this.manager.editingId = id;
        document.getElementById('modal-title').textContent = 'Başarımı Düzenle';
        this.populateForm(achievement);
        this.showModal('achievement-modal');
    }

    /**
     * Show delete confirmation
     */
    deleteAchievementConfirm(id) {
        this.deleteId = id;
        this.showModal('delete-modal');
    }

    /**
     * Confirm and execute delete
     */
    confirmDelete() {
        try {
            this.manager.deleteAchievement(this.deleteId);
            this.showSuccess('Başarım silindi');
            this.closeAllModals();
        } catch (error) {
            this.showError(`Silme hatası: ${error.message}`);
        }
        this.deleteId = null;
    }

    /**
     * Save achievement (add or update)
     */
    saveAchievement() {
        try {
            const achievement = this.getFormData();
            
            if (this.manager.editingId) {
                this.manager.updateAchievement(this.manager.editingId, achievement);
                this.showSuccess('Başarım güncellendi');
            } else {
                this.manager.addAchievement(achievement);
                this.showSuccess('Başarım eklendi');
            }
            
            this.closeAllModals();
        } catch (error) {
            this.showError(`Kaydetme hatası: ${error.message}`);
        }
    }

    /**
     * Get form data as achievement object
     */
    getFormData() {
        const form = document.getElementById('achievement-form');
        const formData = new FormData(form);
        
        const achievement = {
            id: document.getElementById('achievement-id').value.trim(),
            category: document.getElementById('achievement-category').value.trim(),
            type: document.getElementById('achievement-type').value,
            title: document.getElementById('achievement-title').value.trim(),
            description: document.getElementById('achievement-description').value.trim(),
            iconName: document.getElementById('achievement-icon').value.trim() || '🏆',
            target: parseInt(document.getElementById('achievement-target').value),
            isHidden: document.getElementById('achievement-hidden').checked,
            rarity: document.getElementById('achievement-rarity').value,
            calculator: document.getElementById('achievement-calculator').value,
            params: document.getElementById('achievement-params').value.trim() || null
        };

        return achievement;
    }

    /**
     * Populate form with achievement data
     */
    populateForm(achievement) {
        document.getElementById('achievement-id').value = achievement.id;
        document.getElementById('achievement-category').value = achievement.category;
        document.getElementById('achievement-type').value = achievement.type || 'geographic';
        document.getElementById('achievement-title').value = achievement.title;
        document.getElementById('achievement-description').value = achievement.description;
        document.getElementById('achievement-icon').value = achievement.iconName || '';
        document.getElementById('achievement-target').value = achievement.target;
        document.getElementById('achievement-hidden').checked = achievement.isHidden || false;
        document.getElementById('achievement-rarity').value = achievement.rarity || 'common';
        document.getElementById('achievement-calculator').value = achievement.calculator;
        document.getElementById('achievement-params').value = achievement.params ? 
            JSON.stringify(achievement.params, null, 2) : '';
    }

    /**
     * Clear form
     */
    clearForm() {
        document.getElementById('achievement-form').reset();
        document.getElementById('achievement-params').value = '';
    }

    /**
     * Show modal
     */
    showModal(modalId) {
        this.closeAllModals();
        document.getElementById(modalId).classList.add('active');
        
        // Focus first input if achievement modal
        if (modalId === 'achievement-modal') {
            setTimeout(() => {
                document.getElementById('achievement-id').focus();
            }, 100);
        }
    }

    /**
     * Close all modals
     */
    closeAllModals() {
        document.querySelectorAll('.modal').forEach(modal => {
            modal.classList.remove('active');
        });
        this.manager.editingId = null;
        this.deleteId = null;
    }

    /**
     * Import JSON file
     */
    importJSON() {
        document.getElementById('file-input').click();
    }

    /**
     * Handle file import
     */
    handleFileImport(event) {
        const file = event.target.files[0];
        if (!file) return;

        if (file.type !== 'application/json') {
            this.showError('Lütfen JSON dosyası seçin');
            return;
        }

        const reader = new FileReader();
        reader.onload = (e) => {
            try {
                const count = this.manager.importFromJSON(e.target.result);
                this.showSuccess(`${count} başarım içe aktarıldı`);
            } catch (error) {
                this.showError(`İçe aktarma hatası: ${error.message}`);
            }
        };
        reader.readAsText(file);
        
        // Reset file input
        event.target.value = '';
    }

    /**
     * Export JSON file
     */
    exportJSON() {
        try {
            const data = this.manager.exportToJSON();
            const blob = new Blob([JSON.stringify(data, null, 2)], {
                type: 'application/json'
            });
            
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `roqua-achievements-${new Date().toISOString().split('T')[0]}.json`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
            
            this.showSuccess('JSON dosyası dışa aktarıldı');
        } catch (error) {
            this.showError(`Dışa aktarma hatası: ${error.message}`);
        }
    }

    /**
     * Show success message
     */
    showSuccess(message) {
        this.showToast(message, 'success');
    }

    /**
     * Show error message
     */
    showError(message) {
        this.showToast(message, 'error');
    }

    /**
     * Show toast notification
     */
    showToast(message, type = 'info') {
        // Remove existing toasts
        document.querySelectorAll('.toast').forEach(toast => toast.remove());

        const toast = document.createElement('div');
        toast.className = `toast toast-${type}`;
        toast.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: ${type === 'success' ? '#34C759' : type === 'error' ? '#FF3B30' : '#007AFF'};
            color: white;
            padding: 12px 20px;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
            z-index: 10000;
            font-weight: 500;
            max-width: 300px;
            animation: slideInRight 0.3s ease-out;
        `;
        toast.textContent = message;

        // Add slide animation
        const style = document.createElement('style');
        style.textContent = `
            @keyframes slideInRight {
                from {
                    opacity: 0;
                    transform: translateX(100%);
                }
                to {
                    opacity: 1;
                    transform: translateX(0);
                }
            }
        `;
        if (!document.head.querySelector('style[data-toast]')) {
            style.setAttribute('data-toast', '');
            document.head.appendChild(style);
        }

        document.body.appendChild(toast);

        // Auto remove after 3 seconds
        setTimeout(() => {
            if (toast.parentNode) {
                toast.style.animation = 'slideInRight 0.3s ease-out reverse';
                setTimeout(() => toast.remove(), 300);
            }
        }, 3000);

        // Click to dismiss
        toast.addEventListener('click', () => {
            toast.style.animation = 'slideInRight 0.3s ease-out reverse';
            setTimeout(() => toast.remove(), 300);
        });
    }

    /**
     * Show loading state
     */
    showLoading() {
        const container = document.getElementById('achievements-container');
        container.innerHTML = '<div class="loading">Yükleniyor...</div>';
    }
}

// Initialize app when DOM is loaded
let app;
document.addEventListener('DOMContentLoaded', () => {
    app = new App();
    app.init();
});

// Expose app globally for inline event handlers
window.app = app; 