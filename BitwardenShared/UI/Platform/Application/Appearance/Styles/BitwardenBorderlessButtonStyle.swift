import SwiftUI

// MARK: - BitwardenBorderlessButtonStyle

/// The style for a borderless button in this application.
///
struct BitwardenBorderlessButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Asset.Colors.textInteraction.swiftUIColor)
            .padding(.vertical, 14)
            .styleGuide(.subheadlineSemibold)
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

// MARK: ButtonStyle

extension ButtonStyle where Self == BitwardenBorderlessButtonStyle {
    /// The style for a borderless button in this application.
    ///
    static var bitwardenBorderless: BitwardenBorderlessButtonStyle {
        BitwardenBorderlessButtonStyle()
    }
}

// MARK: Previews

#if DEBUG
#Preview() {
    Button {} label: {
        Text("Bitwarden")
    }
    .buttonStyle(.bitwardenBorderless)
}
#endif
