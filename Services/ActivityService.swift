import Foundation
import SwiftUI
import Combine

class ActivityService: ObservableObject {
    static let shared = ActivityService()
    
    private let sessionsStorageKey = "ganbatte_activity_sessions_v1"
    private let unlockedMedalsStorageKey = "ganbatte_unlocked_medals_v1"
    private let uniqueWordsStorageKey = "ganbatte_unique_correct_words_v1"
    private let activeWordMistakesKey = "ganbatte_active_word_mistakes_v1"
    private let activeKanaMistakesKey = "ganbatte_active_kana_mistakes_v1"
    
    static let totalWordsPerLevel: [JLPTLevel: Int] = [
        .n5: 530,
        .n4: 521,
        .n3: 1818,
        .n2: 1398,
        .n1: 2435,
        .all: 6702
    ]
    
    @Published var sessions: [SessionRecord] = []
    @Published var medals: [Medal] = []
    @Published var newlyUnlockedMedal: Medal? = nil
    @Published var uniqueCorrectWordsByLevel: [String: Set<Int>] = [:]
    @Published var activeWordMistakes: [WordMistakeEntry] = []
    @Published var activeKanaMistakes: [KanaMistakeEntry] = []
    @Published var pendingMistakeWorkoutWordIds: [Int]? = nil
    @Published var pendingKanaMistakeWorkoutCharacters: [String]? = nil
    
    private init() {
        loadSessions()
        loadUniqueCorrectWords()
        loadMistakes()
        initMedals()
    }
    
    // MARK: - Initial Medals Catalog (Master Dual-Axis Suite)
    private func initMedals() {
        var catalog: [Medal] = []
        
        // 1. JLPT N5 Medals (530 words)
        catalog.append(contentsOf: [
            Medal(id: "n5_noun_ace", title: "N5 Noun Explorer", description: "Score ≥90% with pace <1.5s on 10+ Nouns", icon: "cube.fill", category: .n5, tier: .bronze, axis: .skill),
            Medal(id: "n5_adj_ace", title: "N5 Adjective Scout", description: "Score ≥90% with pace <1.6s on 10+ Adjectives", icon: "paintbrush.fill", category: .n5, tier: .bronze, axis: .skill),
            Medal(id: "n5_verb_ace", title: "N5 Verb Novice", description: "Score ≥90% with pace <1.8s on 10+ Verbs", icon: "figure.walk", category: .n5, tier: .silver, axis: .skill),
            Medal(id: "n5_grandmaster", title: "N5 Grandmaster", description: "Score ≥95% with pace <1.3s on 20+ Mixed N5 words", icon: "crown.fill", category: .n5, tier: .gold, axis: .skill),
            Medal(id: "n5_cov_25", title: "N5 First Strides", description: "Answer 25 unique N5 words correctly", icon: "1.circle.fill", category: .n5, tier: .bronze, axis: .coverage),
            Medal(id: "n5_cov_50", title: "N5 Gaining Momentum", description: "Answer 50 unique N5 words correctly", icon: "2.circle.fill", category: .n5, tier: .bronze, axis: .coverage),
            Medal(id: "n5_cov_100", title: "N5 Century Mark", description: "Answer 100 unique N5 words correctly", icon: "100.circle.fill", category: .n5, tier: .silver, axis: .coverage),
            Medal(id: "n5_cov_250", title: "N5 Halfway Hero", description: "Answer 250 unique N5 words correctly", icon: "star.fill", category: .n5, tier: .gold, axis: .coverage),
            Medal(id: "n5_cov_full", title: "N5 Completionist", description: "Answer all 530 unique N5 words correctly", icon: "checkmark.seal.fill", category: .n5, tier: .platinum, axis: .coverage)
        ])
        
        // 2. JLPT N4 Medals (521 words)
        catalog.append(contentsOf: [
            Medal(id: "n4_noun_ace", title: "N4 Noun Runner", description: "Score ≥90% with pace <1.4s on 10+ Nouns", icon: "cube.fill", category: .n4, tier: .bronze, axis: .skill),
            Medal(id: "n4_adj_ace", title: "N4 Adjective Sprinter", description: "Score ≥90% with pace <1.5s on 10+ Adjectives", icon: "paintbrush.fill", category: .n4, tier: .bronze, axis: .skill),
            Medal(id: "n4_verb_ace", title: "N4 Verb Strider", description: "Score ≥90% with pace <1.6s on 10+ Verbs", icon: "figure.run", category: .n4, tier: .silver, axis: .skill),
            Medal(id: "n4_grandmaster", title: "N4 Grandmaster", description: "Score ≥95% with pace <1.2s on 20+ Mixed N4 words", icon: "crown.fill", category: .n4, tier: .gold, axis: .skill),
            Medal(id: "n4_cov_25", title: "N4 First Strides", description: "Answer 25 unique N4 words correctly", icon: "1.circle.fill", category: .n4, tier: .bronze, axis: .coverage),
            Medal(id: "n4_cov_50", title: "N4 Gaining Momentum", description: "Answer 50 unique N4 words correctly", icon: "2.circle.fill", category: .n4, tier: .bronze, axis: .coverage),
            Medal(id: "n4_cov_100", title: "N4 Century Mark", description: "Answer 100 unique N4 words correctly", icon: "100.circle.fill", category: .n4, tier: .silver, axis: .coverage),
            Medal(id: "n4_cov_250", title: "N4 Halfway Hero", description: "Answer 250 unique N4 words correctly", icon: "star.fill", category: .n4, tier: .gold, axis: .coverage),
            Medal(id: "n4_cov_full", title: "N4 Completionist", description: "Answer all 521 unique N4 words correctly", icon: "checkmark.seal.fill", category: .n4, tier: .platinum, axis: .coverage)
        ])
        
        // 3. JLPT N3 Medals (1,818 words)
        catalog.append(contentsOf: [
            Medal(id: "n3_noun_ace", title: "N3 Noun Navigator", description: "Score ≥92% with pace <1.3s on 15+ Nouns", icon: "cube.fill", category: .n3, tier: .silver, axis: .skill),
            Medal(id: "n3_adj_ace", title: "N3 Adjective Specialist", description: "Score ≥92% with pace <1.4s on 15+ Adjectives", icon: "paintbrush.fill", category: .n3, tier: .silver, axis: .skill),
            Medal(id: "n3_verb_ace", title: "N3 Verb Virtuoso", description: "Score ≥92% with pace <1.5s on 15+ Verbs", icon: "bolt.fill", category: .n3, tier: .gold, axis: .skill),
            Medal(id: "n3_grandmaster", title: "N3 Grandmaster", description: "Score ≥95% with pace <1.1s on 25+ Mixed N3 words", icon: "crown.fill", category: .n3, tier: .platinum, axis: .skill),
            Medal(id: "n3_cov_50", title: "N3 First Strides", description: "Answer 50 unique N3 words correctly", icon: "1.circle.fill", category: .n3, tier: .bronze, axis: .coverage),
            Medal(id: "n3_cov_100", title: "N3 Century Mark", description: "Answer 100 unique N3 words correctly", icon: "100.circle.fill", category: .n3, tier: .silver, axis: .coverage),
            Medal(id: "n3_cov_250", title: "N3 Solid Base", description: "Answer 250 unique N3 words correctly", icon: "star.leadinghalf.filled", category: .n3, tier: .silver, axis: .coverage),
            Medal(id: "n3_cov_500", title: "N3 Halfway Hero", description: "Answer 500 unique N3 words correctly", icon: "star.fill", category: .n3, tier: .gold, axis: .coverage),
            Medal(id: "n3_cov_full", title: "N3 Completionist", description: "Answer all 1,818 unique N3 words correctly", icon: "checkmark.seal.fill", category: .n3, tier: .platinum, axis: .coverage)
        ])
        
        // 4. JLPT N2 Medals (1,398 words)
        catalog.append(contentsOf: [
            Medal(id: "n2_noun_ace", title: "N2 Noun Scholar", description: "Score ≥92% with pace <1.2s on 15+ Nouns", icon: "cube.fill", category: .n2, tier: .silver, axis: .skill),
            Medal(id: "n2_adj_ace", title: "N2 Adjective Expert", description: "Score ≥92% with pace <1.3s on 15+ Adjectives", icon: "paintbrush.fill", category: .n2, tier: .silver, axis: .skill),
            Medal(id: "n2_verb_ace", title: "N2 Verb Commander", description: "Score ≥92% with pace <1.4s on 15+ Verbs", icon: "bolt.fill", category: .n2, tier: .gold, axis: .skill),
            Medal(id: "n2_grandmaster", title: "N2 Grandmaster", description: "Score ≥95% with pace <1.0s on 25+ Mixed N2 words", icon: "crown.fill", category: .n2, tier: .platinum, axis: .skill),
            Medal(id: "n2_cov_50", title: "N2 First Strides", description: "Answer 50 unique N2 words correctly", icon: "1.circle.fill", category: .n2, tier: .bronze, axis: .coverage),
            Medal(id: "n2_cov_100", title: "N2 Century Mark", description: "Answer 100 unique N2 words correctly", icon: "100.circle.fill", category: .n2, tier: .silver, axis: .coverage),
            Medal(id: "n2_cov_250", title: "N2 Solid Base", description: "Answer 250 unique N2 words correctly", icon: "star.leadinghalf.filled", category: .n2, tier: .silver, axis: .coverage),
            Medal(id: "n2_cov_500", title: "N2 Halfway Hero", description: "Answer 500 unique N2 words correctly", icon: "star.fill", category: .n2, tier: .gold, axis: .coverage),
            Medal(id: "n2_cov_full", title: "N2 Completionist", description: "Answer all 1,398 unique N2 words correctly", icon: "checkmark.seal.fill", category: .n2, tier: .platinum, axis: .coverage)
        ])
        
        // 5. JLPT N1 Medals (2,435 words)
        catalog.append(contentsOf: [
            Medal(id: "n1_noun_ace", title: "N1 Noun Titan", description: "Score ≥95% with pace <1.1s on 20+ Nouns", icon: "cube.fill", category: .n1, tier: .gold, axis: .skill),
            Medal(id: "n1_adj_ace", title: "N1 Adjective Sage", description: "Score ≥95% with pace <1.2s on 20+ Adjectives", icon: "paintbrush.fill", category: .n1, tier: .gold, axis: .skill),
            Medal(id: "n1_verb_ace", title: "N1 Verb Emperor", description: "Score ≥95% with pace <1.3s on 20+ Verbs", icon: "bolt.fill", category: .n1, tier: .gold, axis: .skill),
            Medal(id: "n1_grandmaster", title: "N1 Kami (神速 Master)", description: "Score 100% with pace <0.8s on 30+ Mixed N1 words", icon: "crown.fill", category: .n1, tier: .diamond, axis: .skill),
            Medal(id: "n1_cov_50", title: "N1 First Strides", description: "Answer 50 unique N1 words correctly", icon: "1.circle.fill", category: .n1, tier: .bronze, axis: .coverage),
            Medal(id: "n1_cov_100", title: "N1 Century Mark", description: "Answer 100 unique N1 words correctly", icon: "100.circle.fill", category: .n1, tier: .silver, axis: .coverage),
            Medal(id: "n1_cov_250", title: "N1 Solid Base", description: "Answer 250 unique N1 words correctly", icon: "star.leadinghalf.filled", category: .n1, tier: .silver, axis: .coverage),
            Medal(id: "n1_cov_500", title: "N1 Halfway Hero", description: "Answer 500 unique N1 words correctly", icon: "star.fill", category: .n1, tier: .gold, axis: .coverage),
            Medal(id: "n1_cov_full", title: "N1 Completionist", description: "Answer all 2,435 unique N1 words correctly", icon: "checkmark.seal.fill", category: .n1, tier: .diamond, axis: .coverage)
        ])
        
        // 6. Kana Medals (5 medals)
        catalog.append(contentsOf: [
            Medal(id: "kana_hira_elem", title: "Hiragana Elementary", description: "Score ≥90% with pace <1.8s on 10+ Hiragana", icon: "character.bubble.fill", category: .kana, tier: .bronze, axis: .skill),
            Medal(id: "kana_hira_rapid", title: "Hiragana Rapid", description: "Score ≥95% with pace <1.2s on 20+ Hiragana", icon: "hare.fill", category: .kana, tier: .silver, axis: .skill),
            Medal(id: "kana_kata_break", title: "Katakana Breakthrough", description: "Score ≥85% with pace <1.8s on 10+ Katakana", icon: "character.textbox", category: .kana, tier: .bronze, axis: .skill),
            Medal(id: "kana_kata_master", title: "Katakana Conqueror", description: "Score ≥95% with pace <1.1s on 20+ Katakana", icon: "bolt.fill", category: .kana, tier: .gold, axis: .skill),
            Medal(id: "kana_godspeed", title: "Kana Godspeed (神速)", description: "Score 100% with pace <0.8s on 20+ Mixed Kana", icon: "flame.fill", category: .kana, tier: .platinum, axis: .skill)
        ])
        
        // 7. Habits, Volume & Reflex Medals (7 medals)
        catalog.append(contentsOf: [
            Medal(id: "streak_7", title: "Week Warrior", description: "Reach a 7-day unbroken workout streak", icon: "flame.fill", category: .habits, tier: .silver, axis: .habit),
            Medal(id: "streak_14", title: "Fortnight Focus", description: "Reach a 14-day unbroken workout streak", icon: "flame.circle.fill", category: .habits, tier: .silver, axis: .habit),
            Medal(id: "streak_30", title: "Monthly Discipline", description: "Reach an unbroken 30-day streak", icon: "calendar.badge.clock", category: .habits, tier: .gold, axis: .habit),
            Medal(id: "streak_100", title: "Centurion Legend", description: "Reach an elite 100-day unbroken streak", icon: "medal.fill", category: .habits, tier: .diamond, axis: .habit),
            Medal(id: "vol_500", title: "Dedicated Scholar", description: "Answer 500 total questions", icon: "graduationcap.fill", category: .habits, tier: .silver, axis: .habit),
            Medal(id: "vol_1000", title: "Vocabulary Titan", description: "Answer 1,000 total questions", icon: "trophy.fill", category: .habits, tier: .gold, axis: .habit),
            Medal(id: "reflex_sub1", title: "Sub-Second Reflex", description: "Score 100% with pace <1.0s on 10+ questions", icon: "bolt.shield.fill", category: .habits, tier: .platinum, axis: .skill)
        ])
        
        let unlockedDict = (UserDefaults.standard.dictionary(forKey: unlockedMedalsStorageKey) as? [String: Double]) ?? [:]
        
        self.medals = catalog.map { medal in
            var m = medal
            if let timestamp = unlockedDict[medal.id] {
                m.isUnlocked = true
                m.unlockedDate = Date(timeIntervalSince1970: timestamp)
            }
            return m
        }
    }
    
    // MARK: - Persistence
    private func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: sessionsStorageKey),
              let decoded = try? JSONDecoder().decode([SessionRecord].self, from: data) else {
            self.sessions = []
            return
        }
        self.sessions = decoded.sorted(by: { $0.date < $1.date })
    }
    
    private func saveSessionsLocallyOnly() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsStorageKey)
        }
    }
    
    private func saveSessions() {
        saveSessionsLocallyOnly()
        syncWithCloud()
    }
    
    private func saveUnlockedMedalsLocallyOnly() {
        var dict: [String: Double] = [:]
        for m in medals where m.isUnlocked {
            dict[m.id] = (m.unlockedDate ?? Date()).timeIntervalSince1970
        }
        UserDefaults.standard.set(dict, forKey: unlockedMedalsStorageKey)
    }
    
    private func saveUnlockedMedals() {
        saveUnlockedMedalsLocallyOnly()
        syncWithCloud()
    }
    
    var unlockedMedalsDictionary: [String: Double] {
        var dict: [String: Double] = [:]
        for m in medals where m.isUnlocked {
            dict[m.id] = (m.unlockedDate ?? Date()).timeIntervalSince1970
        }
        return dict
    }
    
    var uniqueCorrectWordsDictionary: [String: [Int]] {
        var toSave: [String: [Int]] = [:]
        for (key, set) in uniqueCorrectWordsByLevel {
            toSave[key] = Array(set)
        }
        return toSave
    }
    
    private func loadUniqueCorrectWords() {
        if let dict = UserDefaults.standard.dictionary(forKey: uniqueWordsStorageKey) as? [String: [Int]] {
            var loaded: [String: Set<Int>] = [:]
            for (key, list) in dict {
                loaded[key] = Set(list)
            }
            self.uniqueCorrectWordsByLevel = loaded
        }
    }
    
    private func saveUniqueCorrectWordsLocallyOnly() {
        UserDefaults.standard.set(uniqueCorrectWordsDictionary, forKey: uniqueWordsStorageKey)
    }
    
    private func saveUniqueCorrectWords() {
        saveUniqueCorrectWordsLocallyOnly()
        syncWithCloud()
    }
    
    // MARK: - Mistake Bank Persistence & Helpers
    private func loadMistakes() {
        if let data = UserDefaults.standard.data(forKey: activeWordMistakesKey),
           let decoded = try? JSONDecoder().decode([WordMistakeEntry].self, from: data) {
            self.activeWordMistakes = decoded
        }
        if let data = UserDefaults.standard.data(forKey: activeKanaMistakesKey),
           let decoded = try? JSONDecoder().decode([KanaMistakeEntry].self, from: data) {
            self.activeKanaMistakes = decoded
        }
    }
    
    private func saveWordMistakesLocallyOnly() {
        if let data = try? JSONEncoder().encode(activeWordMistakes) {
            UserDefaults.standard.set(data, forKey: activeWordMistakesKey)
        }
    }
    
    func saveWordMistakes() {
        saveWordMistakesLocallyOnly()
        syncWithCloud()
    }
    
    private func saveKanaMistakesLocallyOnly() {
        if let data = try? JSONEncoder().encode(activeKanaMistakes) {
            UserDefaults.standard.set(data, forKey: activeKanaMistakesKey)
        }
    }
    
    func saveKanaMistakes() {
        saveKanaMistakesLocallyOnly()
        syncWithCloud()
    }
    
    private func syncWithCloud() {
        CloudSyncService.shared.pushLocalToCloud(
            sessions: sessions,
            medalsDict: unlockedMedalsDictionary,
            uniqueWordsDict: uniqueCorrectWordsDictionary,
            wordMistakes: activeWordMistakes,
            kanaMistakes: activeKanaMistakes
        )
    }
    
    // MARK: - Intelligent Multi-Device Cloud Merge
    func mergeIncomingSyncData(
        remoteSessions: [SessionRecord]?,
        remoteMedals: [String: Double]?,
        remoteUniqueWords: [String: [Int]]?,
        remoteWordMistakes: [WordMistakeEntry]?,
        remoteKanaMistakes: [KanaMistakeEntry]?
    ) {
        // 1. Merge Sessions
        if let incoming = remoteSessions, !incoming.isEmpty {
            var existingMap = Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0) })
            for session in incoming {
                if existingMap[session.id] == nil {
                    existingMap[session.id] = session
                }
            }
            self.sessions = Array(existingMap.values).sorted(by: { $0.date < $1.date })
            saveSessionsLocallyOnly()
        }
        
        // 2. Merge Unlocked Medals
        if let incomingMedals = remoteMedals, !incomingMedals.isEmpty {
            for i in 0..<medals.count {
                let id = medals[i].id
                if let remoteTime = incomingMedals[id] {
                    if !medals[i].isUnlocked {
                        medals[i].isUnlocked = true
                        medals[i].unlockedDate = Date(timeIntervalSince1970: remoteTime)
                    } else if let localDate = medals[i].unlockedDate, localDate.timeIntervalSince1970 > remoteTime {
                        medals[i].unlockedDate = Date(timeIntervalSince1970: remoteTime)
                    }
                }
            }
            saveUnlockedMedalsLocallyOnly()
        }
        
        // 3. Merge Unique Words
        if let incomingWords = remoteUniqueWords, !incomingWords.isEmpty {
            for (level, list) in incomingWords {
                let currentSet = uniqueCorrectWordsByLevel[level] ?? []
                let newSet = currentSet.union(Set(list))
                uniqueCorrectWordsByLevel[level] = newSet
            }
            saveUniqueCorrectWordsLocallyOnly()
        }
        
        // 4. Merge Word Mistakes
        if let incomingMistakes = remoteWordMistakes, !incomingMistakes.isEmpty {
            var localMap = Dictionary(uniqueKeysWithValues: activeWordMistakes.map { ($0.wordId, $0) })
            for remote in incomingMistakes {
                if let local = localMap[remote.wordId] {
                    let isResolved = local.isResolved || remote.isResolved
                    let cleanCount = max(local.consecutiveCleanCount, remote.consecutiveCleanCount)
                    let failCount = max(local.failCount, remote.failCount)
                    let latestFailed = max(local.lastFailedAt, remote.lastFailedAt)
                    
                    var merged = local
                    merged.isResolved = isResolved
                    merged.consecutiveCleanCount = cleanCount
                    merged.failCount = failCount
                    merged.lastFailedAt = latestFailed
                    localMap[remote.wordId] = merged
                } else {
                    localMap[remote.wordId] = remote
                }
            }
            self.activeWordMistakes = Array(localMap.values).sorted(by: { $0.lastFailedAt > $1.lastFailedAt })
            saveWordMistakesLocallyOnly()
        }
        
        // 5. Merge Kana Mistakes
        if let incomingKana = remoteKanaMistakes, !incomingKana.isEmpty {
            var localMap = Dictionary(uniqueKeysWithValues: activeKanaMistakes.map { ("\($0.character)_\($0.script.rawValue)", $0) })
            for remote in incomingKana {
                let key = "\(remote.character)_\(remote.script.rawValue)"
                if let local = localMap[key] {
                    let isResolved = local.isResolved || remote.isResolved
                    let cleanCount = max(local.consecutiveCleanCount, remote.consecutiveCleanCount)
                    let failCount = max(local.failCount, remote.failCount)
                    let slowCount = max(local.slowCount, remote.slowCount)
                    let latestFailed = max(local.lastFailedAt, remote.lastFailedAt)
                    
                    var merged = local
                    merged.isResolved = isResolved
                    merged.consecutiveCleanCount = cleanCount
                    merged.failCount = failCount
                    merged.slowCount = slowCount
                    merged.lastFailedAt = latestFailed
                    localMap[key] = merged
                } else {
                    localMap[key] = remote
                }
            }
            self.activeKanaMistakes = Array(localMap.values).sorted(by: { $0.lastFailedAt > $1.lastFailedAt })
            saveKanaMistakesLocallyOnly()
        }
    }
    
    var unresolvedWordMistakes: [WordMistakeEntry] {
        activeWordMistakes.filter { !$0.isResolved }
    }
    
    var unresolvedWordMistakesCount: Int {
        unresolvedWordMistakes.count
    }
    
    var unresolvedKanaMistakes: [KanaMistakeEntry] {
        activeKanaMistakes.filter { !$0.isResolved }
    }
    
    var unresolvedKanaMistakesCount: Int {
        unresolvedKanaMistakes.count
    }
    
    func clearWordMistake(wordId: Int) {
        if let index = activeWordMistakes.firstIndex(where: { $0.wordId == wordId }) {
            activeWordMistakes[index].isResolved = true
            saveWordMistakes()
        }
    }
    
    func clearKanaMistake(character: String, script: KanaType) {
        if let index = activeKanaMistakes.firstIndex(where: { $0.character == character && $0.script == script }) {
            activeKanaMistakes[index].isResolved = true
            saveKanaMistakes()
        }
    }
    
    func resetAllMistakes() {
        activeWordMistakes.removeAll()
        activeKanaMistakes.removeAll()
        pendingMistakeWorkoutWordIds = nil
        pendingKanaMistakeWorkoutCharacters = nil
        saveWordMistakes()
        saveKanaMistakes()
    }
    
    // MARK: - Mistake Workout Navigation
    func triggerMistakeWorkout(wordIds: [Int]) {
        self.pendingMistakeWorkoutWordIds = wordIds
        NotificationCenter.default.post(
            name: NSNotification.Name("ganbatte_shortcut_to_mistakes"),
            object: nil,
            userInfo: ["wordIds": wordIds]
        )
    }
    
    func clearPendingMistakeWorkout() {
        self.pendingMistakeWorkoutWordIds = nil
    }
    
    func triggerKanaMistakeWorkout(characters: [String]) {
        self.pendingKanaMistakeWorkoutCharacters = characters
        NotificationCenter.default.post(
            name: NSNotification.Name("ganbatte_shortcut_to_kana_mistakes"),
            object: nil,
            userInfo: ["characters": characters]
        )
    }
    
    func clearPendingKanaMistakeWorkout() {
        self.pendingKanaMistakeWorkoutCharacters = nil
    }
    
    // MARK: - Unique Correct Word Tracking
    func recordCorrectWords(level: JLPTLevel, wordIds: [Int]) {
        guard level != .all, !wordIds.isEmpty else { return }
        let key = level.rawValue
        var set = uniqueCorrectWordsByLevel[key] ?? Set<Int>()
        let beforeCount = set.count
        set.formUnion(wordIds)
        if set.count > beforeCount {
            uniqueCorrectWordsByLevel[key] = set
            saveUniqueCorrectWords()
        }
    }
    
    func countUniqueCorrect(level: JLPTLevel) -> Int {
        if level == .all {
            return uniqueCorrectWordsByLevel.values.reduce(0) { $0 + $1.count }
        }
        return uniqueCorrectWordsByLevel[level.rawValue]?.count ?? 0
    }
    
    func coveragePercentage(level: JLPTLevel) -> Double {
        let total = ActivityService.totalWordsPerLevel[level] ?? 500
        guard total > 0 else { return 0 }
        let count = countUniqueCorrect(level: level)
        return min(100.0, (Double(count) / Double(total)) * 100.0)
    }
    
    func isMedalUnlocked(id: String) -> Bool {
        medals.first(where: { $0.id == id })?.isUnlocked ?? false
    }
    
    func levelMasteryInfo(level: JLPTLevel) -> LevelMasteryInfo {
        let count = countUniqueCorrect(level: level)
        let total = ActivityService.totalWordsPerLevel[level] ?? 500
        
        let prefix = level.rawValue.lowercased()
        let nounMastered = isMedalUnlocked(id: "\(prefix)_noun_ace")
        let adjMastered = isMedalUnlocked(id: "\(prefix)_adj_ace")
        let verbMastered = isMedalUnlocked(id: "\(prefix)_verb_ace")
        let allMastered = isMedalUnlocked(id: "\(prefix)_grandmaster")
        
        return LevelMasteryInfo(
            level: level,
            uniqueCorrectWords: count,
            totalWords: total,
            nounMastered: nounMastered,
            adjMastered: adjMastered,
            verbMastered: verbMastered,
            allMastered: allMastered
        )
    }
    
    var allLevelsMastery: [LevelMasteryInfo] {
        [JLPTLevel.n5, .n4, .n3, .n2, .n1].map { levelMasteryInfo(level: $0) }
    }
    
    // MARK: - Record Word Quiz Session
    func recordWordSession(_ result: QuizSessionResult) {
        guard result.totalQuestions > 0 else { return }
        
        // Extract word IDs that were answered CORRECTLY and INCORRECTLY
        let correctIds = result.results.filter { $0.isCorrect }.map { $0.question.targetWord.id }
        let incorrectIds = result.results.filter { !$0.isCorrect }.map { $0.question.targetWord.id }
        
        // Update Mistake Bank with Dual-Key Graduation rule (Option 1)
        for item in result.results {
            let word = item.question.targetWord
            let isCorrect = item.isCorrect
            let pace = item.timeSpent
            
            if !isCorrect {
                // Incorrect answer: record or reset clean streak
                if let index = activeWordMistakes.firstIndex(where: { $0.wordId == word.id }) {
                    activeWordMistakes[index].failCount += 1
                    activeWordMistakes[index].consecutiveCleanCount = 0
                    activeWordMistakes[index].lastFailedAt = Date()
                    activeWordMistakes[index].isResolved = false
                } else {
                    let entry = WordMistakeEntry(
                        wordId: word.id,
                        level: word.jlptLevel,
                        wordType: word.wordType,
                        failCount: 1,
                        consecutiveCleanCount: 0,
                        lastFailedAt: Date(),
                        isResolved: false
                    )
                    activeWordMistakes.append(entry)
                }
            } else {
                // Correct answer: check if it's an active mistake
                if let index = activeWordMistakes.firstIndex(where: { $0.wordId == word.id && !$0.isResolved }) {
                    if pace <= 2.5 {
                        // Clean automatic recall under 2.5 seconds
                        activeWordMistakes[index].consecutiveCleanCount += 1
                        if activeWordMistakes[index].consecutiveCleanCount >= 2 {
                            activeWordMistakes[index].isResolved = true // Dual-Key graduation!
                        }
                    }
                    // If pace > 2.5s, clean streak is preserved without incrementing (hesitation)
                }
            }
        }
        saveWordMistakes()
        
        let record = SessionRecord(
            date: Date(),
            practiceType: .vocabulary,
            questionCount: result.totalQuestions,
            correctCount: result.correctCount,
            totalDurationSeconds: result.totalTime,
            averagePaceSeconds: max(0.1, result.averageTime),
            level: result.config.level,
            wordType: result.config.type,
            kanaType: nil,
            correctWordIds: correctIds,
            incorrectWordIds: incorrectIds
        )
        
        if result.config.level != .all {
            recordCorrectWords(level: result.config.level, wordIds: correctIds)
        }
        
        addSession(record)
    }
    
    // MARK: - Record Kana Quiz Session
    func recordKanaSession(_ summary: KanaSessionSummary) {
        guard summary.totalQuestions > 0 else { return }
        
        let kanaType = summary.results.first?.question.word.type ?? .hiragana
        
        // Update Kana Mistake Bank with Dual-Key rule
        for res in summary.results {
            let char = res.question.word.kana
            let romaji = res.question.word.romaji
            let script = res.question.word.type
            let isCorrect = res.isCorrect
            let pace = res.timeSeconds
            
            if !isCorrect {
                if let index = activeKanaMistakes.firstIndex(where: { $0.character == char && $0.script == script }) {
                    activeKanaMistakes[index].failCount += 1
                    activeKanaMistakes[index].consecutiveCleanCount = 0
                    activeKanaMistakes[index].lastFailedAt = Date()
                    activeKanaMistakes[index].isResolved = false
                } else {
                    let entry = KanaMistakeEntry(
                        character: char,
                        romaji: romaji,
                        script: script,
                        failCount: 1,
                        slowCount: 0,
                        consecutiveCleanCount: 0,
                        lastFailedAt: Date(),
                        isResolved: false
                    )
                    activeKanaMistakes.append(entry)
                }
            } else {
                if let index = activeKanaMistakes.firstIndex(where: { $0.character == char && $0.script == script && !$0.isResolved }) {
                    if pace <= 2.5 {
                        activeKanaMistakes[index].consecutiveCleanCount += 1
                        if activeKanaMistakes[index].consecutiveCleanCount >= 2 {
                            activeKanaMistakes[index].isResolved = true
                        }
                    } else {
                        activeKanaMistakes[index].slowCount += 1
                    }
                }
            }
        }
        saveKanaMistakes()
        
        let record = SessionRecord(
            date: Date(),
            practiceType: .kana,
            questionCount: summary.totalQuestions,
            correctCount: summary.correctCount,
            totalDurationSeconds: summary.totalTimeSeconds,
            averagePaceSeconds: max(0.1, summary.averageTimeSeconds),
            level: nil,
            wordType: nil,
            kanaType: kanaType,
            correctWordIds: nil,
            incorrectWordIds: nil
        )
        
        addSession(record)
    }
    
    private func addSession(_ record: SessionRecord) {
        sessions.append(record)
        saveSessions()
        evaluateMedals(after: record)
    }
    
    // MARK: - Diagnostics Engine
    func wordTypeDiagnostics() -> [WordTypeDiagnostic] {
        var results: [WordTypeDiagnostic] = []
        let vocabSessions = sessions.filter { $0.practiceType == .vocabulary }
        
        for type in [WordType.noun, .verb, .adjective] {
            let matching = vocabSessions.filter { $0.wordType == type }
            let totalQ = matching.reduce(0) { $0 + $1.questionCount }
            let correct = matching.reduce(0) { $0 + $1.correctCount }
            let avgPace: Double
            if !matching.isEmpty {
                avgPace = matching.reduce(0.0) { $0 + $1.averagePaceSeconds } / Double(matching.count)
            } else {
                avgPace = 0.0
            }
            results.append(
                WordTypeDiagnostic(
                    type: type,
                    totalQuestions: totalQ,
                    correctCount: correct,
                    averagePace: avgPace
                )
            )
        }
        return results
    }
    
    func kanaScriptDiagnostics() -> (hiragana: KanaScriptDiagnostic, katakana: KanaScriptDiagnostic) {
        let kanaSessions = sessions.filter { $0.practiceType == .kana }
        
        let hiraSessions = kanaSessions.filter { $0.kanaType == .hiragana || $0.kanaType == nil }
        let hiraQ = hiraSessions.reduce(0) { $0 + $1.questionCount }
        let hiraC = hiraSessions.reduce(0) { $0 + $1.correctCount }
        let hiraPace = hiraSessions.isEmpty ? 0.0 : hiraSessions.reduce(0.0) { $0 + $1.averagePaceSeconds } / Double(hiraSessions.count)
        
        let kataSessions = kanaSessions.filter { $0.kanaType == .katakana }
        let kataQ = kataSessions.reduce(0) { $0 + $1.questionCount }
        let kataC = kataSessions.reduce(0) { $0 + $1.correctCount }
        let kataPace = kataSessions.isEmpty ? 0.0 : kataSessions.reduce(0.0) { $0 + $1.averagePaceSeconds } / Double(kataSessions.count)
        
        return (
            hiragana: KanaScriptDiagnostic(script: .hiragana, totalQuestions: hiraQ, correctCount: hiraC, averagePace: hiraPace),
            katakana: KanaScriptDiagnostic(script: .katakana, totalQuestions: kataQ, correctCount: kataC, averagePace: kataPace)
        )
    }
    
    var identifiedWeakWordType: WordType? {
        let diags = wordTypeDiagnostics().filter { $0.totalQuestions >= 5 }
        guard !diags.isEmpty else { return nil }
        // Lowest accuracy, or if tied, slowest pace
        return diags.min(by: {
            if abs($0.accuracyPercentage - $1.accuracyPercentage) > 5.0 {
                return $0.accuracyPercentage < $1.accuracyPercentage
            }
            return $0.averagePace > $1.averagePace
        })?.type
    }
    
    var identifiedWeakKanaScript: KanaType? {
        let diags = kanaScriptDiagnostics()
        guard diags.hiragana.totalQuestions >= 5 || diags.katakana.totalQuestions >= 5 else { return nil }
        if diags.katakana.totalQuestions == 0 { return .katakana }
        if diags.katakana.accuracyPercentage < diags.hiragana.accuracyPercentage || diags.katakana.averagePace > diags.hiragana.averagePace + 0.4 {
            return .katakana
        }
        return nil
    }
    
    // MARK: - Medal Evaluation Engine
    private func evaluateMedals(after record: SessionRecord) {
        var unlockedNow: [Medal] = []
        let currentStreakCount = currentStreak
        let totalQuestions = totalQuestionsAnswered
        
        for index in 0..<medals.count {
            if medals[index].isUnlocked { continue }
            
            var shouldUnlock = false
            let id = medals[index].id
            
            switch id {
            // MARK: N5 Medals
            case "n5_noun_ace":
                if record.level == .n5 && record.wordType == .noun && record.questionCount >= 10 && record.accuracyPercentage >= 90.0 && record.averagePaceSeconds < 1.5 { shouldUnlock = true }
            case "n5_adj_ace":
                if record.level == .n5 && record.wordType == .adjective && record.questionCount >= 10 && record.accuracyPercentage >= 90.0 && record.averagePaceSeconds < 1.6 { shouldUnlock = true }
            case "n5_verb_ace":
                if record.level == .n5 && record.wordType == .verb && record.questionCount >= 10 && record.accuracyPercentage >= 90.0 && record.averagePaceSeconds < 1.8 { shouldUnlock = true }
            case "n5_grandmaster":
                if record.level == .n5 && (record.wordType == .all || record.wordType == nil) && record.questionCount >= 20 && record.accuracyPercentage >= 95.0 && record.averagePaceSeconds < 1.3 { shouldUnlock = true }
            case "n5_cov_25":
                if countUniqueCorrect(level: .n5) >= 25 { shouldUnlock = true }
            case "n5_cov_50":
                if countUniqueCorrect(level: .n5) >= 50 { shouldUnlock = true }
            case "n5_cov_100":
                if countUniqueCorrect(level: .n5) >= 100 { shouldUnlock = true }
            case "n5_cov_250":
                if countUniqueCorrect(level: .n5) >= 250 { shouldUnlock = true }
            case "n5_cov_full":
                if countUniqueCorrect(level: .n5) >= 530 { shouldUnlock = true }
                
            // MARK: N4 Medals
            case "n4_noun_ace":
                if record.level == .n4 && record.wordType == .noun && record.questionCount >= 10 && record.accuracyPercentage >= 90.0 && record.averagePaceSeconds < 1.4 { shouldUnlock = true }
            case "n4_adj_ace":
                if record.level == .n4 && record.wordType == .adjective && record.questionCount >= 10 && record.accuracyPercentage >= 90.0 && record.averagePaceSeconds < 1.5 { shouldUnlock = true }
            case "n4_verb_ace":
                if record.level == .n4 && record.wordType == .verb && record.questionCount >= 10 && record.accuracyPercentage >= 90.0 && record.averagePaceSeconds < 1.6 { shouldUnlock = true }
            case "n4_grandmaster":
                if record.level == .n4 && (record.wordType == .all || record.wordType == nil) && record.questionCount >= 20 && record.accuracyPercentage >= 95.0 && record.averagePaceSeconds < 1.2 { shouldUnlock = true }
            case "n4_cov_25":
                if countUniqueCorrect(level: .n4) >= 25 { shouldUnlock = true }
            case "n4_cov_50":
                if countUniqueCorrect(level: .n4) >= 50 { shouldUnlock = true }
            case "n4_cov_100":
                if countUniqueCorrect(level: .n4) >= 100 { shouldUnlock = true }
            case "n4_cov_250":
                if countUniqueCorrect(level: .n4) >= 250 { shouldUnlock = true }
            case "n4_cov_full":
                if countUniqueCorrect(level: .n4) >= 521 { shouldUnlock = true }
                
            // MARK: N3 Medals
            case "n3_noun_ace":
                if record.level == .n3 && record.wordType == .noun && record.questionCount >= 15 && record.accuracyPercentage >= 92.0 && record.averagePaceSeconds < 1.3 { shouldUnlock = true }
            case "n3_adj_ace":
                if record.level == .n3 && record.wordType == .adjective && record.questionCount >= 15 && record.accuracyPercentage >= 92.0 && record.averagePaceSeconds < 1.4 { shouldUnlock = true }
            case "n3_verb_ace":
                if record.level == .n3 && record.wordType == .verb && record.questionCount >= 15 && record.accuracyPercentage >= 92.0 && record.averagePaceSeconds < 1.5 { shouldUnlock = true }
            case "n3_grandmaster":
                if record.level == .n3 && (record.wordType == .all || record.wordType == nil) && record.questionCount >= 25 && record.accuracyPercentage >= 95.0 && record.averagePaceSeconds < 1.1 { shouldUnlock = true }
            case "n3_cov_50":
                if countUniqueCorrect(level: .n3) >= 50 { shouldUnlock = true }
            case "n3_cov_100":
                if countUniqueCorrect(level: .n3) >= 100 { shouldUnlock = true }
            case "n3_cov_250":
                if countUniqueCorrect(level: .n3) >= 250 { shouldUnlock = true }
            case "n3_cov_500":
                if countUniqueCorrect(level: .n3) >= 500 { shouldUnlock = true }
            case "n3_cov_full":
                if countUniqueCorrect(level: .n3) >= 1818 { shouldUnlock = true }
                
            // MARK: N2 Medals
            case "n2_noun_ace":
                if record.level == .n2 && record.wordType == .noun && record.questionCount >= 15 && record.accuracyPercentage >= 92.0 && record.averagePaceSeconds < 1.2 { shouldUnlock = true }
            case "n2_adj_ace":
                if record.level == .n2 && record.wordType == .adjective && record.questionCount >= 15 && record.accuracyPercentage >= 92.0 && record.averagePaceSeconds < 1.3 { shouldUnlock = true }
            case "n2_verb_ace":
                if record.level == .n2 && record.wordType == .verb && record.questionCount >= 15 && record.accuracyPercentage >= 92.0 && record.averagePaceSeconds < 1.4 { shouldUnlock = true }
            case "n2_grandmaster":
                if record.level == .n2 && (record.wordType == .all || record.wordType == nil) && record.questionCount >= 25 && record.accuracyPercentage >= 95.0 && record.averagePaceSeconds < 1.0 { shouldUnlock = true }
            case "n2_cov_50":
                if countUniqueCorrect(level: .n2) >= 50 { shouldUnlock = true }
            case "n2_cov_100":
                if countUniqueCorrect(level: .n2) >= 100 { shouldUnlock = true }
            case "n2_cov_250":
                if countUniqueCorrect(level: .n2) >= 250 { shouldUnlock = true }
            case "n2_cov_500":
                if countUniqueCorrect(level: .n2) >= 500 { shouldUnlock = true }
            case "n2_cov_full":
                if countUniqueCorrect(level: .n2) >= 1398 { shouldUnlock = true }
                
            // MARK: N1 Medals
            case "n1_noun_ace":
                if record.level == .n1 && record.wordType == .noun && record.questionCount >= 20 && record.accuracyPercentage >= 95.0 && record.averagePaceSeconds < 1.1 { shouldUnlock = true }
            case "n1_adj_ace":
                if record.level == .n1 && record.wordType == .adjective && record.questionCount >= 20 && record.accuracyPercentage >= 95.0 && record.averagePaceSeconds < 1.2 { shouldUnlock = true }
            case "n1_verb_ace":
                if record.level == .n1 && record.wordType == .verb && record.questionCount >= 20 && record.accuracyPercentage >= 95.0 && record.averagePaceSeconds < 1.3 { shouldUnlock = true }
            case "n1_grandmaster":
                if record.level == .n1 && (record.wordType == .all || record.wordType == nil) && record.questionCount >= 30 && record.accuracyPercentage >= 99.9 && record.averagePaceSeconds < 0.8 { shouldUnlock = true }
            case "n1_cov_50":
                if countUniqueCorrect(level: .n1) >= 50 { shouldUnlock = true }
            case "n1_cov_100":
                if countUniqueCorrect(level: .n1) >= 100 { shouldUnlock = true }
            case "n1_cov_250":
                if countUniqueCorrect(level: .n1) >= 250 { shouldUnlock = true }
            case "n1_cov_500":
                if countUniqueCorrect(level: .n1) >= 500 { shouldUnlock = true }
            case "n1_cov_full":
                if countUniqueCorrect(level: .n1) >= 2435 { shouldUnlock = true }
                
            // MARK: Kana Medals
            case "kana_hira_elem":
                if record.practiceType == .kana && (record.kanaType == .hiragana || record.kanaType == nil) && record.questionCount >= 10 && record.accuracyPercentage >= 90.0 && record.averagePaceSeconds < 1.8 { shouldUnlock = true }
            case "kana_hira_rapid":
                if record.practiceType == .kana && (record.kanaType == .hiragana || record.kanaType == nil) && record.questionCount >= 20 && record.accuracyPercentage >= 95.0 && record.averagePaceSeconds < 1.2 { shouldUnlock = true }
            case "kana_kata_break":
                if record.practiceType == .kana && record.kanaType == .katakana && record.questionCount >= 10 && record.accuracyPercentage >= 85.0 && record.averagePaceSeconds < 1.8 { shouldUnlock = true }
            case "kana_kata_master":
                if record.practiceType == .kana && record.kanaType == .katakana && record.questionCount >= 20 && record.accuracyPercentage >= 95.0 && record.averagePaceSeconds < 1.1 { shouldUnlock = true }
            case "kana_godspeed":
                if record.practiceType == .kana && record.questionCount >= 20 && record.accuracyPercentage >= 99.9 && record.averagePaceSeconds < 0.8 { shouldUnlock = true }
                
            // MARK: Habits & Volume
            case "streak_7":
                if currentStreakCount >= 7 { shouldUnlock = true }
            case "streak_14":
                if currentStreakCount >= 14 { shouldUnlock = true }
            case "streak_30":
                if currentStreakCount >= 30 { shouldUnlock = true }
            case "streak_100":
                if currentStreakCount >= 100 { shouldUnlock = true }
            case "vol_500":
                if totalQuestions >= 500 { shouldUnlock = true }
            case "vol_1000":
                if totalQuestions >= 1000 { shouldUnlock = true }
            case "reflex_sub1":
                if record.questionCount >= 10 && record.accuracyPercentage >= 99.9 && record.averagePaceSeconds < 1.0 { shouldUnlock = true }
                
            default:
                break
            }
            
            if shouldUnlock {
                medals[index].isUnlocked = true
                medals[index].unlockedDate = Date()
                unlockedNow.append(medals[index])
            }
        }
        
        if !unlockedNow.isEmpty {
            saveUnlockedMedals()
            newlyUnlockedMedal = unlockedNow.first
        }
    }
    
    // MARK: - Computed Strava-Style Metrics
    
    var completedSessionsCount: Int {
        sessions.count
    }
    
    var totalQuestionsAnswered: Int {
        sessions.reduce(0) { $0 + $1.questionCount }
    }
    
    var allTimePracticeTime: TimeInterval {
        sessions.reduce(0) { $0 + $1.totalDurationSeconds }
    }
    
    var todayPracticeTime: TimeInterval {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return sessions
            .filter { calendar.startOfDay(for: $0.date) == today }
            .reduce(0) { $0 + $1.totalDurationSeconds }
    }
    
    var todayQuestionsAnswered: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return sessions
            .filter { calendar.startOfDay(for: $0.date) == today }
            .reduce(0) { $0 + $1.questionCount }
    }
    
    var isTodayCompleted: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return sessions.contains { calendar.startOfDay(for: $0.date) == today }
    }
    
    /// Strictly unbroken streak (No shields, no cushions)
    var currentStreak: Int {
        guard !sessions.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let uniqueDays = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        
        var checkDay = today
        var streak = 0
        
        // If today has sessions, start checking today
        if uniqueDays.contains(today) {
            streak += 1
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return streak }
            checkDay = yesterday
        } else {
            // If today doesn't have sessions, check if yesterday had one (streak is still alive)
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
            if !uniqueDays.contains(yesterday) {
                return 0
            }
            streak += 1
            guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: yesterday) else { return streak }
            checkDay = dayBefore
        }
        
        while uniqueDays.contains(checkDay) {
            streak += 1
            guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDay) else { break }
            checkDay = prevDay
        }
        
        return streak
    }
    
    /// Average reaction pace across all workouts
    var averagePaceOverall: Double {
        guard !sessions.isEmpty else { return 0 }
        let totalPace = sessions.reduce(0.0) { $0 + $1.averagePaceSeconds }
        return totalPace / Double(sessions.count)
    }
    
    /// Benchmark label description based on average pace
    var nativeBenchmarkBracketTitle: String {
        guard averagePaceOverall > 0 else { return "Beginner" }
        if averagePaceOverall < 0.8 {
            return "Native Master (神速)"
        } else if averagePaceOverall < 1.2 {
            return "JLPT Exam-Ready Pace"
        } else if averagePaceOverall < 1.8 {
            return "Upper Elementary (SD 4–6) Pace"
        } else if averagePaceOverall < 2.5 {
            return "Lower Elementary (SD 1–3) Pace"
        } else {
            return "Toddler / Learner Pace"
        }
    }
    
    /// Personal Best pace for a session with >= 5 questions and >= 80% accuracy
    var personalBestPace: Double {
        let qualifying = sessions.filter { $0.questionCount >= 5 && $0.accuracyPercentage >= 80 }
        guard let best = qualifying.min(by: { $0.averagePaceSeconds < $1.averagePaceSeconds }) else {
            return sessions.map(\.averagePaceSeconds).min() ?? 0
        }
        return best.averagePaceSeconds
    }
    
    /// Pace trend comparing last 3 sessions against the previous 5 sessions
    var paceTrendSummary: (percentage: Double, isFaster: Bool)? {
        guard sessions.count >= 4 else { return nil }
        
        let recent = sessions.suffix(3)
        let previous = sessions.dropLast(3).suffix(5)
        
        guard !previous.isEmpty else { return nil }
        
        let recentAvg = recent.reduce(0.0) { $0 + $1.averagePaceSeconds } / Double(recent.count)
        let prevAvg = previous.reduce(0.0) { $0 + $1.averagePaceSeconds } / Double(previous.count)
        
        guard prevAvg > 0 else { return nil }
        
        let diff = ((recentAvg - prevAvg) / prevAvg) * 100.0
        let isFaster = diff < 0
        return (abs(diff), isFaster)
    }
    
    /// Weekly Volume (Mon–Sun of the current week)
    var weeklyVolume: [DayVolume] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday start
        
        let now = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return []
        }
        
        let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
        var results: [DayVolume] = []
        let today = calendar.startOfDay(for: now)
        
        for offset in 0..<7 {
            guard let dayDate = calendar.date(byAdding: .day, value: offset, to: weekInterval.start) else { continue }
            let normalizedDay = calendar.startOfDay(for: dayDate)
            
            let daySessions = sessions.filter { calendar.startOfDay(for: $0.date) == normalizedDay }
            let durationSeconds = daySessions.reduce(0.0) { $0 + $1.totalDurationSeconds }
            let minutes = durationSeconds / 60.0
            
            results.append(
                DayVolume(
                    dayLabel: dayLabels[offset],
                    fullDate: dayDate,
                    minutes: minutes,
                    isToday: normalizedDay == today,
                    hasCompletedSession: !daySessions.isEmpty
                )
            )
        }
        
        return results
    }
    
    /// Formatted practice time helper (e.g. "14m", "1h 20m")
    static func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let hours = mins / 60
        let remMins = mins % 60
        
        if hours > 0 {
            return "\(hours)h \(remMins)m"
        } else if mins > 0 {
            return "\(mins)m"
        } else {
            return "\(Int(seconds))s"
        }
    }
    
    // MARK: - Gamified Highlights & Progress Engine
    
    var recentUnlockedMedals: [Medal] {
        medals.filter(\.isUnlocked)
            .sorted(by: { ($0.unlockedDate ?? Date.distantPast) > ($1.unlockedDate ?? Date.distantPast) })
    }
    
    func medalProgress(for medal: Medal) -> MedalProgressInfo {
        if medal.isUnlocked {
            return MedalProgressInfo(
                medal: medal,
                progressRatio: 1.0,
                currentFormatted: "Done",
                targetFormatted: "Unlocked"
            )
        }
        
        let id = medal.id
        
        // 1. Coverage Medals
        if id.hasPrefix("n5_cov_") {
            let current = countUniqueCorrect(level: .n5)
            let target = coverageTarget(for: id, defaultTotal: 530)
            return MedalProgressInfo(medal: medal, progressRatio: min(1.0, Double(current) / Double(target)), currentFormatted: "\(current)", targetFormatted: "\(target) words")
        } else if id.hasPrefix("n4_cov_") {
            let current = countUniqueCorrect(level: .n4)
            let target = coverageTarget(for: id, defaultTotal: 521)
            return MedalProgressInfo(medal: medal, progressRatio: min(1.0, Double(current) / Double(target)), currentFormatted: "\(current)", targetFormatted: "\(target) words")
        } else if id.hasPrefix("n3_cov_") {
            let current = countUniqueCorrect(level: .n3)
            let target = coverageTarget(for: id, defaultTotal: 1818)
            return MedalProgressInfo(medal: medal, progressRatio: min(1.0, Double(current) / Double(target)), currentFormatted: "\(current)", targetFormatted: "\(target) words")
        } else if id.hasPrefix("n2_cov_") {
            let current = countUniqueCorrect(level: .n2)
            let target = coverageTarget(for: id, defaultTotal: 1398)
            return MedalProgressInfo(medal: medal, progressRatio: min(1.0, Double(current) / Double(target)), currentFormatted: "\(current)", targetFormatted: "\(target) words")
        } else if id.hasPrefix("n1_cov_") {
            let current = countUniqueCorrect(level: .n1)
            let target = coverageTarget(for: id, defaultTotal: 2435)
            return MedalProgressInfo(medal: medal, progressRatio: min(1.0, Double(current) / Double(target)), currentFormatted: "\(current)", targetFormatted: "\(target) words")
        }
        
        // 2. Habit & Volume Medals
        switch id {
        case "streak_7":
            return MedalProgressInfo(medal: medal, progressRatio: min(1.0, Double(currentStreak) / 7.0), currentFormatted: "\(currentStreak)", targetFormatted: "7 days")
        case "streak_14":
            return MedalProgressInfo(medal: medal, progressRatio: min(1.0, Double(currentStreak) / 14.0), currentFormatted: "\(currentStreak)", targetFormatted: "14 days")
        case "streak_30":
            return MedalProgressInfo(medal: medal, progressRatio: min(1.0, Double(currentStreak) / 30.0), currentFormatted: "\(currentStreak)", targetFormatted: "30 days")
        case "streak_100":
            return MedalProgressInfo(medal: medal, progressRatio: min(1.0, Double(currentStreak) / 100.0), currentFormatted: "\(currentStreak)", targetFormatted: "100 days")
        case "vol_500":
            return MedalProgressInfo(medal: medal, progressRatio: min(1.0, Double(totalQuestionsAnswered) / 500.0), currentFormatted: "\(totalQuestionsAnswered)", targetFormatted: "500 Qs")
        case "vol_1000":
            return MedalProgressInfo(medal: medal, progressRatio: min(1.0, Double(totalQuestionsAnswered) / 1000.0), currentFormatted: "\(totalQuestionsAnswered)", targetFormatted: "1000 Qs")
        default:
            break
        }
        
        // 3. Kana Medals
        let kanaDiags = kanaScriptDiagnostics()
        if id.hasPrefix("kana_hira") {
            let current = min(20, kanaDiags.hiragana.totalQuestions)
            let target = id == "kana_hira_rapid" ? 20 : 10
            return MedalProgressInfo(medal: medal, progressRatio: min(1.0, Double(current) / Double(target)), currentFormatted: "\(current)", targetFormatted: "\(target) Qs")
        } else if id.hasPrefix("kana_kata") {
            let current = min(20, kanaDiags.katakana.totalQuestions)
            let target = id == "kana_kata_master" ? 20 : 10
            return MedalProgressInfo(medal: medal, progressRatio: min(1.0, Double(current) / Double(target)), currentFormatted: "\(current)", targetFormatted: "\(target) Qs")
        }
        
        // 4. Default Skill/Fallback
        return MedalProgressInfo(medal: medal, progressRatio: 0.0, currentFormatted: "0", targetFormatted: "Goal")
    }
    
    private func coverageTarget(for id: String, defaultTotal: Int) -> Int {
        if id.hasSuffix("_25") { return 25 }
        if id.hasSuffix("_50") { return 50 }
        if id.hasSuffix("_100") { return 100 }
        if id.hasSuffix("_250") { return 250 }
        if id.hasSuffix("_500") { return 500 }
        if id.hasSuffix("_full") { return defaultTotal }
        return defaultTotal
    }
    
    /// Top next medals closest to being unlocked
    var nextToUnlockMedals: [MedalProgressInfo] {
        let locked = medals.filter { !$0.isUnlocked }
        guard !locked.isEmpty else { return [] }
        
        let calculated = locked.map { medalProgress(for: $0) }
        
        // Medals with progress > 0 sorted highest first
        let inProgress = calculated
            .filter { $0.progressRatio > 0.0 }
            .sorted(by: { $0.progressRatio > $1.progressRatio })
        
        if inProgress.count >= 2 {
            return Array(inProgress.prefix(2))
        }
        
        // If not enough in-progress, pad with beginner milestones (e.g. n5_cov_25, streak_7, kana_hira_elem, vol_500)
        var results = inProgress
        let priorityOrder = ["n5_cov_25", "streak_7", "kana_hira_elem", "n5_noun_ace", "vol_500", "n4_cov_25"]
        for pId in priorityOrder {
            if results.count >= 2 { break }
            if !results.contains(where: { $0.medal.id == pId }),
               let found = calculated.first(where: { $0.medal.id == pId }) {
                results.append(found)
            }
        }
        
        // If still under 2, add any locked medals
        for item in calculated {
            if results.count >= 2 { break }
            if !results.contains(where: { $0.medal.id == item.medal.id }) {
                results.append(item)
            }
        }
        
        return results
    }
    
    /// Breakdown of medals by tier
    var medalTierBreakdown: [(tier: MedalTier, unlocked: Int, total: Int)] {
        let tiers: [MedalTier] = [.bronze, .silver, .gold, .platinum, .diamond]
        return tiers.map { tier in
            let matching = medals.filter { $0.tier == tier }
            let unlocked = matching.filter(\.isUnlocked).count
            return (tier: tier, unlocked: unlocked, total: matching.count)
        }
    }
}
