import SwiftUI

struct KanaChartView: View {
    @Binding var hideBottomBar: Bool
    var onOpenReminders: (() -> Void)?
    var onBack: (() -> Void)? = nil
    var showFAB: Bool = false
    
    init(
        hideBottomBar: Binding<Bool> = .constant(false),
        onOpenReminders: (() -> Void)? = nil,
        onBack: (() -> Void)? = nil,
        showFAB: Bool = false
    ) {
        self._hideBottomBar = hideBottomBar
        self.onOpenReminders = onOpenReminders
        self.onBack = onBack
        self.showFAB = showFAB
    }
    
    @AppStorage("ganbatte_active_kana_subtab") private var activeSubTabRaw: String = KanaType.hiragana.rawValue
    @State private var showExerciseFlow: Bool = false
    @State private var tappedLetterId: String? = nil
    
    var activeSubTab: KanaType {
        KanaType(rawValue: activeSubTabRaw) ?? .hiragana
    }
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header & Segmented Switcher
                VStack(spacing: 14) {
                    HStack {
                        Spacer()
                        Text("Kana Chart")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                    }
                    .overlay(alignment: .leading) {
                        if let onBack = onBack {
                            Button(action: onBack) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Hub")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(AppTheme.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(AppTheme.buttonBorder, lineWidth: 1))
                                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                            }
                            .buttonStyle(.plain)
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
                        }
                    }
                    
                    // Segmented Control (Hiragana vs Katakana)
                    HStack(spacing: 4) {
                        ForEach(KanaType.allCases) { kType in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    activeSubTabRaw = kType.rawValue
                                }
                            }) {
                                Text(kType.title)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(activeSubTab == kType ? .white : AppTheme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        activeSubTab == kType ? AppTheme.accent : Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(4)
                    .background(AppTheme.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 20)
                #if os(macOS)
                .padding(.top, 16)
                #else
                .padding(.top, 10)
                #endif
                .padding(.bottom, 12)
                .background(AppTheme.background)
                
                // Chart Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        // Section Header: Gojūon
                        HStack {
                            Text("Gojūon (Basic \(activeSubTab.title))")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AppTheme.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppTheme.inputBackground)
                                .clipShape(Capsule())
                            
                            Spacer()
                            
                            Text("46 characters")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.textTertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                        
                        // Vowel Column Headers: ~a, ~i, ~u, ~e, ~o
                        HStack(spacing: 6) {
                            Text("")
                                .frame(width: 24)
                            
                            ForEach(["~a", "~i", "~u", "~e", "~o"], id: \.self) { vowel in
                                Text(vowel)
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(AppTheme.textTertiary)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 2)
                        
                        // Grid of 11 Rows
                        let rows = KanaDataService.shared.getGojuonRows(type: activeSubTab)
                        VStack(spacing: 8) {
                            ForEach(rows, id: \.rowLabel) { rowItem in
                                HStack(spacing: 6) {
                                    // Row label
                                    Text(rowItem.rowLabel)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .frame(width: 24, alignment: .trailing)
                                    
                                    // 5 Columns
                                    ForEach(rowItem.letters) { letter in
                                        if letter.isEmpty {
                                            Color.clear
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 52)
                                        } else {
                                            let isTapped = tappedLetterId == letter.id
                                            Button(action: {
                                                tappedLetterId = letter.id
                                                KanaDataService.shared.speak(text: letter.kana)
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                                    if tappedLetterId == letter.id {
                                                        tappedLetterId = nil
                                                    }
                                                }
                                            }) {
                                                VStack(spacing: 2) {
                                                    Text(letter.kana)
                                                        .font(.system(size: 20, weight: .bold))
                                                        .foregroundColor(isTapped ? AppTheme.accent : AppTheme.textPrimary)
                                                    
                                                    Text(letter.romaji)
                                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                                        .foregroundColor(AppTheme.textSecondary)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 52)
                                                .background(isTapped ? AppTheme.accentLight.opacity(0.6) : Color.white)
                                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                        .stroke(isTapped ? AppTheme.accent : AppTheme.buttonBorder, lineWidth: isTapped ? 1.5 : 1)
                                                )
                                                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                                                .scaleEffect(isTapped ? 0.95 : 1.0)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 80) // Space for FAB
                    }
                }
            }
            
            // Floating Action Button (Exercise Practice - Optional)
            if showFAB {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showExerciseFlow = true
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accent)
                                    .frame(width: 56, height: 56)
                                    .shadow(color: AppTheme.accent.opacity(0.35), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: "pencil")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
            
            // Kana Exercise Overlay Flow
            if showExerciseFlow {
                KanaExerciseCoordinatorView(
                    initialType: activeSubTab,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showExerciseFlow = false
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
                .zIndex(200)
            }
        }
        .onChange(of: showExerciseFlow) { val in
            withAnimation(.easeInOut(duration: 0.2)) {
                hideBottomBar = val
            }
        }
    }
}
