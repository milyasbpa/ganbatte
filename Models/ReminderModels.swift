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

enum WordReminderFilter: String, Codable, CaseIterable, Identifiable {
    case all = "all"
    case verbsOnly = "verbs"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .all: return "All Words"
        case .verbsOnly: return "Verbs Only (動詞)"
        }
    }
}

struct KanaReminderSettings: Codable, Equatable {
    var isEnabled: Bool
    var script: KanaType
    var times: [ReminderTime]
    
    init(
        isEnabled: Bool = true,
        script: KanaType = .katakana,
        times: [ReminderTime] = [
            ReminderTime(hour: 11, minute: 0),
            ReminderTime(hour: 16, minute: 0)
        ]
    ) {
        self.isEnabled = isEnabled
        self.script = script
        self.times = times
    }
    
    private static let userDefaultsKey = "ganbatte_kana_reminder_settings"
    
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

struct WordReminderSettings: Codable, Equatable {
    var isEnabled: Bool
    var filter: WordReminderFilter
    var times: [ReminderTime]
    
    init(
        isEnabled: Bool = true,
        filter: WordReminderFilter = .verbsOnly,
        times: [ReminderTime] = [
            ReminderTime(hour: 8, minute: 0),
            ReminderTime(hour: 20, minute: 30)
        ]
    ) {
        self.isEnabled = isEnabled
        self.filter = filter
        self.times = times
    }
    
    private static let userDefaultsKey = "ganbatte_word_reminder_settings"
    
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

enum ReminderDeepLink: Equatable {
    case kana(KanaType)
    case words(WordReminderFilter)
}
