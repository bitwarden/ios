import FirebaseCore
import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    func applicationDidFinishLaunching() {
        #if !DEBUG
        FirebaseApp.configure()
        #endif
    }
}
