/**
 * Achievement Form Controller
 * Handles all form operations with validation, sanitization and controls
 */
class AchievementFormController {
    constructor(achievementManager) {
        this.achievementManager = achievementManager;
        this.currentMode = 'add'; // 'add' or 'edit'
        this.currentAchievementId = null;
        this.categories = [];
        this.calculatorTypes = [];
        this.sfSymbols = [];
        
        this.init();
    }

    /**
     * Initialize the form controller
     */
    init() {
        this.setupCategories();
        this.setupCalculatorTypes();
        this.setupSFSymbols();
        this.bindFormEvents();
    }

    /**
     * Setup predefined categories
     */
    setupCategories() {
        this.categories = [
            { id: 'firstSteps', name: 'İlk Adımlar', description: 'Temel başarımlar' },
            { id: 'cityMaster', name: 'Şehir Ustası', description: 'Şehir keşif başarımları' },
            { id: 'districtExplorer', name: 'İlçe Kaşifi', description: 'İlçe bazlı başarımlar' },
            { id: 'countryCollector', name: 'Ülke Koleksiyoncusu', description: 'Ülke seviyesi başarımlar' },
            { id: 'areaExplorer', name: 'Alan Kaşifi', description: 'Alan tabanlı başarımlar' },
            { id: 'percentageMilestone', name: 'Yüzde Kilometre Taşı', description: 'Yüzdelik başarımlar' },
            { id: 'dailyExplorer', name: 'Günlük Kaşif', description: 'Günlük aktivite başarımları' },
            { id: 'weekendWarrior', name: 'Hafta Sonu Savaşçısı', description: 'Hafta sonu özel başarımları' }
        ];
    }

    /**
     * Setup calculator types
     */
    setupCalculatorTypes() {
        this.calculatorTypes = [
            { 
                id: 'milestone', 
                name: 'Kilometre Taşı', 
                description: 'Belirli bir sayıya ulaşma',
                hasParameters: false,
                targetRequired: true
            },
            { 
                id: 'city', 
                name: 'Şehir', 
                description: 'Şehir bazlı hesaplama',
                hasParameters: true,
                targetRequired: true,
                parameterSchema: {
                    cityNames: { type: 'array', description: 'Şehir isimleri listesi' }
                }
            },
            { 
                id: 'district', 
                name: 'İlçe', 
                description: 'İlçe bazlı hesaplama',
                hasParameters: true,
                targetRequired: true,
                parameterSchema: {
                    districtNames: { type: 'array', description: 'İlçe isimleri listesi' }
                }
            },
            { 
                id: 'country', 
                name: 'Ülke', 
                description: 'Ülke bazlı hesaplama',
                hasParameters: true,
                targetRequired: true,
                parameterSchema: {
                    countryNames: { type: 'array', description: 'Ülke isimleri listesi' }
                }
            },
            { 
                id: 'area', 
                name: 'Alan', 
                description: 'Alan bazlı hesaplama',
                hasParameters: true,
                targetRequired: true,
                parameterSchema: {
                    minArea: { type: 'number', description: 'Minimum alan (km²)' },
                    maxArea: { type: 'number', description: 'Maksimum alan (km²)' }
                }
            },
            { 
                id: 'percentage', 
                name: 'Yüzde', 
                description: 'Yüzdelik hesaplama',
                hasParameters: false,
                targetRequired: true
            },
            { 
                id: 'daily_streak', 
                name: 'Günlük Seri', 
                description: 'Ardışık günlük aktivite',
                hasParameters: false,
                targetRequired: true
            },
            { 
                id: 'weekend_streak', 
                name: 'Hafta Sonu Serisi', 
                description: 'Ardışık hafta sonu aktivitesi',
                hasParameters: false,
                targetRequired: true
            },
            { 
                id: 'multi_city', 
                name: 'Çoklu Şehir', 
                description: 'Birden fazla şehirde aktivite',
                hasParameters: true,
                targetRequired: true,
                parameterSchema: {
                    minCities: { type: 'number', description: 'Minimum şehir sayısı' },
                    timeWindow: { type: 'string', description: 'Zaman penceresi (daily, weekly, monthly)' }
                }
            },
            { 
                id: 'time_range', 
                name: 'Zaman Aralığı', 
                description: 'Belirli zaman aralığında aktivite',
                hasParameters: true,
                targetRequired: true,
                parameterSchema: {
                    startTime: { type: 'string', description: 'Başlangıç saati (HH:MM)' },
                    endTime: { type: 'string', description: 'Bitiş saati (HH:MM)' }
                }
            },
            { 
                id: 'conditional', 
                name: 'Koşullu', 
                description: 'Koşullu hesaplama',
                hasParameters: true,
                targetRequired: true,
                parameterSchema: {
                    conditions: { type: 'array', description: 'Koşullar listesi' },
                    operator: { type: 'string', description: 'Mantıksal operatör (AND, OR)' }
                }
            }
        ];
    }

    /**
     * Setup SF Symbols for iOS
     */
    setupSFSymbols() {
        this.sfSymbols = [
            // Navigation & Movement
            { symbol: 'figure.walk', emoji: '🚶', category: 'Hareket', name: 'Yürüyüş' },
            { symbol: 'figure.run', emoji: '🏃', category: 'Hareket', name: 'Koşu' },
            { symbol: 'bicycle', emoji: '🚲', category: 'Hareket', name: 'Bisiklet' },
            { symbol: 'car.fill', emoji: '🚗', category: 'Hareket', name: 'Araba' },
            { symbol: 'airplane.departure', emoji: '✈️', category: 'Hareket', name: 'Uçak' },
            
            // Buildings & Places
            { symbol: 'building.2.fill', emoji: '🏢', category: 'Yapılar', name: 'Ofis Binası' },
            { symbol: 'building.columns.fill', emoji: '🏛️', category: 'Yapılar', name: 'Müze' },
            { symbol: 'house.fill', emoji: '🏠', category: 'Yapılar', name: 'Ev' },
            { symbol: 'location.fill', emoji: '📍', category: 'Yapılar', name: 'Konum' },
            { symbol: 'mappin.and.ellipse', emoji: '📍', category: 'Yapılar', name: 'Harita Pini' },
            
            // Maps & Geography
            { symbol: 'map.fill', emoji: '🗺️', category: 'Harita', name: 'Harita' },
            { symbol: 'map.circle.fill', emoji: '🗺️', category: 'Harita', name: 'Harita Daire' },
            { symbol: 'globe.europe.africa.fill', emoji: '🌍', category: 'Harita', name: 'Dünya (Avrupa)' },
            { symbol: 'globe.americas.fill', emoji: '🌎', category: 'Harita', name: 'Dünya (Amerika)' },
            { symbol: 'globe.central.south.asia.fill', emoji: '🌏', category: 'Harita', name: 'Dünya (Asya)' },
            
            // Measurement & Analytics
            { symbol: 'square.grid.3x3.fill', emoji: '📐', category: 'Ölçüm', name: '3x3 Grid' },
            { symbol: 'square.grid.4x3.fill', emoji: '📏', category: 'Ölçüm', name: '4x3 Grid' },
            { symbol: 'percent', emoji: '💯', category: 'Ölçüm', name: 'Yüzde' },
            { symbol: 'chart.bar.fill', emoji: '📊', category: 'Ölçüm', name: 'Grafik' },
            { symbol: 'speedometer', emoji: '⏱️', category: 'Ölçüm', name: 'Hızölçer' },
            
            // Time & Calendar
            { symbol: 'calendar.badge.checkmark', emoji: '📅', category: 'Zaman', name: 'Takvim' },
            { symbol: 'clock.fill', emoji: '🕐', category: 'Zaman', name: 'Saat' },
            { symbol: 'timer', emoji: '⏲️', category: 'Zaman', name: 'Zamanlayıcı' },
            { symbol: 'sun.max.fill', emoji: '☀️', category: 'Zaman', name: 'Gündüz' },
            { symbol: 'moon.fill', emoji: '🌙', category: 'Zaman', name: 'Gece' },
            
            // Exploration & Adventure
            { symbol: 'binoculars.fill', emoji: '🔭', category: 'Keşif', name: 'Dürbün' },
            { symbol: 'backpack.fill', emoji: '🎒', category: 'Keşif', name: 'Sırt Çantası' },
            { symbol: 'camera.fill', emoji: '📷', category: 'Keşif', name: 'Kamera' },
            { symbol: 'compass.drawing', emoji: '🧭', category: 'Keşif', name: 'Pusula' },
            { symbol: 'mountain.2.fill', emoji: '⛰️', category: 'Keşif', name: 'Dağ' },
            
            // Achievement & Rewards
            { symbol: 'trophy.fill', emoji: '🏆', category: 'Ödül', name: 'Kupa' },
            { symbol: 'medal.fill', emoji: '🏅', category: 'Ödül', name: 'Madalya' },
            { symbol: 'star.fill', emoji: '⭐', category: 'Ödül', name: 'Yıldız' },
            { symbol: 'crown.fill', emoji: '👑', category: 'Ödül', name: 'Taç' },
            { symbol: 'target', emoji: '🎯', category: 'Ödül', name: 'Hedef' }
        ];
    }

    /**
     * Bind form events
     */
    bindFormEvents() {
        // ID field auto-sanitization
        document.addEventListener('input', (e) => {
            if (e.target.id === 'achievementId') {
                this.sanitizeId(e.target);
            }
        });

        // Calculator type change
        document.addEventListener('change', (e) => {
            if (e.target.id === 'achievementCalculator') {
                this.onCalculatorTypeChange(e.target.value);
            }
        });

        // Real-time validation
        document.addEventListener('blur', (e) => {
            if (e.target.form && e.target.form.id === 'achievementForm') {
                this.validateField(e.target);
            }
        });
    }

    /**
     * Sanitize ID field in real-time
     */
    sanitizeId(input) {
        let value = input.value;
        
        // Convert to lowercase
        value = value.toLowerCase();
        
        // Replace spaces and special chars with underscore
        value = value.replace(/[^a-z0-9_]/g, '_');
        
        // Remove multiple underscores
        value = value.replace(/_+/g, '_');
        
        // Remove leading/trailing underscores
        value = value.replace(/^_+|_+$/g, '');
        
        // Limit length
        value = value.substring(0, 50);
        
        input.value = value;
        
        // Check for duplicates
        this.checkIdDuplicate(value);
    }

    /**
     * Check if ID already exists
     */
    checkIdDuplicate(id) {
        const errorElement = document.getElementById('idError');
        const input = document.getElementById('achievementId');
        
        if (!id) {
            this.showFieldError(input, 'ID gereklidir');
            return false;
        }
        
        // Skip check if editing the same achievement
        if (this.currentMode === 'edit' && id === this.currentAchievementId) {
            this.clearFieldError(input);
            return true;
        }
        
        const existing = this.achievementManager.getAchievement(id);
        if (existing) {
            this.showFieldError(input, 'Bu ID zaten kullanılıyor');
            return false;
        }
        
        this.clearFieldError(input);
        return true;
    }

    /**
     * Handle calculator type change
     */
    onCalculatorTypeChange(calculatorType) {
        const parametersContainer = document.getElementById('parametersContainer');
        const targetField = document.getElementById('achievementTarget');
        
        const calculator = this.calculatorTypes.find(c => c.id === calculatorType);
        
        if (!calculator) {
            parametersContainer.style.display = 'none';
            return;
        }
        
        // Show/hide target field
        targetField.closest('.form-group').style.display = calculator.targetRequired ? 'block' : 'none';
        
        // Show/hide parameters
        if (calculator.hasParameters) {
            this.renderParametersForm(calculator);
            parametersContainer.style.display = 'block';
        } else {
            parametersContainer.style.display = 'none';
        }
    }

    /**
     * Render parameters form based on calculator type
     */
    renderParametersForm(calculator) {
        const container = document.getElementById('parametersFields');
        const schema = calculator.parameterSchema;
        
        let html = '<h4>Parametreler</h4>';
        
        for (const [key, config] of Object.entries(schema)) {
            html += `
                <div class="form-group">
                    <label for="param_${key}">${this.formatParameterName(key)}</label>
                    ${this.renderParameterInput(key, config)}
                    <small class="parameter-help">${config.description}</small>
                </div>
            `;
        }
        
        container.innerHTML = html;
    }

    /**
     * Render parameter input based on type
     */
    renderParameterInput(key, config) {
        switch (config.type) {
            case 'array':
                return `<textarea id="param_${key}" placeholder='["item1", "item2", "item3"]' rows="3"></textarea>`;
            case 'number':
                return `<input type="number" id="param_${key}" step="0.01">`;
            case 'string':
                return `<input type="text" id="param_${key}">`;
            default:
                return `<input type="text" id="param_${key}">`;
        }
    }

    /**
     * Format parameter name for display
     */
    formatParameterName(key) {
        const names = {
            cityNames: 'Şehir İsimleri',
            districtNames: 'İlçe İsimleri',
            countryNames: 'Ülke İsimleri',
            minArea: 'Minimum Alan',
            maxArea: 'Maksimum Alan',
            minCities: 'Minimum Şehir Sayısı',
            timeWindow: 'Zaman Penceresi',
            startTime: 'Başlangıç Saati',
            endTime: 'Bitiş Saati',
            conditions: 'Koşullar',
            operator: 'Mantıksal Operatör'
        };
        return names[key] || key;
    }

    /**
     * Populate form with existing data (for edit mode)
     */
    populateForm(achievement) {
        this.currentMode = 'edit';
        this.currentAchievementId = achievement.id;
        
        // Basic fields
        document.getElementById('achievementId').value = achievement.id;
        document.getElementById('achievementTitle').value = achievement.title;
        document.getElementById('achievementDescription').value = achievement.description;
        document.getElementById('achievementCategory').value = achievement.category;
        document.getElementById('achievementRarity').value = achievement.rarity;
        document.getElementById('achievementCalculator').value = achievement.calculator;
        document.getElementById('achievementTarget').value = achievement.target;
        document.getElementById('achievementIcon').value = achievement.iconName;
        document.getElementById('achievementHidden').checked = achievement.isHidden || false;
        
        // Trigger calculator change to show parameters
        this.onCalculatorTypeChange(achievement.calculator);
        
        // Populate parameters if they exist
        if (achievement.parameters) {
            setTimeout(() => {
                this.populateParameters(achievement.parameters);
            }, 100);
        }
    }

    /**
     * Populate parameters fields
     */
    populateParameters(parameters) {
        for (const [key, value] of Object.entries(parameters)) {
            const field = document.getElementById(`param_${key}`);
            if (field) {
                if (Array.isArray(value)) {
                    field.value = JSON.stringify(value, null, 2);
                } else {
                    field.value = value;
                }
            }
        }
    }

    /**
     * Clear form for add mode
     */
    clearForm() {
        this.currentMode = 'add';
        this.currentAchievementId = null;
        
        document.getElementById('achievementForm').reset();
        document.getElementById('parametersContainer').style.display = 'none';
        
        // Clear all error states
        const errorElements = document.querySelectorAll('.field-error, .error-message');
        errorElements.forEach(el => el.remove());
        
        const inputs = document.querySelectorAll('#achievementForm input, #achievementForm select, #achievementForm textarea');
        inputs.forEach(input => {
            input.classList.remove('error');
        });
    }

    /**
     * Validate entire form
     */
    validateForm() {
        const form = document.getElementById('achievementForm');
        let isValid = true;
        
        // Clear previous errors
        this.clearAllErrors();
        
        // Validate required fields
        const requiredFields = [
            { id: 'achievementId', name: 'ID' },
            { id: 'achievementTitle', name: 'Başlık' },
            { id: 'achievementDescription', name: 'Açıklama' },
            { id: 'achievementCategory', name: 'Kategori' },
            { id: 'achievementRarity', name: 'Nadirlik' },
            { id: 'achievementCalculator', name: 'Hesaplayıcı' },
            { id: 'achievementTarget', name: 'Hedef' },
            { id: 'achievementIcon', name: 'İkon' }
        ];
        
        for (const field of requiredFields) {
            const element = document.getElementById(field.id);
            if (!element.value.trim()) {
                this.showFieldError(element, `${field.name} gereklidir`);
                isValid = false;
            }
        }
        
        // Validate ID
        const idField = document.getElementById('achievementId');
        if (idField.value && !this.checkIdDuplicate(idField.value)) {
            isValid = false;
        }
        
        // Validate target (must be positive number)
        const targetField = document.getElementById('achievementTarget');
        if (targetField.value && (isNaN(targetField.value) || parseFloat(targetField.value) <= 0)) {
            this.showFieldError(targetField, 'Hedef pozitif bir sayı olmalıdır');
            isValid = false;
        }
        
        // Validate parameters
        const calculatorType = document.getElementById('achievementCalculator').value;
        const calculator = this.calculatorTypes.find(c => c.id === calculatorType);
        
        if (calculator && calculator.hasParameters) {
            const parametersValid = this.validateParameters(calculator);
            if (!parametersValid) {
                isValid = false;
            }
        }
        
        return isValid;
    }

    /**
     * Validate parameters based on schema
     */
    validateParameters(calculator) {
        let isValid = true;
        const schema = calculator.parameterSchema;
        
        for (const [key, config] of Object.entries(schema)) {
            const field = document.getElementById(`param_${key}`);
            if (!field) continue;
            
            const value = field.value.trim();
            
            if (!value) {
                this.showFieldError(field, 'Bu parametre gereklidir');
                isValid = false;
                continue;
            }
            
            // Type-specific validation
            switch (config.type) {
                case 'array':
                    try {
                        const parsed = JSON.parse(value);
                        if (!Array.isArray(parsed)) {
                            throw new Error('Array olmalıdır');
                        }
                    } catch (e) {
                        this.showFieldError(field, 'Geçerli JSON array formatında olmalıdır');
                        isValid = false;
                    }
                    break;
                    
                case 'number':
                    if (isNaN(value) || parseFloat(value) < 0) {
                        this.showFieldError(field, 'Pozitif bir sayı olmalıdır');
                        isValid = false;
                    }
                    break;
                    
                case 'string':
                    if (key === 'timeWindow' && !['daily', 'weekly', 'monthly'].includes(value)) {
                        this.showFieldError(field, 'daily, weekly veya monthly olmalıdır');
                        isValid = false;
                    } else if ((key === 'startTime' || key === 'endTime') && !/^\d{2}:\d{2}$/.test(value)) {
                        this.showFieldError(field, 'HH:MM formatında olmalıdır');
                        isValid = false;
                    }
                    break;
            }
        }
        
        return isValid;
    }

    /**
     * Get form data as achievement object
     */
    getFormData() {
        const formData = {
            id: document.getElementById('achievementId').value.trim(),
            title: document.getElementById('achievementTitle').value.trim(),
            description: document.getElementById('achievementDescription').value.trim(),
            category: document.getElementById('achievementCategory').value,
            rarity: document.getElementById('achievementRarity').value,
            calculator: document.getElementById('achievementCalculator').value,
            target: parseFloat(document.getElementById('achievementTarget').value),
            iconName: document.getElementById('achievementIcon').value,
            isHidden: document.getElementById('achievementHidden').checked
        };
        
        // Add parameters if they exist
        const calculator = this.calculatorTypes.find(c => c.id === formData.calculator);
        if (calculator && calculator.hasParameters) {
            formData.parameters = this.getParametersData(calculator);
        }
        
        return formData;
    }

    /**
     * Get parameters data from form
     */
    getParametersData(calculator) {
        const parameters = {};
        const schema = calculator.parameterSchema;
        
        for (const [key, config] of Object.entries(schema)) {
            const field = document.getElementById(`param_${key}`);
            if (!field || !field.value.trim()) continue;
            
            let value = field.value.trim();
            
            switch (config.type) {
                case 'array':
                    try {
                        parameters[key] = JSON.parse(value);
                    } catch (e) {
                        // Validation should have caught this
                    }
                    break;
                    
                case 'number':
                    parameters[key] = parseFloat(value);
                    break;
                    
                default:
                    parameters[key] = value;
                    break;
            }
        }
        
        return parameters;
    }

    /**
     * Validate single field
     */
    validateField(field) {
        this.clearFieldError(field);
        
        if (field.hasAttribute('required') && !field.value.trim()) {
            this.showFieldError(field, 'Bu alan gereklidir');
            return false;
        }
        
        // Field-specific validation
        switch (field.id) {
            case 'achievementId':
                return this.checkIdDuplicate(field.value);
                
            case 'achievementTarget':
                if (field.value && (isNaN(field.value) || parseFloat(field.value) <= 0)) {
                    this.showFieldError(field, 'Pozitif bir sayı olmalıdır');
                    return false;
                }
                break;
        }
        
        return true;
    }

    /**
     * Show field error
     */
    showFieldError(field, message) {
        this.clearFieldError(field);
        
        field.classList.add('error');
        
        const errorElement = document.createElement('div');
        errorElement.className = 'field-error error-message';
        errorElement.textContent = message;
        
        field.parentNode.appendChild(errorElement);
    }

    /**
     * Clear field error
     */
    clearFieldError(field) {
        field.classList.remove('error');
        
        const existingError = field.parentNode.querySelector('.field-error');
        if (existingError) {
            existingError.remove();
        }
    }

    /**
     * Clear all form errors
     */
    clearAllErrors() {
        const errorElements = document.querySelectorAll('.field-error, .error-message');
        errorElements.forEach(el => el.remove());
        
        const inputs = document.querySelectorAll('#achievementForm input, #achievementForm select, #achievementForm textarea');
        inputs.forEach(input => {
            input.classList.remove('error');
        });
    }

    /**
     * Render category options
     */
    renderCategoryOptions() {
        const select = document.getElementById('achievementCategory');
        if (!select) return;
        
        select.innerHTML = '<option value="">Kategori Seçin</option>';
        
        this.categories.forEach(category => {
            const option = document.createElement('option');
            option.value = category.id;
            option.textContent = category.name;
            option.title = category.description;
            select.appendChild(option);
        });
    }

    /**
     * Render calculator type options
     */
    renderCalculatorOptions() {
        const select = document.getElementById('achievementCalculator');
        if (!select) return;
        
        select.innerHTML = '<option value="">Hesaplayıcı Seçin</option>';
        
        this.calculatorTypes.forEach(calculator => {
            const option = document.createElement('option');
            option.value = calculator.id;
            option.textContent = calculator.name;
            option.title = calculator.description;
            select.appendChild(option);
        });
    }

    /**
     * Render icon options with search and categories
     */
    renderIconSelector() {
        const container = document.getElementById('iconSelectorContainer');
        if (!container) return;
        
        const categories = [...new Set(this.sfSymbols.map(icon => icon.category))];
        
        let html = `
            <div class="icon-selector">
                <div class="icon-search">
                    <input type="text" id="iconSearch" placeholder="İkon ara...">
                </div>
                <div class="icon-categories">
                    <button type="button" class="icon-category-btn active" data-category="all">Tümü</button>
                    ${categories.map(cat => 
                        `<button type="button" class="icon-category-btn" data-category="${cat}">${cat}</button>`
                    ).join('')}
                </div>
                <div class="icon-grid" id="iconGrid">
                    ${this.renderIconGrid()}
                </div>
            </div>
        `;
        
        container.innerHTML = html;
        
        // Bind icon selector events
        this.bindIconSelectorEvents();
    }

    /**
     * Render icon grid
     */
    renderIconGrid(filter = '') {
        let icons = this.sfSymbols;
        
        if (filter && filter !== 'all') {
            icons = icons.filter(icon => 
                icon.category === filter || 
                icon.name.toLowerCase().includes(filter.toLowerCase()) ||
                icon.symbol.toLowerCase().includes(filter.toLowerCase())
            );
        }
        
        return icons.map(icon => `
            <div class="icon-option" data-symbol="${icon.symbol}" title="${icon.name}">
                <span class="icon-emoji">${icon.emoji}</span>
                <span class="icon-name">${icon.name}</span>
            </div>
        `).join('');
    }

    /**
     * Bind icon selector events
     */
    bindIconSelectorEvents() {
        // Icon search
        const searchInput = document.getElementById('iconSearch');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                const iconGrid = document.getElementById('iconGrid');
                iconGrid.innerHTML = this.renderIconGrid(e.target.value);
            });
        }
        
        // Category filter
        const categoryBtns = document.querySelectorAll('.icon-category-btn');
        categoryBtns.forEach(btn => {
            btn.addEventListener('click', (e) => {
                categoryBtns.forEach(b => b.classList.remove('active'));
                e.target.classList.add('active');
                
                const category = e.target.dataset.category;
                const iconGrid = document.getElementById('iconGrid');
                iconGrid.innerHTML = this.renderIconGrid(category === 'all' ? '' : category);
            });
        });
        
        // Icon selection
        document.addEventListener('click', (e) => {
            if (e.target.closest('.icon-option')) {
                const iconOption = e.target.closest('.icon-option');
                const symbol = iconOption.dataset.symbol;
                
                // Update hidden input
                document.getElementById('achievementIcon').value = symbol;
                
                // Update visual feedback
                document.querySelectorAll('.icon-option').forEach(opt => opt.classList.remove('selected'));
                iconOption.classList.add('selected');
                
                // Update preview if exists
                const preview = document.getElementById('iconPreview');
                if (preview) {
                    const iconData = this.sfSymbols.find(icon => icon.symbol === symbol);
                    preview.innerHTML = `${iconData.emoji} ${iconData.name}`;
                }
            }
        });
    }

    /**
     * Initialize form UI components
     */
    initializeFormUI() {
        this.renderCategoryOptions();
        this.renderCalculatorOptions();
        this.renderIconSelector();
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AchievementFormController;
} 