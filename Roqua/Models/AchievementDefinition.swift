import Foundation

// MARK: - Achievement Configuration
struct AchievementConfig: Codable {
    let version: String
    let lastUpdated: String
    let achievements: [AchievementDefinition]
}

// MARK: - Achievement Definition
struct AchievementDefinition: Codable, Identifiable {
    let id: String
    let category: String
    let type: String
    let title: String
    let description: String
    let iconName: String
    let target: Int
    let isHidden: Bool
    let rarity: String
    let calculator: String
    let params: [String: AnyCodable]?
}

// MARK: - AnyCodable for flexible JSON params
struct AnyCodable: Codable {
    let value: Any
    
    init<T>(_ value: T?) {
        self.value = value ?? ()
    }
    
    // MARK: - Codable Implementation
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            value = arrayVal.map { $0.value }
        } else if let dictVal = try? container.decode([String: AnyCodable].self) {
            value = dictVal.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown value type")
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let boolVal as Bool:
            try container.encode(boolVal)
        case let intVal as Int:
            try container.encode(intVal)
        case let doubleVal as Double:
            try container.encode(doubleVal)
        case let stringVal as String:
            try container.encode(stringVal)
        case let arrayVal as [Any]:
            let codableArray = arrayVal.map { AnyCodable($0) }
            try container.encode(codableArray)
        case let dictVal as [String: Any]:
            let codableDict = dictVal.mapValues { AnyCodable($0) }
            try container.encode(codableDict)
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unknown value type")
            )
        }
    }
}

// MARK: - Helper Extensions
extension AnyCodable {
    var stringValue: String? {
        return value as? String
    }
    
    var intValue: Int? {
        return value as? Int
    }
    
    var doubleValue: Double? {
        return value as? Double
    }
    
    var boolValue: Bool? {
        return value as? Bool
    }
    
    var arrayValue: [Any]? {
        return value as? [Any]
    }
    
    var dictionaryValue: [String: Any]? {
        return value as? [String: Any]
    }
} 