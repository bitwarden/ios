import UIKit

/// Helper functions and computed properties extended off the `UIApplication` class.
///
extension UIApplication {
    /// Returns the first connected window scene's key window.
    var firstKeyWindow: UIWindow? {
        connectedScenes.compactMap { $0 as? UIWindowScene }.first?.keyWindow
    }
}
