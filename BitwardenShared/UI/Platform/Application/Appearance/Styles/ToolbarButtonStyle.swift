import BitwardenResources
import SwiftUI

// MARK: - ToolbarButtonStyle

/// The style for all toolbar buttons in this application.
///
struct ToolbarButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled: Bool

    /// The color of the foreground elements in this button, including text and template
    /// images.
    var foregroundColor: Color {
        isEnabled
            ? SharedAsset.Colors.buttonOutlinedForeground.swiftUIColor
            : SharedAsset.Colors.buttonFilledDisabledForeground.swiftUIColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .styleGuide(.body)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

// MARK: ButtonStyle

extension ButtonStyle where Self == ToolbarButtonStyle {
    /// The style for all toolbar buttons in this application.
    ///
    static var toolbar: ToolbarButtonStyle {
        ToolbarButtonStyle()
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    VStack {
        Button("Hello World!") {}

        Button("Hello World!") {}
            .disabled(true)
    }
    .buttonStyle(.toolbar)
    .padding()
}
#endif
