import SwiftUI

struct KanaExerciseConfigView: View {
    @Binding var config: KanaQuizConfig
    var onStartQuiz: (KanaQuizConfig) -> Void
    var onDismiss: () -> Void
    
    let countPresets = [10, 20, 30, 50]
    
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
                            Text("Kana")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(AppTheme.accent)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text("Kana Speed Practice")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    // Invisible spacer for balance
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18))
                        Text("Kana")
                            .font(.system(size: 18))
                    }
                    .opacity(0)
                }
                .padding(.horizontal, 20)
                #if os(macOS)
                .padding(.top, 16)
                #else
                .padding(.top, 16)
                #endif
                .padding(.bottom, 12)
                .background(AppTheme.background)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // Section 1: Kana Script Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PRACTICE SCRIPT")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.textSecondary)
                                .tracking(0.5)
                            
                            VStack(spacing: 8) {
                                ForEach(KanaType.allCases) { kType in
                                    let isSelected = config.kanaType == kType
                                    let wordCount = kType == .hiragana ? "1,000 common words" : "500 loanwords"
                                    let sample = kType == .hiragana ? "さくら、ねこ、たべる" : "コーヒー、テレビ、バス"
                                    
                                    Button(action: {
                                        config.kanaType = kType
                                    }) {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(isSelected ? AppTheme.accent : AppTheme.inputBackground)
                                                    .frame(width: 40, height: 40)
                                                
                                                Text(kType == .hiragana ? "あ" : "ア")
                                                    .font(.system(size: 20, weight: .bold))
                                                    .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 3) {
                                                HStack(spacing: 6) {
                                                    Text(kType.title)
                                                        .font(.system(size: 15, weight: .semibold))
                                                        .foregroundColor(AppTheme.textPrimary)
                                                    
                                                    Text("• \(wordCount)")
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundColor(AppTheme.textSecondary)
                                                }
                                                
                                                Text(sample)
                                                    .font(.system(size: 12, weight: .regular))
                                                    .foregroundColor(AppTheme.textTertiary)
                                            }
                                            
                                            Spacer()
                                            
                                            if isSelected {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(AppTheme.accent)
                                            } else {
                                                Circle()
                                                    .stroke(AppTheme.buttonBorder, lineWidth: 1.5)
                                                    .frame(width: 18, height: 18)
                                            }
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(isSelected ? AppTheme.accentLight.opacity(0.5) : Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(isSelected ? AppTheme.accent : AppTheme.buttonBorder, lineWidth: isSelected ? 1.5 : 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Section 2: Number of Questions
                        VStack(alignment: .leading, spacing: 10) {
                            Text("NUMBER OF QUESTIONS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.textSecondary)
                                .tracking(0.5)
                            
                            // Preset Chips
                            HStack(spacing: 8) {
                                ForEach(countPresets, id: \.self) { preset in
                                    let isSelected = config.questionCount == preset
                                    Button(action: {
                                        config.questionCount = preset
                                    }) {
                                        Text("\(preset)")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(isSelected ? AppTheme.accent : Color.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(isSelected ? AppTheme.accent : AppTheme.buttonBorder, lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            // Stepper Row
                            HStack {
                                Text("Custom Count")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary)
                                
                                Spacer()
                                
                                HStack(spacing: 12) {
                                    Button(action: {
                                        if config.questionCount > 5 {
                                            config.questionCount -= 5
                                        }
                                    }) {
                                        Image(systemName: "minus")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(config.questionCount > 5 ? AppTheme.textPrimary : AppTheme.buttonDisabledText)
                                            .frame(width: 32, height: 32)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(AppTheme.buttonBorder, lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(config.questionCount <= 5)
                                    
                                    Text("\(config.questionCount)")
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .frame(minWidth: 32)
                                    
                                    Button(action: {
                                        if config.questionCount < 100 {
                                            config.questionCount += 5
                                        }
                                    }) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(config.questionCount < 100 ? AppTheme.textPrimary : AppTheme.buttonDisabledText)
                                            .frame(width: 32, height: 32)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(AppTheme.buttonBorder, lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(config.questionCount >= 100)
                                }
                            }
                            .padding(.top, 4)
                        }
                        
                        // How it works info badge
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppTheme.accent)
                                
                                Text("Speed Typing Instructions")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                            
                            Text("Read the Kana word and type its Romaji spelling. As soon as you type the correct word, it auto-advances instantly! If unsure, press Enter to skip and see the answer.")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(AppTheme.textSecondary)
                                .lineSpacing(3)
                        }
                        .padding(14)
                        .background(AppTheme.accentLight.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                
                // Bottom Button
                VStack {
                    Button(action: {
                        onStartQuiz(config)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 15, weight: .bold))
                            Text("Start Speed Quiz (\(config.questionCount) Words)")
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
    }
}
