//
//  POIEnrichmentManager.swift
//  Roqua
//
//  Created by POI System on 16.06.2025.
//

import Foundation
import MapKit
import CoreLocation

extension Notification.Name {
    static let newPOIDiscovered = Notification.Name("newPOIDiscovered")
}

// MARK: - POI Category Enum (Apple Official Categories)
enum POICategory: String, CaseIterable {
    // Religious & Cultural
    case religiousSite = "ReligiousSite"
    case mosque = "mosque"
    case church = "church"
    case synagogue = "synagogue"
    
    // Healthcare
    case hospital = "Hospital"
    case pharmacy = "Pharmacy"
    
    // Education
    case school = "School"
    case university = "University"
    case library = "Library"
    
    // Government & Services
    case police = "Police"
    case fireStation = "FireStation"
    case postOffice = "PostOffice"
    
    // Shopping & Dining
    case restaurant = "Restaurant"
    case cafe = "Cafe"
    case store = "Store"
    case bakery = "Bakery"
    case foodMarket = "FoodMarket"
    
    // Transportation
    case airport = "Airport"
    case publicTransport = "PublicTransport"
    case gasStation = "GasStation"
    case parking = "Parking"
    
    // Entertainment & Recreation
    case museum = "Museum"
    case theater = "Theater"
    case movieTheater = "MovieTheater"
    case park = "Park"
    case playground = "Playground"
    case stadium = "Stadium"
    case fitnessCenter = "FitnessCenter"
    
    // Financial
    case bank = "Bank"
    case atm = "ATM"
    
    // Hospitality
    case hotel = "Hotel"
    
    // Other
    case unknown = "unknown"
    
    // Convert Apple MapKit category to our POI category
    static func fromMapKitCategory(_ category: MKPointOfInterestCategory) -> POICategory {
        let categoryString = category.rawValue
        
        // Debug: Print exact MapKit category
        print("🏷️ MapKit POI Category (raw): '\(categoryString)'")
        
        // Direct mapping from Apple's official POI categories
        switch categoryString {
        // Religious Sites
        case "MKPOICategoryReligiousSite", "ReligiousSite":
            return .religiousSite
            
        // Healthcare
        case "MKPOICategoryHospital", "Hospital":
            return .hospital
        case "MKPOICategoryPharmacy", "Pharmacy":
            return .pharmacy
            
        // Education
        case "MKPOICategorySchool", "School":
            return .school
        case "MKPOICategoryUniversity", "University":
            return .university
        case "MKPOICategoryLibrary", "Library":
            return .library
            
        // Government & Services
        case "MKPOICategoryPolice", "Police":
            return .police
        case "MKPOICategoryFireStation", "FireStation":
            return .fireStation
        case "MKPOICategoryPostOffice", "PostOffice":
            return .postOffice
            
        // Shopping & Dining
        case "MKPOICategoryRestaurant", "Restaurant":
            return .restaurant
        case "MKPOICategoryCafe", "Cafe":
            return .cafe
        case "MKPOICategoryStore", "Store":
            return .store
        case "MKPOICategoryBakery", "Bakery":
            return .bakery
        case "MKPOICategoryFoodMarket", "FoodMarket":
            return .foodMarket
            
        // Transportation
        case "MKPOICategoryAirport", "Airport":
            return .airport
        case "MKPOICategoryPublicTransport", "PublicTransport":
            return .publicTransport
        case "MKPOICategoryGasStation", "GasStation":
            return .gasStation
        case "MKPOICategoryParking", "Parking":
            return .parking
            
        // Entertainment & Recreation
        case "MKPOICategoryMuseum", "Museum":
            return .museum
        case "MKPOICategoryTheater", "Theater":
            return .theater
        case "MKPOICategoryMovieTheater", "MovieTheater":
            return .movieTheater
        case "MKPOICategoryPark", "Park":
            return .park
        case "MKPOICategoryPlayground", "Playground":
            return .playground
        case "MKPOICategoryStadium", "Stadium":
            return .stadium
        case "MKPOICategoryFitnessCenter", "FitnessCenter":
            return .fitnessCenter
            
        // Financial
        case "MKPOICategoryBank", "Bank":
            return .bank
        case "MKPOICategoryATM", "ATM":
            return .atm
            
        // Hospitality
        case "MKPOICategoryHotel", "Hotel":
            return .hotel
            
        // Additional categories found in logs
        case "MKPOICategoryNightlife", "Nightlife":
            return .unknown // Could add nightlife category later
        case "MKPOICategoryLandmark", "Landmark":
            return .unknown // Could add landmark category later
            
        default:
            print("⚠️ Unknown MapKit POI Category: '\(categoryString)'")
            return .unknown
        }
    }
}

// MARK: - POI Info
struct POIInfo {
    let name: String
    let category: POICategory
    let type: String
    
    var categoryString: String {
        return category.rawValue
    }
    
    var typeString: String {
        return type
    }
}

// MARK: - POI Enrichment Manager
class POIEnrichmentManager {
    static let shared = POIEnrichmentManager()
    private init() {}
    
    // Cache for POI search results
    private var poiCache: [String: POIInfo] = [:]
    
    func enrichWithPOI(coordinate: CLLocationCoordinate2D, completion: @escaping (POIInfo?) -> Void) {
        let cacheKey = "\(coordinate.latitude)_\(coordinate.longitude)"
        print("🔍 Starting POI search at: \(String(format: "%.6f", coordinate.latitude)), \(String(format: "%.6f", coordinate.longitude))")
        
        // Check cache first
        if let cachedPOI = poiCache[cacheKey] {
            print("🏷️ POI cache hit for: \(cachedPOI.name)")
            completion(cachedPOI)
            return
        }
        
        // Try POI-specific search first  
        print("📡 Starting MKLocalPointsOfInterestRequest with 50m radius...")
        let poiRequest = MKLocalPointsOfInterestRequest(center: coordinate, radius: 50.0)
        
        let search = MKLocalSearch(request: poiRequest)
        search.start { [weak self] response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ POI search error: \(error.localizedDescription)")
                print("🔧 Error code: \((error as NSError).code)")
                print("🌐 Error domain: \((error as NSError).domain)")
                
                // MKErrorDomain error 4 = Network unavailable  
                if (error as NSError).domain == "MKErrorDomain" && (error as NSError).code == 4 {
                    print("🌐 Network error detected - trying fallback search...")
                    
                    // Try regular local search as fallback
                    self.fallbackLocalSearch(coordinate: coordinate, completion: completion)
                    return
                } else {
                    print("❓ Unknown MapKit error: \(error)")
                }
                
                completion(nil)
                return
            }
            
            guard let response = response else {
                print("📍 No POI response from MapKit")
                completion(nil)
                return
            }
            
            print("📊 MapKit returned \(response.mapItems.count) items")
            
            // Debug: Log all mapItems
            for (index, item) in response.mapItems.enumerated() {
                let name = item.name ?? "No name"
                let category = item.pointOfInterestCategory?.rawValue ?? "No category"
                print("📍 Item \(index): '\(name)' - Category: '\(category)'")
            }
            
            // Find the best POI match
            let poiInfo = self.findBestPOI(from: response.mapItems, coordinate: coordinate)
            
            if let poiInfo = poiInfo {
                // Cache the result
                self.poiCache[cacheKey] = poiInfo
                print("🏷️ POI found and cached: \(poiInfo.name) (\(poiInfo.categoryString))")
                
                // Send notification for dashboard debug
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .newPOIDiscovered,
                        object: nil,
                        userInfo: [
                            "name": poiInfo.name,
                            "category": poiInfo.categoryString
                        ]
                    )
                }
            } else {
                print("📍 No suitable POI found in search results")
            }
            
            completion(poiInfo)
        }
    }
    
    // Fallback search using regular MKLocalSearch
    private func fallbackLocalSearch(coordinate: CLLocationCoordinate2D, completion: @escaping (POIInfo?) -> Void) {
        print("🔄 Trying fallback MKLocalSearch.Request...")
        
        let request = MKLocalSearch.Request()
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 200,  // Wider search radius
            longitudinalMeters: 200
        )
        
        // Search for common POI types
        request.naturalLanguageQuery = "restaurant mosque church hospital bank school"
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Fallback search also failed: \(error.localizedDescription)")
                print("🧪 Creating test POI as last resort...")
                
                // Create a test POI as last resort
                let testPOI = POIInfo(
                    name: "Keşfedilen Lokasyon",
                    category: .unknown,
                    type: "ExploredLocation"
                )
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .newPOIDiscovered,
                        object: nil,
                        userInfo: [
                            "name": testPOI.name,
                            "category": testPOI.categoryString
                        ]
                    )
                }
                
                completion(testPOI)
                return
            }
            
            guard let response = response else {
                print("📍 No fallback response from MapKit")
                completion(nil)
                return
            }
            
            print("📊 Fallback search returned \(response.mapItems.count) items")
            
            // Find the best POI match
            let poiInfo = self.findBestPOI(from: response.mapItems, coordinate: coordinate)
            
            if let poiInfo = poiInfo {
                // Cache the result
                let cacheKey = "\(coordinate.latitude)_\(coordinate.longitude)"
                self.poiCache[cacheKey] = poiInfo
                print("🏷️ Fallback POI found and cached: \(poiInfo.name) (\(poiInfo.categoryString))")
                
                // Send notification for dashboard debug
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .newPOIDiscovered,
                        object: nil,
                        userInfo: [
                            "name": poiInfo.name,
                            "category": poiInfo.categoryString
                        ]
                    )
                }
                
                completion(poiInfo)
            } else {
                print("📍 No suitable POI found in fallback search")
                completion(nil)
            }
        }
    }
    
    private func findBestPOI(from mapItems: [MKMapItem], coordinate: CLLocationCoordinate2D) -> POIInfo? {
        let currentLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // Filter and sort POIs by distance, considering categories
        let validPOIs = mapItems.compactMap { item -> (MKMapItem, POICategory, Double)? in
            guard let name = item.name,
                  let poiCategory = item.pointOfInterestCategory,
                  let itemLocation = item.placemark.location else {
                return nil
            }
            
            let category = POICategory.fromMapKitCategory(poiCategory)
            let distance = currentLocation.distance(from: itemLocation)
            
            // Filter by distance (max 100m for initial search)
            if distance > 100.0 {
                return nil
            }
            
            // Prioritize known categories
            if category != .unknown {
                return (item, category, distance)
            }
            
            // Also include religious sites by name pattern even if category is unknown
            let lowercaseName = name.lowercased()
            if lowercaseName.contains("church") || lowercaseName.contains("mosque") || 
               lowercaseName.contains("cami") || lowercaseName.contains("kilise") ||
               lowercaseName.contains("saint") || lowercaseName.contains("jesus") ||
               lowercaseName.contains("santa") || lowercaseName.contains("capela") {
                return (item, .religiousSite, distance)
            }
            
            return nil
        }
        
        // Find the closest valid POI
        guard let closestPOI = validPOIs.min(by: { $0.2 < $1.2 }) else {
            print("📍 No valid POIs found within 100m radius")
            return nil
        }
        
        let item = closestPOI.0
        let category = closestPOI.1
        let distance = closestPOI.2
        
        // For religious sites, determine specific type
        let specificType = determineSpecificType(name: item.name ?? "Unknown", category: category)
        
        print("🎯 Selected closest POI: '\(item.name ?? "Unknown")' (\(category.rawValue)) at \(String(format: "%.1f", distance))m")
        
        return POIInfo(
            name: item.name ?? "Unknown Place",
            category: category,
            type: specificType
        )
    }
    
    private func determineSpecificType(name: String, category: POICategory) -> String {
        let lowercaseName = name.lowercased()
        
        // For religious sites, determine specific religion
        if category == .religiousSite {
            // Turkish mosque patterns
            if lowercaseName.contains("cami") || lowercaseName.contains("camii") ||
               lowercaseName.contains("mosque") || lowercaseName.contains("masjid") {
                return "mosque"
            }
            
            // Church patterns (multiple languages)
            if lowercaseName.contains("church") || lowercaseName.contains("kilise") ||
               lowercaseName.contains("chapel") || lowercaseName.contains("basilica") ||
               lowercaseName.contains("cathedral") || lowercaseName.contains("santa") ||
               lowercaseName.contains("san ") || lowercaseName.contains("jesus") ||
               lowercaseName.contains("jesús") || lowercaseName.contains("christ") ||
               lowercaseName.contains("saint") || lowercaseName.contains("szent") ||
               lowercaseName.contains("chiesa") || lowercaseName.contains("église") {
                return "church"
            }
            
            // Synagogue patterns
            if lowercaseName.contains("synagogue") || lowercaseName.contains("sinagoga") ||
               lowercaseName.contains("havra") || lowercaseName.contains("beth") ||
               lowercaseName.contains("synagog") {
                return "synagogue"
            }
            
            // Temple patterns
            if lowercaseName.contains("temple") || lowercaseName.contains("mandir") ||
               lowercaseName.contains("wat ") || lowercaseName.contains("pagoda") {
                return "temple"
            }
            
            // Default to generic religious site
            return "religious_site"
        }
        
        // For other categories, return the category name as type
        return category.rawValue.lowercased()
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        print("🗑️ Clearing POI cache...")
        poiCache.removeAll()
        print("✅ POI cache cleared successfully")
    }
} 