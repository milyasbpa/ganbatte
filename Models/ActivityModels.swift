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
        averagePaceSeconds: Double
    ) {
        self.id = id
        self.date = date
        self.practiceType = practiceType
        self.questionCount = questionCount
        self.correctCount = correctCount
        self.totalDurationSeconds = totalDurationSeconds
        self.averagePaceSeconds = averagePaceSeconds
    }
}

// MARK: - Medal Tier & Category
enum MedalTier: String, Codable {
    case bronze
    case silver
    case gold
    case platinum
    
    var color: Color {
        switch self {
        case .bronze: return Color(red: 0.80, green: 0.50, blue: 0.20)
        case .silver: return Color(red: 0.65, green: 0.70, blue: 0.78)
        case .gold: return Color(red: 0.96, green: 0.73, blue: 0.15)
        case .platinum: return Color(red: 0.35, green: 0.75, blue: 0.85)
        }
    }
}

enum MedalCategory: String, Codable {
    case speed = "Speed"
    case streak = "Streak"
    case accuracy = "Accuracy"
    case volume = "Volume"
}

// MARK: - Medal Definition
struct Medal: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String // SF Symbol
    let category: MedalCategory
    let tier: MedalTier
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
