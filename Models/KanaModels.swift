import Foundation

// MARK: - Kana Type
enum KanaType: String, CaseIterable, Identifiable, Codable {
    case hiragana = "Hiragana"
    case katakana = "Katakana"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .hiragana: return "Hiragana"
        case .katakana: return "Katakana"
        }
    }
}

// MARK: - Kana Letter (For Chart Grid)
struct KanaLetter: Identifiable, Hashable {
    let id: String
    let kana: String
    let romaji: String
    let row: String
    let col: Int
    let isEmpty: Bool
    
    init(kana: String, romaji: String, row: String, col: Int, isEmpty: Bool = false) {
        self.id = isEmpty ? "empty_\(row)_\(col)" : "\(romaji)_\(kana)"
        self.kana = kana
        self.romaji = romaji
        self.row = row
        self.col = col
        self.isEmpty = isEmpty
    }
    
    static func empty(row: String, col: Int) -> KanaLetter {
        KanaLetter(kana: "", romaji: "", row: row, col: col, isEmpty: true)
    }
}

// MARK: - Kana Practice Word
struct KanaWord: Identifiable, Codable, Equatable {
    let id: Int
    let kana: String
    let romaji: String
    let meaningEn: String
    let type: KanaType
}

// MARK: - Kana Quiz Configuration
struct KanaQuizConfig: Codable, Equatable {
    var kanaType: KanaType = .hiragana
    var questionCount: Int = 10
    
    private static let userDefaultsKey = "ganbatte_saved_kana_quiz_config"
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: KanaQuizConfig.userDefaultsKey)
        }
    }
    
    static func load() -> KanaQuizConfig {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let config = try? JSONDecoder().decode(KanaQuizConfig.self, from: data) else {
            return KanaQuizConfig()
        }
        return config
    }
}

// MARK: - Kana Quiz Question
struct KanaQuizQuestion: Identifiable {
    let id = UUID()
    let word: KanaWord
    let acceptableAnswers: Set<String>
}

// MARK: - Kana Quiz Result (Per Question)
struct KanaQuizResult: Identifiable {
    let id = UUID()
    let question: KanaQuizQuestion
    let userAnswer: String
    let isCorrect: Bool
    let timeSeconds: Double
}

// MARK: - Kana Session Summary
struct KanaSessionSummary {
    let totalQuestions: Int
    let correctCount: Int
    let totalTimeSeconds: Double
    let results: [KanaQuizResult]
    
    var averageTimeSeconds: Double {
        guard totalQuestions > 0 else { return 0 }
        return totalTimeSeconds / Double(totalQuestions)
    }
    
    var score: Int {
        guard totalQuestions > 0 else { return 0 }
        return Int(round(Double(correctCount) / Double(totalQuestions) * 100))
    }
}
