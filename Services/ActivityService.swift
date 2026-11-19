import Foundation
import SwiftUI
import Combine

class ActivityService: ObservableObject {
    static let shared = ActivityService()
    
    private let sessionsStorageKey = "ganbatte_activity_sessions_v1"
    private let unlockedMedalsStorageKey = "ganbatte_unlocked_medals_v1"
    
    @Published var sessions: [SessionRecord] = []
    @Published var medals: [Medal] = []
    @Published var newlyUnlockedMedal: Medal? = nil
    
    private init() {
        loadSessions()
        initMedals()
    }
    
    // MARK: - Initial Medals Catalog
    private func initMedals() {
        let defaultCatalog: [Medal] = [
            // Speed / Pace
            Medal(
                id: "speed_quick",
                title: "Quick Reflexes",
                description: "Average pace under 3.0s in a workout",
                icon: "hare.fill",
                category: .speed,
                tier: .bronze
            ),
            Medal(
                id: "speed_lightning",
                title: "Lightning Reflex",
                description: "Average pace under 2.0s in a workout",
                icon: "bolt.fill",
                category: .speed,
                tier: .gold
            ),
            Medal(
                id: "speed_godspeed",
                title: "Godspeed",
                description: "Average pace under 1.2s in a workout",
                icon: "flame.fill",
                category: .speed,
                tier: .platinum
            ),
            
            // Streaks
            Medal(
                id: "streak_first",
                title: "First Step",
                description: "Complete your first workout session",
                icon: "figure.walk",
                category: .streak,
                tier: .bronze
            ),
            Medal(
                id: "streak_3",
                title: "On Fire",
                description: "Reach a 3-day workout streak",
                icon: "flame",
                category: .streak,
                tier: .silver
            ),
            Medal(
                id: "streak_7",
                title: "Week Warrior",
                description: "Complete a full 7-day workout streak",
                icon: "crown.fill",
                category: .streak,
                tier: .gold
            ),
            Medal(
                id: "streak_30",
                title: "Unstoppable",
                description: "Reach an incredible 30-day streak",
                icon: "medal.fill",
                category: .streak,
                tier: .platinum
            ),
            
            // Accuracy
            Medal(
                id: "acc_sharpshooter",
                title: "Sharp Mind",
                description: "Achieve 90%+ accuracy in any workout",
                icon: "scope",
                category: .accuracy,
                tier: .silver
            ),
            Medal(
                id: "acc_bullseye",
                title: "Bullseye",
                description: "100% perfect score in a workout (min 10 questions)",
                icon: "target",
                category: .accuracy,
                tier: .gold
            ),
            
            // Volume
            Medal(
                id: "vol_century",
                title: "Century Club",
                description: "Answer 100 total questions",
                icon: "100.circle.fill",
                category: .volume,
                tier: .bronze
            ),
            Medal(
                id: "vol_scholar",
                title: "Dedicated Scholar",
                description: "Answer 500 total questions",
                icon: "graduationcap.fill",
                category: .volume,
                tier: .silver
            ),
            Medal(
                id: "vol_hour",
                title: "Hour of Power",
                description: "Accumulate 60 minutes of active practice",
                icon: "timer",
                category: .volume,
                tier: .gold
            )
        ]
        
        let unlockedDict = (UserDefaults.standard.dictionary(forKey: unlockedMedalsStorageKey) as? [String: Double]) ?? [:]
        
        self.medals = defaultCatalog.map { medal in
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
    
    private func saveSessions() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: sessionsStorageKey)
        }
    }
    
    private func saveUnlockedMedals() {
        var dict: [String: Double] = [:]
        for m in medals where m.isUnlocked {
            dict[m.id] = (m.unlockedDate ?? Date()).timeIntervalSince1970
        }
        UserDefaults.standard.set(dict, forKey: unlockedMedalsStorageKey)
    }
    
    // MARK: - Record Word Quiz Session
    func recordWordSession(_ result: QuizSessionResult) {
        guard result.totalQuestions > 0 else { return }
        
        let record = SessionRecord(
            date: Date(),
            practiceType: .vocabulary,
            questionCount: result.totalQuestions,
            correctCount: result.correctCount,
            totalDurationSeconds: result.totalTime,
            averagePaceSeconds: max(0.1, result.averageTime)
        )
        
        addSession(record)
    }
    
    // MARK: - Record Kana Quiz Session
    func recordKanaSession(_ summary: KanaSessionSummary) {
        guard summary.totalQuestions > 0 else { return }
        
        let record = SessionRecord(
            date: Date(),
            practiceType: .kana,
            questionCount: summary.totalQuestions,
            correctCount: summary.correctCount,
            totalDurationSeconds: summary.totalTimeSeconds,
            averagePaceSeconds: max(0.1, summary.averageTimeSeconds)
        )
        
        addSession(record)
    }
    
    private func addSession(_ record: SessionRecord) {
        sessions.append(record)
        saveSessions()
        evaluateMedals(after: record)
    }
    
    // MARK: - Medal Evaluation Engine
    private func evaluateMedals(after record: SessionRecord) {
        var unlockedNow: [Medal] = []
        let currentStreakCount = currentStreak
        let totalQuestions = totalQuestionsAnswered
        let totalTimeMinutes = allTimePracticeTime / 60.0
        
        for index in 0..<medals.count {
            if medals[index].isUnlocked { continue }
            
            var shouldUnlock = false
            let id = medals[index].id
            
            switch id {
            // Speed
            case "speed_quick":
                if record.averagePaceSeconds < 3.0 && record.questionCount >= 5 && record.accuracyPercentage >= 70 {
                    shouldUnlock = true
                }
            case "speed_lightning":
                if record.averagePaceSeconds < 2.0 && record.questionCount >= 5 && record.accuracyPercentage >= 75 {
                    shouldUnlock = true
                }
            case "speed_godspeed":
                if record.averagePaceSeconds < 1.2 && record.questionCount >= 5 && record.accuracyPercentage >= 80 {
                    shouldUnlock = true
                }
                
            // Streaks
            case "streak_first":
                shouldUnlock = true
            case "streak_3":
                if currentStreakCount >= 3 { shouldUnlock = true }
            case "streak_7":
                if currentStreakCount >= 7 { shouldUnlock = true }
            case "streak_30":
                if currentStreakCount >= 30 { shouldUnlock = true }
                
            // Accuracy
            case "acc_sharpshooter":
                if record.accuracyPercentage >= 90.0 && record.questionCount >= 5 {
                    shouldUnlock = true
                }
            case "acc_bullseye":
                if record.accuracyPercentage >= 99.9 && record.questionCount >= 10 {
                    shouldUnlock = true
                }
                
            // Volume
            case "vol_century":
                if totalQuestions >= 100 { shouldUnlock = true }
            case "vol_scholar":
                if totalQuestions >= 500 { shouldUnlock = true }
            case "vol_hour":
                if totalTimeMinutes >= 60.0 { shouldUnlock = true }
                
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
    
    /// Consecutive days with at least 1 completed workout
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
    
    /// Personal Best pace for a session with >= 5 questions and >= 80% accuracy
    var personalBestPace: Double {
        let qualifying = sessions.filter { $0.questionCount >= 5 && $0.accuracyPercentage >= 80 }
        guard let best = qualifying.min(by: { $0.averagePaceSeconds < $1.averagePaceSeconds }) else {
            // Fallback to absolute best session if none qualified with 80%
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
        
        // Difference in percent: lower is faster
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
}
