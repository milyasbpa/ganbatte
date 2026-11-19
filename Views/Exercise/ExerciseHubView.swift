import SwiftUI

enum ExerciseCategory: String, CaseIterable, Identifiable {
    case kotoba = "Kotoba"
    case kana = "Kana"
    case kanji = "Kanji"
    case bunpou = "Bunpou"
    
    var id: String { rawValue }
}

enum ActiveWorkout {
    case vocab
    case kana
}

struct ExerciseHubView: View {
    @Binding var hideBottomBar: Bool
    @ObservedObject private var activityService = ActivityService.shared
    
    // Category Selection
    @State private var selectedCategory: ExerciseCategory = .kotoba
    @State private var activeWorkout: ActiveWorkout? = nil
    
    // Kotoba Configuration State
    @State private var kotobaConfig = QuizConfig.load()
    @State private var totalWords: Int = 966
    
    // Kana Configuration State
    @State private var kanaConfig = KanaQuizConfig.load()
    
    // Word Ranges (10 Words each)
    private var batchRanges: [(start: Int, end: Int)] {
        var batches: [(Int, Int)] = []
        let batchSize = 10
        var current = 1
        while current <= totalWords {
            let bEnd = min(current + batchSize - 1, totalWords)
            batches.append((current, bEnd))
            current += batchSize
            if batches.count >= 40 { break }
        }
        return batches
    }
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Header
                headerView
                
                // Mode Switcher (Kotoba, Kana, Kanji [disabled], Bunpou [disabled])
                categorySwitcher
                
                // Active Mode Configuration Body
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        switch selectedCategory {
                        case .kotoba:
                            kotobaConsoleView
                        case .kana:
                            kanaConsoleView
                        case .kanji, .bunpou:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                }
                
                Spacer(minLength: 10)
                
                // Sticky Action Button (Pinned at bottom, above bottom bar)
                bottomActionButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }
            
            // Full Screen Quiz Flow Overlays
            if activeWorkout == .vocab {
                ExerciseCoordinatorView(
                    initialConfig: kotobaConfig,
                    startImmediately: true,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            activeWorkout = nil
                            hideBottomBar = false
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .opacity))
                .zIndex(200)
            } else if activeWorkout == .kana {
                KanaExerciseCoordinatorView(
                    initialConfig: kanaConfig,
                    startImmediately: true,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            activeWorkout = nil
                            hideBottomBar = false
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .opacity))
                .zIndex(200)
            }
        }
        .onAppear {
            kotobaConfig = QuizConfig.load()
            kanaConfig = KanaQuizConfig.load()
            updateKotobaTotalWords()
        }
        .onChange(of: kotobaConfig.level) { _ in
            updateKotobaTotalWords()
        }
        .onChange(of: kotobaConfig.type) { _ in
            updateKotobaTotalWords()
        }
        .onChange(of: activeWorkout) { workout in
            hideBottomBar = (workout != nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ganbatte_shortcut_to_exercise"))) { notif in
            if let catStr = notif.userInfo?["category"] as? String {
                if catStr == "Kotoba" {
                    selectedCategory = .kotoba
                    if let levelRaw = notif.userInfo?["level"] as? String, let level = JLPTLevel(rawValue: levelRaw) {
                        kotobaConfig.level = level
                    }
                    if let start = notif.userInfo?["startWord"] as? Int {
                        kotobaConfig.startWord = start
                    }
                    if let end = notif.userInfo?["endWord"] as? Int {
                        kotobaConfig.endWord = end
                    }
                    updateKotobaTotalWords()
                } else if catStr == "Kana" {
                    selectedCategory = .kana
                    if let typeRaw = notif.userInfo?["kanaType"] as? String, let type = KanaType(rawValue: typeRaw) {
                        kanaConfig.kanaType = type
                    }
                }
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Exercise")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Train memory, speed, and accuracy")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            // Streak Pill
            HStack(spacing: 5) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(activityService.currentStreak > 0 ? Color(red: 0.95, green: 0.40, blue: 0.15) : AppTheme.textTertiary)
                
                Text(activityService.currentStreak > 0 ? "\(activityService.currentStreak)d" : "0d")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(AppTheme.buttonBorder, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
    
    // MARK: - Category Switcher (Option A: Kanji & Bunpou visible but disabled, no SOON badge)
    private var categorySwitcher: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ExerciseCategory.allCases) { cat in
                    let isSelected = selectedCategory == cat
                    let isAvailable = (cat == .kotoba || cat == .kana)
                    
                    Button(action: {
                        if isAvailable {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = cat
                            }
                        }
                    }) {
                        Text(cat.rawValue)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(
                                isSelected
                                ? .white
                                : (isAvailable ? AppTheme.textSecondary : AppTheme.textTertiary.opacity(0.8))
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                isSelected
                                ? AppTheme.accent
                                : (isAvailable ? Color.white : Color(hex: 0xF5F2EB).opacity(0.8))
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(
                                        isSelected ? Color.clear : (isAvailable ? AppTheme.buttonBorder : AppTheme.buttonBorder.opacity(0.4)),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: isSelected ? AppTheme.accent.opacity(0.25) : Color.clear, radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isAvailable)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 12)
    }
    
    // MARK: - Kotoba Live Console
    private var kotobaConsoleView: some View {
        VStack(spacing: 12) {
            // Card 1: JLPT Level & Word Range
            VStack(alignment: .leading, spacing: 12) {
                // JLPT Level Selection
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text("JLPT LEVEL")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .tracking(0.5)
                        
                        Spacer()
                        
                        Text("\(totalWords) Words Available")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppTheme.accent)
                    }
                    
                    HStack(spacing: 6) {
                        ForEach([JLPTLevel.n5, .n4, .n3, .n2, .n1, .all], id: \.self) { level in
                            let isLevelSelected = kotobaConfig.level == level
                            Button(action: {
                                kotobaConfig.level = level
                            }) {
                                Text(level.rawValue)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(isLevelSelected ? .white : AppTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 7)
                                    .background(isLevelSelected ? AppTheme.accent : AppTheme.inputBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider()
                
                // WORD RANGE (10 Words Quick Jump)
                VStack(alignment: .leading, spacing: 7) {
                    Text("WORD RANGE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .tracking(0.5)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) {
                            ForEach(batchRanges, id: \.start) { batch in
                                let isBatchSelected = kotobaConfig.startWord == batch.start && kotobaConfig.endWord == batch.end
                                Button(action: {
                                    kotobaConfig.startWord = batch.start
                                    kotobaConfig.endWord = batch.end
                                }) {
                                    Text("\(batch.start) – \(batch.end)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(isBatchSelected ? .white : AppTheme.textPrimary)
                                        .padding(.horizontal, 13)
                                        .padding(.vertical, 7)
                                        .background(isBatchSelected ? AppTheme.accent : AppTheme.inputBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                                .stroke(isBatchSelected ? Color.clear : AppTheme.buttonBorder.opacity(0.5), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                // Custom Range Stepper (Compact inline)
                HStack {
                    Text("Custom Range:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        // Start stepper
                        stepperControl(
                            value: $kotobaConfig.startWord,
                            range: 1...kotobaConfig.endWord
                        )
                        
                        Text("to")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                        
                        // End stepper
                        stepperControl(
                            value: $kotobaConfig.endWord,
                            range: kotobaConfig.startWord...totalWords
                        )
                    }
                }
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.buttonBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
            
            // Card 2: Question Style (Horizontal 3-Column) + Part of Speech
            VStack(alignment: .leading, spacing: 12) {
                // Header
                Text("QUESTION STYLE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
                    .tracking(0.5)
                
                // Horizontal 3-Column Selector
                HStack(spacing: 8) {
                    ForEach(QuestionType.allCases) { qType in
                        let isSelected = kotobaConfig.questionType == qType
                        Button(action: {
                            kotobaConfig.questionType = qType
                        }) {
                            VStack(spacing: 5) {
                                Image(systemName: qType.iconName)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(isSelected ? AppTheme.accent : AppTheme.textPrimary)
                                
                                Text(qTypeTitle(qType))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(isSelected ? AppTheme.accent : AppTheme.textPrimary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isSelected ? AppTheme.accentLight.opacity(0.4) : AppTheme.inputBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .stroke(isSelected ? AppTheme.accent : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Divider()
                    .padding(.vertical, 1)
                
                // Part of Speech Filters (Inline compact chips)
                VStack(alignment: .leading, spacing: 6) {
                    Text("PART OF SPEECH")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .tracking(0.5)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(WordType.allCases) { wType in
                                let isSelected = kotobaConfig.type == wType
                                Button(action: {
                                    kotobaConfig.type = wType
                                }) {
                                    Text(wType.rawValue)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                                        .padding(.horizontal, 11)
                                        .padding(.vertical, 6)
                                        .background(isSelected ? AppTheme.accent : AppTheme.inputBackground)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
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
    }
    
    // MARK: - Kana Live Console
    private var kanaConsoleView: some View {
        VStack(spacing: 12) {
            // Card 1: Script Selection
            VStack(alignment: .leading, spacing: 10) {
                Text("PRACTICE SCRIPT")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
                    .tracking(0.5)
                
                HStack(spacing: 12) {
                    ForEach(KanaType.allCases) { kType in
                        let isSelected = kanaConfig.kanaType == kType
                        Button(action: {
                            kanaConfig.kanaType = kType
                        }) {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            isSelected
                                            ? (kType == .hiragana ? AppTheme.accent : Color(red: 0.25, green: 0.48, blue: 0.88))
                                            : AppTheme.inputBackground
                                        )
                                        .frame(width: 40, height: 40)
                                    
                                    Text(kType == .hiragana ? "あ" : "ア")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                                }
                                
                                Text(kType.title)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                Text(kType == .hiragana ? "1,000 words" : "500 words")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isSelected ? AppTheme.accentLight.opacity(0.3) : Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(isSelected ? AppTheme.accent : AppTheme.buttonBorder, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.buttonBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
            
            // Card 2: Question Count Presets
            VStack(alignment: .leading, spacing: 10) {
                Text("QUESTION COUNT")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
                    .tracking(0.5)
                
                HStack(spacing: 8) {
                    ForEach([10, 20, 30, 50], id: \.self) { count in
                        let isSelected = kanaConfig.questionCount == count
                        Button(action: {
                            kanaConfig.questionCount = count
                        }) {
                            Text("\(count)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(isSelected ? AppTheme.accent : AppTheme.inputBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.buttonBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
            
            // Instructions Banner
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.accent)
                
                Text("Type the Romaji spelling as fast as you can. It advances instantly upon the correct answer!")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineSpacing(2)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.accentLight.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    // MARK: - Bottom Action Button (Unified Color and Clean Text)
    private var bottomActionButton: some View {
        Group {
            if selectedCategory == .kotoba {
                Button(action: {
                    kotobaConfig.save()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        activeWorkout = .vocab
                        hideBottomBar = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 15, weight: .bold))
                        Text("Start Quiz (\(kotobaConfig.questionCount) Questions)")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: AppTheme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(BubbleScaleButtonStyle())
            } else if selectedCategory == .kana {
                Button(action: {
                    kanaConfig.save()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        activeWorkout = .kana
                        hideBottomBar = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 15, weight: .bold))
                        Text("Start Quiz (\(kanaConfig.questionCount) Questions)")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: AppTheme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(BubbleScaleButtonStyle())
            }
        }
    }
    
    // MARK: - Stepper Control Helper
    private func stepperControl(value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack(spacing: 4) {
            Button(action: {
                if value.wrappedValue > range.lowerBound {
                    value.wrappedValue -= 1
                }
            }) {
                Image(systemName: "minus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(value.wrappedValue > range.lowerBound ? AppTheme.textPrimary : AppTheme.buttonDisabledText)
                    .frame(width: 24, height: 24)
                    .background(AppTheme.inputBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(value.wrappedValue <= range.lowerBound)
            
            Text("\(value.wrappedValue)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(AppTheme.textPrimary)
                .frame(minWidth: 28)
            
            Button(action: {
                if value.wrappedValue < range.upperBound {
                    value.wrappedValue += 1
                }
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(value.wrappedValue < range.upperBound ? AppTheme.textPrimary : AppTheme.buttonDisabledText)
                    .frame(width: 24, height: 24)
                    .background(AppTheme.inputBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(value.wrappedValue >= range.upperBound)
        }
    }
    
    // MARK: - Helper Methods
    private func qTypeTitle(_ qType: QuestionType) -> String {
        switch qType {
        case .image: return "Image"
        case .sound: return "Audio"
        case .sentence: return "Fill-in"
        }
    }
    
    private func updateKotobaTotalWords() {
        let count = DatabaseService.shared.countWords(level: kotobaConfig.level, type: kotobaConfig.type)
        totalWords = max(count, 4)
        if kotobaConfig.endWord > totalWords {
            kotobaConfig.endWord = totalWords
        }
        if kotobaConfig.startWord > kotobaConfig.endWord {
            kotobaConfig.startWord = max(1, kotobaConfig.endWord - 9)
        }
    }
}
