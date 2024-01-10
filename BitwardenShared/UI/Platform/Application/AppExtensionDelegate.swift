import BitwardenSdk

/// A delegate that is used to handle actions and configure the display for when the app runs within
/// an app extension.
///
public protocol AppExtensionDelegate: AnyObject {
    /// Whether the app is running within an extension.
    var isInAppExtension: Bool { get }

    /// The autofill request should be completed with the specified username and password.
    ///
    /// - Parameters:
    ///   - username: The username to fill.
    ///   - password: The password to fill.
    ///
    func completeAutofillRequest(username: String, password: String)

    /// A cancel button was tapped to exit the extension.
    ///
    func didCancel()
}
