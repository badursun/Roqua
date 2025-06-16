import Foundation
import CoreLocation
import Combine

// MARK: - Location Events

enum LocationEvent {
    case permissionChanged(LocationPermissionState)
    case permissionDenied
    case permissionGranted(PermissionType)
    case significantLocationChange(CLLocation)
    case locationAccuracyImproved(CLLocation)
    case locationTrackingStarted
    case locationTrackingStopped
    case locationError(Error)
}

enum PermissionType {
    case whenInUse
    case always
}

// MARK: - Achievement Events

enum AchievementEvent {
    case newRegionDiscovered(VisitedRegion)
    case regionEnriched(VisitedRegion, oldRegion: VisitedRegion?)
    case explorationPercentageChanged(Double, previousPercentage: Double)
    case newCityDiscovered(String, region: VisitedRegion)
    case newDistrictDiscovered(String, region: VisitedRegion)
    case newCountryDiscovered(String, region: VisitedRegion)
    case achievementUnlocked(Achievement, progress: AchievementProgress)
    case progressMilestone(Achievement, progress: AchievementProgress, milestone: Int)
}

// MARK: - Grid Events

enum GridEvent {
    case newGridsAdded(count: Int, totalGrids: Int)
    case explorationPercentageUpdated(Double)
    case gridCalculationCompleted
}

// MARK: - Event Bus

@MainActor
class EventBus: ObservableObject {
    static let shared = EventBus()
    
    // Publishers for different event types
    private let locationEventSubject = PassthroughSubject<LocationEvent, Never>()
    private let achievementEventSubject = PassthroughSubject<AchievementEvent, Never>()
    private let gridEventSubject = PassthroughSubject<GridEvent, Never>()
    
    // Public publishers
    var locationEvents: AnyPublisher<LocationEvent, Never> {
        locationEventSubject.eraseToAnyPublisher()
    }
    
    var achievementEvents: AnyPublisher<AchievementEvent, Never> {
        achievementEventSubject.eraseToAnyPublisher()
    }
    
    var gridEvents: AnyPublisher<GridEvent, Never> {
        gridEventSubject.eraseToAnyPublisher()
    }
    
    private init() {}
    
    // MARK: - Event Publishing
    
    func publish(locationEvent: LocationEvent) {
        locationEventSubject.send(locationEvent)
        print("📡 Location Event: \(locationEvent)")
    }
    
    func publish(achievementEvent: AchievementEvent) {
        achievementEventSubject.send(achievementEvent)
        print("🏆 Achievement Event: \(achievementEvent)")
    }
    
    func publish(gridEvent: GridEvent) {
        gridEventSubject.send(gridEvent)
        print("🌐 Grid Event: \(gridEvent)")
    }
}

// MARK: - Event Extensions for Logging

extension LocationEvent: CustomStringConvertible {
    var description: String {
        switch self {
        case .permissionChanged(let state):
            return "Permission changed to \(state)"
        case .permissionDenied:
            return "Permission denied"
        case .permissionGranted(let type):
            return "Permission granted: \(type)"
        case .significantLocationChange(let location):
            return "Significant location change: \(location.coordinate)"
        case .locationAccuracyImproved(let location):
            return "Location accuracy improved: ±\(location.horizontalAccuracy)m"
        case .locationTrackingStarted:
            return "Location tracking started"
        case .locationTrackingStopped:
            return "Location tracking stopped"
        case .locationError(let error):
            return "Location error: \(error.localizedDescription)"
        }
    }
}

extension AchievementEvent: CustomStringConvertible {
    var description: String {
        switch self {
        case .newRegionDiscovered(let region):
            return "New region discovered at \(region.centerCoordinate)"
        case .regionEnriched(let region, _):
            return "Region enriched: \(region.city ?? "Unknown"), \(region.country ?? "Unknown")"
        case .explorationPercentageChanged(let new, let old):
            return "Exploration percentage: \(old)% → \(new)%"
        case .newCityDiscovered(let city, _):
            return "New city discovered: \(city)"
        case .newDistrictDiscovered(let district, _):
            return "New district discovered: \(district)"
        case .newCountryDiscovered(let country, _):
            return "New country discovered: \(country)"
        case .achievementUnlocked(let achievement, _):
            return "Achievement unlocked: \(achievement.title)"
        case .progressMilestone(let achievement, _, let milestone):
            return "Progress milestone: \(achievement.title) - \(milestone)%"
        }
    }
}

extension GridEvent: CustomStringConvertible {
    var description: String {
        switch self {
        case .newGridsAdded(let count, let total):
            return "New grids added: +\(count) (total: \(total))"
        case .explorationPercentageUpdated(let percentage):
            return "Exploration percentage updated: \(percentage)%"
        case .gridCalculationCompleted:
            return "Grid calculation completed"
        }
    }
} 