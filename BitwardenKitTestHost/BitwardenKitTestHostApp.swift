import SwiftUI

// MARK: - BitwardenKitTestHostApp

/// A minimal application that hosts `BitwardenKitSnapshotTests`.
///
/// Snapshot tests render views from the app's key window (`drawHierarchyInKeyWindow`), which
/// requires the tests to run inside a host application. This app has no functionality of its own.
///
@main
struct BitwardenKitTestHostApp: App {
    var body: some Scene {
        WindowGroup {
            Color.clear
        }
    }
}
