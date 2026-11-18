import SwiftUI

struct WordDetailView: View {
    @State var currentWord: Word
    let wordsList: [Word]
    var onDismiss: () -> Void
    
    @State private var currentIndex: Int = 0
    
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
                            Text("Words")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(AppTheme.accent)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text("\(currentIndex + 1) / \(max(wordsList.count, 1))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    // Invisible balancing element for exact center alignment
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Words")
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
                
                // 2. SCROLLABLE MIDDLE CONTENT AREA
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        // Hero Cropped Image Banner (Full Width within container margins)
                        CardImageView(imageName: currentWord.imageName, contentMode: .fill)
                            .aspectRatio(1.0, contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        
                        // Word Details Section
                        VStack(alignment: .leading, spacing: 8) {
                            // Main Word Header & Audio Button Row (Perfect alignment)
                            HStack(alignment: .center) {
                                // Main Kana (36pt bold)
                                Text(currentWord.kana)
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                Spacer()
                                
                                // Volume Button (Circle with border matching card_001.png)
                                Button(action: {
                                    AudioService.shared.speak(currentWord.kana)
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
                                if !currentWord.kanji.isEmpty && currentWord.kanji != currentWord.kana {
                                    FuriganaText(
                                        text: currentWord.kanji,
                                        fontSize: 20,
                                        furiganaSize: 11,
                                        textColor: AppTheme.textPrimary,
                                        furiganaColor: AppTheme.textSecondary,
                                        boldKanji: true
                                    )
                                    .fixedSize(horizontal: true, vertical: false)
                                }
                                
                                Text(currentWord.romaji)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(AppTheme.textSecondary)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            
                            // Type with Terracotta Bullet
                            HStack(spacing: 5) {
                                Text("•")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppTheme.accent)
                                
                                Text(currentWord.type)
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
                                        AudioService.shared.speak(currentWord.exampleJa, rate: 0.42)
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
                                    text: currentWord.exampleJa,
                                    fontSize: 18,
                                    furiganaSize: 10.5,
                                    textColor: AppTheme.textPrimary,
                                    furiganaColor: AppTheme.textSecondary
                                )
                                
                                // English sentence translation (Font size 15pt)
                                Text(currentWord.exampleEn)
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
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 30)
                        .onEnded { value in
                            if value.translation.width < -50 {
                                nextCard()
                            } else if value.translation.width > 50 {
                                prevCard()
                            }
                        }
                )
                
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
                    
                    // Next Button
                    Button(action: nextCard) {
                        HStack(spacing: 6) {
                            Text("Next")
                                .font(.system(size: 16, weight: .semibold))
                            Text("→")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(currentIndex < wordsList.count - 1 ? AppTheme.textPrimary : AppTheme.buttonDisabledText)
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
                    .disabled(currentIndex >= wordsList.count - 1)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
                .background(AppTheme.background)
            }
        }
        .onAppear {
            if let idx = wordsList.firstIndex(where: { $0.id == currentWord.id }) {
                currentIndex = idx
            }
            // Auto play voice on initial open
            AudioService.shared.speak(currentWord.kana)
        }
    }
    
    private func nextCard() {
        guard currentIndex < wordsList.count - 1 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            currentIndex += 1
            currentWord = wordsList[currentIndex]
        }
        // Auto play voice on next
        AudioService.shared.speak(currentWord.kana)
    }
    
    private func prevCard() {
        guard currentIndex > 0 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            currentIndex -= 1
            currentWord = wordsList[currentIndex]
        }
        // Auto play voice on previous
        AudioService.shared.speak(currentWord.kana)
    }
}
