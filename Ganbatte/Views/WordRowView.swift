import SwiftUI

struct WordRowView: View {
    let word: Word
    var onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Thumbnail Image
                CardImageView(imageName: word.imageName, contentMode: .fill)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                // Word Details
                VStack(alignment: .leading, spacing: 3) {
                    Text(word.kanji.isEmpty ? word.kana : word.kanji)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text(word.kana)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Text(word.type)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(AppTheme.textTertiary)
                }
                
                Spacer()
                
                // Audio Button
                Button(action: {
                    AudioService.shared.speak(word.kana)
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 42, height: 42)
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                        
                        Image(systemName: "music.note")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppTheme.audioIcon)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
