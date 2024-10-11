import SwiftUI

// MARK: - Toast

/// A data model for a toast.
///
struct Toast: Equatable, Identifiable {
    // MARK: Properties

    /// A unique identifier of the toast.
    let id = UUID()

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
    ///
    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
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
            .padding(.vertical, 14)
            .foregroundColor(Asset.Colors.textReversed.swiftUIColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Asset.Colors.backgroundAlert.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 4)
            .accessibilityElement(children: .combine)
            .padding(.horizontal, 16)
            .task(id: toast.id) {
                do {
                    try await Task.sleep(nanoseconds: 3 * NSEC_PER_SEC)
                    withAnimation {
                        self.toast = nil
                    }
                } catch {
                    // No-op: Skip the animation if the task/sleep is cancelled.
                }
            }
        }
    }
}

// MARK: - View

extension View {
    /// Adds a toast view in an overlay at the bottom of the view.
    ///
    /// - Parameter toast: A binding to the toast to show.
    /// - Returns: A view that displays a toast.
    ///
    func toast(_ toast: Binding<Toast?>) -> some View {
        overlay(alignment: .bottom) {
            ToastView(toast: toast)
                .padding(.bottom, 28)
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
        Asset.Colors.backgroundSecondary.swiftUIColor
            .toast(.constant(Toast(title: "Taos, NM!")))
    }
}
#endif
