import BitwardenResources
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

        /// A binding for whether the text view has focus.
        @Binding var isFocused: Bool

        /// Initializes a new `Coordinator` for the `BitwardenUITextView`.
        ///
        /// - Parameters:
        ///    - parent: The parent view that owns this coordinator.
        ///    - calculatedHeight: The height of the text view.
        ///    - isFocused: A binding for whether the text view has focus.
        ///
        init(
            _ parent: BitwardenUITextView,
            calculatedHeight: Binding<CGFloat>,
            isFocused: Binding<Bool>
        ) {
            self.parent = parent
            self.calculatedHeight = calculatedHeight
            _isFocused = isFocused
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            isFocused = true
        }

        func textViewDidChange(_ uiView: UITextView) {
            parent.text = uiView.text
            parent.recalculateHeight(
                view: uiView,
                result: calculatedHeight
            )
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            isFocused = false
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

    /// Whether the view allows user interaction.
    @Environment(\.isEnabled) var isEnabled: Bool

    /// A binding for whether the text view has focus.
    @Binding var isFocused: Bool

    /// Creates and returns the coordinator for the `UITextView`.
    ///
    /// - Returns: A `Coordinator` instance to manage the `UITextView`'s events.
    ///
    func makeCoordinator() -> Coordinator {
        Coordinator(self, calculatedHeight: $calculatedHeight, isFocused: $isFocused)
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
        textView.textColor = isEnabled
            ? SharedAsset.Colors.textPrimary.color
            : SharedAsset.Colors.textDisabled.color
        textView.isScrollEnabled = false
        textView.isEditable = isEditable
        textView.isUserInteractionEnabled = true
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.tintColor = SharedAsset.Colors.tintPrimary.color
        textView.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let customFont = FontFamily.DMSans.regular.font(size: 15)
        textView.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: customFont)
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

        if isFocused, !uiView.isFirstResponder {
            // Dispatch here to prevent modifying state during a view update.
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        } else if !isFocused, uiView.isFirstResponder {
            // Dispatch here to prevent modifying state during a view update.
            DispatchQueue.main.async {
                uiView.endEditing(true)
            }
        }

        // Dispatch here to ensure UITextView has a valid width.
        DispatchQueue.main.asyncAfter(deadline: UI.after(0.15)) {
            recalculateHeight(
                view: uiView,
                result: $calculatedHeight
            )
        }
    }

    /// Recalculates the height of the UIView based on its content size and updates the binding if the height changes.
    ///
    /// - Parameters:
    ///   - view: The UIView whose height is to be recalculated.
    ///   - result: A binding to a CGFloat that stores the height value.
    ///
    private func recalculateHeight(
        view: UIView,
        result: Binding<CGFloat>
    ) {
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

    @available(iOS 16, *)
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width else { return nil }
        let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: size.height)
    }
}
