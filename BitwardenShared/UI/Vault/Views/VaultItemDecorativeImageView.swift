import BitwardenResources
import SwiftUI

// MARK: - VaultItemDecorativeImageView

/// A decorative image that is used to be displayed in the cipher rows on lists
/// which also has a placeholder to be shown when the main image can't
/// or shouldn't be loaded.
///
struct VaultItemDecorativeImageView<PlaceholderContent: View>: View {
    /// The base url used to download decorative images
    let iconBaseURL: URL?

    /// The vault item that has decorative icon
    let item: VaultItemWithDecorativeIcon

    /// Whether to download the web icons
    let showWebIcons: Bool

    /// The placeholder content to build from the icon asset.
    let placeholderContent: ((SharedImageAsset) -> PlaceholderContent)?

    var body: some View {
        // The Group is needed so `.accessibilityHidden(false)` can be applied to this image wrapper.
        // This allows automated tests to detect the image's accessibility ID even though the image itself
        // is excluded from the accessibility tree.
        Group {
            if showWebIcons, let cipherDecorativeIconDataView = item.cipherDecorativeIconDataView, let iconBaseURL {
                CipherIconAsyncImage(
                    url: IconImageHelper.getIconImage(
                        for: cipherDecorativeIconDataView,
                        from: iconBaseURL,
                    ),
                    placeholder: { placeholder(item.icon) },
                )
            } else {
                placeholder(item.icon)
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
    ///   - placeholderContent: The placeholder content to build from the icon asset.
    ///
    init(
        item: VaultItemWithDecorativeIcon,
        iconBaseURL: URL?,
        showWebIcons: Bool,
        placeholderContent: ((SharedImageAsset) -> PlaceholderContent)? = nil,
    ) {
        self.item = item
        self.iconBaseURL = iconBaseURL
        self.placeholderContent = placeholderContent
        self.showWebIcons = showWebIcons
    }

    // MARK: - Private Views

    /// The placeholder view to use.
    ///
    /// - Parameter icon: The icon to use in the placeholder view.
    /// - Returns: The placeholder view.
    @ViewBuilder
    private func placeholder(_ icon: SharedImageAsset) -> some View {
        if item.shouldUseCustomPlaceholderContent, let placeholderContent {
            placeholderContent(icon)
        } else {
            placeholderDecorativeImage(icon)
        }
    }

    /// The placeholder image for the decorative image.
    private func placeholderDecorativeImage(_ icon: SharedImageAsset) -> some View {
        Image(decorative: icon)
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
    }
}

// MARK: - CipherIconAsyncImage

/// `AsyncImage` replacement that fetches through `CipherIconImageLoader` so requests carry the
/// user's mTLS client certificate.
private struct CipherIconAsyncImage<Placeholder: View>: View {
    let url: URL?
    let placeholder: () -> Placeholder

    @SwiftUI.State private var image: UIImage?

    /// Task managing the current image load, cancelled and restarted when the URL changes.
    @SwiftUI.State private var loadTask: Task<Void, Never>?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityHidden(true)
            } else {
                placeholder()
            }
        }
        .onAppear { startLoadingImage(from: url) }
        .onChange(of: url) { newUrl in startLoadingImage(from: newUrl) }
        .onDisappear {
            loadTask?.cancel()
            loadTask = nil
        }
    }

    /// Cancels any in-flight load and starts a new image load for the given URL.
    ///
    /// - Parameter imageUrl: The URL to load the image from, or `nil` to clear the displayed image.
    private func startLoadingImage(from imageUrl: URL?) {
        loadTask?.cancel()
        loadTask = Task {
            guard let imageUrl else { image = nil; return }
            image = await CipherIconImageLoader.shared.loadImage(from: imageUrl)
        }
    }
}

extension VaultItemDecorativeImageView where PlaceholderContent == EmptyView {
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
        showWebIcons: Bool,
    ) {
        self.item = item
        self.iconBaseURL = iconBaseURL
        placeholderContent = nil
        self.showWebIcons = showWebIcons
    }
}
