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
     * Setup SF Symbols for iOS - Comprehensive List for Achievements
     */
    setupSFSymbols() {
        this.sfSymbols = [
            // Hareket & Aktivite
            { symbol: 'figure.walk', emoji: '🚶', category: 'Hareket', name: 'Yürüyüş' },
            { symbol: 'figure.run', emoji: '🏃', category: 'Hareket', name: 'Koşu' },
            { symbol: 'figure.hiking', emoji: '🥾', category: 'Hareket', name: 'Yürüyüş' },
            { symbol: 'figure.cycling', emoji: '🚴', category: 'Hareket', name: 'Bisiklet' },
            { symbol: 'bicycle', emoji: '🚲', category: 'Hareket', name: 'Bisiklet' },
            { symbol: 'car.fill', emoji: '🚗', category: 'Hareket', name: 'Araba' },
            { symbol: 'bus.fill', emoji: '🚌', category: 'Hareket', name: 'Otobüs' },
            { symbol: 'tram.fill', emoji: '🚊', category: 'Hareket', name: 'Tramvay' },
            { symbol: 'train.side.front.car', emoji: '🚂', category: 'Hareket', name: 'Tren' },
            { symbol: 'airplane', emoji: '✈️', category: 'Hareket', name: 'Uçak' },
            { symbol: 'airplane.departure', emoji: '✈️', category: 'Hareket', name: 'Kalkış' },
            { symbol: 'airplane.arrival', emoji: '🛬', category: 'Hareket', name: 'İniş' },
            { symbol: 'ferry.fill', emoji: '⛴️', category: 'Hareket', name: 'Feribot' },
            { symbol: 'sailboat.fill', emoji: '⛵', category: 'Hareket', name: 'Yelkenli' },
            
            // Lokasyon & Yerler  
            { symbol: 'location.fill', emoji: '📍', category: 'Lokasyon', name: 'Konum' },
            { symbol: 'mappin', emoji: '📌', category: 'Lokasyon', name: 'İğne' },
            { symbol: 'mappin.and.ellipse', emoji: '📍', category: 'Lokasyon', name: 'Konum Daire' },
            { symbol: 'mappin.circle.fill', emoji: '📍', category: 'Lokasyon', name: 'Konum Daire' },
            { symbol: 'pin.fill', emoji: '📌', category: 'Lokasyon', name: 'Pin' },
            { symbol: 'signpost.left.fill', emoji: '🪧', category: 'Lokasyon', name: 'Tabela Sol' },
            { symbol: 'signpost.right.fill', emoji: '🪧', category: 'Lokasyon', name: 'Tabela Sağ' },
            
            // Yapılar & Binalar
            { symbol: 'house.fill', emoji: '🏠', category: 'Yapılar', name: 'Ev' },
            { symbol: 'building.fill', emoji: '🏢', category: 'Yapılar', name: 'Bina' },
            { symbol: 'building.2.fill', emoji: '🏢', category: 'Yapılar', name: 'İkiz Bina' },
            { symbol: 'building.columns.fill', emoji: '🏛️', category: 'Yapılar', name: 'Köşk/Müze' },
            { symbol: 'house.and.flag.fill', emoji: '🏛️', category: 'Yapılar', name: 'Resmi Bina' },
            { symbol: 'hospital.fill', emoji: '🏥', category: 'Yapılar', name: 'Hastane' },
            { symbol: 'cross.case.fill', emoji: '🏥', category: 'Yapılar', name: 'Tıp Merkezi' },
            { symbol: 'graduationcap.fill', emoji: '🎓', category: 'Yapılar', name: 'Üniversite' },
            { symbol: 'book.closed.fill', emoji: '📚', category: 'Yapılar', name: 'Kütüphane' },
            { symbol: 'storefront.fill', emoji: '🏪', category: 'Yapılar', name: 'Mağaza' },
            { symbol: 'cart.fill', emoji: '🛒', category: 'Yapılar', name: 'Market' },
            { symbol: 'fuelpump.fill', emoji: '⛽', category: 'Yapılar', name: 'Benzin İstasyonu' },
            { symbol: 'fork.knife', emoji: '🍽️', category: 'Yapılar', name: 'Restoran' },
            { symbol: 'cup.and.saucer.fill', emoji: '☕', category: 'Yapılar', name: 'Kafe' },
            
            // Harita & Coğrafya
            { symbol: 'map.fill', emoji: '🗺️', category: 'Harita', name: 'Harita' },
            { symbol: 'map.circle.fill', emoji: '🗺️', category: 'Harita', name: 'Harita Daire' },
            { symbol: 'globe', emoji: '🌍', category: 'Harita', name: 'Dünya' },
            { symbol: 'globe.europe.africa.fill', emoji: '🌍', category: 'Harita', name: 'Avrupa/Afrika' },
            { symbol: 'globe.americas.fill', emoji: '🌎', category: 'Harita', name: 'Amerika' },
            { symbol: 'globe.central.south.asia.fill', emoji: '🌏', category: 'Harita', name: 'Asya' },
            { symbol: 'compass.drawing', emoji: '🧭', category: 'Harita', name: 'Pusula' },
            { symbol: 'location.north.fill', emoji: '🧭', category: 'Harita', name: 'Kuzey' },
            { symbol: 'scope', emoji: '🔍', category: 'Harita', name: 'Büyüteç' },
            
            // Doğa & Çevre
            { symbol: 'mountain.2.fill', emoji: '⛰️', category: 'Doğa', name: 'Dağlar' },
            { symbol: 'tree.fill', emoji: '🌳', category: 'Doğa', name: 'Ağaç' },
            { symbol: 'leaf.fill', emoji: '🍃', category: 'Doğa', name: 'Yaprak' },
            { symbol: 'snowflake', emoji: '❄️', category: 'Doğa', name: 'Kar Tanesi' },
            { symbol: 'sun.max.fill', emoji: '☀️', category: 'Doğa', name: 'Güneş' },
            { symbol: 'moon.fill', emoji: '🌙', category: 'Doğa', name: 'Ay' },
            { symbol: 'star.fill', emoji: '⭐', category: 'Doğa', name: 'Yıldız' },
            { symbol: 'cloud.fill', emoji: '☁️', category: 'Doğa', name: 'Bulut' },
            { symbol: 'drop.fill', emoji: '💧', category: 'Doğa', name: 'Damla' },
            { symbol: 'flame.fill', emoji: '🔥', category: 'Doğa', name: 'Ateş' },
            
            // Zaman & Takvim
            { symbol: 'clock.fill', emoji: '🕐', category: 'Zaman', name: 'Saat' },
            { symbol: 'timer', emoji: '⏲️', category: 'Zaman', name: 'Kronometrek' },
            { symbol: 'stopwatch.fill', emoji: '⏱️', category: 'Zaman', name: 'Kronometre' },
            { symbol: 'calendar', emoji: '📅', category: 'Zaman', name: 'Takvim' },
            { symbol: 'calendar.badge.checkmark', emoji: '📅', category: 'Zaman', name: 'Takvim Tik' },
            { symbol: 'hourglass', emoji: '⏳', category: 'Zaman', name: 'Kum Saati' },
            { symbol: 'alarm.fill', emoji: '⏰', category: 'Zaman', name: 'Alarm' },
            
            // Keşif & Macera
            { symbol: 'binoculars.fill', emoji: '🔭', category: 'Keşif', name: 'Dürbün' },
            { symbol: 'backpack.fill', emoji: '🎒', category: 'Keşif', name: 'Sırt Çantası' },
            { symbol: 'camera.fill', emoji: '📷', category: 'Keşif', name: 'Kamera' },
            { symbol: 'photo.fill', emoji: '🖼️', category: 'Keşif', name: 'Fotoğraf' },
            { symbol: 'eye.fill', emoji: '👁️', category: 'Keşif', name: 'Göz' },
            { symbol: 'magnifyingglass', emoji: '🔍', category: 'Keşif', name: 'Arama' },
            { symbol: 'flashlight.on.fill', emoji: '🔦', category: 'Keşif', name: 'El Feneri' },
            { symbol: 'tent.fill', emoji: '⛺', category: 'Keşif', name: 'Çadır' },
            
            // Ödüller & Başarımlar
            { symbol: 'trophy.fill', emoji: '🏆', category: 'Ödül', name: 'Kupa' },
            { symbol: 'medal.fill', emoji: '🏅', category: 'Ödül', name: 'Madalya' },
            { symbol: 'rosette', emoji: '🏵️', category: 'Ödül', name: 'Rozet' },
            { symbol: 'crown.fill', emoji: '👑', category: 'Ödül', name: 'Taç' },
            { symbol: 'gem.fill', emoji: '💎', category: 'Ödül', name: 'Elmas' },
            { symbol: 'sparkles', emoji: '✨', category: 'Ödül', name: 'Parıltı' },
            { symbol: 'target', emoji: '🎯', category: 'Ödül', name: 'Hedef' },
            { symbol: 'flag.fill', emoji: '🚩', category: 'Ödül', name: 'Bayrak' },
            { symbol: 'flag.checkered', emoji: '🏁', category: 'Ödül', name: 'Finiş' },
            { symbol: 'checkmark.seal.fill', emoji: '✅', category: 'Ödül', name: 'Onay Mührü' },
            
            // Sayılar & İstatistik
            { symbol: 'chart.bar.fill', emoji: '📊', category: 'İstatistik', name: 'Bar Grafik' },
            { symbol: 'chart.pie.fill', emoji: '📈', category: 'İstatistik', name: 'Pasta Grafik' },
            { symbol: 'chart.line.uptrend.xyaxis', emoji: '📈', category: 'İstatistik', name: 'Yükseliş' },
            { symbol: 'percent', emoji: '%', category: 'İstatistik', name: 'Yüzde' },
            { symbol: 'number', emoji: '#', category: 'İstatistik', name: 'Sayı' },
            { symbol: 'plus.circle.fill', emoji: '➕', category: 'İstatistik', name: 'Artı' },
            { symbol: 'minus.circle.fill', emoji: '➖', category: 'İstatistik', name: 'Eksi' },
            { symbol: 'multiply.circle.fill', emoji: '✖️', category: 'İstatistik', name: 'Çarpı' },
            { symbol: 'speedometer', emoji: '⚡', category: 'İstatistik', name: 'Hız' },
            
            // Grid & Alan
            { symbol: 'square.grid.3x3.fill', emoji: '⊞', category: 'Grid', name: '3x3 Grid' },
            { symbol: 'square.grid.4x3.fill', emoji: '⊟', category: 'Grid', name: '4x3 Grid' },
            { symbol: 'grid', emoji: '▦', category: 'Grid', name: 'Grid' },
            { symbol: 'rectangle.grid.1x2.fill', emoji: '▬', category: 'Grid', name: '1x2 Grid' },
            { symbol: 'rectangle.grid.2x2.fill', emoji: '▦', category: 'Grid', name: '2x2 Grid' },
            { symbol: 'square.fill', emoji: '⬛', category: 'Grid', name: 'Kare' },
            { symbol: 'circle.fill', emoji: '⚫', category: 'Grid', name: 'Daire' },
            { symbol: 'triangle.fill', emoji: '🔺', category: 'Grid', name: 'Üçgen' },
            
            // Sosyal & İnsan
            { symbol: 'person.fill', emoji: '👤', category: 'Sosyal', name: 'Kişi' },
            { symbol: 'person.2.fill', emoji: '👥', category: 'Sosyal', name: 'İki Kişi' },
            { symbol: 'person.3.fill', emoji: '👨‍👩‍👧', category: 'Sosyal', name: 'Grup' },
            { symbol: 'heart.fill', emoji: '❤️', category: 'Sosyal', name: 'Kalp' },
            { symbol: 'hand.thumbsup.fill', emoji: '👍', category: 'Sosyal', name: 'Beğeni' },
            { symbol: 'hands.clap.fill', emoji: '👏', category: 'Sosyal', name: 'Alkış' },
            { symbol: 'face.smiling.fill', emoji: '😊', category: 'Sosyal', name: 'Gülümseme' },
            
            // Teknoloji & Araçlar
            { symbol: 'iphone', emoji: '📱', category: 'Teknoloji', name: 'Telefon' },
            { symbol: 'laptopcomputer', emoji: '💻', category: 'Teknoloji', name: 'Laptop' },
            { symbol: 'wifi', emoji: '📶', category: 'Teknoloji', name: 'WiFi' },
            { symbol: 'antenna.radiowaves.left.and.right', emoji: '📡', category: 'Teknoloji', name: 'Sinyal' },
            { symbol: 'qrcode', emoji: '▦', category: 'Teknoloji', name: 'QR Kod' },
            { symbol: 'link', emoji: '🔗', category: 'Teknoloji', name: 'Bağlantı' }
        ];
    }

    /**
     * Bind form events
     */
    bindFormEvents() {
        // ID field auto-sanitization
        document.addEventListener('input', (e) => {
            if (e.target.id === 'achievement-id') {
                this.sanitizeId(e.target);
            }
        });

        // Calculator type change
        document.addEventListener('change', (e) => {
            if (e.target.id === 'achievement-calculator') {
                this.onCalculatorTypeChange(e.target.value);
            }
        });

        // Real-time validation
        document.addEventListener('blur', (e) => {
            if (e.target.form && e.target.form.id === 'achievement-form') {
                this.validateField(e.target);
            }
        });

        // Icon picker button
        document.addEventListener('click', (e) => {
            if (e.target.id === 'icon-picker-btn') {
                this.toggleIconPicker();
            }
            
            // Icon selection
            if (e.target.closest('.icon-option')) {
                const iconOption = e.target.closest('.icon-option');
                const iconSymbol = iconOption.dataset.symbol;
                this.selectIcon(iconSymbol);
            }
        });

        // Close icon picker when clicking outside
        document.addEventListener('click', (e) => {
            const iconPicker = document.getElementById('icon-picker-modal');
            const iconBtn = document.getElementById('icon-picker-btn');
            
            if (iconPicker && iconPicker.style.display !== 'none' && 
                !iconPicker.contains(e.target) && e.target !== iconBtn) {
                this.hideIconPicker();
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
        
        // Allow letters, numbers and underscore, replace other chars with underscore
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
        const input = document.getElementById('achievement-id');
        
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
        const targetField = document.getElementById('achievement-target');
        
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
     * Validate entire form
     */
    validateForm() {
        let isValid = true;
        
        // Clear previous errors
        this.clearAllErrors();
        
        // Validate required fields
        const requiredFields = [
            { id: 'achievement-id', name: 'ID' },
            { id: 'achievement-title', name: 'Başlık' },
            { id: 'achievement-description', name: 'Açıklama' },
            { id: 'achievement-category', name: 'Kategori' },
            { id: 'achievement-rarity', name: 'Nadirlik' },
            { id: 'achievement-calculator', name: 'Hesaplayıcı' },
            { id: 'achievement-target', name: 'Hedef' },
            { id: 'achievement-icon', name: 'İkon' }
        ];
        
        for (const field of requiredFields) {
            const element = document.getElementById(field.id);
            if (!element.value.trim()) {
                this.showFieldError(element, `${field.name} gereklidir`);
                isValid = false;
            }
        }
        
        // Validate ID
        const idField = document.getElementById('achievement-id');
        if (idField.value && !this.checkIdDuplicate(idField.value)) {
            isValid = false;
        }
        
        // Validate target (must be positive number)
        const targetField = document.getElementById('achievement-target');
        if (targetField.value && (isNaN(targetField.value) || parseFloat(targetField.value) <= 0)) {
            this.showFieldError(targetField, 'Hedef pozitif bir sayı olmalıdır');
            isValid = false;
        }
        
        // Validate parameters
        const calculatorType = document.getElementById('achievement-calculator').value;
        const calculator = this.calculatorTypes.find(c => c.id === calculatorType);
        
        if (calculator && calculator.hasParameters) {
            const parametersValid = this.validateParameters(calculator);
            if (!parametersValid) {
                isValid = false;
            }
        }
        
        // Validate manual JSON parameters
        const manualParams = document.getElementById('achievement-params');
        if (manualParams && manualParams.value.trim()) {
            try {
                JSON.parse(manualParams.value.trim());
                this.clearFieldError(manualParams);
            } catch (e) {
                this.showFieldError(manualParams, 'Geçerli JSON formatında olmalıdır');
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
            id: document.getElementById('achievement-id').value.trim(),
            title: document.getElementById('achievement-title').value.trim(),
            description: document.getElementById('achievement-description').value.trim(),
            category: document.getElementById('achievement-category').value,
            rarity: document.getElementById('achievement-rarity').value,
            calculator: document.getElementById('achievement-calculator').value,
            target: parseFloat(document.getElementById('achievement-target').value),
            icon: document.getElementById('achievement-icon').value,
            isHidden: document.getElementById('achievement-hidden').checked
        };
        
        // Add parameters if they exist
        const calculator = this.calculatorTypes.find(c => c.id === formData.calculator);
        if (calculator && calculator.hasParameters) {
            formData.parameters = this.getParametersData(calculator);
        }
        
        // Also check for manual JSON parameters
        const manualParams = document.getElementById('achievement-params');
        if (manualParams && manualParams.value.trim()) {
            try {
                const manualParamsData = JSON.parse(manualParams.value.trim());
                // Merge with existing parameters or use as fallback
                formData.parameters = formData.parameters ? 
                    { ...formData.parameters, ...manualParamsData } : 
                    manualParamsData;
            } catch (e) {
                // Invalid JSON, but don't fail - validation should catch this
                console.warn('Invalid JSON in manual parameters field');
            }
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
            case 'achievement-id':
                return this.checkIdDuplicate(field.value);
                
            case 'achievement-target':
                if (field.value && (isNaN(field.value) || parseFloat(field.value) <= 0)) {
                    this.showFieldError(field, 'Pozitif bir sayı olmalıdır');
                    return false;
                }
                break;
                
            case 'achievement-params':
                if (field.value.trim()) {
                    try {
                        JSON.parse(field.value.trim());
                    } catch (e) {
                        this.showFieldError(field, 'Geçerli JSON formatında olmalıdır');
                        return false;
                    }
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
        
        const inputs = document.querySelectorAll('#achievement-form input, #achievement-form select, #achievement-form textarea');
        inputs.forEach(input => {
            input.classList.remove('error');
        });
    }

    /**
     * Clear form for add mode
     */
    clearForm() {
        this.currentMode = 'add';
        this.currentAchievementId = null;
        
        document.getElementById('achievement-form').reset();
        const parametersContainer = document.getElementById('parametersContainer');
        if (parametersContainer) parametersContainer.style.display = 'none';
        
        // Clear manual JSON parameters
        const manualParams = document.getElementById('achievement-params');
        if (manualParams) manualParams.value = '';
        
        this.clearAllErrors();
    }

    /**
     * Copy achievement data for creating variations
     */
    copyForNewAchievement(achievement) {
        this.currentMode = 'copy';
        this.currentAchievementId = null;
        
        // Generate new ID based on original
        const baseId = achievement.id;
        let newId = `${baseId}_copy`;
        let counter = 1;
        
        // Find unique ID
        while (this.achievementManager.getAchievement(newId)) {
            newId = `${baseId}_copy_${counter}`;
            counter++;
        }
        
        // Populate form with copied data but new ID
        document.getElementById('achievement-id').value = newId;
        document.getElementById('achievement-title').value = `${achievement.title} (Kopya)`;
        document.getElementById('achievement-description').value = achievement.description;
        document.getElementById('achievement-category').value = achievement.category;
        document.getElementById('achievement-rarity').value = achievement.rarity;
        document.getElementById('achievement-calculator').value = achievement.calculator;
        document.getElementById('achievement-target').value = achievement.target;
        document.getElementById('achievement-icon').value = achievement.icon || achievement.iconName;
        document.getElementById('achievement-hidden').checked = achievement.isHidden || false;
        
        // Trigger calculator change to show parameters
        this.onCalculatorTypeChange(achievement.calculator);
        
        // Populate parameters if they exist
        if (achievement.parameters) {
            setTimeout(() => {
                this.populateParameters(achievement.parameters);
                // Also populate manual JSON field
                const manualParams = document.getElementById('achievement-params');
                if (manualParams) {
                    manualParams.value = JSON.stringify(achievement.parameters, null, 2);
                }
            }, 100);
        }
        
        // Clear any existing errors
        this.clearAllErrors();
        
        // Focus on title field for quick editing
        setTimeout(() => {
            document.getElementById('achievement-title').focus();
            document.getElementById('achievement-title').select();
        }, 150);
    }

    /**
     * Populate form with existing data (for edit mode)
     */
    populateForm(achievement) {
        this.currentMode = 'edit';
        this.currentAchievementId = achievement.id;
        
        // Basic fields
        document.getElementById('achievement-id').value = achievement.id;
        document.getElementById('achievement-title').value = achievement.title;
        document.getElementById('achievement-description').value = achievement.description;
        document.getElementById('achievement-category').value = achievement.category;
        document.getElementById('achievement-rarity').value = achievement.rarity;
        document.getElementById('achievement-calculator').value = achievement.calculator;
        document.getElementById('achievement-target').value = achievement.target;
        document.getElementById('achievement-icon').value = achievement.icon || achievement.iconName;
        document.getElementById('achievement-hidden').checked = achievement.isHidden || false;
        
        // Trigger calculator change to show parameters
        this.onCalculatorTypeChange(achievement.calculator);
        
        // Populate parameters if they exist
        if (achievement.parameters) {
            setTimeout(() => {
                this.populateParameters(achievement.parameters);
                // Also populate manual JSON field as backup
                const manualParams = document.getElementById('achievement-params');
                if (manualParams) {
                    manualParams.value = JSON.stringify(achievement.parameters, null, 2);
                }
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
     * Initialize form UI components
     */
    initializeFormUI() {
        this.renderCategoryOptions();
        this.renderCalculatorOptions();
        this.renderIconPicker();
    }

    /**
     * Render icon picker modal
     */
    renderIconPicker() {
        const iconPicker = document.getElementById('icon-picker-modal');
        if (!iconPicker) return;

        // Group SF Symbols by category
        const categorizedIcons = this.sfSymbols.reduce((acc, symbol) => {
            if (!acc[symbol.category]) {
                acc[symbol.category] = [];
            }
            acc[symbol.category].push(symbol);
            return acc;
        }, {});

        let html = '';
        for (const [category, icons] of Object.entries(categorizedIcons)) {
            html += `
                <div class="icon-category">
                    <div class="icon-category-title">${category}</div>
                    <div class="icon-category-grid">
                        ${icons.map(icon => `
                            <div class="icon-option" data-symbol="${icon.symbol}" title="${icon.name}">
                                <span class="sf-icon">${icon.emoji}</span>
                                <span class="icon-name">${icon.symbol.split('.')[0]}</span>
                            </div>
                        `).join('')}
                    </div>
                </div>
            `;
        }

        iconPicker.innerHTML = html;
    }

    /**
     * Toggle icon picker visibility
     */
    toggleIconPicker() {
        const iconPicker = document.getElementById('icon-picker-modal');
        if (iconPicker.style.display === 'none' || !iconPicker.style.display) {
            this.showIconPicker();
        } else {
            this.hideIconPicker();
        }
    }

    /**
     * Show icon picker
     */
    showIconPicker() {
        const iconPicker = document.getElementById('icon-picker-modal');
        iconPicker.style.display = 'block';
        
        // Highlight currently selected icon
        const currentIcon = document.getElementById('achievement-icon').value;
        const iconOptions = iconPicker.querySelectorAll('.icon-option');
        iconOptions.forEach(option => {
            option.classList.toggle('selected', option.dataset.symbol === currentIcon);
        });
    }

    /**
     * Hide icon picker
     */
    hideIconPicker() {
        const iconPicker = document.getElementById('icon-picker-modal');
        iconPicker.style.display = 'none';
    }

    /**
     * Select an icon
     */
    selectIcon(iconSymbol) {
        const iconInput = document.getElementById('achievement-icon');
        iconInput.value = iconSymbol;
        
        // Update icon display in input (could add preview here)
        this.hideIconPicker();
        
        // Trigger validation
        this.validateField(iconInput);
    }

    /**
     * Render category options
     */
    renderCategoryOptions() {
        const select = document.getElementById('achievement-category');
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
        const select = document.getElementById('achievement-calculator');
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
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AchievementFormController;
} 