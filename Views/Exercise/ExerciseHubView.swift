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
    
    // Quick Batch Presets (10 Words each)
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
                
                // Mode Switcher (Kotoba, Kana, Kanji, Bunpou)
                categorySwitcher
                
                // Active Mode Configuration Body
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        switch selectedCategory {
                        case .kotoba:
                            kotobaConsoleView
                        case .kana:
                            kanaConsoleView
                        case .kanji:
                            comingSoonConsoleView(
                                title: "Kanji Practice",
                                kanjiText: "漢字",
                                description: "Radicals, Onyomi, Kunyomi readings, and stroke order quizzes will be available in the upcoming update."
                            )
                        case .bunpou:
                            comingSoonConsoleView(
                                title: "Bunpou Practice",
                                kanjiText: "文法",
                                description: "Sentence patterns, particle fill-ins, and grammatical ordering drills will be available in the upcoming update."
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 100)
                }
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
        .padding(.bottom, 14)
    }
    
    // MARK: - Category Switcher (Kotoba, Kana, Kanji, Bunpou)
    private var categorySwitcher: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ExerciseCategory.allCases) { cat in
                    let isSelected = selectedCategory == cat
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = cat
                        }
                    }) {
                        HStack(spacing: 5) {
                            Text(cat.rawValue)
                                .font(.system(size: 13, weight: .bold))
                            
                            if cat == .kanji || cat == .bunpou {
                                Text("SOON")
                                    .font(.system(size: 8, weight: .black))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.black.opacity(0.06))
                                    .clipShape(Capsule())
                            }
                        }
                        .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(isSelected ? AppTheme.accent : Color.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.clear : AppTheme.buttonBorder, lineWidth: 1)
                        )
                        .shadow(color: isSelected ? AppTheme.accent.opacity(0.25) : Color.clear, radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 14)
    }
    
    // MARK: - Kotoba Live Console
    private var kotobaConsoleView: some View {
        VStack(spacing: 14) {
            // Card 1: JLPT Level & Word Batches
            VStack(alignment: .leading, spacing: 14) {
                // JLPT Level Selection
                VStack(alignment: .leading, spacing: 8) {
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
                    
                    HStack(spacing: 8) {
                        ForEach([JLPTLevel.n5, .n4, .n3, .n2, .n1, .all], id: \.self) { level in
                            let isLevelSelected = kotobaConfig.level == level
                            Button(action: {
                                kotobaConfig.level = level
                            }) {
                                Text(level.rawValue)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(isLevelSelected ? .white : AppTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(isLevelSelected ? AppTheme.accent : AppTheme.inputBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider()
                
                // 10-Word Quick Batches
                VStack(alignment: .leading, spacing: 9) {
                    Text("10-WORD BATCHES")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .tracking(0.5)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(batchRanges, id: \.start) { batch in
                                let isBatchSelected = kotobaConfig.startWord == batch.start && kotobaConfig.endWord == batch.end
                                Button(action: {
                                    kotobaConfig.startWord = batch.start
                                    kotobaConfig.endWord = batch.end
                                }) {
                                    Text("\(batch.start) – \(batch.end)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(isBatchSelected ? .white : AppTheme.textPrimary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(isBatchSelected ? AppTheme.accent : AppTheme.inputBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(isBatchSelected ? Color.clear : AppTheme.buttonBorder.opacity(0.5), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                // Custom Range Stepper (Collapsible / Compact)
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
                .padding(.top, 2)
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.buttonBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
            
            // Card 2: Question Style
            VStack(alignment: .leading, spacing: 10) {
                Text("QUESTION STYLE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
                    .tracking(0.5)
                
                VStack(spacing: 8) {
                    ForEach(QuestionType.allCases) { qType in
                        let isSelected = kotobaConfig.questionType == qType
                        Button(action: {
                            kotobaConfig.questionType = qType
                        }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(isSelected ? AppTheme.accent : AppTheme.inputBackground)
                                        .frame(width: 34, height: 34)
                                    
                                    Image(systemName: qType.iconName)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(qType.title)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    
                                    Text(qType.subtitle)
                                        .font(.system(size: 11))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(isSelected ? AppTheme.accent : AppTheme.buttonDisabledText)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isSelected ? AppTheme.accentLight.opacity(0.3) : Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(isSelected ? AppTheme.accent.opacity(0.4) : AppTheme.buttonBorder.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.buttonBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
            
            // Card 3: Part of Speech Filter
            VStack(alignment: .leading, spacing: 10) {
                Text("PART OF SPEECH")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
                    .tracking(0.5)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(WordType.allCases) { wType in
                            let isSelected = kotobaConfig.type == wType
                            Button(action: {
                                kotobaConfig.type = wType
                            }) {
                                Text(wType.rawValue)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(isSelected ? AppTheme.accent : AppTheme.inputBackground)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.buttonBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
            
            // Action Button: Start Kotoba Quiz
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
                    Text("Start Kotoba Quiz (\(kotobaConfig.questionCount) Questions)")
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
            .padding(.top, 4)
        }
    }
    
    // MARK: - Kana Live Console
    private var kanaConsoleView: some View {
        VStack(spacing: 14) {
            // Card 1: Script Selection
            VStack(alignment: .leading, spacing: 12) {
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
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            isSelected
                                            ? (kType == .hiragana ? AppTheme.accent : Color(red: 0.25, green: 0.48, blue: 0.88))
                                            : AppTheme.inputBackground
                                        )
                                        .frame(width: 44, height: 44)
                                    
                                    Text(kType == .hiragana ? "あ" : "ア")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                                }
                                
                                Text(kType.title)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                Text(kType == .hiragana ? "1,000 words" : "500 loanwords")
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
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
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.buttonBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
            
            // Card 2: Question Count Presets
            VStack(alignment: .leading, spacing: 12) {
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
                                .padding(.vertical, 10)
                                .background(isSelected ? AppTheme.accent : AppTheme.inputBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.buttonBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
            
            // Instructions Pill
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.accent)
                
                Text("Type the Romaji spelling as fast as you can. It advances instantly upon the correct answer!")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineSpacing(2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.accentLight.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            
            // Action Button: Start Kana Speed Quiz
            Button(action: {
                kanaConfig.save()
                withAnimation(.easeInOut(duration: 0.25)) {
                    activeWorkout = .kana
                    hideBottomBar = true
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text("Start Kana Speed Quiz (\(kanaConfig.questionCount) Words)")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.35, green: 0.40, blue: 0.85), Color(red: 0.55, green: 0.35, blue: 0.90)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color(red: 0.35, green: 0.40, blue: 0.85).opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(BubbleScaleButtonStyle())
            .padding(.top, 4)
        }
    }
    
    // MARK: - Coming Soon Console (Kanji & Bunpou)
    private func comingSoonConsoleView(
        title: String,
        kanjiText: String,
        description: String
    ) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.04))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle().stroke(AppTheme.buttonBorder, lineWidth: 1)
                    )
                
                Text(kanjiText)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding(.top, 10)
            
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("SOON")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.05))
                        .clipShape(Capsule())
                }
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 10)
            }
            
            // Frosted Level Pills
            HStack(spacing: 8) {
                ForEach(["N5", "N4", "N3", "N2", "N1"], id: \.self) { lvl in
                    Text(lvl)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textTertiary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.inputBackground.opacity(0.6))
                        .clipShape(Capsule())
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 10)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.buttonBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
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
