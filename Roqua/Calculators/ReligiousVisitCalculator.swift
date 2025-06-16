import Foundation

// MARK: - Religious Visit Calculator
struct ReligiousVisitCalculator: AchievementCalculator {
    func calculate(regions: [VisitedRegion], params: [String: Any]?) -> Int {
        let religionType = params?["religionType"] as? String
        let visitType = params?["visitType"] as? String ?? "any"
        
        // Religious categories
        let religiousCategories = ["mosque", "church", "synagogue", "temple"]
        
        let religiousRegions = regions.filter { region in
            guard let poiCategory = region.poiCategory else { return false }
            
            // Check if it's a religious site
            let isReligious = religiousCategories.contains(poiCategory.lowercased())
            guard isReligious else { return false }
            
            // Religion type filtering (mosque, church, synagogue, etc.)
            if let religionType = religionType {
                return region.isPOIOfCategory(religionType)
            }
            
            return true
        }
        
        switch visitType {
        case "unique": 
            // Unique religious sites visited
            let uniqueSites = Set(religiousRegions.compactMap { $0.poiName })
            return uniqueSites.count
            
        case "total":
            // Total visits to religious sites
            return religiousRegions.reduce(0) { $0 + $1.visitCount }
            
        case "any":
            fallthrough
        default:
            // Number of different religious sites visited
            return religiousRegions.count
        }
    }
}

// MARK: - Mosque Visit Calculator (Specific)
struct MosqueVisitCalculator: AchievementCalculator {
    func calculate(regions: [VisitedRegion], params: [String: Any]?) -> Int {
        let visitType = params?["visitType"] as? String ?? "unique"
        let cityFilter = params?["cityName"] as? String
        
        var mosqueRegions = regions.filter { region in
            region.isPOIOfCategory("mosque")
        }
        
        // City filtering
        if let cityFilter = cityFilter {
            mosqueRegions = mosqueRegions.filter { region in
                region.city?.lowercased().contains(cityFilter.lowercased()) == true
            }
        }
        
        switch visitType {
        case "unique":
            let uniqueMosques = Set(mosqueRegions.compactMap { $0.poiName })
            return uniqueMosques.count
            
        case "total":
            return mosqueRegions.reduce(0) { $0 + $1.visitCount }
            
        default:
            return mosqueRegions.count
        }
    }
}

// MARK: - Church Visit Calculator (Specific)
struct ChurchVisitCalculator: AchievementCalculator {
    func calculate(regions: [VisitedRegion], params: [String: Any]?) -> Int {
        let visitType = params?["visitType"] as? String ?? "unique"
        
        let churchRegions = regions.filter { region in
            region.isPOIOfCategory("church")
        }
        
        switch visitType {
        case "unique":
            let uniqueChurches = Set(churchRegions.compactMap { $0.poiName })
            return uniqueChurches.count
            
        case "total":
            return churchRegions.reduce(0) { $0 + $1.visitCount }
            
        default:
            return churchRegions.count
        }
    }
}

// MARK: - Multi Religion Calculator (Diverse Religious Visits)
struct MultiReligionCalculator: AchievementCalculator {
    func calculate(regions: [VisitedRegion], params: [String: Any]?) -> Int {
        let requiredTypes = params?["requiredTypes"] as? [String] ?? ["mosque", "church"]
        let visitType = params?["visitType"] as? String ?? "unique_types"
        
        let religiousCategories = ["mosque", "church", "synagogue", "temple"]
        let religiousRegions = regions.filter { region in
            guard let poiCategory = region.poiCategory else { return false }
            return religiousCategories.contains(poiCategory.lowercased())
        }
        
        switch visitType {
        case "unique_types":
            // Count unique religious types visited
            let visitedTypes = Set(religiousRegions.compactMap { $0.poiCategory?.lowercased() })
            return visitedTypes.intersection(Set(requiredTypes.map { $0.lowercased() })).count
            
        case "all_required":
            // Check if all required types have been visited
            let visitedTypes = Set(religiousRegions.compactMap { $0.poiCategory?.lowercased() })
            let hasAllRequired = requiredTypes.allSatisfy { type in
                visitedTypes.contains(type.lowercased())
            }
            return hasAllRequired ? 1 : 0
            
        default:
            // Total diverse religious sites
            return religiousRegions.count
        }
    }
}

// MARK: - General POI Calculator (for hospitals, schools, etc.)
struct POICalculator: AchievementCalculator {
    func calculate(regions: [VisitedRegion], params: [String: Any]?) -> Int {
        let categoryFilter = params?["poiCategory"] as? String
        let categoriesFilter = params?["poiCategories"] as? [String]
        let visitType = params?["visitType"] as? String ?? "count"
        
        var filteredRegions = regions.filter { $0.isPOIEnriched }
        
        // Apply category filtering
        if let categoryFilter = categoryFilter {
            filteredRegions = filteredRegions.filter { $0.isPOIOfCategory(categoryFilter) }
        } else if let categoriesFilter = categoriesFilter {
            filteredRegions = filteredRegions.filter { $0.isPOIOfCategories(categoriesFilter) }
        }
        
        switch visitType {
        case "unique":
            let uniquePOIs = Set(filteredRegions.compactMap { $0.poiName })
            return uniquePOIs.count
            
        case "total":
            return filteredRegions.reduce(0) { $0 + $1.visitCount }
            
        case "count":
            fallthrough
        default:
            return filteredRegions.count
        }
    }
}

 