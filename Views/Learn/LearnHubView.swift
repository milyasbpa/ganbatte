import SwiftUI

enum LearnSubView {
    case hub
    case wordList
    case kanaChart
}

struct LearnHubView: View {
    @Binding var hideBottomBar: Bool
    
    @State private var activeSubView: LearnSubView = .hub
    @ObservedObject private var activityService = ActivityService.shared
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            switch activeSubView {
            case .hub:
                hubContent
                    .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading)))
            case .wordList:
                WordListView(
                    hideBottomBar: $hideBottomBar,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            activeSubView = .hub
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            case .kanaChart:
                KanaChartView(
                    hideBottomBar: $hideBottomBar,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            activeSubView = .hub
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ganbatte_navigate_to_words"))) { _ in
            withAnimation(.easeInOut(duration: 0.22)) {
                activeSubView = .wordList
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ganbatte_navigate_to_kana"))) { _ in
            withAnimation(.easeInOut(duration: 0.22)) {
                activeSubView = .kanaChart
            }
        }
    }
    
    // MARK: - Gojek / Grab Style Hub Content
    private var hubContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("がんばって")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(AppTheme.accent)
                        
                        Text("Ganbatte")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    
                    Text("Explore Japanese Vocabulary & Kana")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Daily Greeting / Motivation Pill Card
                    greetingCard
                    
                    // CATEGORIES Section Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CATEGORIES")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.horizontal, 4)
                        
                        // 2x2 Service Grid
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                            // 1. Kosakata
                            categoryCard(
                                title: "Kosakata",
                                subtitle: "6,700+ Words",
                                badge: "JLPT N5–N1",
                                iconName: "book.closed.fill",
                                gradient: [AppTheme.accent, Color(red: 0.95, green: 0.45, blue: 0.25)],
                                isComingSoon: false,
                                action: {
                                    withAnimation(.easeInOut(duration: 0.22)) {
                                        activeSubView = .wordList
                                    }
                                }
                            )
                            
                            // 2. Kana Chart
                            categoryCard(
                                title: "Kana Chart",
                                subtitle: "Hiragana & Katakana",
                                badge: "Audio & Strokes",
                                iconName: "character.bubble.fill",
                                gradient: [Color(red: 0.25, green: 0.45, blue: 0.88), Color(red: 0.45, green: 0.60, blue: 0.95)],
                                isComingSoon: false,
                                action: {
                                    withAnimation(.easeInOut(duration: 0.22)) {
                                        activeSubView = .kanaChart
                                    }
                                }
                            )
                            
                            // 3. Kanji (Coming Soon)
                            categoryCard(
                                title: "Kanji",
                                subtitle: "Radicals & Jōyō",
                                badge: "Coming Soon",
                                iconName: "character.textbox",
                                gradient: [Color(red: 0.50, green: 0.45, blue: 0.70), Color(red: 0.65, green: 0.60, blue: 0.82)],
                                isComingSoon: true,
                                action: {}
                            )
                            
                            // 4. Bunpou (Coming Soon)
                            categoryCard(
                                title: "Bunpou",
                                subtitle: "Sentence Patterns",
                                badge: "Coming Soon",
                                iconName: "list.bullet.rectangle.portrait.fill",
                                gradient: [Color(red: 0.25, green: 0.65, blue: 0.65), Color(red: 0.45, green: 0.80, blue: 0.75)],
                                isComingSoon: true,
                                action: {}
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 90)
            }
        }
    }
    
    // MARK: - Greeting Card
    private var greetingCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.12))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.accent)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(activityService.isTodayCompleted ? "Great momentum today!" : "Keep the momentum going!")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                if activityService.todayQuestionsAnswered > 0 {
                    Text("\(activityService.todayQuestionsAnswered) questions completed today.")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                } else {
                    Text("Choose a category or jump into a quick quiz.")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            Spacer()
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
    
    // MARK: - Category Grid Card Builder
    private func categoryCard(
        title: String,
        subtitle: String,
        badge: String,
        iconName: String,
        gradient: [Color],
        isComingSoon: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            if !isComingSoon {
                action()
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    LinearGradient(
                        colors: isComingSoon ? [Color.gray.opacity(0.4), Color.gray.opacity(0.6)] : gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 42, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: isComingSoon ? Color.clear : gradient.first?.opacity(0.3) ?? Color.clear, radius: 5, x: 0, y: 2)
                    
                    Spacer()
                    
                    if isComingSoon {
                        Text(badge)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(AppTheme.textTertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.05))
                            .clipShape(Capsule())
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isComingSoon ? AppTheme.textSecondary : AppTheme.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textTertiary)
                }
                
                if !isComingSoon {
                    HStack(spacing: 4) {
                        Text(badge)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(gradient.first ?? AppTheme.accent)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(isComingSoon ? 0.7 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.buttonBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(isComingSoon)
    }
}
