import SwiftUI

enum SlideDirection {
    case forward, backward
}

struct WordDetailView: View {
    let initialIndex: Int
    @Binding var wordsList: [Word]
    let totalCount: Int
    let selectedType: WordType
    var onLoadMore: (((() -> Void)?) -> Void)? = nil
    var onDismiss: () -> Void
    
    @State private var currentIndex: Int
    @State private var slideDirection: SlideDirection = .forward
    #if os(macOS)
    @State private var keyMonitor: Any?
    #endif
    
    init(
        initialIndex: Int,
        wordsList: Binding<[Word]>,
        totalCount: Int? = nil,
        selectedType: WordType = .all,
        onLoadMore: (((() -> Void)?) -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.initialIndex = initialIndex
        self._wordsList = wordsList
        self.totalCount = totalCount ?? wordsList.wrappedValue.count
        self.selectedType = selectedType
        self.onLoadMore = onLoadMore
        self.onDismiss = onDismiss
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    init(
        initialIndex: Int,
        wordsList: [Word],
        totalCount: Int? = nil,
        selectedType: WordType = .all,
        onLoadMore: (((() -> Void)?) -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.init(
            initialIndex: initialIndex,
            wordsList: .constant(wordsList),
            totalCount: totalCount ?? wordsList.count,
            selectedType: selectedType,
            onLoadMore: onLoadMore,
            onDismiss: onDismiss
        )
    }
    
    var effectiveTotalCount: Int {
        max(totalCount, wordsList.count)
    }
    
    var currentWord: Word {
        guard currentIndex >= 0 && currentIndex < wordsList.count else {
            return wordsList.first!
        }
        return wordsList[currentIndex]
    }
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. TOP HEADER (PINNED AT TOP)
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
                    
                    Text("\(currentIndex + 1) / \(max(effectiveTotalCount, 1))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    // Invisible balancing element for exact center alignment
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
                .padding(.top, 36)
                #else
                .padding(.top, 16)
                #endif
                .padding(.bottom, 24)
                .background(AppTheme.background)
                
                // 2. MIDDLE CONTENT AREA (SWIPEABLE PAGING)
                #if os(iOS)
                TabView(selection: $currentIndex) {
                    ForEach(0..<wordsList.count, id: \.self) { idx in
                        wordDetailCard(for: wordsList[idx])
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)
                #else
                ZStack {
                    wordDetailCard(for: currentWord)
                        .id(currentIndex)
                        .transition(.asymmetric(
                            insertion: .move(edge: slideDirection == .forward ? .trailing : .leading),
                            removal: .move(edge: slideDirection == .forward ? .leading : .trailing)
                        ))
                }
                .frame(maxHeight: .infinity)
                .highPriorityGesture(
                    DragGesture(minimumDistance: 30)
                        .onEnded { value in
                            if value.translation.width < -40 {
                                nextCard()
                            } else if value.translation.width > 40 {
                                prevCard()
                            }
                        }
                )
                #endif
                
                // 3. BOTTOM NAVIGATION BUTTONS (PINNED AT BOTTOM, ALWAYS VISIBLE!)
                HStack(spacing: 12) {
                    // Previous Button
                    Button(action: prevCard) {
                        HStack(spacing: 6) {
                            Text("←")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Previous")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(currentIndex > 0 ? AppTheme.textPrimary : AppTheme.buttonDisabledText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.buttonBorder, lineWidth: 1.2)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .disabled(currentIndex <= 0)
                    .keyboardShortcut(.leftArrow, modifiers: [])
                    
                    // Next Button
                    Button(action: nextCard) {
                        HStack(spacing: 6) {
                            Text("Next")
                                .font(.system(size: 16, weight: .semibold))
                            Text("→")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(currentIndex < effectiveTotalCount - 1 ? AppTheme.textPrimary : AppTheme.buttonDisabledText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.buttonBorder, lineWidth: 1.2)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .disabled(currentIndex >= effectiveTotalCount - 1)
                    .keyboardShortcut(.rightArrow, modifiers: [])
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
                .background(AppTheme.background)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Floating Exercise Action Button (Shortcut to Exercise)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: navigateToExercise) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accent)
                                .frame(width: 52, height: 52)
                                .shadow(color: AppTheme.accent.opacity(0.4), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "pencil")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(BubbleScaleButtonStyle())
                    .padding(.trailing, 20)
                    .padding(.bottom, 74)
                }
            }
        }
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.leftArrow) {
            prevCard()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            nextCard()
            return .handled
        }
        .onChange(of: currentIndex) { newIndex in
            guard newIndex >= 0 && newIndex < wordsList.count else { return }
            AudioService.shared.speak(wordsList[newIndex].kana)
            checkAndLoadMore(for: newIndex)
        }
        .onAppear {
            checkAndLoadMore(for: currentIndex)
            // Auto play voice on initial open
            AudioService.shared.speak(currentWord.kana)
            
            #if os(macOS)
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 123 { // Left Arrow
                    prevCard()
                    return nil
                } else if event.keyCode == 124 { // Right Arrow
                    nextCard()
                    return nil
                }
                return event
            }
            #endif
        }
        .onDisappear {
            #if os(macOS)
            if let monitor = keyMonitor {
                NSEvent.removeMonitor(monitor)
                keyMonitor = nil
            }
            #endif
        }
    }
    
    // MARK: - Word Detail Card (Scrollable Content)
    private func wordDetailCard(for word: Word) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                // Hero Cropped Image Banner (Full Width within container margins)
                CardImageView(imageName: word.imageName, contentMode: .fill)
                    .aspectRatio(1.0, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                
                // Word Details Section
                VStack(alignment: .leading, spacing: 8) {
                    // Main Word Header & Audio Button Row (Perfect alignment)
                    HStack(alignment: .center) {
                        // Main Kana (36pt bold)
                        Text(word.kana)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Spacer()
                        
                        // Volume Button (Circle with border matching card_001.png)
                        Button(action: {
                            AudioService.shared.speak(word.kana)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.audioButtonBg)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(AppTheme.audioButtonBorder, lineWidth: 1.2)
                                    )
                                    .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1.5)
                                
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 17))
                                    .foregroundColor(AppTheme.audioIcon)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Kanji & Romaji (Side by side)
                    HStack(alignment: .bottom, spacing: 8) {
                        if !word.kanji.isEmpty && word.kanji != word.kana {
                            FuriganaText(
                                text: word.kanji,
                                fontSize: 20,
                                furiganaSize: 11,
                                textColor: AppTheme.textPrimary,
                                furiganaColor: AppTheme.textSecondary,
                                boldKanji: true
                            )
                            .fixedSize(horizontal: true, vertical: false)
                        }
                        
                        Text(word.romaji)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    
                    // Type with Terracotta Bullet
                    HStack(spacing: 5) {
                        Text("•")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.accent)
                        
                        Text(word.type)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.top, 2)
                    
                    // Example Section
                    VStack(alignment: .leading, spacing: 6) {
                        // Example Header with Space Between Audio Icon (No circle background)
                        HStack {
                            Text("Example")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(AppTheme.textSecondary)
                            
                            Spacer()
                            
                            Button(action: {
                                AudioService.shared.speak(word.exampleJa, rate: 0.42)
                            }) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.audioIcon)
                                    .padding(4)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Japanese sentence with furigana (Font size 18pt)
                        FuriganaText(
                            text: word.exampleJa,
                            fontSize: 18,
                            furiganaSize: 10.5,
                            textColor: AppTheme.textPrimary,
                            furiganaColor: AppTheme.textSecondary
                        )
                        
                        // English sentence translation (Font size 15pt)
                        Text(word.exampleEn)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.top, 2)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .frame(maxHeight: .infinity)
    }
    
    private func checkAndLoadMore(for index: Int) {
        if index >= wordsList.count - 5 && wordsList.count < effectiveTotalCount {
            onLoadMore?(nil)
        }
    }
    
    private func nextCard() {
        guard currentIndex < effectiveTotalCount - 1 else { return }
        
        if currentIndex >= wordsList.count - 1 {
            // Buffer boundary reached: request load more and advance once available
            onLoadMore? {
                if self.currentIndex < self.wordsList.count - 1 {
                    #if os(macOS)
                    self.slideDirection = .forward
                    #endif
                    withAnimation(.easeInOut(duration: 0.25)) {
                        self.currentIndex += 1
                    }
                }
            }
            return
        }
        
        if currentIndex >= wordsList.count - 5 {
            onLoadMore?(nil)
        }
        
        #if os(macOS)
        slideDirection = .forward
        #endif
        withAnimation(.easeInOut(duration: 0.25)) {
            currentIndex += 1
        }
    }
    
    private func prevCard() {
        guard currentIndex > 0 else { return }
        #if os(macOS)
        slideDirection = .backward
        #endif
        withAnimation(.easeInOut(duration: 0.25)) {
            currentIndex -= 1
        }
    }
    
    private func navigateToExercise() {
        let batchStart = (currentIndex / 10) * 10 + 1
        let batchEnd = min(batchStart + 9, effectiveTotalCount)
        let wordType = selectedType
        
        var cfg = QuizConfig.load()
        cfg.level = JLPTLevel(rawValue: currentWord.level) ?? .n5
        cfg.type = wordType
        cfg.startWord = batchStart
        cfg.endWord = batchEnd
        cfg.save()
        
        NotificationCenter.default.post(
            name: NSNotification.Name("ganbatte_shortcut_to_exercise"),
            object: nil,
            userInfo: [
                "category": "Kotoba",
                "level": currentWord.level,
                "type": wordType.rawValue,
                "startWord": batchStart,
                "endWord": batchEnd
            ]
        )
        UserDefaults.standard.set(AppTab.exercise.rawValue, forKey: "ganbatte_active_main_tab")
        onDismiss()
    }
}
