import SwiftUI

struct WordListView: View {
    @Binding var hideBottomBar: Bool
    var onOpenReminders: (() -> Void)?
    var onBack: (() -> Void)? = nil
    var showFAB: Bool = false
    
    init(
        hideBottomBar: Binding<Bool> = .constant(false),
        initialLevel: JLPTLevel = .all,
        onOpenReminders: (() -> Void)? = nil,
        onBack: (() -> Void)? = nil,
        showFAB: Bool = false
    ) {
        self._hideBottomBar = hideBottomBar
        self.onOpenReminders = onOpenReminders
        self.onBack = onBack
        self.showFAB = showFAB
        self._selectedLevel = State(initialValue: initialLevel)
    }
    
    @State private var words: [Word] = []
    @State private var totalCount: Int = 0
    @State private var searchQuery: String = ""
    @State private var selectedLevel: JLPTLevel = .all
    @State private var selectedType: WordType = .all
    
    @State private var showDifficultyModal: Bool = false
    @State private var showTypeModal: Bool = false
    @State private var selectedWordForDetail: Word? = nil
    @State private var showExerciseFlow: Bool = false
    
    private let pageSize = 40
    @State private var currentOffset = 0
    @State private var isLoadingMore = false
    @State private var canLoadMore = true
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Text("Words")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                }
                .overlay(alignment: .leading) {
                    if let onBack = onBack {
                        Button(action: onBack) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(AppTheme.accent)
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 16)
                    }
                }
                .overlay(alignment: .trailing) {
                    if let onOpenReminders = onOpenReminders {
                        Button(action: onOpenReminders) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.textSecondary)
                                .frame(width: 32, height: 32)
                                .background(Color.white)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(AppTheme.buttonBorder, lineWidth: 1))
                                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 16)
                    }
                }
                .padding(.top, 22)
                .padding(.bottom, 12)
                
                // Search Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.textSecondary)
                        .font(.system(size: 16))
                    
                    ZStack(alignment: .leading) {
                        if searchQuery.isEmpty {
                            Text("Search by word or meaning...")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        TextField("", text: $searchQuery)
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.textPrimary)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()
                    }
                    
                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppTheme.textSecondary)
                                .font(.system(size: 16))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(AppTheme.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                // Filter Buttons Bar
                HStack(spacing: 12) {
                    // Difficulty Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showDifficultyModal = true
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DIFFICULTY")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AppTheme.textSecondary)
                                .tracking(0.5)
                            
                            HStack {
                                Text(selectedLevel.rawValue)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(selectedLevel == .all ? AppTheme.textPrimary : AppTheme.accent)
                                
                                Spacer()
                                
                                Image(systemName: "arrowtriangle.down.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.inputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    // Type Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showTypeModal = true
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TYPE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AppTheme.textSecondary)
                                .tracking(0.5)
                            
                            HStack {
                                Text(selectedType.rawValue)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(selectedType == .all ? AppTheme.textPrimary : AppTheme.accent)
                                
                                Spacer()
                                
                                Image(systemName: "arrowtriangle.down.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.inputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                // Words Scrollable List
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(words.enumerated()), id: \.element.id) { index, word in
                            WordRowView(word: word) {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    selectedWordForDetail = word
                                }
                            }
                            .onAppear {
                                if index == words.count - 8 && canLoadMore && !isLoadingMore {
                                    loadMoreWords()
                                }
                            }
                        }
                        
                        if isLoadingMore {
                            ProgressView()
                                .padding(.vertical, 16)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 80)
                }
            }
            
            // Floating Action Button (Exercise Shortcut)
            if showFAB {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            let count = totalCount > 0 ? totalCount : 10
                            var cfg = QuizConfig.load()
                            cfg.level = selectedLevel
                            cfg.startWord = 1
                            cfg.endWord = min(10, count)
                            cfg.save()
                            
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ganbatte_shortcut_to_exercise"),
                                object: nil,
                                userInfo: [
                                    "category": "Kotoba",
                                    "level": selectedLevel.rawValue,
                                    "startWord": 1,
                                    "endWord": min(10, count)
                                ]
                            )
                            UserDefaults.standard.set(AppTab.exercise.rawValue, forKey: "ganbatte_active_main_tab")
                        }) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accent)
                                    .frame(width: 52, height: 52)
                                    .shadow(color: AppTheme.accent.opacity(0.35), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: "pencil")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(BubbleScaleButtonStyle())
                        .padding(.trailing, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
            
            // Difficulty Modal Overlay
            if showDifficultyModal {
                DifficultyModalView(
                    selectedLevel: $selectedLevel,
                    isPresented: $showDifficultyModal
                )
                .transition(.opacity)
                .zIndex(100)
            }
            
            // Type Modal Overlay
            if showTypeModal {
                TypeModalView(
                    selectedType: $selectedType,
                    isPresented: $showTypeModal
                )
                .transition(.opacity)
                .zIndex(100)
            }
            
            // Word Detail Overlay (Multiplatform)
            if let word = selectedWordForDetail,
               let idx = words.firstIndex(where: { $0.id == word.id }) {
                WordDetailView(
                    initialIndex: idx,
                    wordsList: words,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedWordForDetail = nil
                        }
                    }
                )
                .id(word.id)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
                .zIndex(200)
            }
            
            // Exercise Flow Overlay
            if showExerciseFlow {
                ExerciseCoordinatorView(
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showExerciseFlow = false
                            hideBottomBar = selectedWordForDetail != nil
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
                .zIndex(300)
            }
        }
        .onAppear {
            reloadWords()
        }
        .onChange(of: selectedLevel) { _ in
            reloadWords()
        }
        .onChange(of: selectedType) { _ in
            reloadWords()
        }
        .onChange(of: searchQuery) { _ in
            reloadWords()
        }
        .onChange(of: showExerciseFlow) { val in
            withAnimation(.easeInOut(duration: 0.2)) {
                hideBottomBar = val || (selectedWordForDetail != nil)
            }
        }
        .onChange(of: selectedWordForDetail) { val in
            withAnimation(.easeInOut(duration: 0.2)) {
                hideBottomBar = (val != nil) || showExerciseFlow
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ganbatte_apply_word_filter"))) { notif in
            if let levelRaw = notif.userInfo?["level"] as? String, let level = JLPTLevel(rawValue: levelRaw) {
                selectedLevel = level
            }
            if let typeRaw = notif.userInfo?["type"] as? String, let type = WordType(rawValue: typeRaw) {
                selectedType = type
            }
            reloadWords()
        }
    }
    
    private func reloadWords() {
        currentOffset = 0
        canLoadMore = true
        let count = DatabaseService.shared.countWords(level: selectedLevel, type: selectedType, searchQuery: searchQuery)
        totalCount = count
        
        let initialWords = DatabaseService.shared.fetchWords(
            level: selectedLevel,
            type: selectedType,
            searchQuery: searchQuery,
            limit: pageSize,
            offset: 0
        )
        words = initialWords
        currentOffset = initialWords.count
        if initialWords.count >= count {
            canLoadMore = false
        }
    }
    
    private func loadMoreWords() {
        guard canLoadMore && !isLoadingMore else { return }
        isLoadingMore = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let more = DatabaseService.shared.fetchWords(
                level: selectedLevel,
                type: selectedType,
                searchQuery: searchQuery,
                limit: pageSize,
                offset: currentOffset
            )
            
            DispatchQueue.main.async {
                self.words.append(contentsOf: more)
                self.currentOffset += more.count
                self.isLoadingMore = false
                if self.words.count >= self.totalCount || more.isEmpty {
                    self.canLoadMore = false
                }
            }
        }
    }
}
