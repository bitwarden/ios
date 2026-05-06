import BitwardenSdk

/// A delegate that is used to handle actions and configure the display for when the app runs within
/// an app extension.
///
@MainActor
public protocol AppExtensionDelegate: AnyObject {
    /// The app's route that the app should navigate to after auth has been completed.
    var authCompletionRoute: AppRoute? { get }

    /// Whether the app extension can autofill credentials.
    var canAutofill: Bool { get }

    /// Whether the app is running within an extension.
    var isInAppExtension: Bool { get }

    /// The page details parsed from the host web page, if available.
    var pageDetails: PageDetails? { get }

    /// Whether the app is running the save login flow in the action extension. This flow opens the
    /// add vault item view and completes the extension request when the item has been added.
    var isInAppExtensionSaveLoginFlow: Bool { get }

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

    /// The autofill request should be completed using explicit page field opId mappings from
    /// a saved Autofill Assist configuration.
    ///
    /// - Parameters:
    ///   - username: The username to fill.
    ///   - password: The password to fill.
    ///   - fields: A list of additional fields to fill.
    ///   - usernameOpId: The opId of the page field to receive the username, or `nil` for heuristic
    ///     detection.
    ///   - passwordOpId: The opId of the page field to receive the password, or `nil` for heuristic
    ///     detection.
    ///
    func completeAutofillRequest(
        username: String,
        password: String,
        fields: [(String, String)]?,
        usernameOpId: String?,
        passwordOpId: String?,
    )

    /// A cancel button was tapped to exit the extension.
    ///
    func didCancel()

    /// The user has successfully authenticated.
    ///
    func didCompleteAuth()
}

public extension AppExtensionDelegate {
    /// Whether the app extension can autofill credentials.
    var canAutofill: Bool { false }

    /// Whether the app is running the save login flow in the action extension. This flow opens the
    /// add vault item view and completes the extension request when the item has been added.
    var isInAppExtensionSaveLoginFlow: Bool { false }

    /// The page details parsed from the host web page, if available.
    var pageDetails: PageDetails? { nil }

    /// The autofill request should be completed with the specified username and password.
    ///
    /// - Parameters:
    ///   - username: The username to fill.
    ///   - password: The password to fill.
    ///   - fields: A list of additional fields to fill.
    ///
    func completeAutofillRequest(username: String, password: String, fields: [(String, String)]?) {}

    /// Defaults to calling `completeAutofillRequest(username:password:fields:)`, ignoring opIds.
    ///
    func completeAutofillRequest(
        username: String,
        password: String,
        fields: [(String, String)]?,
        usernameOpId: String?,
        passwordOpId: String?,
    ) {
        completeAutofillRequest(username: username, password: password, fields: fields)
    }

    /// The user has successfully authenticated.
    ///
    func didCompleteAuth() {}
}
