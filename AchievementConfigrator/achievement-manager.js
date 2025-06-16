/**
 * Roqua Achievement Manager
 * Modular achievement management system
 */

class AchievementManager {
    constructor() {
        this.achievements = [];
        this.filteredAchievements = [];
        this.currentFilters = {
            category: '',
            rarity: '',
            calculator: '',
            search: ''
        };
        this.isGridView = true;
        this.editingId = null;
    }

    /**
     * Initialize the manager with sample data
     */
    init() {
        // Load sample data if no data exists
        if (this.achievements.length === 0) {
            this.loadSampleData();
        }
        this.applyFilters();
        this.updateStats();
        this.populateFilters();
        this.render();
    }

    /**
     * Load sample achievement data
     */
    loadSampleData() {
        this.achievements = [
            {
                id: "first_steps",
                category: "firstSteps",
                type: "milestone",
                title: "İlk Adımlar",
                description: "İlk 10 bölgeyi keşfet",
                iconName: "🚶",
                target: 10,
                isHidden: false,
                rarity: "common",
                calculator: "milestone",
                params: null
            },
            {
                id: "istanbul_master",
                category: "cityMaster",
                type: "geographic",
                title: "İstanbul Ustası",
                description: "İstanbul'da 50+ bölge keşfet",
                iconName: "🏢",
                target: 50,
                isHidden: false,
                rarity: "rare",
                calculator: "city",
                params: {
                    cityName: "İstanbul"
                }
            },
            {
                id: "district_explorer_25",
                category: "districtExplorer",
                type: "geographic",
                title: "İlçe Uzmanı",
                description: "25+ farklı ilçe keşfet",
                iconName: "🗺️",
                target: 25,
                isHidden: false,
                rarity: "rare",
                calculator: "district",
                params: null
            },
            {
                id: "country_collector_5",
                category: "countryCollector",
                type: "geographic",
                title: "Dünya Gezgini",
                description: "5+ ülke ziyaret et",
                iconName: "🌍",
                target: 5,
                isHidden: false,
                rarity: "epic",
                calculator: "country",
                params: null
            },
            {
                id: "area_explorer_1km",
                category: "areaExplorer",
                type: "exploration",
                title: "Alan Kaşifi",
                description: "1 km² alan keşfet",
                iconName: "📐",
                target: 1000000,
                isHidden: false,
                rarity: "common",
                calculator: "area",
                params: {
                    unit: "square_meters"
                }
            },
            {
                id: "daily_explorer_7",
                category: "dailyExplorer",
                type: "temporal",
                title: "Günlük Kaşif",
                description: "7 gün üst üste keşif yap",
                iconName: "📅",
                target: 7,
                isHidden: false,
                rarity: "rare",
                calculator: "daily_streak",
                params: {
                    type: "consecutive_days"
                }
            },
            {
                id: "weekend_warrior",
                category: "weekendWarrior",
                type: "temporal",
                title: "Hafta Sonu Savaşçısı",
                description: "4 hafta sonu üst üste keşif yap",
                iconName: "☀️",
                target: 4,
                isHidden: false,
                rarity: "rare",
                calculator: "weekend_streak",
                params: {
                    type: "consecutive_weekends"
                }
            },
            {
                id: "percentage_001",
                category: "percentageMilestone",
                type: "exploration",
                title: "Dünya'nın Binde Biri",
                description: "Dünya'nın %0.001'ini keşfet",
                iconName: "💯",
                target: 1,
                isHidden: false,
                rarity: "epic",
                calculator: "percentage",
                params: {
                    multiplier: 1000
                }
            }
        ];
    }

    /**
     * Add new achievement
     */
    addAchievement(achievement) {
        // Validate required fields
        if (!this.validateAchievement(achievement)) {
            throw new Error('Achievement validation failed');
        }

        // Check for duplicate ID
        if (this.achievements.find(a => a.id === achievement.id)) {
            throw new Error('Achievement ID already exists');
        }

        // Parse params if string
        if (typeof achievement.params === 'string') {
            try {
                achievement.params = achievement.params ? JSON.parse(achievement.params) : null;
            } catch (e) {
                throw new Error('Invalid JSON in params field');
            }
        }

        this.achievements.push(achievement);
        this.applyFilters();
        this.updateStats();
        this.populateFilters();
        this.render();
        
        return achievement;
    }

    /**
     * Update existing achievement
     */
    updateAchievement(id, updatedAchievement) {
        const index = this.achievements.findIndex(a => a.id === id);
        if (index === -1) {
            throw new Error('Achievement not found');
        }

        // If ID changed, check for duplicates
        if (updatedAchievement.id !== id && this.achievements.find(a => a.id === updatedAchievement.id)) {
            throw new Error('Achievement ID already exists');
        }

        if (!this.validateAchievement(updatedAchievement)) {
            throw new Error('Achievement validation failed');
        }

        // Parse params if string
        if (typeof updatedAchievement.params === 'string') {
            try {
                updatedAchievement.params = updatedAchievement.params ? JSON.parse(updatedAchievement.params) : null;
            } catch (e) {
                throw new Error('Invalid JSON in params field');
            }
        }

        this.achievements[index] = updatedAchievement;
        this.applyFilters();
        this.updateStats();
        this.populateFilters();
        this.render();
        
        return updatedAchievement;
    }

    /**
     * Delete achievement by ID
     */
    deleteAchievement(id) {
        const index = this.achievements.findIndex(a => a.id === id);
        if (index === -1) {
            throw new Error('Achievement not found');
        }

        const deleted = this.achievements.splice(index, 1)[0];
        this.applyFilters();
        this.updateStats();
        this.populateFilters();
        this.render();
        
        return deleted;
    }

    /**
     * Get achievement by ID
     */
    getAchievement(id) {
        return this.achievements.find(a => a.id === id);
    }

    /**
     * Validate achievement object
     */
    validateAchievement(achievement) {
        const required = ['id', 'category', 'title', 'description', 'target', 'calculator'];
        
        for (const field of required) {
            if (!achievement[field] || achievement[field] === '') {
                return false;
            }
        }

        // Validate target is positive number
        if (achievement.target <= 0) {
            return false;
        }

        return true;
    }

    /**
     * Apply current filters to achievements
     */
    applyFilters() {
        this.filteredAchievements = this.achievements.filter(achievement => {
            // Category filter
            if (this.currentFilters.category && achievement.category !== this.currentFilters.category) {
                return false;
            }

            // Rarity filter
            if (this.currentFilters.rarity && achievement.rarity !== this.currentFilters.rarity) {
                return false;
            }

            // Calculator filter
            if (this.currentFilters.calculator && achievement.calculator !== this.currentFilters.calculator) {
                return false;
            }

            // Search filter
            if (this.currentFilters.search) {
                const searchTerm = this.currentFilters.search.toLowerCase();
                return achievement.title.toLowerCase().includes(searchTerm) ||
                       achievement.description.toLowerCase().includes(searchTerm) ||
                       achievement.id.toLowerCase().includes(searchTerm);
            }

            return true;
        });
    }

    /**
     * Set filter and reapply
     */
    setFilter(type, value) {
        this.currentFilters[type] = value;
        this.applyFilters();
        this.render();
    }

    /**
     * Clear all filters
     */
    clearFilters() {
        this.currentFilters = {
            category: '',
            rarity: '',
            calculator: '',
            search: ''
        };
        this.applyFilters();
        this.render();
        
        // Reset filter UI
        document.getElementById('category-filter').value = '';
        document.getElementById('rarity-filter').value = '';
        document.getElementById('calculator-filter').value = '';
        document.getElementById('search-input').value = '';
    }

    /**
     * Update statistics
     */
    updateStats() {
        const totalCount = this.achievements.length;
        const categoryCount = new Set(this.achievements.map(a => a.category)).size;
        const calculatorCount = new Set(this.achievements.map(a => a.calculator)).size;

        document.getElementById('total-count').textContent = totalCount;
        document.getElementById('category-count').textContent = categoryCount;
        document.getElementById('calculator-count').textContent = calculatorCount;
    }

    /**
     * Populate filter dropdowns
     */
    populateFilters() {
        const categories = [...new Set(this.achievements.map(a => a.category))].sort();
        const calculators = [...new Set(this.achievements.map(a => a.calculator))].sort();

        // Populate category filter
        const categoryFilter = document.getElementById('category-filter');
        const currentCategory = categoryFilter.value;
        categoryFilter.innerHTML = '<option value="">Tümü</option>';
        categories.forEach(category => {
            const option = document.createElement('option');
            option.value = category;
            option.textContent = this.formatCategoryName(category);
            categoryFilter.appendChild(option);
        });
        categoryFilter.value = currentCategory;

        // Populate calculator filter
        const calculatorFilter = document.getElementById('calculator-filter');
        const currentCalculator = calculatorFilter.value;
        calculatorFilter.innerHTML = '<option value="">Tümü</option>';
        calculators.forEach(calculator => {
            const option = document.createElement('option');
            option.value = calculator;
            option.textContent = this.formatCalculatorName(calculator);
            calculatorFilter.appendChild(option);
        });
        calculatorFilter.value = currentCalculator;

        // Update category groups
        this.updateCategoryGroups(categories);
    }

    /**
     * Update category groups in sidebar
     */
    updateCategoryGroups(categories) {
        const container = document.getElementById('category-groups');
        container.innerHTML = '';

        categories.forEach(category => {
            const count = this.achievements.filter(a => a.category === category).length;
            const groupDiv = document.createElement('div');
            groupDiv.className = 'category-group';
            groupDiv.innerHTML = `
                <span>${this.formatCategoryName(category)}</span>
                <span class="category-count">${count}</span>
            `;
            
            groupDiv.addEventListener('click', () => {
                // Toggle category filter
                if (this.currentFilters.category === category) {
                    this.setFilter('category', '');
                    document.getElementById('category-filter').value = '';
                    groupDiv.classList.remove('active');
                } else {
                    document.querySelectorAll('.category-group').forEach(g => g.classList.remove('active'));
                    this.setFilter('category', category);
                    document.getElementById('category-filter').value = category;
                    groupDiv.classList.add('active');
                }
            });

            container.appendChild(groupDiv);
        });
    }

    /**
     * Toggle view mode (grid/list)
     */
    toggleView(isGrid) {
        this.isGridView = isGrid;
        
        // Update view buttons
        document.getElementById('grid-view').classList.toggle('active', isGrid);
        document.getElementById('list-view').classList.toggle('active', !isGrid);
        
        // Update container class
        const container = document.getElementById('achievements-container');
        container.className = isGrid ? 'achievements-grid' : 'achievements-list';
        
        this.render();
    }

    /**
     * Render achievements
     */
    render() {
        const container = document.getElementById('achievements-container');
        
        if (this.filteredAchievements.length === 0) {
            container.innerHTML = this.renderEmptyState();
            return;
        }

        container.innerHTML = this.filteredAchievements
            .map(achievement => this.renderAchievementCard(achievement))
            .join('');

        // Add animation class
        container.classList.add('fade-in');
        setTimeout(() => container.classList.remove('fade-in'), 300);
    }

    /**
     * Get icon display with fallback
     */
    getIconDisplay(iconName) {
        const iconMap = {
            'figure.walk': '🚶',
            'building.2.fill': '🏢',
            'building.columns.fill': '🏛️',
            'map.fill': '🗺️',
            'map.circle.fill': '🗺️',
            'globe.europe.africa.fill': '🌍',
            'globe.americas.fill': '🌎',
            'globe.central.south.asia.fill': '🌏',
            'square.grid.3x3.fill': '📐',
            'square.grid.4x3.fill': '📏',
            'percent': '💯',
            'calendar.badge.checkmark': '📅',
            'sun.max.fill': '☀️',
            'binoculars.fill': '🔭',
            'backpack.fill': '🎒',
            'airplane.departure': '✈️'
        };
        
        return iconMap[iconName] || iconName || '🏆';
    }

    /**
     * Render single achievement card
     */
    renderAchievementCard(achievement) {
        const iconDisplay = this.getIconDisplay(achievement.iconName);
        const hiddenClass = achievement.isHidden ? ' hidden' : '';
        const hiddenIcon = achievement.isHidden ? '<span title="Gizli Başarım" style="color: var(--accent-color); font-size: 10px;">✨</span>' : '';
        
        if (this.isGridView) {
            return `
                <div class="achievement-card${hiddenClass}" data-id="${achievement.id}">
                    <div class="achievement-header">
                        <div class="achievement-main">
                            <div class="achievement-icon">${iconDisplay}</div>
                            <div class="achievement-text">
                                <div class="achievement-title">${achievement.title}</div>
                                <div class="achievement-description">${achievement.description}</div>
                            </div>
                        </div>
                        <div class="achievement-actions">
                            <button class="action-btn edit-btn" onclick="app.editAchievement('${achievement.id}')" title="Düzenle"></button>
                            <button class="action-btn delete-btn" onclick="app.deleteAchievementConfirm('${achievement.id}')" title="Sil"></button>
                        </div>
                    </div>
                    
                    <div class="achievement-meta">
                        <span class="achievement-category">${this.formatCategoryName(achievement.category)}</span>
                        <span class="achievement-rarity rarity-${achievement.rarity}">${achievement.rarity.toUpperCase()}</span>
                    </div>
                    
                    <div class="achievement-target">
                        <span class="target-label">Hedef</span>
                        <span class="target-value">${achievement.target.toLocaleString('tr-TR')}</span>
                    </div>
                    
                    <div class="calculator-info">
                        <span>${this.formatCalculatorName(achievement.calculator)}</span>
                        ${hiddenIcon}
                    </div>
                </div>
            `;
        } else {
            return `
                <div class="achievement-card list-view${hiddenClass}" data-id="${achievement.id}">
                    <div class="achievement-icon">${iconDisplay}</div>
                    <div class="achievement-content">
                        <div>
                            <div class="achievement-title">${achievement.title}</div>
                            <div class="achievement-description">${achievement.description}</div>
                        </div>
                        <div class="achievement-category">${this.formatCategoryName(achievement.category)}</div>
                        <div class="achievement-rarity rarity-${achievement.rarity}">${achievement.rarity.toUpperCase()}</div>
                        <div class="target-value">${achievement.target.toLocaleString('tr-TR')}</div>
                        <div class="achievement-actions">
                            <button class="action-btn edit-btn" onclick="app.editAchievement('${achievement.id}')" title="Düzenle"></button>
                            <button class="action-btn delete-btn" onclick="app.deleteAchievementConfirm('${achievement.id}')" title="Sil"></button>
                        </div>
                    </div>
                </div>
            `;
        }
    }

    /**
     * Render empty state
     */
    renderEmptyState() {
        return `
            <div class="empty-state">
                <div class="empty-state-icon">🏆</div>
                <div class="empty-state-title">Başarım Bulunamadı</div>
                <div class="empty-state-description">
                    ${this.achievements.length === 0 
                        ? 'Henüz hiç başarım yok. İlk başarımınızı ekleyerek başlayın!'
                        : 'Filtrelerinize uygun başarım bulunamadı. Filtreleri temizleyerek tekrar deneyin.'
                    }
                </div>
                <button class="btn btn-primary" onclick="app.showAddModal()">+ Yeni Başarım Ekle</button>
            </div>
        `;
    }

    /**
     * Format category name for display
     */
    formatCategoryName(category) {
        const categoryNames = {
            'firstSteps': 'İlk Adımlar',
            'cityMaster': 'Şehir Ustası',
            'districtExplorer': 'İlçe Kaşifi',
            'countryCollector': 'Ülke Koleksiyoncusu',
            'areaExplorer': 'Alan Kaşifi',
            'percentageMilestone': 'Yüzde Kilometre Taşı',
            'dailyExplorer': 'Günlük Kaşif',
            'weekendWarrior': 'Hafta Sonu Savaşçısı'
        };
        return categoryNames[category] || category;
    }

    /**
     * Format calculator name for display
     */
    formatCalculatorName(calculator) {
        const calculatorNames = {
            'milestone': 'Kilometre Taşı',
            'city': 'Şehir',
            'district': 'İlçe',
            'country': 'Ülke',
            'area': 'Alan',
            'percentage': 'Yüzde',
            'daily_streak': 'Günlük Seri',
            'weekend_streak': 'Hafta Sonu Serisi',
            'multi_city': 'Çoklu Şehir',
            'time_range': 'Zaman Aralığı',
            'conditional': 'Koşullu'
        };
        return calculatorNames[calculator] || calculator;
    }

    /**
     * Import achievements from JSON
     */
    importFromJSON(jsonData) {
        try {
            let data;
            if (typeof jsonData === 'string') {
                data = JSON.parse(jsonData);
            } else {
                data = jsonData;
            }

            // Support both array and object format
            const achievements = Array.isArray(data) ? data : (data.achievements || []);
            
            if (!Array.isArray(achievements)) {
                throw new Error('Invalid format: achievements must be an array');
            }

            // Validate all achievements
            for (const achievement of achievements) {
                if (!this.validateAchievement(achievement)) {
                    throw new Error(`Invalid achievement: ${achievement.id || 'unknown'}`);
                }
            }

            this.achievements = achievements;
            this.applyFilters();
            this.updateStats();
            this.populateFilters();
            this.render();

            return achievements.length;
        } catch (error) {
            throw new Error(`JSON import failed: ${error.message}`);
        }
    }

    /**
     * Export achievements to JSON
     */
    exportToJSON() {
        return {
            version: "1.0",
            lastUpdated: new Date().toISOString(),
            achievements: this.achievements
        };
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AchievementManager;
} 