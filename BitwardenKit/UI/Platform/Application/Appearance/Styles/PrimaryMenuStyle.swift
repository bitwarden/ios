import BitwardenResources
import SwiftUI

// MARK: - PrimaryMenuStyle

/// A custom `MenuStyle` for styling `Menu` components similar to `PrimaryButtonStyle`. On iOS 17+, a `Menu`
/// can be styled with a `ButtonStyle` instead of a `MenuStyle` (prior to iOS 17, a `ButtonStyle`
/// has no effect on a `Menu`). `ButtonStyle` also allows using `configuration.isPressed` to style
/// the pressed state.
///
@available(iOS, deprecated: 17, message: "Prefer using PrimaryButtonStyle to style Menu buttons on iOS 17+")
public struct PrimaryMenuStyle: MenuStyle {
    // MARK: Properties

    @Environment(\.isEnabled) var isEnabled: Bool

    /// The size of the button.
    var size: ButtonStyleSize

    /// If the menu's button should fill to take up as much width as possible.
    var shouldFillWidth = true

    /// The background color of this button.
    var backgroundColor: Color {
        isEnabled
            ? SharedAsset.Colors.buttonFilledBackground.swiftUIColor
            : SharedAsset.Colors.buttonFilledDisabledBackground.swiftUIColor
    }

    /// The color of the foreground elements in this button, including text and template
    /// images.
    var foregroundColor: Color {
        isEnabled
            ? SharedAsset.Colors.buttonFilledForeground.swiftUIColor
            : SharedAsset.Colors.buttonFilledDisabledForeground.swiftUIColor
    }

    public func makeBody(configuration: Configuration) -> some View {
        Menu(configuration)
            .foregroundColor(foregroundColor)
            .multilineTextAlignment(.center)
            .styleGuide(size.fontStyle, includeLinePadding: false, includeLineSpacing: false)
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .frame(maxWidth: shouldFillWidth ? .infinity : nil, minHeight: size.minimumHeight)
            .background(backgroundColor)
            .clipShape(Capsule())
    }
}

// MARK: - MenuStyle

public extension MenuStyle where Self == PrimaryMenuStyle {
    /// The style for all primary menus in this application.
    ///
    /// - Parameters:
    ///   - shouldFillWidth: A flag indicating if this menu's button should fill all available space.
    ///   - size: The size of the menu's button. Defaults to `large`.
    ///
    static func primary(
        shouldFillWidth: Bool = true,
        size: ButtonStyleSize = .large,
    ) -> PrimaryMenuStyle {
        PrimaryMenuStyle(
            size: size,
            shouldFillWidth: shouldFillWidth,
        )
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    Menu {
        Button("First") {}
        Button("Second") {}
    } label: {
        SharedAsset.Icons.plus32.swiftUIImage
    }
    .menuStyle(.primary())
}
#endif
