import Foundation

// MARK: - Area Calculator
struct AreaCalculator: AchievementCalculator {
    func calculate(regions: [VisitedRegion], params: [String: Any]?) -> Int {
        let totalArea = regions.reduce(0.0) { total, region in
            // Use region.areaSquareMeters if available, otherwise calculate from radius
            if region.areaSquareMeters > 0 {
                return total + region.areaSquareMeters
            } else {
                let areaInSquareMeters = Double(region.radius * region.radius) * .pi
                return total + areaInSquareMeters
            }
        }
        return Int(totalArea)
    }
} 