import SwiftUI

// MARK: - InlineButtonStyle

/// The style for all inline buttons in this application.
///
public struct InlineButtonStyle: ButtonStyle {
    /// Initializes an `InlineButtonStyle`.
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}
