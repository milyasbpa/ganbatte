import SwiftUI
import UserNotifications

struct ReminderSheetView: View {
    var onDismiss: () -> Void
    
    @ObservedObject private var notifService = NotificationService.shared
    @State private var kanaSettings = KanaReminderSettings.load()
    @State private var wordSettings = WordReminderSettings.load()
    @State private var testSentFeedback: String? = nil
    
    // Form state for adding Kana reminder
    @State private var newKanaScript: KanaType = .katakana
    @State private var newKanaTime: Date = Self.makeDate(hour: 7, minute: 30)
    
    // Form state for adding Vocabulary reminder
    @State private var newWordLevel: JLPTLevel = .n5
    @State private var newWordType: WordType = .verb
    @State private var newWordTime: Date = Self.makeDate(hour: 8, minute: 0)
    
    private static func makeDate(hour: Int, minute: Int) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? Date()
    }
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Study Reminders")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Daily training schedules & alerts")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.textTertiary)
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                #if os(macOS)
                .padding(.top, 16)
                #else
                .padding(.top, 16)
                #endif
                .padding(.bottom, 14)
                .background(AppTheme.background)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 1. Permission Banner (if needed)
                        if notifService.authorizationStatus != .authorized {
                            permissionBanner
                        }
                        
                        // Feedback banner if test notification was fired
                        if let feedback = testSentFeedback {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: 0x34C759))
                                Text(feedback)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(hex: 0x34C759).opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        
                        // 2. Card 1: Kana Speed Practice Reminder
                        kanaCard
                        
                        // 3. Card 2: Vocabulary Reminder
                        vocabularyCard
                        
                        // 4. Offline Info Footer
                        HStack(spacing: 8) {
                            Image(systemName: "bell.badge")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.accent)
                            
                            Text("Notifications run 100% offline. Tapping an alert automatically opens the corresponding practice drill.")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.cardBorder, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            notifService.checkAuthorization()
        }
    }
    
    // MARK: - Permission Banner
    private var permissionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 20))
                .foregroundColor(AppTheme.accent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Notifications are disabled")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text("Enable permissions to receive daily study alerts.")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            Button(action: {
                notifService.requestPermission()
            }) {
                Text("Enable")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(AppTheme.accentLight.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Kana Card
    private var kanaCard: some View {
        VStack(spacing: 14) {
            // Title & Toggle
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(AppTheme.accentLight)
                            .frame(width: 32, height: 32)
                        Text("あ")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.accent)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Kana Speed Practice")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("TypeRacer reading drills")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                CustomToggle(
                    isOn: Binding(
                        get: { kanaSettings.isEnabled },
                        set: { val in
                            kanaSettings.isEnabled = val
                            saveAndReschedule()
                        }
                    ),
                    activeColor: AppTheme.accent
                )
            }
            
            if kanaSettings.isEnabled {
                Divider()
                    .background(AppTheme.cardBorder)
                
                // Add New Reminder Row
                VStack(alignment: .leading, spacing: 8) {
                    Text("ADD REMINDER")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .tracking(0.5)
                    
                    HStack(spacing: 8) {
                        // Script Menu
                        Menu {
                            ForEach(KanaType.allCases) { script in
                                Button(script.title) {
                                    newKanaScript = script
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(newKanaScript == .katakana ? "⚡ Katakana" : "🌸 Hiragana")
                                    .font(.system(size: 13, weight: .bold))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 9, weight: .semibold))
                            }
                            .foregroundColor(AppTheme.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(AppTheme.accentLight.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        DatePicker("", selection: $newKanaTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        
                        Button(action: addKanaReminder) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Add")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(AppTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(AppTheme.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                
                // Scheduled List
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("SCHEDULED DRILLS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .tracking(0.5)
                        
                        Spacer()
                        
                        Text("\(kanaSettings.items.count) active")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                    
                    if kanaSettings.items.isEmpty {
                        HStack {
                            Spacer()
                            Text("No reminders scheduled yet.")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textTertiary)
                                .padding(.vertical, 10)
                            Spacer()
                        }
                        .background(AppTheme.inputBackground.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        VStack(spacing: 6) {
                            ForEach(kanaSettings.items) { item in
                                HStack(spacing: 10) {
                                    HStack(spacing: 5) {
                                        Text(item.script == .katakana ? "⚡" : "🌸")
                                            .font(.system(size: 12))
                                        Text(item.script.title)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(AppTheme.accent)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(AppTheme.accentLight.opacity(0.7))
                                    .clipShape(Capsule())
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 11))
                                            .foregroundColor(AppTheme.textSecondary)
                                        Text(item.formatted24)
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            kanaSettings.items.removeAll(where: { $0.id == item.id })
                                            saveAndReschedule()
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(AppTheme.textTertiary)
                                            .frame(width: 28, height: 28)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(AppTheme.buttonBorder.opacity(0.8), lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(AppTheme.background.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(AppTheme.buttonBorder.opacity(0.6), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
                
                Divider()
                    .background(AppTheme.cardBorder)
                
                // Test Notification Button
                Button(action: {
                    triggerTest(target: .kana(newKanaScript))
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("Send Test Kana Notification (3s)")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(AppTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(AppTheme.accentLight.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Vocabulary Card
    private var vocabularyCard: some View {
        VStack(spacing: 14) {
            // Title & Toggle
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: "character.book.closed.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Vocabulary")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Daily word & grammar training alerts")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                CustomToggle(
                    isOn: Binding(
                        get: { wordSettings.isEnabled },
                        set: { val in
                            wordSettings.isEnabled = val
                            saveAndReschedule()
                        }
                    ),
                    activeColor: Color.orange
                )
            }
            
            if wordSettings.isEnabled {
                Divider()
                    .background(AppTheme.cardBorder)
                
                // Add New Reminder Row
                VStack(alignment: .leading, spacing: 8) {
                    Text("ADD REMINDER")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .tracking(0.5)
                    
                    HStack(spacing: 6) {
                        // Level Menu
                        Menu {
                            ForEach(JLPTLevel.allCases, id: \.self) { level in
                                Button(level.rawValue) {
                                    newWordLevel = level
                                }
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Text(newWordLevel == .all ? "All" : newWordLevel.rawValue)
                                    .font(.system(size: 12, weight: .bold))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 8, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: 0xE65100))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 7)
                            .background(Color.orange.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        
                        // Type Menu
                        Menu {
                            ForEach(WordType.allCases, id: \.self) { type in
                                Button(type.title) {
                                    newWordType = type
                                }
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Text(newWordType.title)
                                    .font(.system(size: 12, weight: .semibold))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 8, weight: .semibold))
                            }
                            .foregroundColor(AppTheme.textPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 7)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(AppTheme.buttonBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        DatePicker("", selection: $newWordTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        
                        Button(action: addWordReminder) {
                            HStack(spacing: 3) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Add")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(AppTheme.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                
                // Scheduled List
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("SCHEDULED DRILLS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .tracking(0.5)
                        
                        Spacer()
                        
                        Text("\(wordSettings.items.count) active")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                    
                    if wordSettings.items.isEmpty {
                        HStack {
                            Spacer()
                            Text("No reminders scheduled yet.")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textTertiary)
                                .padding(.vertical, 10)
                            Spacer()
                        }
                        .background(AppTheme.inputBackground.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        VStack(spacing: 6) {
                            ForEach(wordSettings.items) { item in
                                HStack(spacing: 8) {
                                    Text(item.level.rawValue)
                                        .font(.system(size: 11, weight: .heavy))
                                        .foregroundColor(Color(hex: 0xE65100))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.15))
                                        .clipShape(Capsule())
                                    
                                    Text(item.type.title)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 11))
                                            .foregroundColor(AppTheme.textSecondary)
                                        Text(item.formatted24)
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            wordSettings.items.removeAll(where: { $0.id == item.id })
                                            saveAndReschedule()
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(AppTheme.textTertiary)
                                            .frame(width: 28, height: 28)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(AppTheme.buttonBorder.opacity(0.8), lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(AppTheme.background.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(AppTheme.buttonBorder.opacity(0.6), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
                
                Divider()
                    .background(AppTheme.cardBorder)
                
                // Test Notification Button
                Button(action: {
                    triggerTest(target: .words(level: newWordLevel, type: newWordType))
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("Send Test Vocab Notification (3s)")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(Color.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Actions
    private func addKanaReminder() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: newKanaTime)
        let hour = comps.hour ?? 7
        let minute = comps.minute ?? 30
        let item = KanaReminderItem(script: newKanaScript, hour: hour, minute: minute)
        withAnimation(.easeInOut(duration: 0.15)) {
            kanaSettings.items.append(item)
            kanaSettings.items.sort { ($0.hour * 60 + $0.minute) < ($1.hour * 60 + $1.minute) }
            saveAndReschedule()
        }
    }
    
    private func addWordReminder() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: newWordTime)
        let hour = comps.hour ?? 8
        let minute = comps.minute ?? 0
        let item = WordReminderItem(level: newWordLevel, type: newWordType, hour: hour, minute: minute)
        withAnimation(.easeInOut(duration: 0.15)) {
            wordSettings.items.append(item)
            wordSettings.items.sort { ($0.hour * 60 + $0.minute) < ($1.hour * 60 + $1.minute) }
            saveAndReschedule()
        }
    }
    
    private func saveAndReschedule() {
        kanaSettings.save()
        wordSettings.save()
        notifService.rescheduleAllReminders()
    }
    
    private func triggerTest(target: ReminderDeepLink) {
        testSentFeedback = "Notification will appear in 3 seconds..."
        notifService.sendTestNotification(target: target, delay: 3) { success in
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                if testSentFeedback != nil {
                    testSentFeedback = nil
                }
            }
        }
    }
}

// Clean cross-platform CustomToggle
struct CustomToggle: View {
    @Binding var isOn: Bool
    var activeColor: Color = AppTheme.accent
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isOn.toggle()
            }
        }) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? activeColor : Color.black.opacity(0.12))
                    .frame(width: 48, height: 28)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .padding(2)
                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
