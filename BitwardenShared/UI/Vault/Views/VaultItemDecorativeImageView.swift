import SwiftUI

// MARK: - VaultItemDecorativeImageView

/// A decorative image that is used to be displayed in the cipher rows on lists
/// which also has a placeholder to be shown when the main image can't
/// or shouldn't be loaded.
///
struct VaultItemDecorativeImageView: View {
    /// The base url used to download decorative images
    let iconBaseURL: URL?

    /// The vault item that has decorative icon
    let item: VaultItemWithDecorativeIcon

    /// Whether to download the web icons
    let showWebIcons: Bool

    var body: some View {
        // The Group is needed so `.accessibilityHidden(false)` can be applied to this image wrapper.
        // This allows automated tests to detect the image's accessibility ID even though the image itself
        // is excluded from the accessibility tree.
        Group {
            if showWebIcons, let loginView = item.loginView, let iconBaseURL {
                AsyncImage(
                    url: IconImageHelper.getIconImage(
                        for: loginView,
                        from: iconBaseURL
                    ),
                    content: { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .accessibilityHidden(true)
                    },
                    placeholder: {
                        placeholderDecorativeImage(item.icon)
                    }
                )
            } else {
                placeholderDecorativeImage(item.icon)
            }
        }
        .accessibilityIdentifier(item.iconAccessibilityId)
        .accessibilityHidden(false)
    }

    /// Initializes the view vault item with decorative icon image.
    ///
    /// - Parameters:
    ///   - item: The vault item that has decorative icon
    ///   - iconBaseURL: The base url used to download decorative images
    ///   - showWebIcons: Whether to download the web icons.
    ///
    init(
        item: VaultItemWithDecorativeIcon,
        iconBaseURL: URL?,
        showWebIcons: Bool
    ) {
        self.item = item
        self.iconBaseURL = iconBaseURL
        self.showWebIcons = showWebIcons
    }

    // MARK: - Private Views

    /// The placeholder image for the decorative image.
    private func placeholderDecorativeImage(_ icon: ImageAsset) -> some View {
        Image(decorative: icon)
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
    }
}
