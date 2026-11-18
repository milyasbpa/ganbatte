import SwiftUI

struct KanaSpeedQuizView: View {
    let questions: [KanaQuizQuestion]
    let config: KanaQuizConfig
    var onFinish: (KanaSessionSummary) -> Void
    var onQuit: () -> Void
    
    @State private var currentIndex: Int = 0
    @State private var inputText: String = ""
    @State private var questionElapsedTime: Double = 0.0
    @State private var totalSessionTime: Double = 0.0
    @State private var timerActive: Bool = true
    @State private var questionStartTime: Date = Date()
    @State private var results: [KanaQuizResult] = []
    
    enum FeedbackState {
        case none
        case correct
        case wrong
    }
    @State private var feedbackState: FeedbackState = .none
    @State private var revealedAnswer: String? = nil
    @State private var shakeOffset: CGFloat = 0
    @State private var showQuitAlert: Bool = false
    
    @FocusState private var isInputFocused: Bool
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var currentQuestion: KanaQuizQuestion? {
        guard currentIndex >= 0 && currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            if let question = currentQuestion {
                VStack(spacing: 0) {
                    // Header (Quit, Word Counter, Skip)
                    HStack {
                        // Quit Button
                        Button(action: {
                            showQuitAlert = true
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
                        
                        // Word Counter
                        Text("Word \(currentIndex + 1) / \(questions.count)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Spacer()
                        
                        // Skip Button
                        Button(action: {
                            submitAnswer(isSkip: true)
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
                        .disabled(feedbackState != .none)
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
                            let progress = CGFloat(currentIndex + 1) / CGFloat(max(questions.count, 1))
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(AppTheme.cardBorder.opacity(0.6))
                                    .frame(height: 5)
                                
                                Capsule()
                                    .fill(AppTheme.accent)
                                    .frame(width: geo.size.width * progress, height: 5)
                                    .animation(.easeInOut(duration: 0.25), value: currentIndex)
                            }
                        }
                        .frame(height: 5)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "stopwatch")
                                .font(.system(size: 11, weight: .semibold))
                            Text(formatTime(questionElapsedTime))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .lineLimit(1)
                                .fixedSize()
                        }
                        .foregroundColor(AppTheme.accent)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 28) {
                            // Instruction Subtitle
                            Text("Type the Romaji reading of this \(config.kanaType.title):")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                            
                            // Question Card (Large Bold Kana Word)
                            VStack(spacing: 12) {
                                Text(question.word.kana)
                                    .font(.system(size: 48, weight: .heavy))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .tracking(2)
                                    .padding(.top, 16)
                                
                                Text(question.word.meaningEn)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary)
                                    .padding(.bottom, 16)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(AppTheme.buttonBorder, lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                            
                            // Input Box (Autofocused, Speed Typing)
                            VStack(spacing: 8) {
                                HStack(spacing: 10) {
                                    Image(systemName: "keyboard")
                                        .font(.system(size: 18))
                                        .foregroundColor(borderColor)
                                    
                                    TextField("Type romaji here...", text: $inputText)
                                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .textFieldStyle(.plain)
                                        .autocorrectionDisabled()
                                        .focused($isInputFocused)
                                        .disabled(feedbackState != .none)
                                        .onSubmit {
                                            submitAnswer(isSkip: false)
                                        }
                                        .onChange(of: inputText) { newVal in
                                            checkLiveInput(newVal)
                                        }
                                    
                                    if !inputText.isEmpty && feedbackState == .none {
                                        Button(action: {
                                            inputText = ""
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(AppTheme.textTertiary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(borderColor, lineWidth: feedbackState == .none ? 1.5 : 2.5)
                                )
                                .shadow(color: borderColor.opacity(0.15), radius: 8, x: 0, y: 3)
                                .offset(x: shakeOffset)
                                
                                // Feedback message (When wrong, reveal answer)
                                if feedbackState == .wrong, let ans = revealedAnswer {
                                    HStack(spacing: 6) {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundColor(.red)
                                        Text("Correct answer: \(ans)")
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                            .foregroundColor(.red)
                                    }
                                    .transition(.opacity)
                                    .padding(.top, 4)
                                } else if feedbackState == .correct {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Correct!")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.green)
                                    }
                                    .transition(.opacity)
                                    .padding(.top, 4)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Keyboard hint
                            Text("Press Return ↵ to submit or skip")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(AppTheme.textTertiary)
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            
            // Quit confirmation modal
            if showQuitAlert {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { showQuitAlert = false }
                
                VStack(spacing: 16) {
                    Text("Quit Quiz?")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Your quiz progress will not be saved.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 12) {
                        Button("Stay") {
                            showQuitAlert = false
                            isInputFocused = true
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(AppTheme.inputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .buttonStyle(.plain)
                        
                        Button("Quit") {
                            showQuitAlert = false
                            onQuit()
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(Color.red.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
                .frame(width: 270)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                .zIndex(100)
            }
        }
        .onAppear {
            startQuestion()
        }
        .onReceive(timer) { _ in
            if timerActive && feedbackState == .none {
                questionElapsedTime += 0.1
                totalSessionTime += 0.1
            }
        }
    }
    
    private var borderColor: Color {
        switch feedbackState {
        case .none:
            return isInputFocused ? AppTheme.accent : AppTheme.buttonBorder
        case .correct:
            return .green
        case .wrong:
            return .red
        }
    }
    
    private func startQuestion() {
        inputText = ""
        revealedAnswer = nil
        feedbackState = .none
        questionElapsedTime = 0.0
        questionStartTime = Date()
        timerActive = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isInputFocused = true
        }
    }
    
    // Live checking for instant pass (Monkeytype style)
    private func checkLiveInput(_ text: String) {
        guard feedbackState == .none, let question = currentQuestion else { return }
        let clean = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        if question.acceptableAnswers.contains(clean) {
            // STOP TIMER IMMEDIATELY
            timerActive = false
            let pureTime = max(0.1, Date().timeIntervalSince(questionStartTime))
            
            results.append(KanaQuizResult(
                question: question,
                userAnswer: clean,
                isCorrect: true,
                timeSeconds: pureTime
            ))
            
            withAnimation(.easeInOut(duration: 0.15)) {
                feedbackState = .correct
            }
            
            // Advance after brief 0.2s flash (not counted in question time)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                advanceToNext()
            }
        }
    }
    
    // Manual submission (e.g. Enter pressed or Skip tapped)
    private func submitAnswer(isSkip: Bool) {
        guard feedbackState == .none, let question = currentQuestion else { return }
        
        // STOP TIMER IMMEDIATELY
        timerActive = false
        let pureTime = max(0.1, Date().timeIntervalSince(questionStartTime))
        let clean = inputText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let isCorrect = !isSkip && question.acceptableAnswers.contains(clean)
        
        results.append(KanaQuizResult(
            question: question,
            userAnswer: isSkip ? "(Skipped)" : (clean.isEmpty ? "(Blank)" : clean),
            isCorrect: isCorrect,
            timeSeconds: pureTime
        ))
        
        if isCorrect {
            withAnimation(.easeInOut(duration: 0.15)) {
                feedbackState = .correct
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                advanceToNext()
            }
        } else {
            revealedAnswer = question.word.romaji
            withAnimation(.easeInOut(duration: 0.15)) {
                feedbackState = .wrong
            }
            
            // Trigger quick shake
            withAnimation(.linear(duration: 0.08).repeatCount(3, autoreverses: true)) {
                shakeOffset = 8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                shakeOffset = 0
            }
            
            // Advance after 1.0s to allow user to see correct answer (not counted in question time)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                advanceToNext()
            }
        }
    }
    
    private func advanceToNext() {
        if currentIndex + 1 < questions.count {
            currentIndex += 1
            startQuestion()
        } else {
            // Quiz completed
            let correctCount = results.filter { $0.isCorrect }.count
            let pureTotalTime = results.reduce(0.0) { $0 + $1.timeSeconds }
            let summary = KanaSessionSummary(
                totalQuestions: questions.count,
                correctCount: correctCount,
                totalTimeSeconds: pureTotalTime,
                results: results
            )
            onFinish(summary)
        }
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
}
