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

    // MARK: Private Properties

    /// The current pan offset, combining the committed offset and any in-progress drag gesture.
    @SwiftUI.State private var offset: CGSize = .zero

    /// The offset committed at the end of the last drag gesture.
    @SwiftUI.State private var committedOffset: CGSize = .zero

    /// The current zoom scale, combining the committed scale and any in-progress magnification gesture.
    @SwiftUI.State private var scale: CGFloat = Self.minScale

    /// The scale committed at the end of the last magnification gesture.
    @SwiftUI.State private var committedScale: CGFloat = Self.minScale

    // MARK: View

    var body: some View {
        if let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .simultaneousGesture(magnificationGesture)
                .simultaneousGesture(dragGesture)
                .accessibilityIdentifier("AttachmentPreviewImage")
        }
    }

    /// A gesture that pans the image once it's zoomed in.
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

    /// A gesture that zooms the image between `minScale` and `maxScale`.
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

    /// Creates a new `ZoomableImageView`.
    ///
    /// - Parameter data: The image data to display.
    ///
    init(data: Data) {
        self.data = data
    }
}

// MARK: - Constants

private extension ZoomableImageView {
    /// The maximum allowed zoom scale.
    static let maxScale: CGFloat = 5

    /// The minimum allowed zoom scale.
    static let minScale: CGFloat = 1
}

// MARK: - Previews

#if DEBUG
#Preview {
    ZoomableImageView(data: UIImage(systemName: "photo")?.pngData() ?? Data())
}
#endif
