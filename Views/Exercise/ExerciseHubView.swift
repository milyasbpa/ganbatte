import SwiftUI

enum ActiveWorkout {
    case vocab
    case kana
}

struct ExerciseHubView: View {
    @Binding var hideBottomBar: Bool
    @ObservedObject private var activityService = ActivityService.shared
    @State private var activeWorkout: ActiveWorkout? = nil
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
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
                .padding(.bottom, 16)
                
                // Workout Arena Cards
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Card 1: Vocabulary Quiz
                        workoutCard(
                            title: "Vocabulary Quiz",
                            badge: "Workout",
                            badgeColor: AppTheme.accent,
                            iconName: "pencil.and.list.clipboard",
                            iconGradient: [AppTheme.accent, Color(red: 0.95, green: 0.45, blue: 0.25)],
                            description: "Test your vocabulary recall with image clues, audio pronunciation, and fill-in-the-blank sentences.",
                            chips: ["JLPT N5 – N1", "Audio & Kanji", "Custom Count"],
                            buttonTitle: "Start Workout",
                            buttonIcon: "play.fill",
                            action: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    activeWorkout = .vocab
                                    hideBottomBar = true
                                }
                            }
                        )
                        
                        // Card 2: Kana Speed Drill
                        workoutCard(
                            title: "Kana Speed Drill",
                            badge: "Sprint",
                            badgeColor: Color(red: 0.35, green: 0.40, blue: 0.85),
                            iconName: "bolt.fill",
                            iconGradient: [Color(red: 0.35, green: 0.40, blue: 0.85), Color(red: 0.55, green: 0.35, blue: 0.90)],
                            description: "High-intensity reaction drill to build instant recognition of Hiragana and Katakana characters.",
                            chips: ["Hiragana & Katakana", "Speed / Pace", "Audio Feedback"],
                            buttonTitle: "Start Speed Drill",
                            buttonIcon: "bolt.fill",
                            action: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    activeWorkout = .kana
                                    hideBottomBar = true
                                }
                            }
                        )
                        
                        // Card 3: Weak Words Blitz (Coming Soon)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.gray.opacity(0.12))
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "target")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text("Weak Words Blitz")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(AppTheme.textSecondary)
                                        
                                        Spacer()
                                        
                                        Text("Coming Soon")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(AppTheme.textTertiary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.gray.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                    
                                    Text("Smart adaptive practice targeting words you missed")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.textTertiary)
                                        .lineLimit(2)
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.black.opacity(0.04), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 90)
                }
            }
            
            // Overlays
            if activeWorkout == .vocab {
                ExerciseCoordinatorView(
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
        .onChange(of: activeWorkout) { workout in
            hideBottomBar = (workout != nil)
        }
    }
    
    // MARK: - Workout Card Builder
    private func workoutCard(
        title: String,
        badge: String,
        badgeColor: Color,
        iconName: String,
        iconGradient: [Color],
        description: String,
        chips: [String],
        buttonTitle: String,
        buttonIcon: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header row
            HStack(alignment: .top, spacing: 12) {
                LinearGradient(
                    colors: iconGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 46, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                )
                .shadow(color: iconGradient.first?.opacity(0.25) ?? Color.clear, radius: 6, x: 0, y: 3)
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Spacer()
                        
                        Text(badge.uppercased())
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(badgeColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(badgeColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineSpacing(2)
                }
            }
            
            // Chips
            HStack(spacing: 6) {
                ForEach(chips, id: \.self) { chip in
                    Text(chip)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(AppTheme.background)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.buttonBorder, lineWidth: 1))
                }
            }
            
            // Action Button
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: buttonIcon)
                        .font(.system(size: 13, weight: .bold))
                    Text(buttonTitle)
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    LinearGradient(
                        colors: iconGradient,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: iconGradient.first?.opacity(0.25) ?? Color.clear, radius: 5, x: 0, y: 3)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.buttonBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
}
