import Foundation

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
    var hour: Int
    var minute: Int
    
    init(id: String = UUID().uuidString, script: KanaType = .katakana, hour: Int, minute: Int) {
        self.id = id
        self.script = script
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
    var hour: Int
    var minute: Int
    
    init(id: String = UUID().uuidString, level: JLPTLevel = .n5, type: WordType = .verb, hour: Int, minute: Int) {
        self.id = id
        self.level = level
        self.type = type
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
            KanaReminderItem(script: .katakana, hour: 7, minute: 30),
            KanaReminderItem(script: .hiragana, hour: 12, minute: 30),
            KanaReminderItem(script: .katakana, hour: 12, minute: 45),
            KanaReminderItem(script: .katakana, hour: 20, minute: 30)
        ]
    ) {
        self.isEnabled = isEnabled
        self.items = items
    }
    
    private static let userDefaultsKey = "ganbatte_kana_reminder_settings_v2"
    
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
            WordReminderItem(level: .n5, type: .verb, hour: 8, minute: 0),
            WordReminderItem(level: .n5, type: .adjective, hour: 13, minute: 0),
            WordReminderItem(level: .n2, type: .all, hour: 21, minute: 0)
        ]
    ) {
        self.isEnabled = isEnabled
        self.items = items
    }
    
    private static let userDefaultsKey = "ganbatte_word_reminder_settings_v2"
    
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
    case kana(KanaType)
    case words(level: JLPTLevel, type: WordType)
}
