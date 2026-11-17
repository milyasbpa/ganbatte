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
                // Top Navigation Bar with generous header breathing room
                HStack {
                    Button(action: onDismiss) {
                        HStack(spacing: 5) {
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
                    
                    // Balancing Spacer for centered counter
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18))
                        Text("Words")
                            .font(.system(size: 18))
                    }
                    .opacity(0)
                }
                .padding(.horizontal, 18)
                .padding(.top, 22)
                .padding(.bottom, 16)
                
                // Content area (Fits in one glance without scrolling)
                VStack(alignment: .leading, spacing: 0) {
                    // Hero Cropped Image Banner (No white wrapper card)
                    CardImageView(imageName: currentWord.imageName, contentMode: .fit)
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .padding(.horizontal, 16)
                    
                    // Word Info & Details Section
                    VStack(alignment: .leading, spacing: 14) {
                        // Word Header & Main Audio
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                // Large Kana
                                Text(currentWord.kana)
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                // Kanji with Furigana & Romaji (compact, side by side)
                                HStack(alignment: .bottom, spacing: 8) {
                                    if !currentWord.kanji.isEmpty && currentWord.kanji != currentWord.kana {
                                        FuriganaText(
                                            text: currentWord.kanji,
                                            fontSize: 18,
                                            furiganaSize: 10,
                                            textColor: AppTheme.textPrimary,
                                            furiganaColor: AppTheme.textSecondary,
                                            boldKanji: true
                                        )
                                    }
                                    
                                    Text(currentWord.romaji)
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                
                                // Word Type with Terracotta Bullet
                                HStack(spacing: 5) {
                                    Text("•")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(AppTheme.accent)
                                    
                                    Text(currentWord.type)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                .padding(.top, 2)
                            }
                            
                            Spacer()
                            
                            // Audio Button
                            Button(action: {
                                AudioService.shared.speak(currentWord.kana)
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 44, height: 44)
                                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                                    
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 17))
                                        .foregroundColor(AppTheme.audioIcon)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Example Section
                        VStack(alignment: .leading, spacing: 6) {
                            // Example Header with Space Between Audio Button
                            HStack {
                                Text("Example")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(AppTheme.textSecondary)
                                
                                Spacer()
                                
                                Button(action: {
                                    AudioService.shared.speak(currentWord.exampleJa, rate: 0.42)
                                }) {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .padding(4)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            // Japanese sentence with furigana
                            FuriganaText(
                                text: currentWord.exampleJa,
                                fontSize: 17,
                                furiganaSize: 10,
                                textColor: AppTheme.textPrimary,
                                furiganaColor: AppTheme.textSecondary
                            )
                            
                            // English sentence translation
                            Text(currentWord.exampleEn)
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.textSecondary)
                                .padding(.top, 2)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    Spacer(minLength: 16)
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
                
                // Bottom Navigation Buttons (Previous / Next)
                HStack(spacing: 14) {
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
                        .frame(height: 52)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                        .frame(height: 52)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(AppTheme.buttonBorder, lineWidth: 1.2)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .disabled(currentIndex >= wordsList.count - 1)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
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
