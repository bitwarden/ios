import BitwardenKit

// MARK: - ImportLoginsState

/// An object that defines the current state of a `ImportLoginsView`.
///
public struct ImportLoginsState: Equatable, Sendable {
    // MARK: Types

    /// The modes that define where the import logins flow started from.
    ///
    public enum Mode: Equatable, Sendable {
        /// Import logins from the app's settings.
        case settings

        /// Import logins from the vault list.
        case vault
    }

    /// An enumeration of the instruction pages that the user can navigate between.
    ///
    enum Page: Int {
        case intro
        case step1
        case step2
        case step3

        /// The page before the current one.
        var previous: Page? {
            Page(rawValue: rawValue - 1)
        }

        /// The page after the current one.
        var next: Page? {
            Page(rawValue: rawValue + 1)
        }
    }

    // MARK: Properties

    /// The mode of the view based on where the import logins flow was started from.
    var mode: Mode

    /// The current page.
    var page = Page.intro

    /// The hostname of the web vault URL.
    var webVaultHost = Constants.defaultWebVaultHost

    // MARK: Computed Properties

    /// Whether the import logins later button should be shown.
    var shouldShowImportLoginsLater: Bool {
        mode == .vault
    }
}
