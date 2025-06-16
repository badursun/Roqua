import Foundation
import CoreLocation
import Combine

// MARK: - Achievement Models

enum AchievementType: String, CaseIterable, Codable {
    case geographic = "geographic"
    case exploration = "exploration"
    case temporal = "temporal"
    case milestone = "milestone"
}

enum AchievementCategory: String, CaseIterable, Codable {
    case cityMaster = "city_master"
    case districtExplorer = "district_explorer"
    case countryCollector = "country_collector"
    case areaExplorer = "area_explorer"
    case distanceWalker = "distance_walker"
    case gridMaster = "grid_master"
    case percentageMilestone = "percentage_milestone"
    case dailyExplorer = "daily_explorer"
    case weekendWarrior = "weekend_warrior"
    case monthlyChallenger = "monthly_challenger"
    case firstSteps = "first_steps"
    case explorer = "explorer"
    case adventurer = "adventurer"
    case worldTraveler = "world_traveler"
}

struct Achievement: Identifiable, Codable {
    let id: String
    let category: AchievementCategory
    let type: AchievementType
    let title: String
    let description: String
    let iconName: String
    let target: Int
    let isHidden: Bool // Gizli achievement'lar
    let rarity: AchievementRarity
    
    enum AchievementRarity: String, Codable {
        case common = "common"
        case rare = "rare"
        case epic = "epic"
        case legendary = "legendary"
    }
}

struct AchievementProgress: Identifiable, Codable {
    let id: String
    let achievementId: String
    var currentProgress: Int
    let targetProgress: Int
    var isUnlocked: Bool
    var unlockedAt: Date?
    var lastUpdated: Date
    
    var progressPercentage: Double {
        guard targetProgress > 0 else { return 0 }
        return min(Double(currentProgress) / Double(targetProgress), 1.0) * 100
    }
    
    var isCompleted: Bool {
        return currentProgress >= targetProgress
    }
}

struct UserInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let description: String
    let value: String
    let iconName: String
    let priority: Int
    
    enum InsightType {
        case geographic, temporal, comparison, milestone
    }
}

// MARK: - Achievement Manager

@MainActor
class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    
    @Published var achievements: [Achievement] = []
    @Published var userProgress: [AchievementProgress] = []
    @Published var recentUnlocks: [AchievementProgress] = []
    @Published var insights: [UserInsight] = []
    @Published var totalUnlockedCount: Int = 0
    
    private let visitedRegionManager = VisitedRegionManager.shared
    private let settings = AppSettings.shared
    private let eventBus = EventBus.shared
    private var cancellables = Set<AnyCancellable>()
    private var needsSave = false
    private var saveTimer: Timer?
    
    private init() {
        setupAchievements()
        loadUserProgress()
        setupEventListeners()
        calculateAllProgress()
        generateInsights()
    }
    
    // MARK: - Setup
    
    private func setupAchievements() {
        achievements = [
            // Geographic Achievements
            Achievement(
                id: "istanbul_master",
                category: .cityMaster,
                type: .geographic,
                title: "İstanbul Ustası",
                description: "İstanbul'da 50+ bölge keşfet",
                iconName: "building.2.fill",
                target: 50,
                isHidden: false,
                rarity: .rare
            ),
            
            Achievement(
                id: "ankara_master",
                category: .cityMaster,
                type: .geographic,
                title: "Ankara Uzmanı",
                description: "Ankara'da 30+ bölge keşfet",
                iconName: "building.columns.fill",
                target: 30,
                isHidden: false,
                rarity: .rare
            ),
            
            Achievement(
                id: "district_explorer_10",
                category: .districtExplorer,
                type: .geographic,
                title: "İlçe Kaşifi",
                description: "10+ farklı ilçe keşfet",
                iconName: "map.fill",
                target: 10,
                isHidden: false,
                rarity: .common
            ),
            
            Achievement(
                id: "district_explorer_25",
                category: .districtExplorer,
                type: .geographic,
                title: "İlçe Uzmanı",
                description: "25+ farklı ilçe keşfet",
                iconName: "map.circle.fill",
                target: 25,
                isHidden: false,
                rarity: .rare
            ),
            
            Achievement(
                id: "country_collector_5",
                category: .countryCollector,
                type: .geographic,
                title: "Dünya Gezgini",
                description: "5+ ülke ziyaret et",
                iconName: "globe.europe.africa.fill",
                target: 5,
                isHidden: false,
                rarity: .epic
            ),
            
            Achievement(
                id: "country_collector_10",
                category: .countryCollector,
                type: .geographic,
                title: "Kıta Aşan",
                description: "10+ ülke ziyaret et",
                iconName: "globe.americas.fill",
                target: 10,
                isHidden: false,
                rarity: .legendary
            ),
            
            // Exploration Achievements
            Achievement(
                id: "area_explorer_1km",
                category: .areaExplorer,
                type: .exploration,
                title: "Alan Kaşifi",
                description: "1 km² alan keşfet",
                iconName: "square.grid.3x3.fill",
                target: 1000000, // 1 km² in m²
                isHidden: false,
                rarity: .common
            ),
            
            Achievement(
                id: "area_explorer_10km",
                category: .areaExplorer,
                type: .exploration,
                title: "Alan Ustası",
                description: "10 km² alan keşfet",
                iconName: "square.grid.4x3.fill",
                target: 10000000, // 10 km² in m²
                isHidden: false,
                rarity: .rare
            ),
            
            Achievement(
                id: "percentage_001",
                category: .percentageMilestone,
                type: .exploration,
                title: "Dünya'nın Binde Biri",
                description: "Dünya'nın %0.001'ini keşfet",
                iconName: "percent",
                target: 1, // 0.001% * 1000 for easier calculation
                isHidden: false,
                rarity: .epic
            ),
            
            Achievement(
                id: "percentage_01",
                category: .percentageMilestone,
                type: .exploration,
                title: "Dünya'nın Yüzde Biri",
                description: "Dünya'nın %0.01'ini keşfet",
                iconName: "globe.central.south.asia.fill",
                target: 10, // 0.01% * 1000
                isHidden: false,
                rarity: .legendary
            ),
            
            // Milestone Achievements
            Achievement(
                id: "first_steps",
                category: .firstSteps,
                type: .milestone,
                title: "İlk Adımlar",
                description: "İlk 10 bölgeyi keşfet",
                iconName: "figure.walk",
                target: 10,
                isHidden: false,
                rarity: .common
            ),
            
            Achievement(
                id: "explorer_100",
                category: .explorer,
                type: .milestone,
                title: "Kaşif",
                description: "100 bölge keşfet",
                iconName: "binoculars.fill",
                target: 100,
                isHidden: false,
                rarity: .common
            ),
            
            Achievement(
                id: "adventurer_1000",
                category: .adventurer,
                type: .milestone,
                title: "Maceracı",
                description: "1000 bölge keşfet",
                iconName: "backpack.fill",
                target: 1000,
                isHidden: false,
                rarity: .rare
            ),
            
            Achievement(
                id: "world_traveler_10000",
                category: .worldTraveler,
                type: .milestone,
                title: "Dünya Gezgini",
                description: "10000 bölge keşfet",
                iconName: "airplane.departure",
                target: 10000,
                isHidden: false,
                rarity: .legendary
            ),
            
            // Temporal Achievements
            Achievement(
                id: "daily_explorer_7",
                category: .dailyExplorer,
                type: .temporal,
                title: "Günlük Kaşif",
                description: "7 gün üst üste keşif yap",
                iconName: "calendar.badge.checkmark",
                target: 7,
                isHidden: false,
                rarity: .rare
            ),
            
            Achievement(
                id: "weekend_warrior",
                category: .weekendWarrior,
                type: .temporal,
                title: "Hafta Sonu Savaşçısı",
                description: "4 hafta sonu üst üste keşif yap",
                iconName: "sun.max.fill",
                target: 4,
                isHidden: false,
                rarity: .rare
            )
        ]
    }
    
    private func setupEventListeners() {
        // Listen to achievement events
        eventBus.achievementEvents
            .sink { [weak self] event in
                self?.handleAchievementEvent(event)
            }
            .store(in: &cancellables)
        
        // Listen to location events for specific achievements
        eventBus.locationEvents
            .sink { [weak self] event in
                self?.handleLocationEvent(event)
            }
            .store(in: &cancellables)
        
        print("🎯 Achievement event listeners setup completed")
    }
    
    // MARK: - Progress Calculation
    
    func calculateAllProgress() {
        let regions = visitedRegionManager.visitedRegions
        
        for achievement in achievements {
            let progress = calculateProgress(for: achievement, with: regions)
            updateProgress(progress)
        }
        
        updateTotalUnlockedCount()
    }
    
    private func calculateProgress(for achievement: Achievement, with regions: [VisitedRegion]) -> AchievementProgress {
        let currentProgress: Int
        
        switch achievement.category {
        case .cityMaster:
            currentProgress = calculateCityMasterProgress(achievement: achievement, regions: regions)
        case .districtExplorer:
            currentProgress = calculateDistrictExplorerProgress(regions: regions)
        case .countryCollector:
            currentProgress = calculateCountryCollectorProgress(regions: regions)
        case .areaExplorer:
            currentProgress = calculateAreaExplorerProgress(regions: regions)
        case .percentageMilestone:
            currentProgress = calculatePercentageMilestoneProgress()
        case .firstSteps, .explorer, .adventurer, .worldTraveler:
            currentProgress = regions.count
        case .dailyExplorer:
            currentProgress = calculateDailyStreakProgress(regions: regions)
        case .weekendWarrior:
            currentProgress = calculateWeekendWarriorProgress(regions: regions)
        default:
            currentProgress = 0
        }
        
        let existingProgress = userProgress.first { $0.achievementId == achievement.id }
        let isUnlocked = currentProgress >= achievement.target
        
        return AchievementProgress(
            id: existingProgress?.id ?? UUID().uuidString,
            achievementId: achievement.id,
            currentProgress: currentProgress,
            targetProgress: achievement.target,
            isUnlocked: isUnlocked,
            unlockedAt: isUnlocked && existingProgress?.isUnlocked == false ? Date() : existingProgress?.unlockedAt,
            lastUpdated: Date()
        )
    }
    
    // MARK: - Specific Progress Calculations
    
    private func calculateCityMasterProgress(achievement: Achievement, regions: [VisitedRegion]) -> Int {
        let cityName: String
        
        switch achievement.id {
        case "istanbul_master":
            cityName = "İstanbul"
        case "ankara_master":
            cityName = "Ankara"
        default:
            return 0
        }
        
        return regions.filter { $0.city?.contains(cityName) == true }.count
    }
    
    private func calculateDistrictExplorerProgress(regions: [VisitedRegion]) -> Int {
        let uniqueDistricts = Set(regions.compactMap { $0.district })
        return uniqueDistricts.count
    }
    
    private func calculateCountryCollectorProgress(regions: [VisitedRegion]) -> Int {
        let uniqueCountries = Set(regions.compactMap { $0.country })
        return uniqueCountries.count
    }
    
    private func calculateAreaExplorerProgress(regions: [VisitedRegion]) -> Int {
        let totalArea = regions.reduce(0.0) { total, region in
            let areaInSquareMeters = Double(region.radius * region.radius) * .pi
            return total + areaInSquareMeters
        }
        return Int(totalArea)
    }
    
    private func calculatePercentageMilestoneProgress() -> Int {
        let percentage = GridHashManager.shared.explorationPercentage
        return Int(percentage * 1000) // Convert to easier integer calculation
    }
    
    private func calculateDailyStreakProgress(regions: [VisitedRegion]) -> Int {
        // Calculate consecutive days with exploration
        let calendar = Calendar.current
        let sortedDates = regions
            .map { calendar.startOfDay(for: $0.timestampStart) }
            .sorted()
        
        guard !sortedDates.isEmpty else { return 0 }
        
        var maxStreak = 1
        var currentStreak = 1
        
        for i in 1..<sortedDates.count {
            let daysDifference = calendar.dateComponents([.day], from: sortedDates[i-1], to: sortedDates[i]).day ?? 0
            
            if daysDifference == 1 {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else if daysDifference > 1 {
                currentStreak = 1
            }
        }
        
        return maxStreak
    }
    
    private func calculateWeekendWarriorProgress(regions: [VisitedRegion]) -> Int {
        let calendar = Calendar.current
        let weekendRegions = regions.filter { region in
            let weekday = calendar.component(.weekday, from: region.timestampStart)
            return weekday == 1 || weekday == 7 // Sunday or Saturday
        }
        
        // Group by weekend and count consecutive weekends
        let weekendDates = weekendRegions
            .map { calendar.startOfDay(for: $0.timestampStart) }
            .sorted()
        
        // Simplified calculation - count unique weekends
        let uniqueWeekends = Set(weekendDates.map { date in
            calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        })
        
        return uniqueWeekends.count
    }
    
    // MARK: - Progress Management
    
    private func updateProgress(_ newProgress: AchievementProgress) {
        var hasChanges = false
        
        if let index = userProgress.firstIndex(where: { $0.achievementId == newProgress.achievementId }) {
            let oldProgress = userProgress[index]
            
            // Only update if there's actual progress change
            if oldProgress.currentProgress != newProgress.currentProgress || 
               oldProgress.isUnlocked != newProgress.isUnlocked {
                userProgress[index] = newProgress
                hasChanges = true
                
                // Check for new unlock
                if newProgress.isUnlocked && !oldProgress.isUnlocked {
                    handleAchievementUnlock(newProgress)
                }
            }
        } else {
            userProgress.append(newProgress)
            hasChanges = true
            
            if newProgress.isUnlocked {
                handleAchievementUnlock(newProgress)
            }
        }
        
        // Only save if there were actual changes
        if hasChanges {
            needsSave = true
            scheduleBatchSave()
        }
    }
    
    private func handleAchievementUnlock(_ progress: AchievementProgress) {
        recentUnlocks.append(progress)
        
        // Keep only last 10 unlocks
        if recentUnlocks.count > 10 {
            recentUnlocks.removeFirst()
        }
        
        // Show notification
        showAchievementNotification(for: progress)
        
        print("🏆 Achievement Unlocked: \(getAchievement(by: progress.achievementId)?.title ?? "Unknown")")
    }
    
    private func showAchievementNotification(for progress: AchievementProgress) {
        guard let achievement = getAchievement(by: progress.achievementId) else { return }
        
        // Show custom notification banner
        AchievementNotificationManager.shared.showAchievementUnlock(
            achievement: achievement,
            progress: progress
        )
        
        print("🎉 \(achievement.title) unlocked!")
    }
    
    private func updateTotalUnlockedCount() {
        totalUnlockedCount = userProgress.filter { $0.isUnlocked }.count
    }
    
    // MARK: - Insights Generation
    
    private func generateInsights() {
        var newInsights: [UserInsight] = []
        let regions = visitedRegionManager.visitedRegions
        
        // Geographic Insights
        if let mostVisitedCity = getMostVisitedCity(from: regions) {
            newInsights.append(UserInsight(
                type: .geographic,
                title: "En Çok Gezdiğin Şehir",
                description: "\(mostVisitedCity.city) şehrinde \(mostVisitedCity.count) bölge keşfettin",
                value: mostVisitedCity.city,
                iconName: "building.2.fill",
                priority: 1
            ))
        }
        
        // Exploration Insights
        let totalRegions = regions.count
        if totalRegions > 0 {
            newInsights.append(UserInsight(
                type: .milestone,
                title: "Toplam Keşif",
                description: "Şimdiye kadar \(totalRegions) bölge keşfettin",
                value: "\(totalRegions)",
                iconName: "map.fill",
                priority: 2
            ))
        }
        
        // Country Insights
        let uniqueCountries = Set(regions.compactMap { $0.country }).count
        if uniqueCountries > 1 {
            newInsights.append(UserInsight(
                type: .geographic,
                title: "Ülke Çeşitliliği",
                description: "\(uniqueCountries) farklı ülke ziyaret ettin",
                value: "\(uniqueCountries)",
                iconName: "globe.europe.africa.fill",
                priority: 3
            ))
        }
        
        // Recent Activity
        let recentRegions = regions.filter { 
            $0.timestampStart > Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        }
        
        if !recentRegions.isEmpty {
            newInsights.append(UserInsight(
                type: .temporal,
                title: "Bu Hafta",
                description: "Son 7 günde \(recentRegions.count) yeni bölge keşfettin",
                value: "\(recentRegions.count)",
                iconName: "calendar.badge.checkmark",
                priority: 4
            ))
        }
        
        insights = newInsights.sorted { $0.priority < $1.priority }
    }
    
    private func getMostVisitedCity(from regions: [VisitedRegion]) -> (city: String, count: Int)? {
        let cityGroups = Dictionary(grouping: regions.compactMap { $0.city }) { $0 }
        return cityGroups.max { $0.value.count < $1.value.count }
            .map { (city: $0.key, count: $0.value.count) }
    }
    
    // MARK: - Public Methods
    
    func getAchievement(by id: String) -> Achievement? {
        return achievements.first { $0.id == id }
    }
    
    func getProgress(for achievementId: String) -> AchievementProgress? {
        return userProgress.first { $0.achievementId == achievementId }
    }
    
    func getAchievements(by type: AchievementType) -> [Achievement] {
        return achievements.filter { $0.type == type }
    }
    
    func getUnlockedAchievements() -> [Achievement] {
        let unlockedIds = userProgress.filter { $0.isUnlocked }.map { $0.achievementId }
        return achievements.filter { unlockedIds.contains($0.id) }
    }
    
    func getLockedAchievements() -> [Achievement] {
        let unlockedIds = userProgress.filter { $0.isUnlocked }.map { $0.achievementId }
        return achievements.filter { !unlockedIds.contains($0.id) && !$0.isHidden }
    }
    
    func refreshProgress() {
        calculateAllProgress()
        generateInsights()
    }
    
    // MARK: - Data Persistence
    
    private func loadUserProgress() {
        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "user_achievement_progress"),
           let savedProgress = try? JSONDecoder().decode([AchievementProgress].self, from: data) {
            userProgress = savedProgress
            print("📊 Loaded \(savedProgress.count) achievement progress records")
        } else {
            userProgress = []
            print("📊 No saved achievement progress found, starting fresh")
        }
        
        // Load recent unlocks
        if let data = UserDefaults.standard.data(forKey: "recent_achievement_unlocks"),
           let savedUnlocks = try? JSONDecoder().decode([AchievementProgress].self, from: data) {
            recentUnlocks = savedUnlocks
            print("🏆 Loaded \(savedUnlocks.count) recent unlocks")
        }
        
        updateTotalUnlockedCount()
    }
    
    private func scheduleBatchSave() {
        // Cancel existing timer
        saveTimer?.invalidate()
        
        // Schedule new save after 2 seconds of inactivity
        saveTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.performBatchSave()
            }
        }
    }
    
    private func performBatchSave() {
        guard needsSave else { return }
        
        // Save achievement progress
        if let data = try? JSONEncoder().encode(userProgress) {
            UserDefaults.standard.set(data, forKey: "user_achievement_progress")
        }
        
        // Save recent unlocks (keep only last 10)
        let recentToSave = Array(recentUnlocks.suffix(10))
        if let data = try? JSONEncoder().encode(recentToSave) {
            UserDefaults.standard.set(data, forKey: "recent_achievement_unlocks")
        }
        
        needsSave = false
        print("💾 Achievement progress batch saved")
    }
    
    func saveUserProgress() {
        performBatchSave()
    }
    
    // MARK: - Data Reset
    
    func resetAllProgress() {
        print("🗑️ Resetting all achievement progress...")
        
        // Clear memory data
        userProgress.removeAll()
        recentUnlocks.removeAll()
        insights.removeAll()
        totalUnlockedCount = 0
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "user_achievement_progress")
        UserDefaults.standard.removeObject(forKey: "recent_achievement_unlocks")
        
        // Cancel any pending save
        saveTimer?.invalidate()
        needsSave = false
        
        print("✅ All achievement progress reset successfully")
    }
    
    // MARK: - Retroactive Achievement Analysis
    
    func analyzeExistingDataForAchievements() {
        print("🔍 Analyzing existing data for retroactive achievements...")
        
        let regions = visitedRegionManager.visitedRegions
        guard !regions.isEmpty else {
            print("⚠️ No existing regions found for analysis")
            return
        }
        
        // Calculate all achievements based on existing data
        calculateAllProgress()
        
        // Check for any achievements that should have been unlocked
        var retroactiveUnlocks = 0
        for progress in userProgress {
            if progress.isUnlocked && progress.unlockedAt == nil {
                // This achievement was completed but never properly unlocked
                if let index = userProgress.firstIndex(where: { $0.id == progress.id }) {
                    userProgress[index].unlockedAt = Date()
                    retroactiveUnlocks += 1
                }
            }
        }
        
        if retroactiveUnlocks > 0 {
            print("🎉 Found \(retroactiveUnlocks) retroactive achievement unlocks!")
            saveUserProgress()
        }
        
        print("✅ Retroactive analysis complete")
    }
    
    // MARK: - Event Handlers
    
    private func handleAchievementEvent(_ event: AchievementEvent) {
        switch event {
        case .newRegionDiscovered(let region):
            handleNewRegionDiscovered(region)
            
        case .regionEnriched(let enrichedRegion, let oldRegion):
            handleRegionEnriched(enrichedRegion, oldRegion: oldRegion)
            
        case .explorationPercentageChanged(let newPercentage, let previousPercentage):
            handleExplorationPercentageChanged(newPercentage, previousPercentage: previousPercentage)
            
        case .newCityDiscovered(let city, let region):
            handleNewCityDiscovered(city, region: region)
            
        case .newDistrictDiscovered(let district, let region):
            handleNewDistrictDiscovered(district, region: region)
            
        case .newCountryDiscovered(let country, let region):
            handleNewCountryDiscovered(country, region: region)
            
        case .achievementUnlocked(let achievement, let progress):
            // This is published by us, so we don't need to handle it
            break
            
        case .progressMilestone(let achievement, let progress, let milestone):
            // This is published by us, so we don't need to handle it
            break
        }
    }
    
    private func handleLocationEvent(_ event: LocationEvent) {
        switch event {
        case .significantLocationChange(_):
            // Location-based achievements could be handled here
            // For now, we rely on region-based events
            break
            
        case .permissionChanged(let state):
            // Could track permission-related achievements
            print("🎯 Location permission changed to: \(state)")
            
        default:
            break
        }
    }
    
    // MARK: - Specific Event Handlers
    
    private func handleNewRegionDiscovered(_ region: VisitedRegion) {
        print("🎯 Processing new region for achievements: \(region.centerCoordinate)")
        
        // Check milestone achievements (first steps, explorer, etc.)
        checkMilestoneAchievements()
        
        // Check area-based achievements
        checkAreaAchievements()
        
        // Check percentage-based achievements
        checkPercentageAchievements()
    }
    
    private func handleRegionEnriched(_ enrichedRegion: VisitedRegion, oldRegion: VisitedRegion?) {
        print("🎯 Processing enriched region for achievements: \(enrichedRegion.locationDescription)")
        
        // Geographic achievements will be handled by specific city/district/country events
        // This is just for logging and potential future achievements
    }
    
    private func handleExplorationPercentageChanged(_ newPercentage: Double, previousPercentage: Double) {
        print("🎯 Processing percentage change: \(previousPercentage)% → \(newPercentage)%")
        
        // Check percentage milestone achievements
        checkPercentageAchievements()
    }
    
    private func handleNewCityDiscovered(_ city: String, region: VisitedRegion) {
        print("🎯 Processing new city discovery: \(city)")
        
        // Check city-specific achievements
        checkCityAchievements(city: city)
        
        // Check district explorer achievements
        checkDistrictAchievements()
    }
    
    private func handleNewDistrictDiscovered(_ district: String, region: VisitedRegion) {
        print("🎯 Processing new district discovery: \(district)")
        
        // Check district explorer achievements
        checkDistrictAchievements()
    }
    
    private func handleNewCountryDiscovered(_ country: String, region: VisitedRegion) {
        print("🎯 Processing new country discovery: \(country)")
        
        // Check country collector achievements
        checkCountryAchievements()
    }
    
    // MARK: - Smart Achievement Checkers
    
    private func checkMilestoneAchievements() {
        let regionCount = visitedRegionManager.visitedRegions.count
        let milestoneAchievements = achievements.filter { 
            $0.category == .firstSteps || $0.category == .explorer || 
            $0.category == .adventurer || $0.category == .worldTraveler 
        }
        
        for achievement in milestoneAchievements {
            if regionCount >= achievement.target {
                checkAndUnlockAchievement(achievement, currentProgress: regionCount)
            }
        }
    }
    
    private func checkAreaAchievements() {
        let totalArea = visitedRegionManager.visitedRegions.reduce(0.0) { total, region in
            total + region.areaSquareMeters
        }
        
        let areaAchievements = achievements.filter { $0.category == .areaExplorer }
        
        for achievement in areaAchievements {
            let currentProgress = Int(totalArea)
            if currentProgress >= achievement.target {
                checkAndUnlockAchievement(achievement, currentProgress: currentProgress)
            }
        }
    }
    
    private func checkPercentageAchievements() {
        let percentage = GridHashManager.shared.explorationPercentage
        let percentageInt = Int(percentage * 1000) // Convert to easier integer calculation
        
        let percentageAchievements = achievements.filter { $0.category == .percentageMilestone }
        
        for achievement in percentageAchievements {
            if percentageInt >= achievement.target {
                checkAndUnlockAchievement(achievement, currentProgress: percentageInt)
            }
        }
    }
    
    private func checkCityAchievements(city: String) {
        let cityAchievements = achievements.filter { $0.category == .cityMaster }
        
        for achievement in cityAchievements {
            let cityRegions = visitedRegionManager.visitedRegions.filter { 
                $0.city?.contains(getCityNameForAchievement(achievement.id)) == true 
            }
            
            if cityRegions.count >= achievement.target {
                checkAndUnlockAchievement(achievement, currentProgress: cityRegions.count)
            }
        }
    }
    
    private func checkDistrictAchievements() {
        let uniqueDistricts = Set(visitedRegionManager.visitedRegions.compactMap { $0.district })
        let districtCount = uniqueDistricts.count
        
        let districtAchievements = achievements.filter { $0.category == .districtExplorer }
        
        for achievement in districtAchievements {
            if districtCount >= achievement.target {
                checkAndUnlockAchievement(achievement, currentProgress: districtCount)
            }
        }
    }
    
    private func checkCountryAchievements() {
        let uniqueCountries = Set(visitedRegionManager.visitedRegions.compactMap { $0.country })
        let countryCount = uniqueCountries.count
        
        let countryAchievements = achievements.filter { $0.category == .countryCollector }
        
        for achievement in countryAchievements {
            if countryCount >= achievement.target {
                checkAndUnlockAchievement(achievement, currentProgress: countryCount)
            }
        }
    }
    
    private func checkAndUnlockAchievement(_ achievement: Achievement, currentProgress: Int) {
        let existingProgress = userProgress.first { $0.achievementId == achievement.id }
        
        // Only unlock if not already unlocked
        if existingProgress?.isUnlocked != true {
            let newProgress = AchievementProgress(
                id: existingProgress?.id ?? UUID().uuidString,
                achievementId: achievement.id,
                currentProgress: currentProgress,
                targetProgress: achievement.target,
                isUnlocked: true,
                unlockedAt: Date(),
                lastUpdated: Date()
            )
            
            updateProgress(newProgress)
            
            // Publish achievement unlocked event
            eventBus.publish(achievementEvent: .achievementUnlocked(achievement, progress: newProgress))
        }
    }
    
    private func getCityNameForAchievement(_ achievementId: String) -> String {
        switch achievementId {
        case "istanbul_master":
            return "İstanbul"
        case "ankara_master":
            return "Ankara"
        default:
            return ""
        }
    }
} 