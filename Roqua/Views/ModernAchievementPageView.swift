import SwiftUI

// MARK: - Modern Achievement Page
struct ModernAchievementPageView: View {
    @StateObject private var achievementManager = AchievementManager.shared
    @State private var selectedFilter: AchievementFilter = .all
    @State private var selectedAchievement: Achievement?
    @Environment(\.dismiss) private var dismiss
    
    // Grid configuration
    private let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color.appBackground
                .ignoresSafeArea(.all)
            
            // Full page scroll with header included - TAM EKRAN
            ScrollView {
                VStack(spacing: 0) {
                    // Header - status bar alanından başlayarak tam kapla
                    VStack(spacing: 0) {
                        AchievementHeader(
                            achievementManager: achievementManager,
                            onBackTap: {
                                dismiss()
                            }
                        )
                        .padding(.horizontal)
                        .padding(.top, 44) // Status bar + biraz padding
                        .padding(.bottom, 16) // Filter butonlara biraz boşluk
                        
                        // Filter Tabs - header'ın hemen altında
                        AchievementFilterTabs(selectedFilter: $selectedFilter)
                            .padding(.horizontal)
                    }
                    .background(
                        LinearGradient(
                            colors: [
                                Color.purple.opacity(0.8),
                                Color.purple.opacity(0.6),
                                Color.blue.opacity(0.4),
                                Color.purple.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea(.all, edges: .top)
                    )
                    
                    // Content based on filter
                    if selectedFilter == .all {
                        // Category-based layout like old code
                        LazyVStack(spacing: 24) {
                            ForEach(sortedCategories, id: \.self) { category in
                                CategorySection(
                                    category: category,
                                    achievements: sortedAchievements(for: category),
                                    achievementManager: achievementManager,
                                    onAchievementTap: { achievement in
                                        selectedAchievement = achievement
                                    }
                                )
                            }
                            
                            // Hidden Achievements Section
                            if !unlockedHiddenAchievements.isEmpty {
                                HiddenAchievementsSection(
                                    onAchievementTap: { achievement in
                                        selectedAchievement = achievement
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 24)
                        .padding(.bottom, 20)
                    } else {
                        // Grid for unlocked achievements
                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(filteredAchievements) { achievement in
                                ModernAchievementCard(
                                    achievement: achievement,
                                    progress: achievementManager.getProgress(for: achievement.id),
                                    onTap: {
                                        selectedAchievement = achievement
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 24)
                        .padding(.bottom, 20)
                    }
                }
            }
            .ignoresSafeArea(.all) // ScrollView de tam ekran
        }
        .navigationBarHidden(true)
        .onAppear {
            achievementManager.refreshProgress()
        }
        .sheet(item: $selectedAchievement) { achievement in
            // Use existing detail sheet from AchievementPageView - yarım açılır
            AchievementDetailSheet(
                achievement: achievement,
                progress: achievementManager.getProgress(for: achievement.id)
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Filter Logic (Eski koddan birebir)
    private var filteredAchievements: [Achievement] {
        switch selectedFilter {
        case .all:
            // For .all, we use category-based layout, so this is only for unlocked filter fallback
            return achievementManager.achievements
            
        case .unlocked:
            // Unlocked achievements - most recently unlocked first
            return achievementManager.getUnlockedAchievements().sorted { achievement1, achievement2 in
                let progress1 = achievementManager.getProgress(for: achievement1.id)
                let progress2 = achievementManager.getProgress(for: achievement2.id)
                
                // Most recently unlocked first
                let date1 = progress1?.unlockedAt ?? Date.distantPast
                let date2 = progress2?.unlockedAt ?? Date.distantPast
                return date1 > date2
            }
        }
    }
    
    // MARK: - Category Logic (Eski koddan birebir)
    private var groupedAchievements: [AchievementCategory: [Achievement]] {
        let regularAchievements = achievementManager.achievements.filter { !$0.isHidden }
        return Dictionary(grouping: regularAchievements) { $0.category }
    }
    
    // Dynamic sorting: Category by logical order based on actual data
    private var sortedCategories: [AchievementCategory] {
        // Get all unique categories from achievements
        let availableCategories = Array(groupedAchievements.keys)
        
        // Define preferred order for categories that exist
        let categoryOrder: [AchievementCategory] = [
            .firstSteps,        // İlk Adımlar
            .explorer,          // Kaşif
            .adventurer,        // Maceracı
            .worldTraveler,     // Dünya Gezgini
            .cityMaster,        // Şehir Ustası
            .districtExplorer,  // İlçe Kaşifi
            .countryCollector,  // Ülke Koleksiyoneri
            .areaExplorer,      // Alan Kaşifi
            .percentageMilestone, // Yüzde Milestone
            .dailyExplorer,     // Günlük Kaşif
            .weekendWarrior,    // Hafta Sonu Savaşçısı
        ]
        
        // Sort available categories by preferred order, unknowns go to end
        return availableCategories.sorted { category1, category2 in
            let index1 = categoryOrder.firstIndex(of: category1) ?? Int.max
            let index2 = categoryOrder.firstIndex(of: category2) ?? Int.max
            
            if index1 == Int.max && index2 == Int.max {
                // Both unknown, sort alphabetically
                return category1.rawValue < category2.rawValue
            }
            
            return index1 < index2
        }
    }
    
    private func sortedAchievements(for category: AchievementCategory) -> [Achievement] {
        let categoryAchievements = groupedAchievements[category] ?? []
        return categoryAchievements.sorted { achievement1, achievement2 in
            // Primary: Sort by target (ascending - kolay → zor)
            if achievement1.target != achievement2.target {
                return achievement1.target < achievement2.target
            }
            
            // Secondary: Sort by rarity (ascending - kolay → zor)
            let rarity1Value = rarityValue(achievement1.rarity)
            let rarity2Value = rarityValue(achievement2.rarity)
            if rarity1Value != rarity2Value {
                return rarity1Value < rarity2Value
            }
            
            // Tertiary: Sort by title alphabetically
            return achievement1.title < achievement2.title
        }
    }
    
    private var unlockedHiddenAchievements: [Achievement] {
        achievementManager.achievements
            .filter { $0.isHidden }
            .filter { achievement in
                achievementManager.getProgress(for: achievement.id)?.isUnlocked == true
            }
    }
    
    // Eski koddan rarity value helper
    private func rarityValue(_ rarity: Achievement.AchievementRarity) -> Int {
        switch rarity {
        case .common: return 1     // En kolay
        case .rare: return 2       // Orta
        case .epic: return 3       // Zor  
        case .legendary: return 4  // En zor
        }
    }
}

// MARK: - Category Section
struct CategorySection: View {
    let category: AchievementCategory
    let achievements: [Achievement]
    let achievementManager: AchievementManager
    let onAchievementTap: (Achievement) -> Void
    
    // Grid configuration
    private let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category Header
            Text(titleForCategory(category))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primaryText)
            
            // Achievement Grid
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(achievements) { achievement in
                    ModernAchievementCard(
                        achievement: achievement,
                        progress: achievementManager.getProgress(for: achievement.id),
                        onTap: {
                            onAchievementTap(achievement)
                        }
                    )
                }
            }
        }
    }
    
    private func titleForCategory(_ category: AchievementCategory) -> String {
        switch category {
        case .firstSteps: return "İlk Adımlar"
        case .explorer: return "Kaşif"
        case .adventurer: return "Maceracı"
        case .worldTraveler: return "Dünya Gezgini"
        case .cityMaster: return "Şehir Ustası"
        case .districtExplorer: return "İlçe Kaşifi"
        case .countryCollector: return "Ülke Koleksiyoneri"
        case .areaExplorer: return "Alan Kaşifi"
        case .percentageMilestone: return "Yüzde Dönüm Noktaları"
        case .dailyExplorer: return "Günlük Kaşif"
        case .weekendWarrior: return "Hafta Sonu Savaşçısı"
        case .distanceWalker: return "Mesafe Yürüyüşçüsü"
        case .gridMaster: return "Grid Ustası"
        case .monthlyChallenger: return "Aylık Meydan Okuyucu"
        case .religiousVisitor: return "Dini Mekan Ziyaretçisi"
        case .poiExplorer: return "Özel Mekan Kaşifi"
        }
    }
}



// MARK: - Preview
struct ModernAchievementPageView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ModernAchievementPageView()
        }
        .preferredColorScheme(.light)
        
        NavigationView {
            ModernAchievementPageView()
        }
        .preferredColorScheme(.dark)
    }
} 