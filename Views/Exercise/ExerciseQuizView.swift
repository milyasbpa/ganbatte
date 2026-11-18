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
                    Button(action: {
                        showQuitConfirmation = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Quit")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(AppTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // Question Counter & Timer
                    VStack(spacing: 2) {
                        Text("Question \(currentIndex + 1) / \(questions.count)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "stopwatch")
                                .font(.system(size: 11))
                            Text(String(format: "%.1fs", currentElapsed))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(AppTheme.accent)
                    }
                    
                    Spacer()
                    
                    // Invisible balancing element
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                        Text("Quit")
                            .font(.system(size: 16))
                    }
                    .opacity(0)
                }
                .padding(.horizontal, 20)
                #if os(macOS)
                .padding(.top, 36)
                #else
                .padding(.top, 16)
                #endif
                .padding(.bottom, 14)
                .background(AppTheme.background)
                
                // Progress Bar
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
            VStack(spacing: 10) {
                Text("Listen to the pronunciation and select the correct word:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    AudioService.shared.speak(currentQuestion.targetWord.kana)
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 76, height: 76)
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.accent, lineWidth: 2)
                            )
                            .shadow(color: AppTheme.accent.opacity(0.15), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 28))
                            .foregroundColor(AppTheme.accent)
                    }
                }
                .buttonStyle(.plain)
                
                Text("Tap to replay audio")
                    .font(.system(size: 11))
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
                
                // Masked Japanese Sentence
                Text(currentQuestion.maskedSentenceJa)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineSpacing(5)
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
    
    // MARK: - Keyboard Monitor (macOS)
    private func setupKeyMonitor() {
        #if os(macOS)
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard !isShowingFeedback else { return event }
            
            // Number keys 1, 2, 3, 4
            if let chars = event.characters, let num = Int(chars), num >= 1 && num <= 4 {
                selectOption(num - 1)
                return nil
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
