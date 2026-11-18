import SwiftUI

struct MainContainerView: View {
    @AppStorage("ganbatte_active_main_tab") private var activeTabRaw: String = AppTab.words.rawValue
    @State private var hideBottomBar: Bool = false
    @State private var showReminderSheet: Bool = false
    @ObservedObject private var notifService = NotificationService.shared
    
    private var selectedTab: Binding<AppTab> {
        Binding(
            get: { AppTab(rawValue: activeTabRaw) ?? .words },
            set: { activeTabRaw = $0.rawValue }
        )
    }
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selectedTab.wrappedValue {
                case .words:
                    WordListView(
                        hideBottomBar: $hideBottomBar,
                        onOpenReminders: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showReminderSheet = true
                            }
                        }
                    )
                case .kana:
                    KanaChartView(
                        hideBottomBar: $hideBottomBar,
                        onOpenReminders: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showReminderSheet = true
                            }
                        }
                    )
                }
                
                if showReminderSheet {
                    ReminderSheetView(onDismiss: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showReminderSheet = false
                        }
                    })
                    .transition(.move(edge: .bottom))
                    .zIndex(300)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if !hideBottomBar && !showReminderSheet {
                BottomNavBar(selectedTab: selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: showReminderSheet) { val in
            withAnimation(.easeInOut(duration: 0.2)) {
                hideBottomBar = val
            }
        }
        .onReceive(notifService.$pendingDeepLink) { link in
            guard let link = link else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                showReminderSheet = false
                switch link {
                case .kana(let script):
                    activeTabRaw = AppTab.kana.rawValue
                    UserDefaults.standard.set(script.rawValue, forKey: "ganbatte_active_kana_subtab")
                case .words(let level, let type):
                    activeTabRaw = AppTab.words.rawValue
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ganbatte_apply_word_filter"),
                        object: nil,
                        userInfo: ["level": level.rawValue, "type": type.rawValue]
                    )
                }
            }
            notifService.pendingDeepLink = nil
        }
    }
    
    var body: some View {
        #if os(iOS)
        mainContent
            .ignoresSafeArea(.keyboard)
        #elseif os(macOS)
        ZStack {
            // Glassy macOS Ambient Frosted Background
            VisualEffectBackground()
                .ignoresSafeArea()
            
            AppTheme.background.opacity(0.12)
                .ignoresSafeArea()
            
            // Centered Mobile Canvas with iPhone Dimensions
            mainContent
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
        .frame(minWidth: 440, idealWidth: 460, maxWidth: 500, minHeight: 780, idealHeight: 840, maxHeight: 920)
        .onAppear {
            DispatchQueue.main.async {
                if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
                    window.center()
                    window.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
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
