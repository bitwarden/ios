import BitwardenResources
import SwiftUI

// MARK: - FieldLabelIconButtonStyle

/// The style for a button containing an icon displayed next to a label in a form field.
///
struct FieldLabelIconButtonStyle: ButtonStyle {
    // MARK: Properties

    /// A value indicating whether the button is currently enabled or disabled.
    @Environment(\.isEnabled) var isEnabled: Bool

    /// The color of the foreground elements, including text and template images.
    var foregroundColor: Color {
        isEnabled
            ? SharedAsset.Colors.buttonOutlinedForeground.swiftUIColor
            : SharedAsset.Colors.buttonOutlinedDisabledForeground.swiftUIColor
    }

    // MARK: ButtonStyle

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 16, height: 16)
            .foregroundColor(foregroundColor)
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
    VStack {
        Button {} label: {
            Asset.Images.cog16.swiftUIImage
        }

        Button {} label: {
            Asset.Images.cog16.swiftUIImage
        }
        .disabled(true)
    }
    .buttonStyle(.fieldLabelIcon)
}
#endif
