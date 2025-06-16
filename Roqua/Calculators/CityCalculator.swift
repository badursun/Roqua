import Foundation

// MARK: - City Calculator
struct CityCalculator: AchievementCalculator {
    func calculate(regions: [VisitedRegion], params: [String: Any]?) -> Int {
        // Tek şehir desteği (eski format)
        if let cityName = params?["cityName"] as? String {
            return calculateForSingleCity(regions: regions, cityName: cityName)
        }
        
        // Çoklu şehir desteği (yeni format)
        if let cityNames = params?["cityNames"] as? [String] {
            return calculateForMultipleCities(regions: regions, cityNames: cityNames)
        }
        
        print("⚠️ CityCalculator: Missing cityName or cityNames parameter")
        return 0
    }
    
    // MARK: - Private Methods
    
    private func calculateForSingleCity(regions: [VisitedRegion], cityName: String) -> Int {
        return regions.filter { region in
            guard let regionCity = region.city else { return false }
            return isCityMatch(regionCity: regionCity, targetCity: cityName)
        }.count
    }
    
    private func calculateForMultipleCities(regions: [VisitedRegion], cityNames: [String]) -> Int {
        return regions.filter { region in
            guard let regionCity = region.city else { return false }
            return cityNames.contains { targetCity in
                isCityMatch(regionCity: regionCity, targetCity: targetCity)
            }
        }.count
    }
    
    /// Şehir ismi karşılaştırması - case-insensitive ve dil bağımsız
    private func isCityMatch(regionCity: String, targetCity: String) -> Bool {
        let normalizedRegionCity = normalizeCity(regionCity)
        let normalizedTargetCity = normalizeCity(targetCity)
        
        // Exact match
        if normalizedRegionCity == normalizedTargetCity {
            return true
        }
        
        // Contains match (for cases like "İstanbul Province" contains "istanbul")
        if normalizedRegionCity.contains(normalizedTargetCity) {
            return true
        }
        
        // Reverse contains (for cases like "istanbul" contains "ist")
        if normalizedTargetCity.contains(normalizedRegionCity) {
            return true
        }
        
        return false
    }
    
    /// Şehir ismini normalize et - Türkçe karakterler, case, whitespace
    private func normalizeCity(_ city: String) -> String {
        return city
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: "ğ", with: "g")
            .replacingOccurrences(of: "ü", with: "u")
            .replacingOccurrences(of: "ş", with: "s")
            .replacingOccurrences(of: "ö", with: "o")
            .replacingOccurrences(of: "ç", with: "c")
            .replacingOccurrences(of: " province", with: "")
            .replacingOccurrences(of: " ili", with: "")
            .replacingOccurrences(of: " city", with: "")
    }
} 