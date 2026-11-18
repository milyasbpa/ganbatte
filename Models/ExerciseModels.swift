import Foundation
import SwiftUI

// MARK: - Question Type
enum QuestionType: String, CaseIterable, Identifiable {
    case image = "Image"
    case sound = "Sound"
    case sentence = "Sentence"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .image: return "Image"
        case .sound: return "Audio"
        case .sentence: return "Fill in the Blank"
        }
    }
    
    var subtitle: String {
        switch self {
        case .image: return "Guess the word from the image"
        case .sound: return "Guess the word from the audio"
        case .sentence: return "Complete the sentence with the missing word"
        }
    }
    
    var iconName: String {
        switch self {
        case .image: return "photo.fill"
        case .sound: return "speaker.wave.2.fill"
        case .sentence: return "text.quote"
        }
    }
}

// MARK: - Quiz Configuration
struct QuizConfig: Equatable {
    var level: JLPTLevel = .all
    var type: WordType = .all
    var questionType: QuestionType = .image
    var questionCount: Int = 10
}

// MARK: - Quiz Question
struct QuizQuestion: Identifiable {
    let id: UUID = UUID()
    let questionNumber: Int
    let targetWord: Word
    let options: [Word]
    let correctIndex: Int
    let questionType: QuestionType
    
    // Masked sentence for Fill-in-the-blank
    var maskedSentenceJa: String {
        let kanji = targetWord.kanji
        let kana = targetWord.kana
        var sentence = targetWord.exampleJa
        
        if !kanji.isEmpty && sentence.contains(kanji) {
            sentence = sentence.replacingOccurrences(of: kanji, with: " [ ______ ] ")
        } else if sentence.contains(kana) {
            sentence = sentence.replacingOccurrences(of: kana, with: " [ ______ ] ")
        } else {
            sentence = "[ ______ ] " + sentence
        }
        return sentence
    }
}

// MARK: - Question Result
struct QuestionResult: Identifiable {
    let id: UUID = UUID()
    let question: QuizQuestion
    let selectedIndex: Int
    let isCorrect: Bool
    let timeSpent: TimeInterval // Pure response time in seconds
}

// MARK: - Quiz Session Summary
struct QuizSessionResult {
    let results: [QuestionResult]
    let config: QuizConfig
    
    var totalQuestions: Int {
        max(results.count, 1)
    }
    
    var correctCount: Int {
        results.filter { $0.isCorrect }.count
    }
    
    // Score out of 100 without rounding
    var rawScore: Double {
        (Double(correctCount) / Double(totalQuestions)) * 100.0
    }
    
    var formattedScore: String {
        if rawScore.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", rawScore)
        } else {
            return String(format: "%.2f", rawScore)
        }
    }
    
    var totalTime: TimeInterval {
        results.reduce(0) { $0 + $1.timeSpent }
    }
    
    var averageTime: TimeInterval {
        totalTime / Double(totalQuestions)
    }
    
    var slowestResultId: UUID? {
        results.max(by: { $0.timeSpent < $1.timeSpent })?.id
    }
}
