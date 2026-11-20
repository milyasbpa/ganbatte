import Foundation
import SwiftUI

// MARK: - Practice Type
enum PracticeType: String, Codable, CaseIterable {
    case vocabulary = "Vocabulary"
    case kana = "Kana"
    
    var iconName: String {
        switch self {
        case .vocabulary: return "text.book.closed.fill"
        case .kana: return "character.bubble.fill"
        }
    }
}

// MARK: - Completed Session Record
struct SessionRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let practiceType: PracticeType
    let questionCount: Int
    let correctCount: Int
    let totalDurationSeconds: Double
    let averagePaceSeconds: Double // Average seconds per question/word
    
    // Detailed Breakdown Telemetry (Optional for backward compatibility)
    var level: JLPTLevel?
    var wordType: WordType?
    var kanaType: KanaType?
    var correctWordIds: [Int]?
    
    var accuracyPercentage: Double {
        guard questionCount > 0 else { return 0 }
        return (Double(correctCount) / Double(questionCount)) * 100.0
    }
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        practiceType: PracticeType,
        questionCount: Int,
        correctCount: Int,
        totalDurationSeconds: Double,
        averagePaceSeconds: Double,
        level: JLPTLevel? = nil,
        wordType: WordType? = nil,
        kanaType: KanaType? = nil,
        correctWordIds: [Int]? = nil
    ) {
        self.id = id
        self.date = date
        self.practiceType = practiceType
        self.questionCount = questionCount
        self.correctCount = correctCount
        self.totalDurationSeconds = totalDurationSeconds
        self.averagePaceSeconds = averagePaceSeconds
        self.level = level
        self.wordType = wordType
        self.kanaType = kanaType
        self.correctWordIds = correctWordIds
    }
}

// MARK: - Medal Tier & Category
enum MedalTier: String, Codable {
    case bronze
    case silver
    case gold
    case platinum
    case diamond
    
    var color: Color {
        switch self {
        case .bronze: return Color(red: 0.80, green: 0.50, blue: 0.20)
        case .silver: return Color(red: 0.65, green: 0.70, blue: 0.78)
        case .gold: return Color(red: 0.96, green: 0.73, blue: 0.15)
        case .platinum: return Color(red: 0.35, green: 0.75, blue: 0.85)
        case .diamond: return Color(red: 0.65, green: 0.40, blue: 0.95)
        }
    }
    
    var title: String {
        rawValue.capitalized
    }
}

enum MedalCategory: String, Codable, CaseIterable {
    case all = "All"
    case n5 = "N5"
    case n4 = "N4"
    case n3 = "N3"
    case n2 = "N2"
    case n1 = "N1"
    case kana = "Kana"
    case habits = "Habits"
}

enum MedalAxis: String, Codable {
    case skill = "Skill"
    case coverage = "Coverage"
    case habit = "Habit"
}

// MARK: - Medal Definition
struct Medal: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String // SF Symbol
    let category: MedalCategory
    let tier: MedalTier
    var axis: MedalAxis = .skill
    var isUnlocked: Bool = false
    var unlockedDate: Date? = nil
}

// MARK: - Daily Volume for Charts
struct DayVolume: Identifiable {
    let id = UUID()
    let dayLabel: String // "M", "T", "W", "T", "F", "S", "S"
    let fullDate: Date
    let minutes: Double
    let isToday: Bool
    let hasCompletedSession: Bool
}

// MARK: - Diagnostic Metrics Models
struct WordTypeDiagnostic: Identifiable {
    var id: String { type.rawValue }
    let type: WordType
    let totalQuestions: Int
    let correctCount: Int
    let averagePace: Double
    
    var accuracyPercentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return (Double(correctCount) / Double(totalQuestions)) * 100.0
    }
}

struct KanaScriptDiagnostic {
    let script: KanaType
    let totalQuestions: Int
    let correctCount: Int
    let averagePace: Double
    
    var accuracyPercentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return (Double(correctCount) / Double(totalQuestions)) * 100.0
    }
}

struct LevelMasteryInfo: Identifiable {
    var id: String { level.rawValue }
    let level: JLPTLevel
    let uniqueCorrectWords: Int
    let totalWords: Int
    let nounMastered: Bool
    let adjMastered: Bool
    let verbMastered: Bool
    let allMastered: Bool
    
    var coveragePercentage: Double {
        guard totalWords > 0 else { return 0 }
        return min(100.0, (Double(uniqueCorrectWords) / Double(totalWords)) * 100.0)
    }
}
