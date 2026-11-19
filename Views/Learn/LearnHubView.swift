import SwiftUI

enum LearnSubView {
    case hub
    case wordList
    case kanaChart
}

struct LearnHubView: View {
    @Binding var hideBottomBar: Bool
    
    @State private var activeSubView: LearnSubView = .hub
    @State private var selectedLevelForWordList: JLPTLevel = .all
    @ObservedObject private var activityService = ActivityService.shared
    
    // Live counts cached from DatabaseService
    @State private var levelCounts: [JLPTLevel: Int] = [
        .n5: 966,
        .n4: 982,
        .n3: 1811,
        .n2: 1836,
        .n1: 1232
    ]
    @State private var totalWordsCount: Int = 6827
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            switch activeSubView {
            case .hub:
                hubContent
                    .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading)))
            case .wordList:
                WordListView(
                    hideBottomBar: $hideBottomBar,
                    initialLevel: selectedLevelForWordList,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            activeSubView = .hub
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            case .kanaChart:
                KanaChartView(
                    hideBottomBar: $hideBottomBar,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            activeSubView = .hub
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            }
        }
        .onAppear {
            loadDatabaseCounts()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ganbatte_navigate_to_words"))) { notif in
            if let levelRaw = notif.userInfo?["level"] as? String, let level = JLPTLevel(rawValue: levelRaw) {
                selectedLevelForWordList = level
            } else {
                selectedLevelForWordList = .all
            }
            withAnimation(.easeInOut(duration: 0.22)) {
                activeSubView = .wordList
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ganbatte_navigate_to_kana"))) { _ in
            withAnimation(.easeInOut(duration: 0.22)) {
                activeSubView = .kanaChart
            }
        }
    }
    
    // MARK: - Gojek / Grab Style Hub Content
    private var hubContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("がんばって")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(AppTheme.accent)
                        
                        Text("Ganbatte")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    
                    Text("Explore Japanese Vocabulary & Kana")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Daily Motivation Card
                    greetingCard
                    
                    // CATEGORIES Section Header
                    VStack(alignment: .leading, spacing: 14) {
                        Text("CATEGORIES")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .tracking(0.6)
                            .padding(.horizontal, 4)
                        
                        // 1. KOTOBA (Words)
                        kotobaSection
                        
                        // 2. KANA (Hiragana & Katakana - Left Aligned)
                        kanaSection
                        
                        // 3. KANJI (Coming Soon)
                        kanjiSection
                        
                        // 4. BUNPOU (Coming Soon)
                        bunpouSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 90)
            }
        }
    }
    
    // MARK: - Greeting Card
    private var greetingCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.12))
                    .frame(width: 46, height: 46)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(AppTheme.accent)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(activityService.isTodayCompleted ? "Great momentum today!" : "Keep the momentum going!")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                if activityService.todayQuestionsAnswered > 0 {
                    Text("\(activityService.todayQuestionsAnswered) questions completed today.")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                } else {
                    Text("Choose a category or jump into a quick quiz.")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.buttonBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - 1. Kotoba Section (5 Bubbles)
    private var kotobaSection: some View {
        categoryCardContainer(
            title: "Kotoba",
            kanjiSubtitle: "言葉",
            headerActionTitle: "See All (\(formatCount(totalWordsCount)))",
            headerAction: {
                openWordList(level: .all)
            }
        ) {
            HStack(spacing: 0) {
                // N5 Bubble
                kotobaBubble(
                    level: .n5,
                    title: "N5",
                    count: levelCounts[.n5] ?? 966,
                    gradient: [Color(red: 0.88, green: 0.42, blue: 0.32), Color(red: 0.95, green: 0.52, blue: 0.40)]
                )
                
                // N4 Bubble
                kotobaBubble(
                    level: .n4,
                    title: "N4",
                    count: levelCounts[.n4] ?? 982,
                    gradient: [Color(red: 0.92, green: 0.56, blue: 0.20), Color(red: 0.98, green: 0.68, blue: 0.32)]
                )
                
                // N3 Bubble
                kotobaBubble(
                    level: .n3,
                    title: "N3",
                    count: levelCounts[.n3] ?? 1811,
                    gradient: [Color(red: 0.16, green: 0.65, blue: 0.55), Color(red: 0.26, green: 0.78, blue: 0.66)]
                )
                
                // N2 Bubble
                kotobaBubble(
                    level: .n2,
                    title: "N2",
                    count: levelCounts[.n2] ?? 1836,
                    gradient: [Color(red: 0.25, green: 0.48, blue: 0.88), Color(red: 0.42, green: 0.64, blue: 0.98)]
                )
                
                // N1 Bubble
                kotobaBubble(
                    level: .n1,
                    title: "N1",
                    count: levelCounts[.n1] ?? 1232,
                    gradient: [Color(red: 0.58, green: 0.36, blue: 0.78), Color(red: 0.72, green: 0.50, blue: 0.90)]
                )
            }
        }
    }
    
    // MARK: - 2. Kana Section (Left-aligned: Hiragana & Katakana)
    private var kanaSection: some View {
        categoryCardContainer(
            title: "Kana",
            kanjiSubtitle: "仮名",
            headerActionTitle: "See Chart",
            headerAction: {
                withAnimation(.easeInOut(duration: 0.22)) {
                    activeSubView = .kanaChart
                }
            }
        ) {
            HStack(spacing: 0) {
                // Column 1: Hiragana (matches Column 1 / N5 alignment)
                Button(action: {
                    UserDefaults.standard.set(KanaType.hiragana.rawValue, forKey: "ganbatte_active_kana_subtab")
                    withAnimation(.easeInOut(duration: 0.22)) {
                        activeSubView = .kanaChart
                    }
                }) {
                    VStack(spacing: 7) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.88, green: 0.42, blue: 0.32), Color(red: 0.95, green: 0.52, blue: 0.40)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                                .shadow(color: AppTheme.accent.opacity(0.25), radius: 5, x: 0, y: 2)
                            
                            Text("あ")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 1) {
                            Text("Hiragana")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            Text("46 chars")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(BubbleScaleButtonStyle())
                
                // Column 2: Katakana (matches Column 2 / N4 alignment)
                Button(action: {
                    UserDefaults.standard.set(KanaType.katakana.rawValue, forKey: "ganbatte_active_kana_subtab")
                    withAnimation(.easeInOut(duration: 0.22)) {
                        activeSubView = .kanaChart
                    }
                }) {
                    VStack(spacing: 7) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.25, green: 0.48, blue: 0.88), Color(red: 0.42, green: 0.64, blue: 0.98)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                                .shadow(color: Color(red: 0.25, green: 0.48, blue: 0.88).opacity(0.25), radius: 5, x: 0, y: 2)
                            
                            Text("ア")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 1) {
                            Text("Katakana")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            Text("46 chars")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(BubbleScaleButtonStyle())
                
                // Columns 3, 4, 5 are clear space, keeping Hiragana & Katakana strictly left-aligned!
                Color.clear.frame(maxWidth: .infinity)
                Color.clear.frame(maxWidth: .infinity)
                Color.clear.frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - 3. Kanji Section (Coming Soon)
    private var kanjiSection: some View {
        categoryCardContainer(
            title: "Kanji",
            kanjiSubtitle: "漢字",
            isComingSoon: true
        ) {
            HStack(spacing: 0) {
                ForEach(["N5", "N4", "N3", "N2", "N1"], id: \.self) { levelStr in
                    comingSoonBubble(title: levelStr, subtitle: "Soon")
                }
            }
        }
    }
    
    // MARK: - 4. Bunpou Section (Coming Soon)
    private var bunpouSection: some View {
        categoryCardContainer(
            title: "Bunpou",
            kanjiSubtitle: "文法",
            isComingSoon: true
        ) {
            HStack(spacing: 0) {
                ForEach(["N5", "N4", "N3", "N2", "N1"], id: \.self) { levelStr in
                    comingSoonBubble(title: levelStr, subtitle: "Soon")
                }
            }
        }
    }
    
    // MARK: - Card Container Template
    private func categoryCardContainer<Content: View>(
        title: String,
        kanjiSubtitle: String? = nil,
        headerActionTitle: String? = nil,
        isComingSoon: Bool = false,
        headerAction: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Card Header
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    if let kanjiSubtitle = kanjiSubtitle {
                        Text(kanjiSubtitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
                
                Spacer()
                
                if isComingSoon {
                    Text("Coming Soon")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.04))
                        .clipShape(Capsule())
                } else if let actionTitle = headerActionTitle, let action = headerAction {
                    Button(action: action) {
                        HStack(spacing: 3) {
                            Text(actionTitle)
                                .font(.system(size: 12, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(AppTheme.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Content Bubbles
            content()
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.buttonBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - Kotoba Bubble Component
    private func kotobaBubble(
        level: JLPTLevel,
        title: String,
        count: Int,
        gradient: [Color]
    ) -> some View {
        Button(action: {
            openWordList(level: level)
        }) {
            VStack(spacing: 7) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: (gradient.first ?? AppTheme.accent).opacity(0.25), radius: 5, x: 0, y: 2)
                    
                    Text(title)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 1) {
                    Text(title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text(formatCount(count))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(BubbleScaleButtonStyle())
    }
    
    // MARK: - Coming Soon Bubble Component
    private func comingSoonBubble(
        title: String,
        subtitle: String
    ) -> some View {
        VStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(Color(hex: 0xF5F3EE))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.buttonBorder, lineWidth: 1)
                    )
                
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textTertiary)
            }
            
            VStack(spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textTertiary)
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .opacity(0.7)
    }
    
    // MARK: - Helper Methods
    private func openWordList(level: JLPTLevel) {
        selectedLevelForWordList = level
        NotificationCenter.default.post(
            name: NSNotification.Name("ganbatte_apply_word_filter"),
            object: nil,
            userInfo: [
                "level": level.rawValue,
                "type": WordType.all.rawValue
            ]
        )
        withAnimation(.easeInOut(duration: 0.22)) {
            activeSubView = .wordList
        }
    }
    
    private func loadDatabaseCounts() {
        DispatchQueue.global(qos: .userInitiated).async {
            let c5 = DatabaseService.shared.countWords(level: .n5)
            let c4 = DatabaseService.shared.countWords(level: .n4)
            let c3 = DatabaseService.shared.countWords(level: .n3)
            let c2 = DatabaseService.shared.countWords(level: .n2)
            let c1 = DatabaseService.shared.countWords(level: .n1)
            let total = DatabaseService.shared.countWords(level: .all)
            
            DispatchQueue.main.async {
                self.levelCounts = [
                    .n5: c5,
                    .n4: c4,
                    .n3: c3,
                    .n2: c2,
                    .n1: c1
                ]
                self.totalWordsCount = total
            }
        }
    }
    
    private func formatCount(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }
}

// MARK: - Spring Button Style for Gojek-like Tap Feedback
struct BubbleScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
