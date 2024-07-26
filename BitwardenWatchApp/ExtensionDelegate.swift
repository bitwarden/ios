import FirebaseCore
import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    func applicationDidFinishLaunching() {
        #if !DEBUG
        FirebaseApp.configure()
        #endif

        Task {
            try await Task.sleep(nanoseconds: 5_000_000_000)
            perform(Selector(("crash")))
        }
    }
}
