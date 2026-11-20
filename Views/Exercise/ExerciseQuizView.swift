import SwiftUI
#if os(macOS)
import AppKit
#endif

struct ExerciseQuizView: View {
    let questions: [QuizQuestion]
    let config: QuizConfig
    var onFinish: (QuizSessionResult) -> Void
    var onQuit: () -> Void
    
    @State private var currentIndex: Int = 0
    @State private var selectedOptionIndex: Int? = nil
    @State private var isShowingFeedback: Bool = false
    @State private var recordedResults: [QuestionResult] = []
    
    // Timer state
    @State private var questionStartTime: Date = Date()
    @State private var currentElapsed: TimeInterval = 0.0
    @State private var timer: Timer? = nil
    
    #if os(macOS)
    @State private var keyMonitor: Any?
    #endif
    
    @State private var showQuitConfirmation: Bool = false
    
    var currentQuestion: QuizQuestion {
        guard currentIndex >= 0 && currentIndex < questions.count else {
            return questions[0]
        }
        return questions[currentIndex]
    }
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (Pinned at top)
                HStack {
                    // Quit Button
                    Button(action: {
                        showQuitConfirmation = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                            Text("Quit")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.white.opacity(0.85))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(AppTheme.buttonBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 76, alignment: .leading)
                    
                    Spacer()
                    
                    // Question Counter
                    Text("Question \(currentIndex + 1) / \(questions.count)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    // Skip Button
                    Button(action: {
                        skipQuestion()
                    }) {
                        HStack(spacing: 4) {
                            Text("Skip")
                                .font(.system(size: 13, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.white.opacity(0.85))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(AppTheme.buttonBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isShowingFeedback)
                    .frame(minWidth: 76, alignment: .trailing)
                }
                .padding(.horizontal, 20)
                #if os(macOS)
                .padding(.top, 36)
                #else
                .padding(.top, 16)
                #endif
                .padding(.bottom, 12)
                .background(AppTheme.background)
                
                // Progress Bar & Timer Row
                HStack(spacing: 12) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(AppTheme.cardBorder.opacity(0.6))
                                .frame(height: 5)
                            
                            Capsule()
                                .fill(AppTheme.accent)
                                .frame(width: geo.size.width * CGFloat(currentIndex + 1) / CGFloat(max(questions.count, 1)), height: 5)
                                .animation(.easeInOut(duration: 0.25), value: currentIndex)
                        }
                    }
                    .frame(height: 5)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "stopwatch")
                            .font(.system(size: 11, weight: .semibold))
                        Text(formatTime(currentElapsed))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .foregroundColor(AppTheme.accent)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                
                // Question Content + Options
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        // 1. Question Prompt Area
                        questionPromptView
                            .frame(maxWidth: .infinity)
                            .padding(.top, 2)
                        
                        // 2. Options Grid (4 Multiple Choice Options)
                        VStack(spacing: 8) {
                            ForEach(Array(currentQuestion.options.enumerated()), id: \.element.id) { index, word in
                                optionCard(index: index, word: word)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
        }
        .onAppear {
            startQuestion()
            setupKeyMonitor()
        }
        .onDisappear {
            stopTimer()
            removeKeyMonitor()
        }
        .alert("Quit Quiz?", isPresented: $showQuitConfirmation) {
            Button("Stay", role: .cancel) {}
            Button("Quit", role: .destructive) {
                onQuit()
            }
        } message: {
            Text("Your quiz progress will not be saved.")
        }
    }
    
    // MARK: - Question Prompt View
    @ViewBuilder
    private var questionPromptView: some View {
        switch currentQuestion.questionType {
        case .sound:
            VStack(spacing: 12) {
                Text("Listen and choose the meaning:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    AudioService.shared.speak(currentQuestion.targetWord.kana)
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 58, height: 58)
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.accent, lineWidth: 2)
                            )
                            .shadow(color: AppTheme.accent.opacity(0.12), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(AppTheme.accent)
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 2)
                
                Text("Tap to replay audio")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.buttonBorder, lineWidth: 1)
            )
            
        case .image:
            VStack(spacing: 8) {
                Text("Select the word that matches the image:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                
                CardImageView(imageName: currentQuestion.targetWord.imageName, contentMode: .fit)
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(maxHeight: 185)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppTheme.cardBorder.opacity(0.8), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
            
        case .sentence:
            VStack(alignment: .leading, spacing: 10) {
                Text("Complete the missing word:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                
                // Masked Japanese Sentence with Furigana
                FuriganaText(
                    text: currentQuestion.maskedSentenceJa,
                    fontSize: 18,
                    furiganaSize: 10.5,
                    textColor: AppTheme.textPrimary,
                    furiganaColor: AppTheme.textSecondary,
                    boldKanji: true
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                
                // English Sentence Translation
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.top, 2)
                    
                    Text(currentQuestion.targetWord.exampleEn)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.buttonBorder, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Option Card
    private func optionCard(index: Int, word: Word) -> some View {
        let isSelected = selectedOptionIndex == index
        let isCorrect = index == currentQuestion.correctIndex
        
        // Micro-feedback colors
        var bgColor: Color = Color.white
        var borderColor: Color = AppTheme.buttonBorder
        var textColor: Color = AppTheme.textPrimary
        var subtextColor: Color = AppTheme.textSecondary
        var badgeBg: Color = AppTheme.inputBackground
        var badgeText: Color = AppTheme.textPrimary
        
        if isShowingFeedback {
            if isSelected && isCorrect {
                // Correctly chosen
                bgColor = Color(hex: 0x34C759)
                borderColor = Color(hex: 0x28A745)
                textColor = .white
                subtextColor = .white.opacity(0.9)
                badgeBg = .white.opacity(0.25)
                badgeText = .white
            } else if isSelected && !isCorrect {
                // Wrong choice
                bgColor = Color(hex: 0xFF3B30)
                borderColor = Color(hex: 0xDC3545)
                textColor = .white
                subtextColor = .white.opacity(0.9)
                badgeBg = .white.opacity(0.25)
                badgeText = .white
            } else if !isSelected && isCorrect {
                // Highlight the correct answer when user was wrong
                bgColor = Color(hex: 0xE8F5E9)
                borderColor = Color(hex: 0x34C759)
                textColor = Color(hex: 0x1B5E20)
                subtextColor = Color(hex: 0x2E7D32)
                badgeBg = Color(hex: 0x34C759)
                badgeText = .white
            }
        }
        
        return Button(action: {
            selectOption(index)
        }) {
            HStack(spacing: 12) {
                // Number Badge (1, 2, 3, 4)
                Text("\(index + 1)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(badgeText)
                    .frame(width: 30, height: 30)
                    .background(badgeBg)
                    .clipShape(Circle())
                
                if currentQuestion.questionType == .sound {
                    // English Meaning for audio exercises
                    VStack(alignment: .leading, spacing: 2) {
                        Text(word.meaningEn)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(textColor)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        if isShowingFeedback {
                            HStack(spacing: 6) {
                                Text(word.kanji.isEmpty ? word.kana : word.kanji)
                                    .font(.system(size: 12, weight: .bold))
                                
                                if !word.kanji.isEmpty && word.kanji != word.kana {
                                    Text("(\(word.kana))")
                                        .font(.system(size: 11, weight: .medium))
                                }
                            }
                            .foregroundColor(subtextColor)
                        }
                    }
                } else {
                    // Japanese Word (Kanji + Kana reading, NO Latin meaning)
                    HStack(spacing: 8) {
                        Text(word.kanji.isEmpty ? word.kana : word.kanji)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(textColor)
                        
                        if !word.kanji.isEmpty && word.kanji != word.kana {
                            Text("(\(word.kana))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(subtextColor)
                        }
                    }
                }
                
                Spacer()
                
                if isShowingFeedback {
                    if isCorrect {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? .white : Color(hex: 0x34C759))
                    } else if isSelected {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(borderColor, lineWidth: isShowingFeedback && (isSelected || isCorrect) ? 1.8 : 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .disabled(isShowingFeedback)
        #if os(iOS)
        .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: [])
        #endif
    }
    
    // MARK: - Game Logic
    private func startQuestion() {
        selectedOptionIndex = nil
        isShowingFeedback = false
        currentElapsed = 0.0
        questionStartTime = Date()
        
        startTimer()
        
        // Auto play audio if sound question
        if currentQuestion.questionType == .sound {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                AudioService.shared.speak(currentQuestion.targetWord.kana)
            }
        }
    }
    
    private func selectOption(_ index: Int) {
        guard !isShowingFeedback && index >= 0 && index < currentQuestion.options.count else { return }
        
        // 1. STOP TIMER IMMEDIATELY (PURE RESPONSE TIME!)
        let responseTime = Date().timeIntervalSince(questionStartTime)
        stopTimer()
        
        selectedOptionIndex = index
        let isCorrect = (index == currentQuestion.correctIndex)
        
        // 2. RECORD RESULT
        let result = QuestionResult(
            question: currentQuestion,
            selectedIndex: index,
            isCorrect: isCorrect,
            timeSpent: responseTime
        )
        recordedResults.append(result)
        
        // 3. SHOW MICRO-FEEDBACK
        isShowingFeedback = true
        
        // 4. AFTER 0.4 SECONDS, ADVANCE TO NEXT QUESTION
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            advanceToNextQuestion()
        }
    }
    
    private func skipQuestion() {
        guard !isShowingFeedback else { return }
        
        let responseTime = Date().timeIntervalSince(questionStartTime)
        stopTimer()
        
        // Record skipped question (selectedIndex: -1, isCorrect: false)
        let result = QuestionResult(
            question: currentQuestion,
            selectedIndex: -1,
            isCorrect: false,
            timeSpent: responseTime
        )
        recordedResults.append(result)
        
        isShowingFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            advanceToNextQuestion()
        }
    }
    
    private func advanceToNextQuestion() {
        if currentIndex < questions.count - 1 {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentIndex += 1
            }
            startQuestion()
        } else {
            // Quiz finished!
            let summary = QuizSessionResult(results: recordedResults, config: config)
            onFinish(summary)
        }
    }
    
    // MARK: - Timer Handling
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            currentElapsed = Date().timeIntervalSince(questionStartTime)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        if seconds < 60.0 {
            return String(format: "%.1fs", seconds)
        } else {
            let mins = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return String(format: "%d:%02d", mins, secs)
        }
    }
    
    // MARK: - Keyboard Monitor (macOS)
    private func setupKeyMonitor() {
        #if os(macOS)
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard !isShowingFeedback else { return event }
            
            if let chars = event.characters {
                // Number keys 1, 2, 3, 4
                if let num = Int(chars), num >= 1 && num <= 4 {
                    selectOption(num - 1)
                    return nil
                }
                // 's' or 'S' to skip
                if chars.lowercased() == "s" {
                    skipQuestion()
                    return nil
                }
            }
            return event
        }
        #endif
    }
    
    private func removeKeyMonitor() {
        #if os(macOS)
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        #endif
    }
}
