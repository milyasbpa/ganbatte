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
                // Top Navigation Bar
                HStack {
                    Button(action: onDismiss) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Words")
                                .font(.system(size: 17, weight: .regular))
                        }
                        .foregroundColor(AppTheme.accent)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text("\(currentIndex + 1) / \(max(wordsList.count, 1))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    // Balancing Spacer for centered counter
                    Text("Words")
                        .font(.system(size: 17))
                        .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 12)
                
                // Main Detail Card with Swipe Gesture
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Hero Cropped Image Banner
                        CardImageView(imageName: currentWord.imageName, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .padding(8)
                        
                        VStack(alignment: .leading, spacing: 18) {
                            // Word Title & Audio
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    // Main Kana
                                    Text(currentWord.kana)
                                        .font(.system(size: 34, weight: .bold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    
                                    // Kanji & Romaji
                                    HStack(spacing: 8) {
                                        if !currentWord.kanji.isEmpty && currentWord.kanji != currentWord.kana {
                                            Text(currentWord.kanji)
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(AppTheme.textPrimary)
                                        }
                                        
                                        Text(currentWord.romaji)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                    
                                    // Type
                                    HStack(spacing: 4) {
                                        Text("•")
                                            .foregroundColor(AppTheme.textSecondary)
                                        Text(currentWord.type)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                    .padding(.top, 2)
                                }
                                
                                Spacer()
                                
                                // Word Audio Button
                                Button(action: {
                                    AudioService.shared.speak(currentWord.kana)
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(AppTheme.audioButtonBg)
                                            .frame(width: 48, height: 48)
                                        
                                        Image(systemName: "speaker.wave.2.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(AppTheme.audioIcon)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Divider()
                                .background(AppTheme.cardBorder)
                            
                            // Example Section
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Example")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    Button(action: {
                                        AudioService.shared.speak(currentWord.exampleJa, rate: 0.42)
                                    }) {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .font(.system(size: 13))
                                            .foregroundColor(AppTheme.audioIcon)
                                            .padding(4)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                // Furigana sentence
                                FuriganaText(text: currentWord.exampleJa, fontSize: 18, furiganaSize: 11)
                                
                                // English sentence translation
                                Text(currentWord.exampleEn)
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.textSecondary)
                                    .padding(.top, 2)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .padding(.bottom, 24)
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                }
                .simultaneousGesture(
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
                HStack(spacing: 16) {
                    Button(action: prevCard) {
                        HStack(spacing: 6) {
                            Text("←")
                            Text("Previous")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(currentIndex > 0 ? AppTheme.textPrimary : AppTheme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .disabled(currentIndex <= 0)
                    
                    Button(action: nextCard) {
                        HStack(spacing: 6) {
                            Text("Next")
                            Text("→")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(currentIndex < wordsList.count - 1 ? AppTheme.textPrimary : AppTheme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .disabled(currentIndex >= wordsList.count - 1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .onAppear {
            if let idx = wordsList.firstIndex(where: { $0.id == currentWord.id }) {
                currentIndex = idx
            }
        }
    }
    
    private func nextCard() {
        guard currentIndex < wordsList.count - 1 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            currentIndex += 1
            currentWord = wordsList[currentIndex]
        }
    }
    
    private func prevCard() {
        guard currentIndex > 0 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            currentIndex -= 1
            currentWord = wordsList[currentIndex]
        }
    }
}
