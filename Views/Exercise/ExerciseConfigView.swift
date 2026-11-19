import SwiftUI

struct ExerciseConfigView: View {
    @Binding var config: QuizConfig
    var onStartQuiz: (QuizConfig) -> Void
    var onDismiss: () -> Void
    
    @State private var totalWords: Int = 40
    @State private var startText: String = "1"
    @State private var endText: String = "10"
    
    var batchRanges: [(start: Int, end: Int)] {
        var batches: [(Int, Int)] = []
        let batchSize = 10
        var current = 1
        while current <= totalWords {
            let bEnd = min(current + batchSize - 1, totalWords)
            batches.append((current, bEnd))
            current += batchSize
        }
        return batches
    }
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: onDismiss) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(AppTheme.accent)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text("Word Practice")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    // Invisible balancing spacer
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18))
                        Text("Back")
                            .font(.system(size: 18))
                    }
                    .opacity(0)
                }
                .padding(.horizontal, 20)
                #if os(macOS)
                .padding(.top, 36)
                #else
                .padding(.top, 16)
                #endif
                .padding(.bottom, 16)
                .background(AppTheme.background)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // Section 1: Question Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("QUESTION TYPE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.textSecondary)
                                .tracking(0.5)
                            
                            VStack(spacing: 8) {
                                ForEach(QuestionType.allCases) { qType in
                                    Button(action: {
                                        config.questionType = qType
                                    }) {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(config.questionType == qType ? AppTheme.accent : AppTheme.inputBackground)
                                                    .frame(width: 36, height: 36)
                                                
                                                Image(systemName: qType.iconName)
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundColor(config.questionType == qType ? .white : AppTheme.textPrimary)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(qType.title)
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundColor(AppTheme.textPrimary)
                                                
                                                Text(qType.subtitle)
                                                    .font(.system(size: 11, weight: .regular))
                                                    .foregroundColor(AppTheme.textSecondary)
                                            }
                                            
                                            Spacer()
                                            
                                            if config.questionType == qType {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(AppTheme.accent)
                                            } else {
                                                Circle()
                                                    .stroke(AppTheme.buttonBorder, lineWidth: 1.5)
                                                    .frame(width: 18, height: 18)
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(config.questionType == qType ? AppTheme.accentLight.opacity(0.5) : Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(config.questionType == qType ? AppTheme.accent : AppTheme.buttonBorder, lineWidth: config.questionType == qType ? 1.5 : 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Section 2: Difficulty
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DIFFICULTY")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.textSecondary)
                                .tracking(0.5)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(JLPTLevel.allCases, id: \.self) { level in
                                        Button(action: {
                                            config.level = level
                                            updateTotalWords()
                                        }) {
                                            Text(level.rawValue)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(config.level == level ? .white : AppTheme.textPrimary)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(config.level == level ? AppTheme.accent : Color.white)
                                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .stroke(config.level == level ? AppTheme.accent : AppTheme.buttonBorder, lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        
                        // Section 3: Word Type
                        VStack(alignment: .leading, spacing: 10) {
                            Text("WORD TYPE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.textSecondary)
                                .tracking(0.5)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(WordType.allCases, id: \.self) { wType in
                                        Button(action: {
                                            config.type = wType
                                            updateTotalWords()
                                        }) {
                                            Text(wType.rawValue)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(config.type == wType ? .white : AppTheme.textPrimary)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(config.type == wType ? AppTheme.accent : Color.white)
                                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .stroke(config.type == wType ? AppTheme.accent : AppTheme.buttonBorder, lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        
                        // Section 4: Word Range (Quick Batches + Slider + Manual Inputs)
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("WORD RANGE")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AppTheme.textSecondary)
                                    .tracking(0.5)
                                
                                Spacer()
                                
                                Text("\(totalWords) words available")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            
                            // Quick Batch Chips (e.g. 1-10, 11-20, 21-30, etc.)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(batchRanges.enumerated()), id: \.offset) { _, batch in
                                        let isSelected = (config.startWord == batch.start && config.endWord == batch.end)
                                        Button(action: {
                                            config.startWord = batch.start
                                            config.endWord = batch.end
                                            startText = "\(batch.start)"
                                            endText = "\(batch.end)"
                                        }) {
                                            Text("\(batch.start) – \(batch.end)")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(isSelected ? AppTheme.accent : Color.white)
                                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                        .stroke(isSelected ? AppTheme.accent : AppTheme.buttonBorder, lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            
                            // Manual Inputs (Start & End with Stepper and Direct Input)
                            HStack(spacing: 12) {
                                // Start Input Card
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("START")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    HStack(spacing: 8) {
                                        Button(action: {
                                            if config.startWord > 1 {
                                                config.startWord -= 1
                                                startText = "\(config.startWord)"
                                            }
                                        }) {
                                            Image(systemName: "minus")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(config.startWord > 1 ? AppTheme.textPrimary : AppTheme.buttonDisabledText)
                                                .frame(width: 28, height: 28)
                                                .background(AppTheme.inputBackground)
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(config.startWord <= 1)
                                        
                                        TextField("1", text: $startText)
                                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                                            .foregroundColor(AppTheme.textPrimary)
                                            .multilineTextAlignment(.center)
                                            .textFieldStyle(.plain)
                                            .onChange(of: startText) { val in
                                                if let num = Int(val.trimmingCharacters(in: .whitespaces)) {
                                                    let clamped = max(1, min(num, totalWords))
                                                    config.startWord = clamped
                                                    if config.endWord < clamped {
                                                        config.endWord = min(clamped + 9, totalWords)
                                                    }
                                                }
                                            }
                                        
                                        Button(action: {
                                            if config.startWord < totalWords {
                                                config.startWord += 1
                                                if config.endWord < config.startWord {
                                                    config.endWord = min(config.startWord + 9, totalWords)
                                                }
                                                startText = "\(config.startWord)"
                                            }
                                        }) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(config.startWord < totalWords ? AppTheme.textPrimary : AppTheme.buttonDisabledText)
                                                .frame(width: 28, height: 28)
                                                .background(AppTheme.inputBackground)
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(config.startWord >= totalWords)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(AppTheme.buttonBorder, lineWidth: 1)
                                    )
                                }
                                .frame(maxWidth: .infinity)
                                
                                Text("to")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary)
                                    .padding(.top, 14)
                                
                                // End Input Card
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("END")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    HStack(spacing: 8) {
                                        Button(action: {
                                            if config.endWord > 1 {
                                                config.endWord -= 1
                                                if config.startWord > config.endWord {
                                                    config.startWord = max(1, config.endWord - 9)
                                                }
                                                endText = "\(config.endWord)"
                                            }
                                        }) {
                                            Image(systemName: "minus")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(config.endWord > 1 ? AppTheme.textPrimary : AppTheme.buttonDisabledText)
                                                .frame(width: 28, height: 28)
                                                .background(AppTheme.inputBackground)
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(config.endWord <= 1)
                                        
                                        TextField("10", text: $endText)
                                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                                            .foregroundColor(AppTheme.textPrimary)
                                            .multilineTextAlignment(.center)
                                            .textFieldStyle(.plain)
                                            .onChange(of: endText) { val in
                                                if let num = Int(val.trimmingCharacters(in: .whitespaces)) {
                                                    let clamped = max(1, min(num, totalWords))
                                                    config.endWord = clamped
                                                    if config.startWord > clamped {
                                                        config.startWord = max(1, clamped - 9)
                                                    }
                                                }
                                            }
                                        
                                        Button(action: {
                                            if config.endWord < totalWords {
                                                config.endWord += 1
                                                endText = "\(config.endWord)"
                                            }
                                        }) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(config.endWord < totalWords ? AppTheme.textPrimary : AppTheme.buttonDisabledText)
                                                .frame(width: 28, height: 28)
                                                .background(AppTheme.inputBackground)
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(config.endWord >= totalWords)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(AppTheme.buttonBorder, lineWidth: 1)
                                    )
                                }
                                .frame(maxWidth: .infinity)
                            }
                            
                            // Info Badge
                            HStack(spacing: 6) {
                                Image(systemName: "scope")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppTheme.accent)
                                
                                Text("Selected: Words \(config.startWord) – \(config.endWord) (\(config.questionCount) Questions)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(AppTheme.accentLight.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                
                // Bottom Action: Start Quiz
                VStack {
                    Button(action: {
                        onStartQuiz(config)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 15, weight: .bold))
                            Text("Start Quiz (\(config.questionCount) Questions)")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: AppTheme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                .background(AppTheme.background)
            }
        }
        .onAppear {
            updateTotalWords()
        }
    }
    
    private func updateTotalWords() {
        let count = DatabaseService.shared.countWords(level: config.level, type: config.type)
        totalWords = max(count, 4)
        if config.endWord > totalWords {
            config.endWord = totalWords
        }
        if config.startWord > config.endWord {
            config.startWord = max(1, config.endWord - 9)
        }
        startText = "\(config.startWord)"
        endText = "\(config.endWord)"
    }
}
