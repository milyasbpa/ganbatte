import Foundation
import UserNotifications

final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var pendingDeepLink: ReminderDeepLink? = nil
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorization()
    }
    
    func setup() {
        UNUserNotificationCenter.current().delegate = self
        checkAuthorization()
    }
    
    func checkAuthorization(completion: ((UNAuthorizationStatus) -> Void)? = nil) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                completion?(settings.authorizationStatus)
            }
        }
    }
    
    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
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
        let center = UNUserNotificationCenter.current()
        
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
        guard settings.isEnabled else { return }
        
        let center = UNUserNotificationCenter.current()
        let scriptTitle = settings.script == .katakana ? "Katakana" : "Hiragana"
        
        for time in settings.times {
            let content = UNMutableNotificationContent()
            content.title = "⚡ Kana Speed Practice"
            content.body = "Waktunya melatih kecepatan baca \(scriptTitle)! Selesaikan 10 kata dalam 1 menit."
            content.sound = .default
            content.attachments = makeNotificationAttachments()
            content.userInfo = [
                "type": "kana",
                "script": settings.script.rawValue
            ]
            
            var comps = DateComponents()
            comps.hour = time.hour
            comps.minute = time.minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let req = UNNotificationRequest(
                identifier: "ganbatte.reminder.kana.\(time.hour)_\(time.minute)",
                content: content,
                trigger: trigger
            )
            center.add(req)
        }
    }
    
    private func scheduleWordReminders() {
        let settings = WordReminderSettings.load()
        guard settings.isEnabled else { return }
        
        let center = UNUserNotificationCenter.current()
        
        for time in settings.times {
            let content = UNMutableNotificationContent()
            if settings.filter == .verbsOnly {
                content.title = "⚔️ Morning Verb Drill"
                content.body = "Waktunya latihan 20 kata kerja! Kuasai pola arti dan kanjinya."
            } else {
                content.title = "📖 Daily Vocab Drill"
                content.body = "Waktunya latihan 20 kosakata harian! Jaga konsistensi belajarmu."
            }
            content.sound = .default
            content.attachments = makeNotificationAttachments()
            content.userInfo = [
                "type": "words",
                "filter": settings.filter.rawValue
            ]
            
            var comps = DateComponents()
            comps.hour = time.hour
            comps.minute = time.minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let req = UNNotificationRequest(
                identifier: "ganbatte.reminder.word.\(time.hour)_\(time.minute)",
                content: content,
                trigger: trigger
            )
            center.add(req)
        }
    }
    
    // MARK: - Instant Test Notification
    func sendTestNotification(target: ReminderDeepLink, delay: TimeInterval = 3, completion: @escaping (Bool) -> Void) {
        requestPermission { granted in
            guard granted else {
                completion(false)
                return
            }
            
            let center = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.sound = .default
            content.attachments = self.makeNotificationAttachments()
            
            switch target {
            case .kana(let script):
                content.title = "⚡ Kana Speed Practice (Test)"
                let title = script == .katakana ? "Katakana" : "Hiragana"
                content.body = "Tap untuk langsung latihan kecepatan baca \(title)!"
                content.userInfo = ["type": "kana", "script": script.rawValue]
                
            case .words(let filter):
                if filter == .verbsOnly {
                    content.title = "⚔️ Verb Drill (Test)"
                    content.body = "Tap untuk langsung latihan 20 kata kerja N5!"
                } else {
                    content.title = "📖 Vocab Drill (Test)"
                    content.body = "Tap untuk langsung latihan kosakata harian!"
                }
                content.userInfo = ["type": "words", "filter": filter.rawValue]
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
        
        if let type = userInfo["type"] as? String {
            if type == "kana" {
                let scriptRaw = userInfo["script"] as? String ?? ""
                let script = KanaType(rawValue: scriptRaw) ?? .katakana
                DispatchQueue.main.async {
                    self.pendingDeepLink = .kana(script)
                }
            } else if type == "words" {
                let filterRaw = userInfo["filter"] as? String ?? ""
                let filter = WordReminderFilter(rawValue: filterRaw) ?? .verbsOnly
                DispatchQueue.main.async {
                    self.pendingDeepLink = .words(filter)
                }
            }
        }
        
        completionHandler()
    }
}
