import BitwardenResources
import SwiftUI

// MARK: - Toast

/// A data model for a toast.
///
struct Toast: Equatable, Identifiable {
    // MARK: Types

    /// A mode that captures what sort of toast this is.
    enum ToastMode {
        /// The toast should dismiss itself after a few seconds.
        case automaticDismiss

        /// The toast should not automatically dismiss itself, and something else should do the dismissal.
        case manualDismiss
    }

    // MARK: Properties

    /// A unique identifier of the toast.
    let id = UUID()

    /// The mode of the toast.
    let mode: ToastMode

    /// The title text displayed in the toast.
    let title: String

    /// The subtitle text displayed in the toast.
    let subtitle: String?

    // MARK: Initialization

    /// Initialize a `Toast`.
    ///
    /// - Parameters:
    ///   - title: The title text displayed in the toast.
    ///   - subtitle: The subtitle text displayed in the toast.
    ///   - mode: The mode for the toast
    ///
    init(title: String, subtitle: String? = nil, mode: ToastMode = .automaticDismiss) {
        self.title = title
        self.subtitle = subtitle
        self.mode = mode
    }

    static func == (lhs: Toast, rhs: Toast) -> Bool {
        // Exclude `id` from `Equatable`, it's only used by the view to handle animations between toasts.
        lhs.title == rhs.title
            && lhs.subtitle == rhs.subtitle
    }
}

// MARK: - ToastView

/// A view that displays a toast message which is shown when the binding has a value and is hidden
/// after a delay.
///
struct ToastView: View {
    // MARK: Properties

    /// A binding to the toast to show.
    @Binding var toast: Toast?

    var body: some View {
        if let toast {
            VStack(alignment: .leading, spacing: 4) {
                Text(toast.title)
                    .styleGuide(
                        .headline,
                        weight: .bold,
                        includeLinePadding: false,
                        includeLineSpacing: false
                    )

                if let subtitle = toast.subtitle {
                    Text(subtitle)
                        .styleGuide(.callout)
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .id(toast.id)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .foregroundColor(SharedAsset.Colors.textReversed.swiftUIColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SharedAsset.Colors.backgroundAlert.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 4)
            .accessibilityIdentifier("ToastElement")
            .accessibilityElement(children: .combine)
            .padding(.horizontal, 12)
            .task(id: toast.id) {
                guard self.toast?.mode == .automaticDismiss else { return }
                do {
                    try await Task.sleep(nanoseconds: 3 * NSEC_PER_SEC)
                    withAnimation {
                        self.toast = nil
                    }
                } catch {
                    // No-op: Skip the animation if the task/sleep is cancelled.
                }
            }
            .onDisappear {
                self.toast = nil
            }
        }
    }
}

// MARK: - View

extension View {
    /// Adds a toast view in an overlay at the bottom of the view.
    ///
    /// - Parameters:
    ///     - toast: A binding to the toast to show.
    ///     - additionalBottomPadding: Additional bottom padding to apply to the toast.
    /// - Returns: A view that displays a toast.
    ///
    func toast(_ toast: Binding<Toast?>, additionalBottomPadding: CGFloat = 0) -> some View {
        overlay(alignment: .bottom) {
            ToastView(toast: toast)
                .padding(.bottom, 12 + additionalBottomPadding)
                .animation(.easeInOut, value: toast.wrappedValue)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    VStack {
        ToastView(toast: .constant(Toast(title: "Toast!")))

        ToastView(toast: .constant(Toast(title: "Toast!", subtitle: "Lorem ipsum dolor sit amet.")))
    }
    .padding()
}

#Preview("Toast Overlay") {
    NavigationView {
        SharedAsset.Colors.backgroundSecondary.swiftUIColor
            .toast(.constant(Toast(title: "Taos, NM!")))
    }
}
#endif
