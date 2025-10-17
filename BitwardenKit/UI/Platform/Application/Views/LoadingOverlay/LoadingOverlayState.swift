/// State used to configure the display of a `LoadingOverlayView`.
///
public struct LoadingOverlayState: Equatable {
    // MARK: Properties

    /// The title of the loading overlay, displayed below the activity indicator.
    public let title: String

    // MARK: Initializers

    /// Initializes a `LoadingOverlayState`.
    ///
    /// - Parameters:
    ///   - title: The title of the loading overlay, displayed below the activity indicator.
    public init(title: String) {
        self.title = title
    }
}
