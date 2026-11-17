import SwiftUI

struct FuriganaText: View {
    let text: String
    var fontSize: CGFloat = 18
    var furiganaSize: CGFloat = 10
    var textColor: Color = AppTheme.textPrimary
    var furiganaColor: Color = AppTheme.textSecondary
    var boldKanji: Bool = false
    
    var body: some View {
        let segments = FuriganaService.shared.parse(text)
        
        HStack(alignment: .bottom, spacing: 0) {
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
                        .font(.system(size: fontSize, weight: (boldKanji || segment.isKanji) ? .bold : .regular))
                        .foregroundColor(textColor)
                        .fixedSize()
                }
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}
