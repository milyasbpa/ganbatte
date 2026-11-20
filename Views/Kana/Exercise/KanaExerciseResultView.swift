import SwiftUI

struct KanaExerciseResultView: View {
    let summary: KanaSessionSummary
    var onRetrySameQuestions: () -> Void
    var onChangeConfig: () -> Void
    var onFinish: () -> Void
    
    @ObservedObject private var activityService = ActivityService.shared
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Text("Kana Speed Results")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
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
                    VStack(spacing: 18) {
                        // Unlocked Medal Banner
                        if let medal = activityService.newlyUnlockedMedal {
                            unlockedMedalBanner(medal)
                        }
                        
                        // 1. Score Summary Card
                        VStack(spacing: 14) {
                            Text("FINAL SCORE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.textSecondary)
                                .tracking(0.6)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(summary.score)")
                                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                                    .foregroundColor(summary.score >= 70 ? Color(hex: 0x34C759) : AppTheme.accent)
                                
                                Text("/ 100")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            
                            Divider()
                                .background(AppTheme.cardBorder)
                                .padding(.horizontal, 10)
                            
                            // Stats Row
                            HStack {
                                VStack(spacing: 4) {
                                    Text("ACCURACY")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(AppTheme.textSecondary)
                                    Text("\(summary.correctCount) / \(summary.totalQuestions)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                
                                Rectangle()
                                    .fill(AppTheme.cardBorder)
                                    .frame(width: 1, height: 28)
                                
                                VStack(spacing: 4) {
                                    Text("TOTAL TIME")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(AppTheme.textSecondary)
                                    Text(String(format: "%.1fs", summary.totalTimeSeconds))
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                
                                Rectangle()
                                    .fill(AppTheme.cardBorder)
                                    .frame(width: 1, height: 28)
                                
                                VStack(spacing: 4) {
                                    Text("AVG SPEED")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(AppTheme.textSecondary)
                                    Text(String(format: "%.1fs/word", summary.averageTimeSeconds))
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.top, 2)
                        }
                        .padding(.vertical, 18)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(AppTheme.buttonBorder, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
                        
                        // 2. Word Breakdown List
                        VStack(alignment: .leading, spacing: 10) {
                            Text("WORD BREAKDOWN")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.textSecondary)
                                .tracking(0.5)
                            
                            VStack(spacing: 8) {
                                ForEach(Array(summary.results.enumerated()), id: \.offset) { index, res in
                                    resultRow(index: index + 1, res: res)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                
                // Bottom 3 Action Buttons (Pinned)
                VStack(spacing: 10) {
                    // 1. Primary: Retry Same Words
                    Button(action: onRetrySameQuestions) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 15, weight: .bold))
                            Text("Retry Same Words")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: AppTheme.accent.opacity(0.25), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                    
                    // 2. Secondary: Change Quiz Settings
                    Button(action: onChangeConfig) {
                        HStack(spacing: 8) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Change Quiz Settings")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.buttonBorder, lineWidth: 1.2)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // 3. Tertiary: Finish / Back to Kana Chart
                    Button(action: onFinish) {
                        Text("← Finish (Back to Kana)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 16)
                .background(AppTheme.background)
            }
        }
        .onDisappear {
            activityService.newlyUnlockedMedal = nil
        }
    }
    
    @ViewBuilder
    private func resultRow(index: Int, res: KanaQuizResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // Word Number & Status badge
                HStack(spacing: 6) {
                    Text("#\(index)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: res.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(res.isCorrect ? "Correct" : "Incorrect")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(res.isCorrect ? Color(hex: 0x34C759) : AppTheme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        (res.isCorrect ? Color(hex: 0x34C759) : AppTheme.accent).opacity(0.12)
                    )
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                // Time Taken
                HStack(spacing: 4) {
                    Image(systemName: "stopwatch")
                        .font(.system(size: 10))
                    Text(String(format: "%.1fs", res.timeSeconds))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                }
                .foregroundColor(AppTheme.textSecondary)
            }
            
            // Kana Word and Meaning
            HStack(alignment: .firstTextBaseline) {
                Text(res.question.word.kana)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(res.question.word.meaningEn)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
                
                Spacer()
            }
            
            // Answers (Your input vs Expected Romaji)
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("Typed:")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(AppTheme.textTertiary)
                    Text(res.userAnswer)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(res.isCorrect ? Color(hex: 0x34C759) : AppTheme.accent)
                }
                
                if !res.isCorrect {
                    HStack(spacing: 4) {
                        Text("Expected:")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(AppTheme.textTertiary)
                        Text(res.question.word.romaji)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(res.isCorrect ? Color.green.opacity(0.25) : Color.red.opacity(0.25), lineWidth: 1)
        )
    }
    
    private func unlockedMedalBanner(_ medal: Medal) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(medal.tier.color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: medal.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(medal.tier.color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.15))
                    Text("NEW TROPHY UNLOCKED!")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.15))
                }
                
                Text(medal.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(medal.description)
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(medal.tier.color.opacity(0.4), lineWidth: 1.5)
        )
        .shadow(color: medal.tier.color.opacity(0.2), radius: 8, x: 0, y: 3)
    }
}
