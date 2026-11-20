import Foundation

enum JLPTLevel: String, CaseIterable, Identifiable, Hashable, Codable {
    case all = "All"
    case n5 = "N5"
    case n4 = "N4"
    case n3 = "N3"
    case n2 = "N2"
    case n1 = "N1"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .all: return "All"
        case .n5: return "First steps"
        case .n4: return "Basics"
        case .n3: return "Pre-intermediate"
        case .n2: return "Intermediate"
        case .n1: return "Advanced"
        }
    }
    
    var subtitle: String? {
        switch self {
        case .all: return nil
        case .n5: return "JLPT N5 level"
        case .n4: return "JLPT N4 level"
        case .n3: return "JLPT N3 level"
        case .n2: return "JLPT N2 level"
        case .n1: return "JLPT N1 level"
        }
    }
}

enum WordType: String, CaseIterable, Identifiable, Hashable, Codable {
    case all = "All"
    case noun = "Noun"
    case verb = "Verb"
    case adjective = "Adjective"
    
    var id: String { rawValue }
    
    var title: String { rawValue }
}

struct Word: Identifiable, Hashable {
    let id: Int
    let level: String
    let type: String
    let cardNumber: Int
    let kanji: String
    let kana: String
    let romaji: String
    let meaningEn: String
    let meaningJa: String
    let exampleJa: String
    let exampleEn: String
    let imageName: String
    
    var jlptLevel: JLPTLevel {
        JLPTLevel(rawValue: level) ?? .n5
    }
    
    var wordType: WordType {
        WordType(rawValue: type) ?? .noun
    }
}
