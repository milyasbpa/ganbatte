import SwiftUI

struct ExerciseConfigView: View {
    @Binding var config: QuizConfig
    var onStartQuiz: (QuizConfig) -> Void
    var onDismiss: () -> Void
    
    let countPresets = [5, 10, 15, 20]
    
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
                            Text("Words")
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
                        Text("Words")
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
                    VStack(alignment: .leading, spacing: 22) {
                        // Section 1: Question Type
                        VStack(alignment: .leading, spacing: 10) {
                            Text("QUESTION TYPE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.textSecondary)
                                .tracking(0.5)
                            
                            VStack(spacing: 10) {
                                ForEach(QuestionType.allCases) { qType in
                                    Button(action: {
                                        config.questionType = qType
                                    }) {
                                        HStack(spacing: 14) {
                                            ZStack {
                                                Circle()
                                                    .fill(config.questionType == qType ? AppTheme.accent : AppTheme.inputBackground)
                                                    .frame(width: 42, height: 42)
                                                
                                                Image(systemName: qType.iconName)
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(config.questionType == qType ? .white : AppTheme.textPrimary)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(qType.title)
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(AppTheme.textPrimary)
                                                
                                                Text(qType.subtitle)
                                                    .font(.system(size: 12, weight: .regular))
                                                    .foregroundColor(AppTheme.textSecondary)
                                            }
                                            
                                            Spacer()
                                            
                                            if config.questionType == qType {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(AppTheme.accent)
                                            } else {
                                                Circle()
                                                    .stroke(AppTheme.buttonBorder, lineWidth: 1.5)
                                                    .frame(width: 20, height: 20)
                                            }
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(config.questionType == qType ? AppTheme.accentLight.opacity(0.5) : Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(config.questionType == qType ? AppTheme.accent : AppTheme.buttonBorder, lineWidth: config.questionType == qType ? 1.5 : 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Section 2: Difficulty
                        VStack(alignment: .leading, spacing: 10) {
                            Text("DIFFICULTY")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.textSecondary)
                                .tracking(0.5)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(JLPTLevel.allCases, id: \.self) { level in
                                        Button(action: {
                                            config.level = level
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
                        
                        // Section 4: Question Count
                        VStack(alignment: .leading, spacing: 10) {
                            Text("NUMBER OF QUESTIONS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.textSecondary)
                                .tracking(0.5)
                            
                            // Preset Chips
                            HStack(spacing: 8) {
                                ForEach(countPresets, id: \.self) { preset in
                                    Button(action: {
                                        config.questionCount = preset
                                    }) {
                                        Text("\(preset)")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(config.questionCount == preset ? .white : AppTheme.textPrimary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(config.questionCount == preset ? AppTheme.accent : Color.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(config.questionCount == preset ? AppTheme.accent : AppTheme.buttonBorder, lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            // Custom Stepper
                            HStack {
                                Text("Custom Count")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary)
                                
                                Spacer()
                                
                                HStack(spacing: 14) {
                                    Button(action: {
                                        if config.questionCount > 3 {
                                            config.questionCount -= 1
                                        }
                                    }) {
                                        Image(systemName: "minus")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(config.questionCount > 3 ? AppTheme.textPrimary : AppTheme.buttonDisabledText)
                                            .frame(width: 32, height: 32)
                                            .background(AppTheme.inputBackground)
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(config.questionCount <= 3)
                                    
                                    Text("\(config.questionCount)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .frame(minWidth: 28)
                                    
                                    Button(action: {
                                        if config.questionCount < 50 {
                                            config.questionCount += 1
                                        }
                                    }) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(config.questionCount < 50 ? AppTheme.textPrimary : AppTheme.buttonDisabledText)
                                            .frame(width: 32, height: 32)
                                            .background(AppTheme.inputBackground)
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(config.questionCount >= 50)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(AppTheme.buttonBorder, lineWidth: 1)
                                )
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 20)
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
    }
}
