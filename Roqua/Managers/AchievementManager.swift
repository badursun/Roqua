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
    case cityMaster = "cityMaster"
    case districtExplorer = "districtExplorer"
    case countryCollector = "countryCollector"
    case areaExplorer = "areaExplorer"
    case distanceWalker = "distanceWalker"
    case gridMaster = "gridMaster"
    case percentageMilestone = "percentageMilestone"
    case dailyExplorer = "dailyExplorer"
    case weekendWarrior = "weekendWarrior"
    case monthlyChallenger = "monthlyChallenger"
    case firstSteps = "firstSteps"
    case explorer = "explorer"
    case adventurer = "adventurer"
    case worldTraveler = "worldTraveler"
}

struct Achievement: Identifiable, Codable {
    let id: String
    let category: AchievementCategory
    let type: AchievementType
    let title: String
    let description: String
    let iconName: String
    let imageName: String? // New: Custom image support
    let target: Int
    let isHidden: Bool // Gizli achievement'lar
    let rarity: AchievementRarity
    
    // Computed property to determine what to display
    var displayIcon: String {
        return imageName ?? iconName
    }
    
    var isCustomImage: Bool {
        return imageName != nil
    }
    
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
    private var achievementDefinitions: [AchievementDefinition] = []
    
    private init() {
        setupAchievements()
        loadUserProgress()
        setupEventListeners()
        calculateAllProgress()
        generateInsights()
    }
    
    // MARK: - Setup
    
    private func setupAchievements() {
        loadAchievementsFromJSON()
    }
    
    private func loadAchievementsFromJSON() {
        guard let url = Bundle.main.url(forResource: "achievements", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("❌ Failed to load achievements.json")
            achievements = [] // Fallback to empty
            return
        }
        
        do {
            let config = try JSONDecoder().decode(AchievementConfig.self, from: data)
            achievementDefinitions = config.achievements
            achievements = achievementDefinitions.map { convertToAchievement($0) }
            print("✅ Loaded \(achievements.count) achievements from JSON")
        } catch {
            print("❌ JSON parsing error: \(error)")
            achievements = [] // Fallback
        }
    }
    
    private func convertToAchievement(_ def: AchievementDefinition) -> Achievement {
        return Achievement(
            id: def.id,
            category: AchievementCategory(rawValue: def.category) ?? .firstSteps,
            type: AchievementType(rawValue: def.type) ?? .milestone,
            title: def.title,
            description: def.description,
            iconName: def.iconName,
            imageName: def.imageName,
            target: def.target,
            isHidden: def.isHidden,
            rarity: Achievement.AchievementRarity(rawValue: def.rarity) ?? .common
        )
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
        // Use Calculator Factory with dynamic achievement definition
        let currentProgress: Int
        
        if let definition = achievementDefinitions.first(where: { $0.id == achievement.id }) {
            let calculator = CalculatorFactory.getCalculator(for: definition.calculator)
            let params = definition.params?.mapValues { $0.value }
            currentProgress = calculator.calculate(regions: regions, params: params)
        } else {
            print("⚠️ No definition found for achievement: \(achievement.id)")
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
        let milestoneAchievements = achievements.filter { 
            $0.category == .firstSteps || $0.category == .explorer || 
            $0.category == .adventurer || $0.category == .worldTraveler 
        }
        
        for achievement in milestoneAchievements {
            let progress = calculateProgress(for: achievement, with: visitedRegionManager.visitedRegions)
            
            if progress.currentProgress >= achievement.target {
                checkAndUnlockAchievement(achievement, currentProgress: progress.currentProgress)
            }
        }
    }
    
    private func checkAreaAchievements() {
        let areaAchievements = achievements.filter { $0.category == .areaExplorer }
        
        for achievement in areaAchievements {
            let progress = calculateProgress(for: achievement, with: visitedRegionManager.visitedRegions)
            
            if progress.currentProgress >= achievement.target {
                checkAndUnlockAchievement(achievement, currentProgress: progress.currentProgress)
            }
        }
    }
    
    private func checkPercentageAchievements() {
        let percentageAchievements = achievements.filter { $0.category == .percentageMilestone }
        
        for achievement in percentageAchievements {
            let progress = calculateProgress(for: achievement, with: visitedRegionManager.visitedRegions)
            
            if progress.currentProgress >= achievement.target {
                checkAndUnlockAchievement(achievement, currentProgress: progress.currentProgress)
            }
        }
    }
    
    private func checkCityAchievements(city: String) {
        let cityAchievements = achievements.filter { $0.category == .cityMaster }
        
        for achievement in cityAchievements {
            // Use dynamic calculation with JSON parameters
            let progress = calculateProgress(for: achievement, with: visitedRegionManager.visitedRegions)
            
            if progress.currentProgress >= achievement.target {
                checkAndUnlockAchievement(achievement, currentProgress: progress.currentProgress)
            }
        }
    }
    
    private func checkDistrictAchievements() {
        let districtAchievements = achievements.filter { $0.category == .districtExplorer }
        
        for achievement in districtAchievements {
            let progress = calculateProgress(for: achievement, with: visitedRegionManager.visitedRegions)
            
            if progress.currentProgress >= achievement.target {
                checkAndUnlockAchievement(achievement, currentProgress: progress.currentProgress)
            }
        }
    }
    
    private func checkCountryAchievements() {
        let countryAchievements = achievements.filter { $0.category == .countryCollector }
        
        for achievement in countryAchievements {
            let progress = calculateProgress(for: achievement, with: visitedRegionManager.visitedRegions)
            
            if progress.currentProgress >= achievement.target {
                checkAndUnlockAchievement(achievement, currentProgress: progress.currentProgress)
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
}

// MARK: - Category Enhancement Extension
extension AchievementManager {
    
    // Calculate difficulty rating for a category (1-5 stars)
    func difficultyRating(for category: AchievementCategory) -> Int {
        let categoryAchievements = achievements.filter { $0.category == category }
        guard !categoryAchievements.isEmpty else { return 1 }
        
        let rarityPoints = categoryAchievements.map { achievement in
            switch achievement.rarity {
            case .common: return 1
            case .rare: return 3
            case .epic: return 5
            case .legendary: return 10
            }
        }
        
        let averageRarity = Double(rarityPoints.reduce(0, +)) / Double(rarityPoints.count)
        
        // Convert to 1-5 star system
        switch averageRarity {
        case 0..<2: return 1      // Very Easy (mostly common)
        case 2..<4: return 2      // Easy (common + some rare)
        case 4..<6: return 3      // Medium (mixed rarity)
        case 6..<8: return 4      // Hard (mostly epic)
        default: return 5         // Very Hard (legendary heavy)
        }
    }
    

    
    // Check if category is fully mastered (all achievements unlocked)
    func isFullyMastered(category: AchievementCategory) -> Bool {
        let categoryAchievements = achievements.filter { $0.category == category }
        let unlockedCount = categoryAchievements.filter { achievement in
            getProgress(for: achievement.id)?.isUnlocked ?? false
        }.count
        
        return unlockedCount == categoryAchievements.count && !categoryAchievements.isEmpty
    }
    
    // Get completion ratio for a category
    func completionRatio(for category: AchievementCategory) -> Double {
        let categoryAchievements = achievements.filter { $0.category == category }
        guard !categoryAchievements.isEmpty else { return 0.0 }
        
        let unlockedCount = categoryAchievements.filter { achievement in
            getProgress(for: achievement.id)?.isUnlocked ?? false
        }.count
        
        return Double(unlockedCount) / Double(categoryAchievements.count)
    }
} 