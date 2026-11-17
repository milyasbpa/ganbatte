import SwiftUI

struct MainContainerView: View {
    var body: some View {
        #if os(iOS)
        WordListView()
        #elseif os(macOS)
        ZStack {
            // Glassy macOS Ambient Background
            VisualEffectBackground()
                .ignoresSafeArea()
            
            AppTheme.background.opacity(0.15)
                .ignoresSafeArea()
            
            // Centered Mobile Canvas
            VStack {
                WordListView()
                    .frame(width: 420)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: 15)
                    .padding(.vertical, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 500, minHeight: 800)
        #endif
    }
}

#if os(macOS)
import AppKit

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
#endif
