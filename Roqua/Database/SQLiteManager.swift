import Foundation
import SQLite3

class SQLiteManager {
    static let shared = SQLiteManager()
    private var db: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "com.roqua.sqlite", qos: .utility)
    
    private let dbPath: String = {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return (documentsDirectory as NSString).appendingPathComponent("Roqua.sqlite")
    }()
    
    private init() {
        openDatabase()
        createTables()
    }
    
    deinit {
        closeDatabase()
    }
    
    // MARK: - Database Connection
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            print("🗄️ SQLite database opened successfully at: \(dbPath)")
        } else {
            print("❌ Unable to open database: \(String(cString: sqlite3_errmsg(db)))")
            db = nil
        }
    }
    
    private func closeDatabase() {
        if sqlite3_close(db) == SQLITE_OK {
            print("🗄️ SQLite database closed successfully")
        } else {
            print("❌ Unable to close database")
        }
    }
    
    // MARK: - Table Creation
    private func createTables() {
        createVisitedRegionsTable()
    }
    
    private func createVisitedRegionsTable() {
        let createTableSQL = """
            CREATE TABLE IF NOT EXISTS visited_regions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                latitude REAL NOT NULL,
                longitude REAL NOT NULL,
                radius INTEGER NOT NULL DEFAULT 200,
                timestamp_start TEXT NOT NULL,
                timestamp_end TEXT,
                visit_count INTEGER NOT NULL DEFAULT 1,
                city TEXT,
                district TEXT,
                country TEXT,
                country_code TEXT,
                geohash TEXT,
                accuracy REAL,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
        """
        
        if sqlite3_exec(db, createTableSQL, nil, nil, nil) == SQLITE_OK {
            print("🗄️ visited_regions table created successfully")
            createIndexes()
        } else {
            print("❌ visited_regions table could not be created: \(String(cString: sqlite3_errmsg(db)))")
        }
    }
    
    private func createIndexes() {
        let indexes = [
            "CREATE INDEX IF NOT EXISTS idx_visited_regions_location ON visited_regions(latitude, longitude);",
            "CREATE INDEX IF NOT EXISTS idx_visited_regions_geohash ON visited_regions(geohash);",
            "CREATE INDEX IF NOT EXISTS idx_visited_regions_timestamp ON visited_regions(timestamp_start);",
            "CREATE INDEX IF NOT EXISTS idx_visited_regions_country ON visited_regions(country);"
        ]
        
        for indexSQL in indexes {
            if sqlite3_exec(db, indexSQL, nil, nil, nil) == SQLITE_OK {
                print("🗄️ Index created successfully")
            } else {
                print("❌ Index creation failed: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
    }
    
    // MARK: - CRUD Operations
    func insertVisitedRegion(_ region: VisitedRegion) -> Int64? {
        return dbQueue.sync {
            let insertSQL = """
                INSERT INTO visited_regions 
                (latitude, longitude, radius, timestamp_start, timestamp_end, visit_count, 
                 city, district, country, country_code, geohash, accuracy, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """
            
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            // Bind parameters
            sqlite3_bind_double(statement, 1, region.latitude)
            sqlite3_bind_double(statement, 2, region.longitude)
            sqlite3_bind_int(statement, 3, Int32(region.radius))
            sqlite3_bind_text(statement, 4, region.timestampStart.iso8601String, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            
            if let timestampEnd = region.timestampEnd {
                sqlite3_bind_text(statement, 5, timestampEnd.iso8601String, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            } else {
                sqlite3_bind_null(statement, 5)
            }
            
            sqlite3_bind_int(statement, 6, Int32(region.visitCount))
            
            // Optional fields
            bindOptionalText(statement, 7, region.city)
            bindOptionalText(statement, 8, region.district)
            bindOptionalText(statement, 9, region.country)
            bindOptionalText(statement, 10, region.countryCode)
            bindOptionalText(statement, 11, region.geohash)
            
            if let accuracy = region.accuracy {
                sqlite3_bind_double(statement, 12, accuracy)
            } else {
                sqlite3_bind_null(statement, 12)
            }
            
            // Bind current timestamp manually
            sqlite3_bind_text(statement, 13, Date().iso8601String, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            
            if sqlite3_step(statement) == SQLITE_DONE {
                let insertedId = sqlite3_last_insert_rowid(db)
                print("🗄️ VisitedRegion inserted with ID: \(insertedId)")
                sqlite3_finalize(statement)
                return insertedId
            } else {
                print("❌ INSERT failed: \(String(cString: sqlite3_errmsg(db)))")
            }
        } else {
            print("❌ INSERT statement could not be prepared: \(String(cString: sqlite3_errmsg(db)))")
        }
        
            sqlite3_finalize(statement)
            return nil
        }
    }
    
    func getAllVisitedRegions() -> [VisitedRegion] {
        return dbQueue.sync {
            let querySQL = "SELECT * FROM visited_regions ORDER BY timestamp_start DESC;"
            var statement: OpaquePointer?
            var regions: [VisitedRegion] = []
            
                if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
                    while sqlite3_step(statement) == SQLITE_ROW {
                        if let region = parseVisitedRegion(from: statement) {
                            regions.append(region)
                        }
                    }
                } else {
                    print("❌ SELECT statement could not be prepared: \(String(cString: sqlite3_errmsg(db)))")
                }
                
                sqlite3_finalize(statement)
                return regions
            }
        }
    
    func getVisitedRegionsNear(latitude: Double, longitude: Double, radiusKm: Double) -> [VisitedRegion] {
        return dbQueue.sync {
            // Simple bounding box query - can be optimized with spatial indexing later
            let latDelta = radiusKm / 111.0 // Approximate km per degree latitude
            let lngDelta = radiusKm / (111.0 * cos(latitude * .pi / 180.0))
            
            let querySQL = """
                SELECT * FROM visited_regions 
                WHERE latitude BETWEEN ? AND ? 
                AND longitude BETWEEN ? AND ?
                ORDER BY timestamp_start DESC;
            """
            
            var statement: OpaquePointer?
            var regions: [VisitedRegion] = []
            
            if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, latitude - latDelta)
            sqlite3_bind_double(statement, 2, latitude + latDelta)
            sqlite3_bind_double(statement, 3, longitude - lngDelta)
            sqlite3_bind_double(statement, 4, longitude + lngDelta)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                if let region = parseVisitedRegion(from: statement) {
                    regions.append(region)
                }
            }
        } else {
            print("❌ Nearby SELECT statement could not be prepared: \(String(cString: sqlite3_errmsg(db)))")
        }
        
            sqlite3_finalize(statement)
            return regions
        }
    }
    
    func updateVisitedRegion(_ region: VisitedRegion) -> Bool {
        guard let id = region.id else { return false }
        
        return dbQueue.sync {
            let updateSQL = """
                UPDATE visited_regions SET 
                latitude = ?, longitude = ?, radius = ?, timestamp_end = ?, visit_count = ?,
                city = ?, district = ?, country = ?, country_code = ?, geohash = ?, accuracy = ?,
                updated_at = ?
                WHERE id = ?;
            """
            
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, updateSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, region.latitude)
            sqlite3_bind_double(statement, 2, region.longitude)
            sqlite3_bind_int(statement, 3, Int32(region.radius))
            
            if let timestampEnd = region.timestampEnd {
                sqlite3_bind_text(statement, 4, timestampEnd.iso8601String, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            } else {
                sqlite3_bind_null(statement, 4)
            }
            
            sqlite3_bind_int(statement, 5, Int32(region.visitCount))
            
            bindOptionalText(statement, 6, region.city)
            bindOptionalText(statement, 7, region.district)
            bindOptionalText(statement, 8, region.country)
            bindOptionalText(statement, 9, region.countryCode)
            bindOptionalText(statement, 10, region.geohash)
            
            if let accuracy = region.accuracy {
                sqlite3_bind_double(statement, 11, accuracy)
            } else {
                sqlite3_bind_null(statement, 11)
            }
            
            // Bind current timestamp manually
            sqlite3_bind_text(statement, 12, Date().iso8601String, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            
            sqlite3_bind_int64(statement, 13, id)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("🗄️ VisitedRegion updated successfully")
                sqlite3_finalize(statement)
                return true
            } else {
                print("❌ UPDATE failed: \(String(cString: sqlite3_errmsg(db)))")
            }
        } else {
            print("❌ UPDATE statement could not be prepared: \(String(cString: sqlite3_errmsg(db)))")
        }
        
            sqlite3_finalize(statement)
            return false
        }
    }
    
    func deleteAllVisitedRegions() -> Bool {
        return dbQueue.sync {
            let deleteSQL = "DELETE FROM visited_regions;"
            
            if sqlite3_exec(db, deleteSQL, nil, nil, nil) == SQLITE_OK {
                print("🗄️ All visited regions deleted successfully")
                return true
            } else {
                print("❌ DELETE failed: \(String(cString: sqlite3_errmsg(db)))")
                return false
            }
        }
    }
    
    // MARK: - Helper Methods
    private func bindOptionalText(_ statement: OpaquePointer?, _ index: Int32, _ text: String?) {
        if let text = text {
            sqlite3_bind_text(statement, index, text, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        } else {
            sqlite3_bind_null(statement, index)
        }
    }
    
    private func parseVisitedRegion(from statement: OpaquePointer?) -> VisitedRegion? {
        guard let statement = statement else { return nil }
        
        let id = sqlite3_column_int64(statement, 0)
        let latitude = sqlite3_column_double(statement, 1)
        let longitude = sqlite3_column_double(statement, 2)
        let radius = Int(sqlite3_column_int(statement, 3))
        
        guard let timestampStartCString = sqlite3_column_text(statement, 4) else { return nil }
        let timestampStartString = String(cString: timestampStartCString)
        guard let timestampStart = Date.fromISO8601String(timestampStartString) else { return nil }
        
        var timestampEnd: Date?
        if let timestampEndCString = sqlite3_column_text(statement, 5) {
            let timestampEndString = String(cString: timestampEndCString)
            timestampEnd = Date.fromISO8601String(timestampEndString)
        }
        
        let visitCount = Int(sqlite3_column_int(statement, 6))
        
        let city = sqlite3_column_text(statement, 7).map { String(cString: $0) }
        let district = sqlite3_column_text(statement, 8).map { String(cString: $0) }
        let country = sqlite3_column_text(statement, 9).map { String(cString: $0) }
        let countryCode = sqlite3_column_text(statement, 10).map { String(cString: $0) }
        let geohash = sqlite3_column_text(statement, 11).map { String(cString: $0) }
        
        var accuracy: Double?
        if sqlite3_column_type(statement, 12) != SQLITE_NULL {
            accuracy = sqlite3_column_double(statement, 12)
        }
        
        return VisitedRegion(
            id: id,
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            timestampStart: timestampStart,
            timestampEnd: timestampEnd,
            visitCount: visitCount,
            city: city,
            district: district,
            country: country,
            countryCode: countryCode,
            geohash: geohash,
            accuracy: accuracy
        )
    }
}

// MARK: - Date Extensions
extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
    
    static func fromISO8601String(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)
    }
} 