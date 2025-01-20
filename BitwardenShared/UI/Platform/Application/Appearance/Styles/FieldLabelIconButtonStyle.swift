import SwiftUI

// MARK: - FieldLabelIconButtonStyle

/// The style for a button containing an icon displayed next to a label in a form field.
///
struct FieldLabelIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 16, height: 16)
            .foregroundColor(Asset.Colors.textInteraction.swiftUIColor)
            .opacity(configuration.isPressed ? 0.5 : 1)
            .contentShape(Rectangle())
    }
}

// MARK: ButtonStyle

extension ButtonStyle where Self == FieldLabelIconButtonStyle {
    /// The style for a field label icon button in this application.
    ///
    static var fieldLabelIcon: FieldLabelIconButtonStyle {
        FieldLabelIconButtonStyle()
    }
}

// MARK: Previews

#if DEBUG
#Preview() {
    Button {} label: {
        Asset.Images.cog16.swiftUIImage
    }
    .buttonStyle(.fieldLabelIcon)
}
#endif
