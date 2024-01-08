/// A delegate that is used to handle actions and configure the display for when the app runs within
/// an app extension.
///
public protocol AppExtensionDelegate: AnyObject {
    /// Whether the app is running within an extension.
    var isInAppExtension: Bool { get }

    /// A cancel button was tapped to exit the extension.
    func didCancel()
}
