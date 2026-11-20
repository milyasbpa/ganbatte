import Foundation
import AVFoundation

final class KanaDataService {
    static let shared = KanaDataService()
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    private init() {}
    
    // MARK: - Speech Synthesis
    func speak(text: String) {
        guard !text.isEmpty else { return }
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        speechSynthesizer.speak(utterance)
    }
    
    // MARK: - Gojūon Grid Generation
    func getGojuonRows(type: KanaType) -> [(rowLabel: String, letters: [KanaLetter])] {
        if type == .hiragana {
            return hiraganaGojuon
        } else {
            return katakanaGojuon
        }
    }
    
    // MARK: - Hiragana Gojūon
    private var hiraganaGojuon: [(rowLabel: String, letters: [KanaLetter])] {
        [
            ("~", [
                KanaLetter(kana: "あ", romaji: "a", row: "~", col: 0),
                KanaLetter(kana: "い", romaji: "i", row: "~", col: 1),
                KanaLetter(kana: "う", romaji: "u", row: "~", col: 2),
                KanaLetter(kana: "え", romaji: "e", row: "~", col: 3),
                KanaLetter(kana: "お", romaji: "o", row: "~", col: 4)
            ]),
            ("k~", [
                KanaLetter(kana: "か", romaji: "ka", row: "k~", col: 0),
                KanaLetter(kana: "き", romaji: "ki", row: "k~", col: 1),
                KanaLetter(kana: "く", romaji: "ku", row: "k~", col: 2),
                KanaLetter(kana: "け", romaji: "ke", row: "k~", col: 3),
                KanaLetter(kana: "こ", romaji: "ko", row: "k~", col: 4)
            ]),
            ("s~", [
                KanaLetter(kana: "さ", romaji: "sa", row: "s~", col: 0),
                KanaLetter(kana: "し", romaji: "shi", row: "s~", col: 1),
                KanaLetter(kana: "す", romaji: "su", row: "s~", col: 2),
                KanaLetter(kana: "せ", romaji: "se", row: "s~", col: 3),
                KanaLetter(kana: "そ", romaji: "so", row: "s~", col: 4)
            ]),
            ("t~", [
                KanaLetter(kana: "た", romaji: "ta", row: "t~", col: 0),
                KanaLetter(kana: "ち", romaji: "chi", row: "t~", col: 1),
                KanaLetter(kana: "つ", romaji: "tsu", row: "t~", col: 2),
                KanaLetter(kana: "て", romaji: "te", row: "t~", col: 3),
                KanaLetter(kana: "と", romaji: "to", row: "t~", col: 4)
            ]),
            ("n~", [
                KanaLetter(kana: "な", romaji: "na", row: "n~", col: 0),
                KanaLetter(kana: "に", romaji: "ni", row: "n~", col: 1),
                KanaLetter(kana: "ぬ", romaji: "nu", row: "n~", col: 2),
                KanaLetter(kana: "ね", romaji: "ne", row: "n~", col: 3),
                KanaLetter(kana: "の", romaji: "no", row: "n~", col: 4)
            ]),
            ("h~", [
                KanaLetter(kana: "は", romaji: "ha", row: "h~", col: 0),
                KanaLetter(kana: "ひ", romaji: "hi", row: "h~", col: 1),
                KanaLetter(kana: "ふ", romaji: "fu", row: "h~", col: 2),
                KanaLetter(kana: "へ", romaji: "he", row: "h~", col: 3),
                KanaLetter(kana: "ほ", romaji: "ho", row: "h~", col: 4)
            ]),
            ("m~", [
                KanaLetter(kana: "ま", romaji: "ma", row: "m~", col: 0),
                KanaLetter(kana: "み", romaji: "mi", row: "m~", col: 1),
                KanaLetter(kana: "む", romaji: "mu", row: "m~", col: 2),
                KanaLetter(kana: "め", romaji: "me", row: "m~", col: 3),
                KanaLetter(kana: "も", romaji: "mo", row: "m~", col: 4)
            ]),
            ("y~", [
                KanaLetter(kana: "や", romaji: "ya", row: "y~", col: 0),
                KanaLetter.empty(row: "y~", col: 1),
                KanaLetter(kana: "ゆ", romaji: "yu", row: "y~", col: 2),
                KanaLetter.empty(row: "y~", col: 3),
                KanaLetter(kana: "よ", romaji: "yo", row: "y~", col: 4)
            ]),
            ("r~", [
                KanaLetter(kana: "ら", romaji: "ra", row: "r~", col: 0),
                KanaLetter(kana: "り", romaji: "ri", row: "r~", col: 1),
                KanaLetter(kana: "る", romaji: "ru", row: "r~", col: 2),
                KanaLetter(kana: "れ", romaji: "re", row: "r~", col: 3),
                KanaLetter(kana: "ろ", romaji: "ro", row: "r~", col: 4)
            ]),
            ("w~", [
                KanaLetter(kana: "わ", romaji: "wa", row: "w~", col: 0),
                KanaLetter.empty(row: "w~", col: 1),
                KanaLetter.empty(row: "w~", col: 2),
                KanaLetter.empty(row: "w~", col: 3),
                KanaLetter(kana: "を", romaji: "wo", row: "w~", col: 4)
            ]),
            ("n", [
                KanaLetter(kana: "ん", romaji: "n", row: "n", col: 0),
                KanaLetter.empty(row: "n", col: 1),
                KanaLetter.empty(row: "n", col: 2),
                KanaLetter.empty(row: "n", col: 3),
                KanaLetter.empty(row: "n", col: 4)
            ])
        ]
    }
    
    // MARK: - Katakana Gojūon
    private var katakanaGojuon: [(rowLabel: String, letters: [KanaLetter])] {
        [
            ("~", [
                KanaLetter(kana: "ア", romaji: "a", row: "~", col: 0),
                KanaLetter(kana: "イ", romaji: "i", row: "~", col: 1),
                KanaLetter(kana: "ウ", romaji: "u", row: "~", col: 2),
                KanaLetter(kana: "エ", romaji: "e", row: "~", col: 3),
                KanaLetter(kana: "オ", romaji: "o", row: "~", col: 4)
            ]),
            ("k~", [
                KanaLetter(kana: "カ", romaji: "ka", row: "k~", col: 0),
                KanaLetter(kana: "キ", romaji: "ki", row: "k~", col: 1),
                KanaLetter(kana: "ク", romaji: "ku", row: "k~", col: 2),
                KanaLetter(kana: "ケ", romaji: "ke", row: "k~", col: 3),
                KanaLetter(kana: "コ", romaji: "ko", row: "k~", col: 4)
            ]),
            ("s~", [
                KanaLetter(kana: "サ", romaji: "sa", row: "s~", col: 0),
                KanaLetter(kana: "シ", romaji: "shi", row: "s~", col: 1),
                KanaLetter(kana: "ス", romaji: "su", row: "s~", col: 2),
                KanaLetter(kana: "セ", romaji: "se", row: "s~", col: 3),
                KanaLetter(kana: "ソ", romaji: "so", row: "s~", col: 4)
            ]),
            ("t~", [
                KanaLetter(kana: "タ", romaji: "ta", row: "t~", col: 0),
                KanaLetter(kana: "チ", romaji: "chi", row: "t~", col: 1),
                KanaLetter(kana: "ツ", romaji: "tsu", row: "t~", col: 2),
                KanaLetter(kana: "テ", romaji: "te", row: "t~", col: 3),
                KanaLetter(kana: "ト", romaji: "to", row: "t~", col: 4)
            ]),
            ("n~", [
                KanaLetter(kana: "ナ", romaji: "na", row: "n~", col: 0),
                KanaLetter(kana: "ニ", romaji: "ni", row: "n~", col: 1),
                KanaLetter(kana: "ヌ", romaji: "nu", row: "n~", col: 2),
                KanaLetter(kana: "ネ", romaji: "ne", row: "n~", col: 3),
                KanaLetter(kana: "ノ", romaji: "no", row: "n~", col: 4)
            ]),
            ("h~", [
                KanaLetter(kana: "ハ", romaji: "ha", row: "h~", col: 0),
                KanaLetter(kana: "ヒ", romaji: "hi", row: "h~", col: 1),
                KanaLetter(kana: "フ", romaji: "fu", row: "h~", col: 2),
                KanaLetter(kana: "ヘ", romaji: "he", row: "h~", col: 3),
                KanaLetter(kana: "ホ", romaji: "ho", row: "h~", col: 4)
            ]),
            ("m~", [
                KanaLetter(kana: "マ", romaji: "ma", row: "m~", col: 0),
                KanaLetter(kana: "ミ", romaji: "mi", row: "m~", col: 1),
                KanaLetter(kana: "ム", romaji: "mu", row: "m~", col: 2),
                KanaLetter(kana: "メ", romaji: "me", row: "m~", col: 3),
                KanaLetter(kana: "モ", romaji: "mo", row: "m~", col: 4)
            ]),
            ("y~", [
                KanaLetter(kana: "ヤ", romaji: "ya", row: "y~", col: 0),
                KanaLetter.empty(row: "y~", col: 1),
                KanaLetter(kana: "ユ", romaji: "yu", row: "y~", col: 2),
                KanaLetter.empty(row: "y~", col: 3),
                KanaLetter(kana: "ヨ", romaji: "yo", row: "y~", col: 4)
            ]),
            ("r~", [
                KanaLetter(kana: "ラ", romaji: "ra", row: "r~", col: 0),
                KanaLetter(kana: "リ", romaji: "ri", row: "r~", col: 1),
                KanaLetter(kana: "ル", romaji: "ru", row: "r~", col: 2),
                KanaLetter(kana: "レ", romaji: "re", row: "r~", col: 3),
                KanaLetter(kana: "ロ", romaji: "ro", row: "r~", col: 4)
            ]),
            ("w~", [
                KanaLetter(kana: "ワ", romaji: "wa", row: "w~", col: 0),
                KanaLetter.empty(row: "w~", col: 1),
                KanaLetter.empty(row: "w~", col: 2),
                KanaLetter.empty(row: "w~", col: 3),
                KanaLetter(kana: "ヲ", romaji: "wo", row: "w~", col: 4)
            ]),
            ("n", [
                KanaLetter(kana: "ン", romaji: "n", row: "n", col: 0),
                KanaLetter.empty(row: "n", col: 1),
                KanaLetter.empty(row: "n", col: 2),
                KanaLetter.empty(row: "n", col: 3),
                KanaLetter.empty(row: "n", col: 4)
            ])
        ]
    }
    
    // MARK: - Romaji Acceptable Answers
    func generateAcceptableAnswers(for rawRomaji: String) -> Set<String> {
        var results = Set<String>()
        let clean = rawRomaji.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        results.insert(clean)
        
        let noSpaces = clean.replacingOccurrences(of: " ", with: "")
        results.insert(noSpaces)
        
        let withDashes = clean
            .replacingOccurrences(of: "aa", with: "a-")
            .replacingOccurrences(of: "ii", with: "i-")
            .replacingOccurrences(of: "uu", with: "u-")
            .replacingOccurrences(of: "ee", with: "e-")
            .replacingOccurrences(of: "oo", with: "o-")
            .replacingOccurrences(of: "ou", with: "o-")
        results.insert(withDashes)
        results.insert(withDashes.replacingOccurrences(of: "-", with: ""))
        
        let fromDashes = clean
            .replacingOccurrences(of: "a-", with: "aa")
            .replacingOccurrences(of: "i-", with: "ii")
            .replacingOccurrences(of: "u-", with: "uu")
            .replacingOccurrences(of: "e-", with: "ee")
            .replacingOccurrences(of: "o-", with: "oo")
        results.insert(fromDashes)
        
        for item in Array(results) {
            results.insert(item.replacingOccurrences(of: "shi", with: "si"))
            results.insert(item.replacingOccurrences(of: "si", with: "shi"))
            results.insert(item.replacingOccurrences(of: "chi", with: "ti"))
            results.insert(item.replacingOccurrences(of: "ti", with: "chi"))
            results.insert(item.replacingOccurrences(of: "tsu", with: "tu"))
            results.insert(item.replacingOccurrences(of: "tu", with: "tsu"))
            results.insert(item.replacingOccurrences(of: "fu", with: "hu"))
            results.insert(item.replacingOccurrences(of: "hu", with: "fu"))
            results.insert(item.replacingOccurrences(of: "ji", with: "zi"))
            results.insert(item.replacingOccurrences(of: "zi", with: "ji"))
        }
        return results
    }
    
    // MARK: - Quiz Generation
    func generateQuiz(config: KanaQuizConfig) -> [KanaQuizQuestion] {
        let pool = DatabaseService.shared.fetchKanaPracticeWords(
            type: config.kanaType,
            limit: config.kanaType == .hiragana ? 1000 : 500
        )
        guard !pool.isEmpty else { return [] }
        
        let shuffled = pool.shuffled()
        let count = min(config.questionCount, shuffled.count)
        let selectedWords = Array(shuffled.prefix(count))
        
        return selectedWords.map { word in
            let acceptable = generateAcceptableAnswers(for: word.romaji)
            return KanaQuizQuestion(word: word, acceptableAnswers: acceptable)
        }
    }
    
    // MARK: - Targeted Kana Mistake Quiz Generation
    func generateMistakeQuiz(characters: [String], type: KanaType? = nil, count: Int = 10) -> [KanaQuizQuestion] {
        guard !characters.isEmpty else { return [] }
        
        var words = DatabaseService.shared.fetchKanaWordsContaining(
            characters: characters,
            type: type,
            limit: 500
        )
        
        // If pool is empty or tiny, fallback to general kana words
        if words.isEmpty {
            words = DatabaseService.shared.fetchKanaPracticeWords(
                type: type ?? .hiragana,
                limit: 100
            )
        }
        
        guard !words.isEmpty else { return [] }
        
        var selectedWords: [KanaWord] = []
        let shuffled = words.shuffled()
        
        while selectedWords.count < count {
            for word in shuffled {
                selectedWords.append(word)
                if selectedWords.count >= count { break }
            }
        }
        
        return selectedWords.map { word in
            let acceptable = generateAcceptableAnswers(for: word.romaji)
            return KanaQuizQuestion(word: word, acceptableAnswers: acceptable)
        }
    }
}
