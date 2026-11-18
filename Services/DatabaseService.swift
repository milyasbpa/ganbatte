import Foundation
import SQLite3

final class DatabaseService {
    static let shared = DatabaseService()
    
    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "co.bas.ganbatte.db", qos: .userInitiated)
    
    private init() {
        openDatabase()
    }
    
    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }
    
    private func openDatabase() {
        // Look for ganbatte.db in app bundle
        guard let dbURL = Bundle.main.url(forResource: "ganbatte", withExtension: "db") ??
                Bundle.main.url(forResource: "ganbatte", withExtension: "db", subdirectory: "Resources") else {
            // Fallback for development/testing if running from Xcode project directory
            let devPath = "/Users/ilyasbashirah/Documents/kerja/bas.co/pictango/ganbatte/Resources/ganbatte.db"
            if FileManager.default.fileExists(atPath: devPath) {
                if sqlite3_open_v2(devPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK {
                    print("Opened database from dev path: \(devPath)")
                    return
                }
            }
            print("Database ganbatte.db not found!")
            return
        }
        
        if sqlite3_open_v2(dbURL.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK {
            print("Successfully opened database at \(dbURL.path)")
        } else {
            print("Failed to open database at \(dbURL.path)")
        }
    }
    
    func fetchWords(
        level: JLPTLevel = .all,
        type: WordType = .all,
        searchQuery: String = "",
        limit: Int = 100,
        offset: Int = 0
    ) -> [Word] {
        queue.sync {
            guard let db = db else { return [] }
            
            var conditions: [String] = []
            var params: [String] = []
            
            if level != .all {
                conditions.append("level = ?")
                params.append(level.rawValue)
            }
            
            if type != .all {
                conditions.append("type = ?")
                params.append(type.rawValue)
            }
            
            let trimmedSearch = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedSearch.isEmpty {
                conditions.append("(kanji LIKE ? OR kana LIKE ? OR romaji LIKE ? OR meaning_en LIKE ? OR meaning_ja LIKE ?)")
                let pattern = "%\(trimmedSearch)%"
                for _ in 0..<5 {
                    params.append(pattern)
                }
            }
            
            var query = "SELECT id, level, type, card_number, kanji, kana, romaji, meaning_en, meaning_ja, example_ja, example_en, image_name FROM words"
            if !conditions.isEmpty {
                query += " WHERE " + conditions.joined(separator: " AND ")
            }
            query += " ORDER BY id ASC LIMIT ? OFFSET ?"
            
            var statement: OpaquePointer?
            defer { sqlite3_finalize(statement) }
            
            guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
                let errMsg = String(cString: sqlite3_errmsg(db))
                print("Failed to prepare statement: \(errMsg)")
                return []
            }
            
            var paramIndex: Int32 = 1
            for param in params {
                sqlite3_bind_text(statement, paramIndex, (param as NSString).utf8String, -1, nil)
                paramIndex += 1
            }
            sqlite3_bind_int(statement, paramIndex, Int32(limit))
            paramIndex += 1
            sqlite3_bind_int(statement, paramIndex, Int32(offset))
            
            var results: [Word] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                let level = String(cString: sqlite3_column_text(statement, 1))
                let type = String(cString: sqlite3_column_text(statement, 2))
                let cardNumber = Int(sqlite3_column_int(statement, 3))
                let kanji = String(cString: sqlite3_column_text(statement, 4))
                let kana = String(cString: sqlite3_column_text(statement, 5))
                let romaji = String(cString: sqlite3_column_text(statement, 6))
                let meaningEn = String(cString: sqlite3_column_text(statement, 7))
                let meaningJa = String(cString: sqlite3_column_text(statement, 8))
                let exampleJa = String(cString: sqlite3_column_text(statement, 9))
                let exampleEn = String(cString: sqlite3_column_text(statement, 10))
                let imageName = String(cString: sqlite3_column_text(statement, 11))
                
                let word = Word(
                    id: id,
                    level: level,
                    type: type,
                    cardNumber: cardNumber,
                    kanji: kanji,
                    kana: kana,
                    romaji: romaji,
                    meaningEn: meaningEn,
                    meaningJa: meaningJa,
                    exampleJa: exampleJa,
                    exampleEn: exampleEn,
                    imageName: imageName
                )
                results.append(word)
            }
            
            return results
        }
    }
    
    func countWords(
        level: JLPTLevel = .all,
        type: WordType = .all,
        searchQuery: String = ""
    ) -> Int {
        queue.sync {
            guard let db = db else { return 0 }
            
            var conditions: [String] = []
            var params: [String] = []
            
            if level != .all {
                conditions.append("level = ?")
                params.append(level.rawValue)
            }
            
            if type != .all {
                conditions.append("type = ?")
                params.append(type.rawValue)
            }
            
            let trimmedSearch = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedSearch.isEmpty {
                conditions.append("(kanji LIKE ? OR kana LIKE ? OR romaji LIKE ? OR meaning_en LIKE ? OR meaning_ja LIKE ?)")
                let pattern = "%\(trimmedSearch)%"
                for _ in 0..<5 {
                    params.append(pattern)
                }
            }
            
            var query = "SELECT COUNT(*) FROM words"
            if !conditions.isEmpty {
                query += " WHERE " + conditions.joined(separator: " AND ")
            }
            
            var statement: OpaquePointer?
            defer { sqlite3_finalize(statement) }
            
            guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
                return 0
            }
            
            var paramIndex: Int32 = 1
            for param in params {
                sqlite3_bind_text(statement, paramIndex, (param as NSString).utf8String, -1, nil)
                paramIndex += 1
            }
            
            if sqlite3_step(statement) == SQLITE_ROW {
                return Int(sqlite3_column_int(statement, 0))
            }
            return 0
        }
    }
    
    // MARK: - Kana Practice Words
    func fetchKanaPracticeWords(type: KanaType, limit: Int = 1000) -> [KanaWord] {
        queue.sync {
            guard let db = db else { return [] }
            
            let query: String
            if type == .katakana {
                query = """
                SELECT id, kanji, kana, romaji, meaning_en 
                FROM words 
                WHERE (kanji GLOB '*[ァ-ン]*' OR kana GLOB '*[ァ-ン]*')
                ORDER BY id ASC
                LIMIT ?
                """
            } else {
                query = """
                SELECT id, kanji, kana, romaji, meaning_en 
                FROM words 
                WHERE level IN ('N5', 'N4', 'N3') 
                  AND kana NOT GLOB '*[ァ-ン]*' 
                  AND kana NOT LIKE '%(%' 
                  AND kana NOT LIKE '%（%'
                  AND kana NOT LIKE '%～%'
                ORDER BY level DESC, id ASC
                LIMIT ?
                """
            }
            
            var statement: OpaquePointer?
            defer { sqlite3_finalize(statement) }
            
            guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
                return []
            }
            
            sqlite3_bind_int(statement, 1, Int32(limit))
            
            var results: [KanaWord] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                let kanji = String(cString: sqlite3_column_text(statement, 1))
                let kana = String(cString: sqlite3_column_text(statement, 2))
                let romaji = String(cString: sqlite3_column_text(statement, 3))
                let meaningEn = String(cString: sqlite3_column_text(statement, 4))
                
                var displayKana = kana
                if type == .katakana {
                    let hasKatakana = kanji.unicodeScalars.contains { scalar in
                        (0x30A0...0x30FF).contains(scalar.value)
                    }
                    displayKana = hasKatakana ? kanji : kana
                }
                
                results.append(KanaWord(
                    id: id,
                    kana: displayKana,
                    romaji: romaji,
                    meaningEn: meaningEn,
                    type: type
                ))
            }
            return results
        }
    }
}
