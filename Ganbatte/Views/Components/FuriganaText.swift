import SwiftUI

struct FuriganaText: View {
    let text: String
    var fontSize: CGFloat = 18
    var furiganaSize: CGFloat = 11
    var textColor: Color = AppTheme.textPrimary
    var furiganaColor: Color = AppTheme.textSecondary
    
    var body: some View {
        let segments = FuriganaService.shared.parse(text)
        
        // Horizontal arrangement of word segments
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(segments) { segment in
                VStack(spacing: 1) {
                    if segment.isKanji, let reading = segment.reading {
                        Text(reading)
                            .font(.system(size: furiganaSize, weight: .regular))
                            .foregroundColor(furiganaColor)
                            .lineLimit(1)
                            .fixedSize()
                    } else {
                        Text(" ")
                            .font(.system(size: furiganaSize))
                            .opacity(0)
                    }
                    
                    Text(segment.text)
                        .font(.system(size: fontSize, weight: .medium))
                        .foregroundColor(textColor)
                        .fixedSize()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
