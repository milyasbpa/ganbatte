import SwiftUI

enum MistakeTab: String, CaseIterable, Identifiable {
    case kotoba = "Kotoba"
    case kana = "Kana"
    
    var id: String { rawValue }
}

struct WeaknessDetailView: View {
    @Binding var isPresented: Bool
    var initialTab: MistakeTab = .kotoba
    
    @ObservedObject private var activityService = ActivityService.shared
    @State private var selectedTab: MistakeTab
    @State private var selectedLevelFilter: JLPTLevel = .all
    @State private var selectedWordForDetail: Word? = nil
    @State private var wordsMap: [Int: Word] = [:]
    
    init(isPresented: Binding<Bool>, initialTab: MistakeTab = .kotoba) {
        self._isPresented = isPresented
        self.initialTab = initialTab
        self._selectedTab = State(initialValue: initialTab)
    }
    
    private var filteredWordMistakes: [WordMistakeEntry] {
        let list = activityService.unresolvedWordMistakes
        if selectedLevelFilter == .all {
            return list.sorted(by: { $0.failCount > $1.failCount })
        }
        return list.filter { $0.level == selectedLevelFilter }
            .sorted(by: { $0.failCount > $1.failCount })
    }
    
    private var unresolvedKanaMistakes: [KanaMistakeEntry] {
        activityService.unresolvedKanaMistakes.sorted(by: { $0.failCount > $1.failCount })
    }
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Pinned Navigation Bar
                navigationBar
                
                // Content Body
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Hero CTA Banner
                        heroActionBanner
                        
                        // Segmented Tab Switcher (Kotoba vs Kana)
                        segmentedTabs
                        
                        if selectedTab == .kotoba {
                            kotobaSection
                        } else {
                            kanaSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 40)
                }
            }
            
            // Full Word Detail Sheet Overlay
            if let word = selectedWordForDetail {
                WordDetailView(
                    initialIndex: 0,
                    wordsList: [word],
                    selectedType: .all,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedWordForDetail = nil
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)))
                .zIndex(200)
            }
        }
        .onAppear {
            reloadWordsMap()
        }
        .onChange(of: activityService.activeWordMistakes) { _ in
            reloadWordsMap()
        }
    }
    
    // MARK: - Navigation Bar (Standard < Back matching TrophyCabinetView & WordDetailView)
    private var navigationBar: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isPresented = false
                }
            }) {
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
            
            VStack(spacing: 2) {
                Text("Mistake Bank")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                let totalCount = activityService.unresolvedWordMistakesCount + activityService.unresolvedKanaMistakesCount
                Text("\(totalCount) Troublesome Items")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            // Invisible balanced back placeholder for exact center title alignment
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                Text("Back")
                    .font(.system(size: 18, weight: .semibold))
            }
            .opacity(0)
        }
        .padding(.horizontal, 20)
        #if os(macOS)
        .padding(.top, 24)
        #else
        .padding(.top, 14)
        #endif
        .padding(.bottom, 12)
        .background(AppTheme.background)
    }
    
    // MARK: - Hero Action Banner
    private var heroActionBanner: some View {
        VStack(spacing: 8) {
            if selectedTab == .kotoba {
                let count = activityService.unresolvedWordMistakesCount
                if count > 0 {
                    Button(action: {
                        let ids = activityService.unresolvedWordMistakes.map { $0.wordId }
                        activityService.triggerMistakeWorkout(wordIds: ids)
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isPresented = false
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 18, weight: .bold))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Practice Mistakes (\(count) Words)")
                                    .font(.system(size: 15, weight: .bold))
                                Text("Load targeted workout in Exercise Hub")
                                    .font(.system(size: 11, weight: .medium))
                                    .opacity(0.9)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: 0xE65100), AppTheme.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: AppTheme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(BubbleScaleButtonStyle())
                }
            } else {
                let kCount = activityService.unresolvedKanaMistakesCount
                if kCount > 0 {
                    Button(action: {
                        let chars = activityService.unresolvedKanaMistakes.map { $0.character }
                        activityService.triggerKanaMistakeWorkout(characters: chars)
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isPresented = false
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 18, weight: .bold))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Practice Kana Mistakes (\(kCount) Characters)")
                                    .font(.system(size: 15, weight: .bold))
                                Text("Filtered exclusively for target characters")
                                    .font(.system(size: 11, weight: .medium))
                                    .opacity(0.9)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: 0x1565C0), Color(hex: 0x1E88E5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color(hex: 0x1565C0).opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(BubbleScaleButtonStyle())
                }
            }
            
            // Dual-Key Rule Guidance Tag
            HStack(spacing: 6) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.accent)
                Text("Dual-Key Rule: 2 consecutive clean answers in ≤ 2.5s removes each item.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.top, 2)
        }
    }
    
    // MARK: - Segmented Switcher
    private var segmentedTabs: some View {
        HStack(spacing: 8) {
            ForEach(MistakeTab.allCases) { tab in
                let isSelected = selectedTab == tab
                let count = tab == .kotoba ? activityService.unresolvedWordMistakesCount : activityService.unresolvedKanaMistakesCount
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .bold))
                        
                        Text("\(count)")
                            .font(.system(size: 11, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(isSelected ? Color.white.opacity(0.25) : AppTheme.inputBackground)
                            .clipShape(Capsule())
                    }
                    .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(isSelected ? AppTheme.accent : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isSelected ? Color.clear : AppTheme.buttonBorder, lineWidth: 1)
                    )
                    .shadow(color: isSelected ? AppTheme.accent.opacity(0.2) : Color.clear, radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Kotoba Section
    private var kotobaSection: some View {
        VStack(spacing: 12) {
            // JLPT Level Sub-filters
            let allUnresolved = activityService.unresolvedWordMistakes
            if !allUnresolved.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach([JLPTLevel.all, .n5, .n4, .n3, .n2, .n1], id: \.self) { lvl in
                            let count = lvl == .all ? allUnresolved.count : allUnresolved.filter { $0.level == lvl }.count
                            if count > 0 || lvl == .all {
                                let isSelected = selectedLevelFilter == lvl
                                Button(action: {
                                    selectedLevelFilter = lvl
                                }) {
                                    HStack(spacing: 4) {
                                        Text(lvl.rawValue)
                                            .font(.system(size: 12, weight: .bold))
                                        Text("(\(count))")
                                            .font(.system(size: 10, weight: .semibold))
                                    }
                                    .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? AppTheme.accent : Color.white)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(isSelected ? Color.clear : AppTheme.buttonBorder, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            
            // Mistake Cards List
            if filteredWordMistakes.isEmpty {
                emptyStateView(
                    title: "Kotoba Mistake Bank Clear!",
                    subtitle: "No troublesome words recorded for this filter. Answer accurately in ≤ 2.5s to keep it clean!"
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(filteredWordMistakes) { entry in
                        wordMistakeCard(entry: entry)
                    }
                }
            }
        }
    }
    
    // MARK: - Kotoba Mistake Card
    private func wordMistakeCard(entry: WordMistakeEntry) -> some View {
        let word = wordsMap[entry.wordId]
        
        return HStack(alignment: .center, spacing: 12) {
            // 64x64 Thumbnail Image
            if let word = word {
                CardImageView(imageName: word.imageName, contentMode: .fill)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppTheme.buttonBorder, lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.inputBackground)
                    .frame(width: 64, height: 64)
            }
            
            // Word Meta & Graduation Progress
            VStack(alignment: .leading, spacing: 4) {
                // Top Meta Row
                HStack(spacing: 6) {
                    // Missed Count
                    Text("Missed \(entry.failCount)x")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: 0xD84315))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: 0xFBE9E7))
                        .clipShape(Capsule())
                    
                    // Distinct JLPT Badge (N4 distinct Royal Blue #1565C0 on #E3F2FD)
                    let levelColor = entry.level == .n4 ? Color(hex: 0x1565C0) : AppTheme.accent
                    let levelBg = entry.level == .n4 ? Color(hex: 0xE3F2FD) : AppTheme.accentLight.opacity(0.5)
                    Text(entry.level.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(levelColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(levelBg)
                        .clipShape(Capsule())
                    
                    Text("•")
                        .foregroundColor(AppTheme.textTertiary)
                    
                    Text(entry.wordType.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                // Kanji & Kana
                HStack(alignment: .bottom, spacing: 6) {
                    if let word = word, !word.kanji.isEmpty && word.kanji != word.kana {
                        Text(word.kanji)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text(word.kana)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    } else {
                        Text(word?.kana ?? "Word #\(entry.wordId)")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
                
                // Meaning
                Text(word?.meaningEn ?? "Vocabulary Item")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
                
                // Dual-Key Clean Status Indicator
                HStack(spacing: 6) {
                    if entry.consecutiveCleanCount == 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: 0xDC3545))
                                .frame(width: 6, height: 6)
                            Text("0/2 Clean (Needs 2 Fast Runs)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(hex: 0xDC3545))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: 0xFFEBEE))
                        .clipShape(Capsule())
                    } else if entry.consecutiveCleanCount == 1 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 6, height: 6)
                            Text("1/2 Clean (1 Fast Run to Clear!)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: 0xE65100))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: 0xFFF3E0))
                        .clipShape(Capsule())
                    }
                }
                .padding(.top, 2)
            }
            
            Spacer(minLength: 4)
            
            // Audio Button
            if let word = word {
                Button(action: {
                    AudioService.shared.speak(word.kana)
                }) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.audioButtonBg)
                            .frame(width: 36, height: 36)
                            .overlay(Circle().stroke(AppTheme.audioButtonBorder, lineWidth: 1))
                        
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.audioIcon)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.buttonBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
        .contentShape(Rectangle())
        .onTapGesture {
            if let word = word {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedWordForDetail = word
                }
            }
        }
    }
    
    // MARK: - Kana Section
    private var kanaSection: some View {
        VStack(spacing: 12) {
            if unresolvedKanaMistakes.isEmpty {
                emptyStateView(
                    title: "Kana Mistake Bank Clear!",
                    subtitle: "Zero troublesome Hiragana or Katakana characters recorded. Great job!"
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(unresolvedKanaMistakes) { entry in
                        kanaMistakeCard(entry: entry)
                    }
                }
            }
        }
    }
    
    // MARK: - Kana Mistake Card
    private func kanaMistakeCard(entry: KanaMistakeEntry) -> some View {
        HStack(alignment: .center, spacing: 14) {
            // Kana Large Glyph Box
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.inputBackground)
                    .frame(width: 56, height: 56)
                
                Text(entry.character)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Missed \(entry.failCount)x")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: 0xD84315))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: 0xFBE9E7))
                        .clipShape(Capsule())
                    
                    Text(entry.script.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.accentLight.opacity(0.5))
                        .clipShape(Capsule())
                    
                    if entry.slowCount > 0 {
                        Text("\(entry.slowCount)x Slow")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color.orange)
                    }
                }
                
                Text(entry.romaji)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                // Clean Status
                HStack(spacing: 6) {
                    if entry.consecutiveCleanCount == 0 {
                        Text("🔴 0/2 Clean (Needs Speed Recall)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(hex: 0xDC3545))
                    } else {
                        Text("🟡 1/2 Clean (1 Speed Recall Left)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: 0xE65100))
                    }
                }
            }
            
            Spacer()
            
            // Audio Button
            Button(action: {
                AudioService.shared.speak(entry.character)
            }) {
                ZStack {
                    Circle()
                        .fill(AppTheme.audioButtonBg)
                        .frame(width: 36, height: 36)
                        .overlay(Circle().stroke(AppTheme.audioButtonBorder, lineWidth: 1))
                    
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.audioIcon)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.buttonBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
    }
    
    // MARK: - Empty State View
    private func emptyStateView(title: String, subtitle: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(red: 0.20, green: 0.70, blue: 0.45))
                .padding(.top, 20)
            
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            
            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.buttonBorder.opacity(0.6), lineWidth: 1)
        )
    }
    
    // MARK: - Database Word Fetch
    private func reloadWordsMap() {
        let ids = activityService.unresolvedWordMistakes.map { $0.wordId }
        guard !ids.isEmpty else {
            wordsMap = [:]
            return
        }
        let fetched = DatabaseService.shared.fetchWords(by: ids)
        wordsMap = Dictionary(uniqueKeysWithValues: fetched.map { ($0.id, $0) })
    }
}
