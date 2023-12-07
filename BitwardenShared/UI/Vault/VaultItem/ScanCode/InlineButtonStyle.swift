import SwiftUI

// MARK: - InlineButtonStyle

/// The style for all primary buttons in this application.
///
struct InlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}
