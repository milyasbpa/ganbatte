import Foundation
import Combine

/// Manages cross-device synchronization between macOS and iOS
/// using Apple's iCloud Key-Value Store (NSUbiquitousKeyValueStore)
/// with local caching and offline JSON export/import fallback.
final class CloudSyncService: ObservableObject {
    static let shared = CloudSyncService()
    
    // Cloud storage keys matching ActivityService keys
    private let cloudSessionsKey = "ganbatte_cloud_sessions_v1"
    private let cloudMedalsKey = "ganbatte_cloud_medals_v1"
    private let cloudWordsKey = "ganbatte_cloud_unique_words_v1"
    private let cloudWordMistakesKey = "ganbatte_cloud_word_mistakes_v1"
    private let cloudKanaMistakesKey = "ganbatte_cloud_kana_mistakes_v1"
    private let cloudLastSyncKey = "ganbatte_cloud_last_sync_timestamp"
    
    @Published var isCloudAvailable: Bool = false
    @Published var lastSyncDate: Date? = nil
    @Published var isSyncing: Bool = false
    @Published var syncStatusMessage: String = "Ready"
    
    private let cloudStore = NSUbiquitousKeyValueStore.default
    private var observer: NSObjectProtocol?
    
    private init() {
        if let lastTimestamp = UserDefaults.standard.object(forKey: "ganbatte_local_last_sync") as? Double {
            self.lastSyncDate = Date(timeIntervalSince1970: lastTimestamp)
        }
        setupCloudObserver()
    }
    
    deinit {
        if let obs = observer {
            NotificationCenter.default.removeObserver(obs)
        }
    }
    
    // MARK: - Lifecycle & Observation
    func setupCloudObserver() {
        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloudStore,
            queue: .main
        ) { [weak self] notification in
            self?.handleExternalCloudChange(notification)
        }
        
        // Initial sync handshake
        triggerManualSync()
    }
    
    // MARK: - Push Local State to iCloud
    func pushLocalToCloud(
        sessions: [SessionRecord],
        medalsDict: [String: Double],
        uniqueWordsDict: [String: [Int]],
        wordMistakes: [WordMistakeEntry],
        kanaMistakes: [KanaMistakeEntry]
    ) {
        guard let sessionsData = try? JSONEncoder().encode(sessions),
              let wordMistakesData = try? JSONEncoder().encode(wordMistakes),
              let kanaMistakesData = try? JSONEncoder().encode(kanaMistakes) else {
            return
        }
        
        cloudStore.set(sessionsData, forKey: cloudSessionsKey)
        cloudStore.set(medalsDict, forKey: cloudMedalsKey)
        cloudStore.set(uniqueWordsDict, forKey: cloudWordsKey)
        cloudStore.set(wordMistakesData, forKey: cloudWordMistakesKey)
        cloudStore.set(kanaMistakesData, forKey: cloudKanaMistakesKey)
        cloudStore.set(Date().timeIntervalSince1970, forKey: cloudLastSyncKey)
        
        let synced = cloudStore.synchronize()
        DispatchQueue.main.async {
            self.isCloudAvailable = synced
            if synced {
                let now = Date()
                self.lastSyncDate = now
                UserDefaults.standard.set(now.timeIntervalSince1970, forKey: "ganbatte_local_last_sync")
                self.syncStatusMessage = "Synced with iCloud"
            }
        }
    }
    
    // MARK: - Pull from iCloud & Merge
    func triggerManualSync() {
        DispatchQueue.main.async {
            self.isSyncing = true
        }
        let syncSuccess = cloudStore.synchronize()
        
        // Pull remote keys if present
        pullAndMergeFromCloud()
        
        let now = Date()
        DispatchQueue.main.async {
            self.isCloudAvailable = syncSuccess
            self.lastSyncDate = now
            UserDefaults.standard.set(now.timeIntervalSince1970, forKey: "ganbatte_local_last_sync")
            self.isSyncing = false
            self.syncStatusMessage = syncSuccess ? "iCloud Sync Active" : "Local Storage Active"
        }
    }
    
    private func handleExternalCloudChange(_ notification: Notification) {
        pullAndMergeFromCloud()
        DispatchQueue.main.async {
            self.lastSyncDate = Date()
            self.syncStatusMessage = "Updated from another device"
        }
    }
    
    private func pullAndMergeFromCloud() {
        var remoteSessions: [SessionRecord]? = nil
        if let data = cloudStore.data(forKey: cloudSessionsKey),
           let decoded = try? JSONDecoder().decode([SessionRecord].self, from: data) {
            remoteSessions = decoded
        }
        
        let remoteMedals = cloudStore.dictionary(forKey: cloudMedalsKey) as? [String: Double]
        let remoteUniqueWords = cloudStore.dictionary(forKey: cloudWordsKey) as? [String: [Int]]
        
        var remoteWordMistakes: [WordMistakeEntry]? = nil
        if let data = cloudStore.data(forKey: cloudWordMistakesKey),
           let decoded = try? JSONDecoder().decode([WordMistakeEntry].self, from: data) {
            remoteWordMistakes = decoded
        }
        
        var remoteKanaMistakes: [KanaMistakeEntry]? = nil
        if let data = cloudStore.data(forKey: cloudKanaMistakesKey),
           let decoded = try? JSONDecoder().decode([KanaMistakeEntry].self, from: data) {
            remoteKanaMistakes = decoded
        }
        
        DispatchQueue.main.async {
            ActivityService.shared.mergeIncomingSyncData(
                remoteSessions: remoteSessions,
                remoteMedals: remoteMedals,
                remoteUniqueWords: remoteUniqueWords,
                remoteWordMistakes: remoteWordMistakes,
                remoteKanaMistakes: remoteKanaMistakes
            )
        }
    }
    
    // MARK: - Direct JSON Backup Export & Import (AirDrop / File Sharing)
    struct SyncBackupPackage: Codable {
        let exportDate: Date
        let appVersion: String
        let sessions: [SessionRecord]
        let medals: [String: Double]
        let uniqueWords: [String: [Int]]
        let wordMistakes: [WordMistakeEntry]
        let kanaMistakes: [KanaMistakeEntry]
    }
    
    func createExportPackage() -> URL? {
        let package = SyncBackupPackage(
            exportDate: Date(),
            appVersion: "1.0",
            sessions: ActivityService.shared.sessions,
            medals: ActivityService.shared.unlockedMedalsDictionary,
            uniqueWords: ActivityService.shared.uniqueCorrectWordsDictionary,
            wordMistakes: ActivityService.shared.activeWordMistakes,
            kanaMistakes: ActivityService.shared.activeKanaMistakes
        )
        
        guard let data = try? JSONEncoder().encode(package) else { return nil }
        
        let filename = "ganbatte_progress_backup.json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }
    
    func importPackage(from url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url),
              let package = try? JSONDecoder().decode(SyncBackupPackage.self, from: data) else {
            return false
        }
        
        DispatchQueue.main.async {
            ActivityService.shared.mergeIncomingSyncData(
                remoteSessions: package.sessions,
                remoteMedals: package.medals,
                remoteUniqueWords: package.uniqueWords,
                remoteWordMistakes: package.wordMistakes,
                remoteKanaMistakes: package.kanaMistakes
            )
            self.lastSyncDate = Date()
            self.syncStatusMessage = "Imported from backup file"
        }
        return true
    }
}
