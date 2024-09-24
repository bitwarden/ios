import SwiftUI

// MARK: - TransparentButtonStyle

/// The style for all transparent buttons in this application.
///
struct TransparentButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled: Bool

    /// The color of the foreground elements in this button, including text and template
    /// images.
    var foregroundColor: Color {
        isEnabled
            ? Asset.Colors.primaryBitwarden.swiftUIColor
            : Asset.Colors.textTertiary.swiftUIColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .styleGuide(.bodyBold)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

// MARK: ButtonStyle

extension ButtonStyle where Self == TransparentButtonStyle {
    /// The style for all transparent buttons in this application.
    ///
    static var transparent: TransparentButtonStyle {
        TransparentButtonStyle()
    }
}

// MARK: Previews

#if DEBUG
#Preview("Enabled") {
    Button("Hello World!") {}
        .buttonStyle(.transparent)
}

#Preview("Disabled") {
    Button("Hello World!") {}
        .buttonStyle(.transparent)
        .disabled(true)
}
#endif
