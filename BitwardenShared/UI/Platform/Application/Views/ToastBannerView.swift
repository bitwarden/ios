import BitwardenResources
import SwiftUI

// MARK: - ToastBannerView

/// A toast banner view which displays a toast message and doesn't automatically dismiss. This is
/// similar to `ToastView` but has a close button to dismiss the banner and supports displaying
/// custom buttons at the bottom of the banner.
///
struct ToastBannerView<ButtonContent: View>: View {
    // MARK: Properties

    /// A button content view to display below the title and subtitle of the toast banner.
    let buttonContent: ButtonContent

    /// A binding which controls if the toast banner is visible.
    @Binding var isVisible: Bool

    /// The subtitle text displayed in the toast banner.
    let subtitle: String

    /// The title text displayed in the toast banner.
    let title: String

    // MARK: View

    var body: some View {
        if isVisible {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .styleGuide(
                                .headline,
                                weight: .semibold,
                                includeLinePadding: false,
                                includeLineSpacing: false
                            )
                        Text(subtitle)
                            .styleGuide(.callout)
                    }
                    .foregroundStyle(SharedAsset.Colors.textReversed.swiftUIColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        isVisible = false
                    } label: {
                        Image(asset: Asset.Images.close16, label: Text(Localizations.close))
                            .imageStyle(.accessoryIcon16(color: SharedAsset.Colors.iconReversed.swiftUIColor))
                            .padding(16) // Add padding to increase tappable area...
                    }
                    .padding(-16) // ...but remove it to not affect layout.
                }

                buttonContent
                    .buttonStyle(.secondary(isReversed: true, shouldFillWidth: false, size: .small))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
            .background(SharedAsset.Colors.backgroundAlert.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 4)
            .accessibilityIdentifier("ToastElement")
            .accessibilityElement(children: .combine)
            .padding(.horizontal, 12)
        }
    }

    // MARK: Initialization

    /// Initialize a `ToastBannerView`.
    ///
    /// - Parameters:
    ///   - title: The title text displayed in the toast banner.
    ///   - subtitle: The subtitle text displayed in the toast banner.
    ///   - isVisible: A binding which controls if the toast banner is visible.
    ///   - buttonContent: A button content view to display below the title and subtitle of the toast banner.
    ///
    init(
        title: String,
        subtitle: String,
        isVisible: Binding<Bool>,
        @ViewBuilder buttonContent: () -> ButtonContent
    ) {
        self.title = title
        self.subtitle = subtitle
        _isVisible = isVisible
        self.buttonContent = buttonContent()
    }
}

// MARK: - View

extension View {
    /// Displays a toast banner view in an overlay at the bottom of the view.
    ///
    /// - Parameters:
    ///   - title: The title text displayed in the toast banner.
    ///   - subtitle: The subtitle text displayed in the toast banner.
    ///   - additionalBottomPadding: Additional bottom padding to apply to the toast banner.
    ///   - isVisible: A binding which controls if the toast banner is visible.
    ///   - buttonContent: A button content view to display below the title and subtitle of the toast banner.
    /// - Returns: A view that displays a toast banner.
    ///
    func toastBanner<ButtonContent: View>(
        title: String,
        subtitle: String,
        additionalBottomPadding: CGFloat = 0,
        isVisible: Binding<Bool>,
        @ViewBuilder buttonContent: () -> ButtonContent
    ) -> some View {
        overlay(alignment: .bottom) {
            ToastBannerView(
                title: title,
                subtitle: subtitle,
                isVisible: isVisible,
                buttonContent: buttonContent
            )
            .padding(.bottom, 12 + additionalBottomPadding)
            .animation(.easeInOut, value: isVisible.wrappedValue)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    ToastBannerView(
        title: "Title",
        subtitle: "Subtitle",
        isVisible: .constant(true)
    ) {
        Button("Tap me") {}
    }
    .padding()
}
#endif
