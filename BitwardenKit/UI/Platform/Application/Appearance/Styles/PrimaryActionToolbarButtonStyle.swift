import BitwardenResources
import SwiftUI

// MARK: - PrimaryActionToolbarButtonStyle

/// The style for primary action toolbar buttons. Uses the prominent style on iOS 26 and later so
/// the button stands out on the Liquid Glass toolbar, and the plain toolbar style on earlier
/// versions of iOS.
///
public struct PrimaryActionToolbarButtonStyle: PrimitiveButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26, *) {
            Button(configuration)
                .buttonStyle(.borderedProminent)
                .tint(SharedAsset.Colors.buttonFilledBackground.swiftUIColor)
        } else {
            Button(configuration)
                .buttonStyle(.toolbar)
        }
    }
}

// MARK: PrimitiveButtonStyle

public extension PrimitiveButtonStyle where Self == PrimaryActionToolbarButtonStyle {
    /// The style for primary action toolbar buttons.
    ///
    static var primaryActionToolbar: PrimaryActionToolbarButtonStyle {
        PrimaryActionToolbarButtonStyle()
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
    .buttonStyle(.primaryActionToolbar)
    .padding()
}
#endif
