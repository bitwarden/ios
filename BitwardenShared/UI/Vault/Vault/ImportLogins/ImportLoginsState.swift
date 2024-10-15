// MARK: - ImportLoginsState

/// An object that defines the current state of a `ImportLoginsView`.
///
struct ImportLoginsState: Equatable, Sendable {
    // MARK: Types

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

    /// The current page.
    var page = Page.intro

    /// The hostname of the web vault URL.
    var webVaultHost = Constants.defaultWebVaultHost
}
