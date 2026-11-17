import SwiftUI

struct MainContainerView: View {
    var body: some View {
        #if os(iOS)
        WordListView()
        #elseif os(macOS)
        ZStack {
            // Glassy macOS Ambient Frosted Background
            VisualEffectBackground()
                .ignoresSafeArea()
            
            AppTheme.background.opacity(0.12)
                .ignoresSafeArea()
            
            // Centered Mobile Canvas with iPhone Pro Dimensions
            VStack {
                WordListView()
                    .frame(width: 410)
                    .frame(maxHeight: 900)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 30, x: 0, y: 15)
                    .padding(.vertical, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 460, minHeight: 950)
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
