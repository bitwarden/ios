import SwiftUI
import WebKit

// MARK: - GifView

/// A view that displays a GIF using a `WKWebView`.
/// This view handles the rendering of the GIF asset
/// and ensures that the background is transparent.
///
struct GifView: UIViewRepresentable {
    // MARK: Properties

    /// The `DataAsset` that contains the GIF data to be rendered.
    private let gif: DataAsset

    // MARK: Initialization

    /// Initializes the `GifView` with a specific `DataAsset` for the GIF.
    ///
    /// - Parameter gif: The data asset for the GIF.
    ///
    init(gif: DataAsset) {
        self.gif = gif
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear

        webView.load(
            gif.data.data,
            mimeType: "image/gif",
            characterEncodingName: "UTF-8",
            baseURL: Bundle.main.bundleURL
        )

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.reload()
    }
}
