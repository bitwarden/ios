import BitwardenSdk

/// A delegate that is used to handle actions and configure the display for when the app runs within
/// an app extension.
///
public protocol AppExtensionDelegate: AnyObject {
    /// The app's route that the app should navigate to after auth has been completed.
    var authCompletionRoute: AppRoute { get }

    /// Whether the app is running within an extension.
    var isInAppExtension: Bool { get }

    /// The URI of the credential to autofill.
    var uri: String? { get }

    /// The autofill request should be completed with the specified username and password.
    ///
    /// - Parameters:
    ///   - username: The username to fill.
    ///   - password: The password to fill.
    ///   - fields: A list of additional fields to fill.
    ///
    func completeAutofillRequest(username: String, password: String, fields: [(String, String)]?)

    /// A cancel button was tapped to exit the extension.
    ///
    func didCancel()
}

public extension AppExtensionDelegate {
    /// The autofill request should be completed with the specified username and password.
    ///
    /// - Parameters:
    ///   - username: The username to fill.
    ///   - password: The password to fill.
    ///   - fields: A list of additional fields to file.
    ///
    func completeAutofillRequest(username: String, password: String, fields: [(String, String)]?) {}

    /// The autofill request should be completed with the specified username and password.
    ///
    /// - Parameters:
    ///   - username: The username to fill.
    ///   - password: The password to fill.
    ///
    func completeAutofillRequest(username: String, password: String) {
        completeAutofillRequest(username: username, password: password, fields: nil)
    }
}
