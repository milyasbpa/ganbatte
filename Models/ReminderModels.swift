import Foundation

// MARK: - Reminder Training Mode
enum ReminderMode: String, Codable, CaseIterable, Identifiable {
    case learn = "Learn"
    case exercise = "Exercise"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .learn: return "book.fill"
        case .exercise: return "bolt.fill"
        }
    }
}

struct ReminderTime: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var hour: Int
    var minute: Int
    
    init(id: String = UUID().uuidString, hour: Int, minute: Int) {
        self.id = id
        self.hour = hour
        self.minute = minute
    }
    
    var formatted24: String {
        String(format: "%02d:%02d", hour, minute)
    }
    
    var formatted12: String {
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%02d:%02d %@", displayHour, minute, period)
    }
}

// MARK: - Kana Reminder Item
struct KanaReminderItem: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var script: KanaType
    var mode: ReminderMode = .exercise
    var hour: Int
    var minute: Int
    
    init(id: String = UUID().uuidString, script: KanaType = .katakana, mode: ReminderMode = .exercise, hour: Int, minute: Int) {
        self.id = id
        self.script = script
        self.mode = mode
        self.hour = hour
        self.minute = minute
    }
    
    var formatted24: String {
        String(format: "%02d:%02d", hour, minute)
    }
}

// MARK: - Word Reminder Item
struct WordReminderItem: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var level: JLPTLevel
    var type: WordType
    var mode: ReminderMode = .exercise
    var hour: Int
    var minute: Int
    
    init(id: String = UUID().uuidString, level: JLPTLevel = .n5, type: WordType = .verb, mode: ReminderMode = .exercise, hour: Int, minute: Int) {
        self.id = id
        self.level = level
        self.type = type
        self.mode = mode
        self.hour = hour
        self.minute = minute
    }
    
    var formatted24: String {
        String(format: "%02d:%02d", hour, minute)
    }
}

// MARK: - Kana Settings
struct KanaReminderSettings: Codable, Equatable {
    var isEnabled: Bool
    var items: [KanaReminderItem]
    
    init(
        isEnabled: Bool = true,
        items: [KanaReminderItem] = [
            KanaReminderItem(script: .katakana, mode: .exercise, hour: 7, minute: 30),
            KanaReminderItem(script: .hiragana, mode: .exercise, hour: 17, minute: 30)
        ]
    ) {
        self.isEnabled = isEnabled
        self.items = items
    }
    
    private static let userDefaultsKey = "ganbatte_kana_reminder_settings_v3"
    
    static func load() -> KanaReminderSettings {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode(KanaReminderSettings.self, from: data) else {
            return KanaReminderSettings()
        }
        return decoded
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: Self.userDefaultsKey)
        }
    }
}

// MARK: - Word Settings
struct WordReminderSettings: Codable, Equatable {
    var isEnabled: Bool
    var items: [WordReminderItem]
    
    init(
        isEnabled: Bool = true,
        items: [WordReminderItem] = [
            WordReminderItem(level: .n4, type: .verb, mode: .learn, hour: 8, minute: 0),
            WordReminderItem(level: .n5, type: .verb, mode: .exercise, hour: 12, minute: 30),
            WordReminderItem(level: .n5, type: .adjective, mode: .exercise, hour: 13, minute: 0),
            WordReminderItem(level: .n4, type: .adjective, mode: .learn, hour: 18, minute: 0),
            WordReminderItem(level: .n4, type: .verb, mode: .exercise, hour: 19, minute: 30),
            WordReminderItem(level: .n4, type: .adjective, mode: .exercise, hour: 20, minute: 0)
        ]
    ) {
        self.isEnabled = isEnabled
        self.items = items
    }
    
    private static let userDefaultsKey = "ganbatte_word_reminder_settings_v3"
    
    static func load() -> WordReminderSettings {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode(WordReminderSettings.self, from: data) else {
            return WordReminderSettings()
        }
        return decoded
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: Self.userDefaultsKey)
        }
    }
}

// MARK: - Deep Link Target
enum ReminderDeepLink: Equatable {
    case kana(KanaType, mode: ReminderMode)
    case words(level: JLPTLevel, type: WordType, mode: ReminderMode)
}
