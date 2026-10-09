import Foundation
import SwiftUI
import UIKit

// MARK: - ZoomableImageView

/// A view that displays image data with pinch-to-zoom and, once zoomed in, drag-to-pan gestures.
///
struct ZoomableImageView: View {
    // MARK: Private Properties

    /// The decoded image, created once so the image data isn't decoded again whenever the view
    /// is re-rendered.
    @StateObject private var imageBox: DecodedImageBox

    /// Whether the image is currently zoomed in.
    @Binding private var isZoomed: Bool

    // MARK: View

    var body: some View {
        if let image = imageBox.image {
            ZoomableView(isZoomed: $isZoomed) {
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
    /// - Parameters:
    ///   - data: The image data to display.
    ///   - isZoomed: A binding that is updated with whether the image is currently zoomed in.
    ///
    init(data: Data, isZoomed: Binding<Bool> = .constant(false)) {
        _imageBox = StateObject(wrappedValue: DecodedImageBox(data: data))
        _isZoomed = isZoomed
    }
}

// MARK: - DecodedImageBox

/// An object that decodes image data once and holds on to the resulting image.
///
private final class DecodedImageBox: ObservableObject {
    /// The decoded image, or `nil` if the data couldn't be decoded.
    let image: UIImage?

    /// Creates a new `DecodedImageBox`.
    ///
    /// - Parameter data: The image data to decode.
    ///
    init(data: Data) {
        image = UIImage(data: data)
    }
}

// MARK: - ZoomableView

/// A container view that applies pinch-to-zoom and, once zoomed in, drag-to-pan gestures to its
/// content. The content can't be panned past the point where its edges meet the container's.
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

    /// The size of the available space the content is displayed in.
    @SwiftUI.State private var containerSize: CGSize = .zero

    /// The size of the content before it's scaled.
    @SwiftUI.State private var contentSize: CGSize = .zero

    /// Whether the content is currently zoomed in.
    @Binding private var isZoomed: Bool

    /// The current pan offset, combining the committed offset and any in-progress drag gesture.
    @SwiftUI.State private var offset: CGSize = .zero

    /// The current zoom scale, combining the committed scale and any in-progress magnification gesture.
    @SwiftUI.State private var scale: CGFloat = Self.minScale

    // MARK: View

    var body: some View {
        content
            .background(sizeReader(ContentSizeKey.self))
            .onPreferenceChange(ContentSizeKey.self) { contentSize = $0 }
            .scaleEffect(scale)
            .offset(offset)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(sizeReader(ContainerSizeKey.self))
            .onPreferenceChange(ContainerSizeKey.self) { containerSize = $0 }
            .contentShape(Rectangle())
            .simultaneousGesture(magnificationGesture)
            // Panning is only enabled while zoomed in, so that an unzoomed drag isn't consumed
            // here and can instead dismiss the sheet the content is presented in.
            .simultaneousGesture(dragGesture, including: committedScale > Self.minScale ? .all : .none)
            .onChange(of: scale > Self.minScale) { isZoomed = $0 }
    }

    /// A gesture that pans the content once it's zoomed in.
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard committedScale > Self.minScale else { return }
                offset = clamped(
                    CGSize(
                        width: committedOffset.width + value.translation.width,
                        height: committedOffset.height + value.translation.height,
                    ),
                    scale: scale,
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
                offset = clamped(committedOffset, scale: scale)
            }
            .onEnded { _ in
                committedScale = scale
                guard committedScale > Self.minScale else {
                    withAnimation {
                        offset = .zero
                        committedOffset = .zero
                    }
                    return
                }
                committedOffset = offset
            }
    }

    // MARK: Initialization

    /// Creates a new `ZoomableView`.
    ///
    /// - Parameters:
    ///   - isZoomed: A binding that is updated with whether the content is currently zoomed in.
    ///   - content: The content to zoom and pan.
    ///
    init(isZoomed: Binding<Bool> = .constant(false), @ViewBuilder content: () -> Content) {
        self.content = content()
        _isZoomed = isZoomed
    }

    // MARK: Private Methods

    /// Limits an offset so the scaled content can't be panned past the edges of the container.
    ///
    /// - Parameters:
    ///   - offset: The offset to limit.
    ///   - scale: The scale the content is being displayed at.
    /// - Returns: The offset, limited to the range the content can be panned within.
    ///
    private func clamped(_ offset: CGSize, scale: CGFloat) -> CGSize {
        let maxX = max(0, (contentSize.width * scale - containerSize.width) / 2)
        let maxY = max(0, (contentSize.height * scale - containerSize.height) / 2)
        return CGSize(
            width: min(max(offset.width, -maxX), maxX),
            height: min(max(offset.height, -maxY), maxY),
        )
    }

    /// A transparent view that reports the size of the view it's applied to as a background.
    ///
    /// - Parameter key: The preference key to report the size with.
    /// - Returns: A view that reports the size it's given.
    ///
    private func sizeReader<Key: PreferenceKey>(_ key: Key.Type) -> some View where Key.Value == CGSize {
        GeometryReader { proxy in
            Color.clear.preference(key: key, value: proxy.size)
        }
    }
}

// MARK: - Constants

private extension ZoomableView {
    /// The maximum allowed zoom scale.
    static var maxScale: CGFloat { 5 }

    /// The minimum allowed zoom scale.
    static var minScale: CGFloat { 1 }
}

// MARK: - Preference Keys

/// A preference key that reports the size of the container a `ZoomableView` is displayed in.
private struct ContainerSizeKey: PreferenceKey {
    static let defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

/// A preference key that reports the unscaled size of a `ZoomableView`'s content.
private struct ContentSizeKey: PreferenceKey {
    static let defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    ZoomableImageView(data: UIImage(systemName: "photo")?.pngData() ?? Data())
}
#endif
