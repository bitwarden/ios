import SwiftUI

/// A `ViewModifier` that causes a `View`'s `frame` to scale with dynamic font size.
///
struct ScaledFrame: ViewModifier {
    // MARK: Private Properties

    /// The current scale to use when calculating the actual frame size.
    ///
    /// This value is a `ScaledMetric`, which bases the scaling on the current DynamicType setting.
    @ScaledMetric private var scale = 1.0

    /// The scaled representation of ``height``.
    private var scaledHeight: CGFloat { height * scale }

    /// The scaled representation of ``width``.
    private var scaledWidth: CGFloat { width * scale }

    // MARK: Properties

    /// The height of the frame before scaling.
    let height: CGFloat

    /// The width of the frame before scaling.
    let width: CGFloat

    // MARK: Initialization

    /// Creates a new `ScaledFrame` modifier that sets the frame of the view to a scaled
    /// representation of the `height` and `width`, based on the user's current Dynamic
    /// Type setting.
    ///
    /// - Parameters:
    ///   - width: The width of the frame before scaling.
    ///   - height: The height of the frame before scaling.
    ///
    init(
        width: CGFloat,
        height: CGFloat
    ) {
        self.width = width
        self.height = height
    }

    // MARK: View

    func body(content: Content) -> some View {
        content
            .frame(width: scaledWidth, height: scaledHeight)
    }
}

// MARK: View

extension View {
    /// Sets the frame of a `View` to width/height values that can optionally be scaled with
    /// dynamic font size.
    ///
    /// - Parameters:
    ///   - width: The width of the view before scaling.
    ///   - height: The height of the view before scaling.
    ///   - scaleWithFont: Whether to scale the frame with dynamic font size.
    ///
    @ViewBuilder
    func frame(width: CGFloat, height: CGFloat, scaleWithFont: Bool) -> some View {
        if scaleWithFont {
            scaledFrame(width: width, height: height)
        } else {
            frame(width: width, height: height)
        }
    }

    /// Set the frame of a `View` to width/height values that will scale with dynamic font size.
    ///
    /// - Parameters:
    ///   - width: The width of the image before scaling
    ///   - height: The height of the image before scaling.
    ///
    func scaledFrame(width: CGFloat, height: CGFloat) -> some View {
        modifier(ScaledFrame(width: width, height: height))
    }
}

// MARK: Image + ScaledFrame

extension Image {
    /// Set the frame of an `Image` to width/height values that will scale with dynamic font size.
    ///
    /// - Parameters:
    ///   - width: The width of the image before scaling
    ///   - height: The height of the image before scaling.
    ///
    func scaledFrame(width: CGFloat, height: CGFloat) -> some View {
        resizable()
            .modifier(ScaledFrame(width: width, height: height))
    }
}

#if DEBUG
#Preview {
    VStack {
        Image(systemName: "ruler.fill")
            .aspectRatio(contentMode: .fit)
            .scaledFrame(width: 24, height: 24)
            .environment(\.sizeCategory, .extraSmall)

        Image(systemName: "ruler.fill")
            .aspectRatio(contentMode: .fit)
            .scaledFrame(width: 24, height: 24)
            .environment(\.sizeCategory, .extraExtraLarge)

        Image(systemName: "ruler.fill")
            .aspectRatio(contentMode: .fit)
            .scaledFrame(width: 24, height: 24)
            .environment(\.sizeCategory, .accessibilityMedium)

        Image(systemName: "ruler.fill")
            .aspectRatio(contentMode: .fit)
            .scaledFrame(width: 24, height: 24)
            .environment(\.sizeCategory, .accessibilityExtraLarge)
    }
    .previewLayout(.sizeThatFits)
}
#endif
