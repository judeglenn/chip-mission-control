import SwiftUI

@main
struct ChipMissionControlApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No visible window — UI is entirely in the NSStatusItem popover.
        // The Settings scene keeps SwiftUI happy without showing a main window.
        Settings {
            EmptyView()
        }
    }
}
