import SwiftUI

@main
struct GanbatteApp: App {
    var body: some Scene {
        WindowGroup {
            MainContainerView()
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 460, height: 800)
        #endif
    }
}
