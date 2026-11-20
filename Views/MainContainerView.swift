import SwiftUI

struct MainContainerView: View {
    @AppStorage("ganbatte_active_main_tab") private var activeTabRaw: String = AppTab.learn.rawValue
    @State private var hideBottomBar: Bool = false
    @State private var isShowingSplash: Bool = true
    @ObservedObject private var notifService = NotificationService.shared
    
    private var selectedTab: Binding<AppTab> {
        Binding(
            get: { AppTab(rawValue: activeTabRaw) ?? .learn },
            set: { activeTabRaw = $0.rawValue }
        )
    }
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selectedTab.wrappedValue {
                case .learn:
                    LearnHubView(
                        hideBottomBar: $hideBottomBar
                    )
                case .exercise:
                    ExerciseHubView(
                        hideBottomBar: $hideBottomBar
                    )
                case .activity:
                    ActivityDashboardView()
                case .reminders:
                    ReminderSheetView(onDismiss: nil)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if !hideBottomBar {
                BottomNavBar(selectedTab: selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ganbatte_shortcut_to_mistakes"))) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                activeTabRaw = AppTab.exercise.rawValue
            }
        }
        .onReceive(notifService.$pendingDeepLink) { link in
            guard let link = link else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                switch link {
                case .kana(let script, let mode):
                    if mode == .learn {
                        activeTabRaw = AppTab.learn.rawValue
                        UserDefaults.standard.set(script.rawValue, forKey: "ganbatte_active_kana_subtab")
                        NotificationCenter.default.post(name: NSNotification.Name("ganbatte_navigate_to_kana"), object: nil)
                    } else {
                        var kCfg = KanaQuizConfig.load()
                        kCfg.kanaType = script
                        kCfg.save()
                        activeTabRaw = AppTab.exercise.rawValue
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ganbatte_shortcut_to_exercise"),
                            object: nil,
                            userInfo: ["category": "Kana", "kanaType": script.rawValue]
                        )
                    }
                    
                case .words(let level, let type, let mode):
                    if mode == .learn {
                        activeTabRaw = AppTab.learn.rawValue
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ganbatte_apply_word_filter"),
                            object: nil,
                            userInfo: ["level": level.rawValue, "type": type.rawValue]
                        )
                        NotificationCenter.default.post(name: NSNotification.Name("ganbatte_navigate_to_words"), object: nil)
                    } else {
                        var cfg = QuizConfig.load()
                        cfg.level = level
                        cfg.type = type
                        cfg.save()
                        activeTabRaw = AppTab.exercise.rawValue
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ganbatte_shortcut_to_exercise"),
                            object: nil,
                            userInfo: ["category": "Kotoba", "level": level.rawValue, "type": type.rawValue]
                        )
                    }
                }
            }
            notifService.pendingDeepLink = nil
        }
    }
    
    var body: some View {
        #if os(iOS)
        ZStack {
            mainContent
                .ignoresSafeArea(.keyboard)
            
            if isShowingSplash {
                SplashScreenView(isShowing: $isShowingSplash)
                    .transition(.opacity.combined(with: .scale(scale: 1.03)))
                    .zIndex(999)
            }
        }
        #elseif os(macOS)
        ZStack {
            // Glassy macOS Ambient Frosted Background
            VisualEffectBackground()
                .ignoresSafeArea()
            
            AppTheme.background.opacity(0.12)
                .ignoresSafeArea()
            
            // Centered Mobile Canvas with iPhone Dimensions
            ZStack {
                mainContent
                
                if isShowingSplash {
                    SplashScreenView(isShowing: $isShowingSplash)
                        .transition(.opacity.combined(with: .scale(scale: 1.03)))
                        .zIndex(999)
                }
            }
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
