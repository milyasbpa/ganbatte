import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
struct FuriganaFlowLayout: Layout {
    var horizontalSpacing: CGFloat = 0
    var verticalSpacing: CGFloat = 4
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentPoint = CGPoint.zero
        var maxY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentPoint.x + size.width > maxWidth && currentPoint.x > 0 {
                currentPoint.x = 0
                currentPoint.y += lineHeight + verticalSpacing
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            currentPoint.x += size.width + horizontalSpacing
            maxY = max(maxY, currentPoint.y + lineHeight)
        }
        
        return CGSize(width: maxWidth.isFinite ? maxWidth : currentPoint.x, height: maxY)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0
        var lineSubviews: [(LayoutSubview, CGSize, CGFloat)] = []
        
        func flushLine() {
            for (subview, size, x) in lineSubviews {
                let y = currentY + (lineHeight - size.height)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            }
            lineSubviews.removeAll()
        }
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                flushLine()
                currentX = bounds.minX
                currentY += lineHeight + verticalSpacing
                lineHeight = 0
            }
            lineSubviews.append((subview, size, currentX))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + horizontalSpacing
        }
        flushLine()
    }
}

struct FuriganaText: View {
    let text: String
    var fontSize: CGFloat = 18
    var furiganaSize: CGFloat = 10
    var textColor: Color = AppTheme.textPrimary
    var furiganaColor: Color = AppTheme.textSecondary
    var boldKanji: Bool = false
    var isWrapped: Bool = true
    
    var body: some View {
        let segments = FuriganaService.shared.parse(text)
        
        if isWrapped {
            FuriganaFlowLayout(horizontalSpacing: 0, verticalSpacing: 4) {
                segmentViews(segments)
            }
        } else {
            HStack(alignment: .bottom, spacing: 0) {
                segmentViews(segments)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
    }
    
    @ViewBuilder
    private func segmentViews(_ segments: [FuriganaSegment]) -> some View {
        ForEach(segments) { segment in
            if segment.text == "[ ______ ]" {
                VStack(spacing: 1) {
                    Text(" ")
                        .font(.system(size: furiganaSize))
                        .opacity(0)
                    
                    Text(" [ ______ ] ")
                        .font(.system(size: fontSize, weight: .bold))
                        .foregroundColor(AppTheme.accent)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(AppTheme.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            } else {
                VStack(spacing: 1) {
                    if segment.isKanji, let reading = segment.reading {
                        Text(reading)
                            .font(.system(size: furiganaSize, weight: .medium))
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
    }
}
