import SwiftUI

@main
struct GanbatteApp: App {
    init() {
        NotificationService.shared.setup()
    }
    
    var body: some Scene {
        WindowGroup {
            MainContainerView()
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 460, height: 840)
        .windowResizability(.contentSize)
        #endif
    }
}
