import SwiftUI
import UserNotifications

struct ReminderSheetView: View {
    var onDismiss: () -> Void
    
    @ObservedObject private var notifService = NotificationService.shared
    @State private var kanaSettings = KanaReminderSettings.load()
    @State private var wordSettings = WordReminderSettings.load()
    @State private var testSentFeedback: String? = nil
    
    // Quick time presets for adding
    let quickTimePresets: [(label: String, h: Int, m: Int)] = [
        ("08:00", 8, 0),
        ("11:00", 11, 0),
        ("14:00", 14, 0),
        ("16:00", 16, 0),
        ("20:30", 20, 30),
        ("21:30", 21, 30)
    ]
    
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
                        
                        // 3. Card 2: Vocabulary & Verbs Reminder
                        wordCard
                        
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
                
                // Script Selector (Hiragana vs Katakana)
                VStack(alignment: .leading, spacing: 6) {
                    Text("PRACTICE SCRIPT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .tracking(0.5)
                    
                    HStack(spacing: 6) {
                        ForEach(KanaType.allCases) { kType in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    kanaSettings.script = kType
                                    saveAndReschedule()
                                }
                            }) {
                                Text(kType.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(kanaSettings.script == kType ? .white : AppTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(kanaSettings.script == kType ? AppTheme.accent : AppTheme.inputBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Times List
                VStack(alignment: .leading, spacing: 6) {
                    Text("SCHEDULED TIMES")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .tracking(0.5)
                    
                    // Chips of currently active times
                    if kanaSettings.times.isEmpty {
                        Text("No reminder times added yet.")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textTertiary)
                            .padding(.vertical, 4)
                    } else {
                        FlowLayout(spacing: 8) {
                            ForEach(kanaSettings.times) { item in
                                HStack(spacing: 6) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(AppTheme.accent)
                                    
                                    Text(item.formatted24)
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(AppTheme.textPrimary)
                                    
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            kanaSettings.times.removeAll(where: { $0.id == item.id })
                                            saveAndReschedule()
                                        }
                                    }) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(AppTheme.textTertiary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppTheme.inputBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                    
                    // Quick Add Presets
                    HStack(spacing: 6) {
                        Text("Add:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.textTertiary)
                        
                        ForEach(quickTimePresets, id: \.label) { p in
                            let alreadyAdded = kanaSettings.times.contains(where: { $0.hour == p.h && $0.minute == p.m })
                            if !alreadyAdded {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        kanaSettings.times.append(ReminderTime(hour: p.h, minute: p.m))
                                        kanaSettings.times.sort(by: { ($0.hour * 60 + $0.minute) < ($1.hour * 60 + $1.minute) })
                                        saveAndReschedule()
                                    }
                                }) {
                                    Text("+\(p.label)")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .stroke(AppTheme.buttonBorder, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                
                Divider()
                    .background(AppTheme.cardBorder)
                
                // Test Notification Button
                Button(action: {
                    triggerTest(target: .kana(kanaSettings.script))
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
    
    // MARK: - Word Card
    private var wordCard: some View {
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
                        Text("Vocabulary & Verbs")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Morning & evening word drills")
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
                
                // Target Filter Selector
                VStack(alignment: .leading, spacing: 6) {
                    Text("PRACTICE TARGET")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .tracking(0.5)
                    
                    HStack(spacing: 6) {
                        ForEach(WordReminderFilter.allCases) { filter in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    wordSettings.filter = filter
                                    saveAndReschedule()
                                }
                            }) {
                                Text(filter.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(wordSettings.filter == filter ? .white : AppTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(wordSettings.filter == filter ? AppTheme.accent : AppTheme.inputBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Times List
                VStack(alignment: .leading, spacing: 6) {
                    Text("SCHEDULED TIMES")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .tracking(0.5)
                    
                    if wordSettings.times.isEmpty {
                        Text("No reminder times added yet.")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textTertiary)
                            .padding(.vertical, 4)
                    } else {
                        FlowLayout(spacing: 8) {
                            ForEach(wordSettings.times) { item in
                                HStack(spacing: 6) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(Color.orange)
                                    
                                    Text(item.formatted24)
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(AppTheme.textPrimary)
                                    
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            wordSettings.times.removeAll(where: { $0.id == item.id })
                                            saveAndReschedule()
                                        }
                                    }) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(AppTheme.textTertiary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppTheme.inputBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                    
                    // Quick Add Presets
                    HStack(spacing: 6) {
                        Text("Add:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.textTertiary)
                        
                        ForEach(quickTimePresets, id: \.label) { p in
                            let alreadyAdded = wordSettings.times.contains(where: { $0.hour == p.h && $0.minute == p.m })
                            if !alreadyAdded {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        wordSettings.times.append(ReminderTime(hour: p.h, minute: p.m))
                                        wordSettings.times.sort(by: { ($0.hour * 60 + $0.minute) < ($1.hour * 60 + $1.minute) })
                                        saveAndReschedule()
                                    }
                                }) {
                                    Text("+\(p.label)")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .stroke(AppTheme.buttonBorder, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                
                Divider()
                    .background(AppTheme.cardBorder)
                
                // Test Notification Button
                Button(action: {
                    triggerTest(target: .words(wordSettings.filter))
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

// Simple FlowLayout for chips wrapping
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeightInRow: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += maxHeightInRow + spacing
                maxHeightInRow = 0
            }
            maxHeightInRow = max(maxHeightInRow, size.height)
            x += size.width + spacing
        }
        height = y + maxHeightInRow
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var maxHeightInRow: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += maxHeightInRow + spacing
                maxHeightInRow = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            maxHeightInRow = max(maxHeightInRow, size.height)
            x += size.width + spacing
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
