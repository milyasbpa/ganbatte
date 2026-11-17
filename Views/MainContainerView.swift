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
            
            // Centered Mobile Canvas with iPhone Dimensions
            WordListView()
                .frame(width: 410)
                .frame(maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 12)
                .padding(.vertical, 14)
        }
        .frame(minWidth: 440, minHeight: 650)
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
