// MARK: SendRoute

/// The route to a specific screen in the send tab.
///
public enum SendRoute: Equatable {
    /// A route to the add item screen.
    case addItem

    /// A route to the camera screen.
    case camera

    /// A route that dismisses a presented sheet.
    case dismiss

    /// A route to the file browser.
    case fileBrowser

    /// A route to the send screen.
    case list

    /// A route to the photo library screen.
    case photoLibrary
}
