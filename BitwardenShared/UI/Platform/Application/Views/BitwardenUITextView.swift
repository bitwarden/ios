import SwiftUI
import UIKit

// MARK: - BitwardenUITextView

/// A custom `UITextView` wrapped in a `UIViewRepresentable` for use in SwiftUI.
///
struct BitwardenUITextView: UIViewRepresentable {
    // MARK: - Coordinator

    /// A coordinator to act as the delegate for `UITextView`, handling text changes and other events.
    ///
    class Coordinator: NSObject, UITextViewDelegate {
        /// The parent view.
        var parent: BitwardenUITextView

        /// The calculated height of the text view.
        var calculatedHeight: Binding<CGFloat>

        /// Initializes a new `Coordinator` for the `BitwardenUITextView`.
        ///
        /// - Parameters:
        ///    -  parent: The parent view that owns this coordinator.
        ///    - calculatedHeight: The height of the text view.
        ///
        init(
            _ parent: BitwardenUITextView,
            calculatedHeight: Binding<CGFloat>
        ) {
            self.parent = parent
            self.calculatedHeight = calculatedHeight
        }

        func textViewDidChange(_ uiView: UITextView) {
            parent.text = uiView.text
            parent.recalculateHeight(
                view: uiView,
                result: calculatedHeight
            )
        }
    }

    // MARK: Properties

    /// The text entered into the text field.
    @Binding var text: String

    /// The calculated height of the `UITextView`. This value is dynamically updated based on the
    /// content size, and it helps to adjust the height of the view in SwiftUI.
    @Binding var calculatedHeight: CGFloat

    /// Indicates whether the `UITextView` is editable. When set to `true`, the user can edit the
    /// text. If `false`, the text view is read-only.
    var isEditable: Bool = true

    /// Creates and returns the coordinator for the `UITextView`.
    ///
    /// - Returns: A `Coordinator` instance to manage the `UITextView`'s events.
    ///
    func makeCoordinator() -> Coordinator {
        Coordinator(self, calculatedHeight: $calculatedHeight)
    }

    // MARK: - UIViewRepresentable Methods

    /// Creates and configures the `UITextView` for this view.
    ///
    /// - Parameter context: The context containing the coordinator for this view.
    /// - Returns: A configured `UITextView` instance.
    ///
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.adjustsFontForContentSizeCategory = true
        textView.autocapitalizationType = .sentences
        textView.delegate = context.coordinator
        textView.textColor = Asset.Colors.textPrimary.color
        textView.isScrollEnabled = false
        textView.isEditable = isEditable
        textView.isUserInteractionEnabled = true
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.tintColor = Asset.Colors.tintPrimary.color
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let backupFont = UIFont.preferredFont(forTextStyle: .body)
        let customFont = UIFont(name: FontFamily.DMSans.regular.name, size: 15)
        textView.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: customFont ?? backupFont)
        return textView
    }

    /// Updates the `UITextView` with the latest text when the SwiftUI state changes.
    ///
    /// - Parameters:
    ///   - uiView: The `UITextView` instance being updated.
    ///   - context: The context containing the coordinator for this view.
    ///
    func updateUIView(
        _ uiView: UITextView,
        context: Context
    ) {
        if uiView.text != text {
            uiView.text = text
        }

        recalculateHeight(
            view: uiView,
            result: $calculatedHeight
        )
    }

    private func recalculateHeight(view: UIView, result: Binding<CGFloat>) {
        let newSize = view.sizeThatFits(
            CGSize(
                width: view.frame.size.width,
                height: CGFloat.greatestFiniteMagnitude
            )
        )

        if result.wrappedValue != newSize.height {
            DispatchQueue.main.async {
                result.wrappedValue = newSize.height
            }
        }
    }
}
