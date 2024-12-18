import SwiftUI

// MARK: - DynamicImageTextStackView

/// A dynamic stack view that lays out content vertically when in a regular vertical size class
/// and horizontally for the compact vertical size class.
/// In iOS 16+, this might be accomplishable with a ViewThatFits
struct DynamicImageTextStackView<I: View, T: View>: View {
    /// An environment variable for getting the vertical size class of the view.
    @Environment(\.verticalSizeClass) var verticalSizeClass

    // The minimum height to lay the contents out in.
    private let minHeight: CGFloat

    // The image content of the view; in a vertical size class this is above the text
    // and in a horizontal size class is on the leading side of the text.
    private let imageContent: I

    // The text content of the view; in a vertical size class this is below the image
    // and in a horizontal size class is on the trailing side of the image.
    private let textContent: T

    var body: some View {
        if verticalSizeClass == .regular {
            VStack(spacing: 24) {
                imageContent
                textContent
            }
            .padding(.top, 32)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, minHeight: minHeight)
        } else {
            HStack(alignment: .top, spacing: 40) {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    imageContent
                        .padding(.leading, 36)
                        .padding(.vertical, 16)
                    Spacer(minLength: 0)
                }
                .frame(minHeight: minHeight)

                textContent
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, minHeight: minHeight)
            }
        }
    }

    // MARK: Initialization

    /// Creates a new `DynamicImageTextStackView`. This view lays out content
    /// vertically when in a regular vertical size class
    /// and horizontally for the compact vertical size class.
    ///
    /// - Parameters:
    ///   - minHeight: The minimum height to lay the contents out in.
    ///   - imageContent: The image content of the view;
    ///     in a vertical size class this is above the text
    ///     and in a horizontal size class is on the leading side of the text.
    ///   - textContent: The text content of the view;
    ///     in a vertical size class this is below the image
    ///     and in a horizontal size class is on the trailing side of the image.
    ///
    init(
        minHeight: CGFloat,
        @ViewBuilder imageContent: @escaping () -> I,
        @ViewBuilder textContent: @escaping () -> T
    ) {
        self.minHeight = minHeight
        self.imageContent = imageContent()
        self.textContent = textContent()
    }

}
