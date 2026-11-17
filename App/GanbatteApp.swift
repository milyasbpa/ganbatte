import SwiftUI

@main
struct GanbatteApp: App {
    var body: some Scene {
        WindowGroup {
            MainContainerView()
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 480, height: 960)
        #endif
    }
}
