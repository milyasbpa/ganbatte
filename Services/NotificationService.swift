import Foundation
import UserNotifications

final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var pendingDeepLink: ReminderDeepLink? = nil
    
    private var center: UNUserNotificationCenter? {
        guard Bundle.main.bundleIdentifier != nil else { return nil }
        return UNUserNotificationCenter.current()
    }
    
    private override init() {
        super.init()
        guard let center = center else {
            authorizationStatus = .authorized
            return
        }
        center.delegate = self
        checkAuthorization()
    }
    
    func setup() {
        guard let center = center else { return }
        center.delegate = self
        checkAuthorization()
    }
    
    func checkAuthorization(completion: ((UNAuthorizationStatus) -> Void)? = nil) {
        guard let center = center else {
            self.authorizationStatus = .authorized
            completion?(.authorized)
            return
        }
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                completion?(settings.authorizationStatus)
            }
        }
    }
    
    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        guard let center = center else {
            completion?(true)
            return
        }
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        center.requestAuthorization(options: options) { granted, error in
            DispatchQueue.main.async {
                self.checkAuthorization { status in
                    if granted {
                        self.rescheduleAllReminders()
                    }
                    completion?(granted)
                }
            }
        }
    }
    
    // MARK: - Reschedule All
    func rescheduleAllReminders() {
        guard let center = center else { return }
        
        center.getPendingNotificationRequests { existing in
            let toRemove = existing
                .map { $0.identifier }
                .filter { $0.hasPrefix("ganbatte.reminder.") }
            
            center.removePendingNotificationRequests(withIdentifiers: toRemove)
            
            self.scheduleKanaReminders()
            self.scheduleWordReminders()
        }
    }
    
    private func scheduleKanaReminders() {
        let settings = KanaReminderSettings.load()
        guard settings.isEnabled, let center = center else { return }
        
        for item in settings.items {
            let content = UNMutableNotificationContent()
            let scriptTitle = item.script == .katakana ? "Katakana" : "Hiragana"
            
            if item.mode == .learn {
                content.title = "📖 \(scriptTitle) Flashcards"
                content.body = "Time to review \(scriptTitle) characters and stroke order!"
            } else {
                content.title = "⚡ \(scriptTitle) Speed Practice"
                content.body = "Time to practice your \(scriptTitle) reading speed! 15 words in 60 seconds."
            }
            
            content.sound = .default
            content.attachments = makeNotificationAttachments()
            content.userInfo = [
                "type": "kana",
                "script": item.script.rawValue,
                "mode": item.mode.rawValue
            ]
            
            var comps = DateComponents()
            comps.hour = item.hour
            comps.minute = item.minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let req = UNNotificationRequest(
                identifier: "ganbatte.reminder.kana.\(item.id)",
                content: content,
                trigger: trigger
            )
            center.add(req)
        }
    }
    
    private func scheduleWordReminders() {
        let settings = WordReminderSettings.load()
        guard settings.isEnabled, let center = center else { return }
        
        for item in settings.items {
            let content = UNMutableNotificationContent()
            let levelTitle = item.level == .all ? "All Levels" : item.level.rawValue
            let typeTitle = item.type == .all ? "Vocabulary" : "\(item.type.title)s"
            
            if item.mode == .learn {
                content.title = "📖 Learn \(levelTitle) \(typeTitle)"
                content.body = "Time to explore new \(levelTitle) \(typeTitle.lowercased()) cards with native illustrations & audio."
            } else {
                content.title = "⚡ \(levelTitle) \(typeTitle) Drill"
                content.body = "Ready for your \(levelTitle) \(typeTitle.lowercased()) speed test? Lock in your streak!"
            }
            
            content.sound = .default
            content.attachments = makeNotificationAttachments()
            content.userInfo = [
                "type": "words",
                "level": item.level.rawValue,
                "wordType": item.type.rawValue,
                "mode": item.mode.rawValue
            ]
            
            var comps = DateComponents()
            comps.hour = item.hour
            comps.minute = item.minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let req = UNNotificationRequest(
                identifier: "ganbatte.reminder.word.\(item.id)",
                content: content,
                trigger: trigger
            )
            center.add(req)
        }
    }
    
    // MARK: - Instant Test Notification
    func sendTestNotification(target: ReminderDeepLink, delay: TimeInterval = 3, completion: @escaping (Bool) -> Void) {
        requestPermission { granted in
            guard granted, let center = self.center else {
                completion(false)
                return
            }
            
            let content = UNMutableNotificationContent()
            content.sound = .default
            content.attachments = self.makeNotificationAttachments()
            
            switch target {
            case .kana(let script, let mode):
                let title = script == .katakana ? "Katakana" : "Hiragana"
                if mode == .learn {
                    content.title = "📖 \(title) Flashcards (Test)"
                    content.body = "Tap to review \(title) characters and stroke order now!"
                } else {
                    content.title = "⚡ \(title) Speed Practice (Test)"
                    content.body = "Tap to practice \(title) reading speed now!"
                }
                content.userInfo = ["type": "kana", "script": script.rawValue, "mode": mode.rawValue]
                
            case .words(let level, let type, let mode):
                let levelTitle = level == .all ? "All Levels" : level.rawValue
                let typeTitle = type == .all ? "Vocabulary" : "\(type.title)s"
                if mode == .learn {
                    content.title = "📖 Learn \(levelTitle) \(typeTitle) (Test)"
                    content.body = "Tap to explore \(levelTitle) \(typeTitle.lowercased()) cards now!"
                } else {
                    content.title = "⚡ \(levelTitle) \(typeTitle) Drill (Test)"
                    content.body = "Tap to test your \(levelTitle) \(typeTitle.lowercased()) speed now!"
                }
                content.userInfo = [
                    "type": "words",
                    "level": level.rawValue,
                    "wordType": type.rawValue,
                    "mode": mode.rawValue
                ]
            }
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, delay), repeats: false)
            let req = UNNotificationRequest(
                identifier: "ganbatte.reminder.test.\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            
            center.add(req) { error in
                DispatchQueue.main.async {
                    completion(error == nil)
                }
            }
        }
    }
    
    private func makeNotificationAttachments() -> [UNNotificationAttachment] {
        guard let url = Bundle.main.url(forResource: "NotificationIcon", withExtension: "png") else {
            return []
        }
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ganbatte_icon_\(UUID().uuidString).png")
        do {
            try? FileManager.default.removeItem(at: tempURL)
            try FileManager.default.copyItem(at: url, to: tempURL)
            let att = try UNNotificationAttachment(identifier: "app_icon", url: tempURL, options: nil)
            return [att]
        } catch {
            return []
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and play sound even if app is in foreground
        #if os(macOS)
        completionHandler([.banner, .sound, .badge])
        #else
        completionHandler([.banner, .sound, .badge])
        #endif
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let modeRaw = userInfo["mode"] as? String ?? ReminderMode.exercise.rawValue
        let mode = ReminderMode(rawValue: modeRaw) ?? .exercise
        
        if let type = userInfo["type"] as? String {
            if type == "kana" {
                let scriptRaw = userInfo["script"] as? String ?? ""
                let script = KanaType(rawValue: scriptRaw) ?? .katakana
                DispatchQueue.main.async {
                    self.pendingDeepLink = .kana(script, mode: mode)
                }
            } else if type == "words" {
                let levelRaw = userInfo["level"] as? String ?? "N5"
                let wordTypeRaw = userInfo["wordType"] as? String ?? "Verb"
                let level = JLPTLevel(rawValue: levelRaw) ?? .n5
                let wordType = WordType(rawValue: wordTypeRaw) ?? .verb
                DispatchQueue.main.async {
                    self.pendingDeepLink = .words(level: level, type: wordType, mode: mode)
                }
            }
        }
        
        completionHandler()
    }
}
