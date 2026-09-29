import Foundation
import SwiftUI
import UIKit

// MARK: - ZoomableImageView

/// A view that displays image data with pinch-to-zoom and, once zoomed in, drag-to-pan gestures.
///
struct ZoomableImageView: View {
    // MARK: Properties

    /// The image data to display.
    let data: Data

    // MARK: View

    var body: some View {
        if let image = UIImage(data: data) {
            ZoomableView {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
            .accessibilityIdentifier("AttachmentPreviewImage")
        }
    }

    // MARK: Initialization

    /// Creates a new `ZoomableImageView`.
    ///
    /// - Parameter data: The image data to display.
    ///
    init(data: Data) {
        self.data = data
    }
}

// MARK: - ZoomableView

/// A container view that applies pinch-to-zoom and, once zoomed in, drag-to-pan gestures to its
/// content.
///
struct ZoomableView<Content: View>: View {
    // MARK: Properties

    /// The content to zoom and pan.
    let content: Content

    // MARK: Private Properties

    /// The offset committed at the end of the last drag gesture.
    @SwiftUI.State private var committedOffset: CGSize = .zero

    /// The scale committed at the end of the last magnification gesture.
    @SwiftUI.State private var committedScale: CGFloat = Self.minScale

    /// The current pan offset, combining the committed offset and any in-progress drag gesture.
    @SwiftUI.State private var offset: CGSize = .zero

    /// The current zoom scale, combining the committed scale and any in-progress magnification gesture.
    @SwiftUI.State private var scale: CGFloat = Self.minScale

    // MARK: View

    var body: some View {
        content
            .scaleEffect(scale)
            .offset(offset)
            .simultaneousGesture(magnificationGesture)
            .simultaneousGesture(dragGesture)
    }

    /// A gesture that pans the content once it's zoomed in.
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard committedScale > Self.minScale else { return }
                offset = CGSize(
                    width: committedOffset.width + value.translation.width,
                    height: committedOffset.height + value.translation.height,
                )
            }
            .onEnded { _ in
                committedOffset = offset
            }
    }

    /// A gesture that zooms the content between `minScale` and `maxScale`.
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(committedScale * value, Self.minScale), Self.maxScale)
            }
            .onEnded { _ in
                committedScale = scale
                guard committedScale == Self.minScale else { return }
                withAnimation {
                    offset = .zero
                    committedOffset = .zero
                }
            }
    }

    // MARK: Initialization

    /// Creates a new `ZoomableView`.
    ///
    /// - Parameter content: The content to zoom and pan.
    ///
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
}

// MARK: - Constants

private extension ZoomableView {
    /// The maximum allowed zoom scale.
    static var maxScale: CGFloat { 5 }

    /// The minimum allowed zoom scale.
    static var minScale: CGFloat { 1 }
}

// MARK: - Previews

#if DEBUG
#Preview {
    ZoomableImageView(data: UIImage(systemName: "photo")?.pngData() ?? Data())
}
#endif
