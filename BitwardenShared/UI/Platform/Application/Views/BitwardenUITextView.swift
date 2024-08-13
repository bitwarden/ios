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
        ///
        var parent: BitwardenUITextView

        ///
        var calculatedHeight: Binding<CGFloat>

        /// Initializes a new `Coordinator` for the `BitwardenUITextView`.
        ///
        /// - Parameter parent: The parent view that owns this coordinator.
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

    ///
    @Binding var calculatedHeight: CGFloat

    /// Creates and returns the coordinator for the `UITextView`.
    ///
    /// - Returns: A `Coordinator` instance to manage the `UITextView`'s events.
    ///
    func makeCoordinator() -> Coordinator {
        Coordinator(
            self,
            calculatedHeight: $calculatedHeight
        )
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
        textView.isUserInteractionEnabled = true
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.tintColor = Asset.Colors.primaryBitwarden.color
        let font = UIFont.preferredFont(forTextStyle: .body)
        textView.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
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
