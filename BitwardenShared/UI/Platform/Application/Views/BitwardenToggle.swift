import SwiftUI

// MARK: - BitwardenToggle

/// A wrapper around a `Toggle` that is customized based on the Bitwarden design system.
///
struct BitwardenToggle<FooterContent: View>: View {
    // MARK: Properties

    /// The accessibility identifier for the toggle.
    let accessibilityIdentifier: String?

    /// The footer text displayed below the toggle.
    let footer: String?

    /// The footer content displayed below the toggle. This can be used for more customized content
    /// than just plain text. The `footer` string will take precedence over this if provided.
    let footerContent: FooterContent?

    /// A binding for whether the toggle is on.
    @Binding var isOn: Bool

    /// The title of the toggle.
    let title: String

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle(title, isOn: $isOn)
                .toggleStyle(.bitwarden)
                .padding(.vertical, 12)
                .accessibilityIdentifier(accessibilityIdentifier ?? "")
                .accessibilityLabel(title)

            if footer != nil || footerContent != nil {
                Divider()

                Group {
                    if let footer {
                        Text(footer)
                            .styleGuide(.subheadline)
                            .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                    } else if let footerContent {
                        footerContent
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: Initialization

    /// Initialize a `BitwardenToggle` with no footer.
    ///
    /// - Parameters:
    ///   - title: The title of the toggle.
    ///   - isOn: A binding for whether the toggle is on.
    ///   - accessibilityIdentifier: The accessibility identifier for the toggle.
    ///
    init(
        _ title: String,
        isOn: Binding<Bool>,
        accessibilityIdentifier: String? = nil
    ) where FooterContent == EmptyView {
        self.accessibilityIdentifier = accessibilityIdentifier
        _isOn = isOn
        footer = nil
        footerContent = nil
        self.title = title
    }

    /// Initialize a `BitwardenToggle` with footer text.
    ///
    /// - Parameters:
    ///   - title: The title of the toggle.
    ///   - footer: The footer text displayed below the toggle.
    ///   - isOn: A binding for whether the toggle is on.
    ///   - accessibilityIdentifier: The accessibility identifier for the toggle.
    ///
    init(
        _ title: String,
        footer: String,
        isOn: Binding<Bool>,
        accessibilityIdentifier: String? = nil
    ) where FooterContent == EmptyView {
        self.accessibilityIdentifier = accessibilityIdentifier
        _isOn = isOn
        self.footer = footer
        footerContent = nil
        self.title = title
    }

    /// Initialize a `BitwardenToggle` with footer content.
    ///
    /// - Parameters:
    ///   - title: The title of the toggle.
    ///   - isOn: A binding for whether the toggle is on.
    ///   - accessibilityIdentifier: The accessibility identifier for the toggle.
    ///   - footerContent: The footer content displayed below the toggle.
    ///
    init(
        _ title: String,
        isOn: Binding<Bool>,
        accessibilityIdentifier: String? = nil,
        @ViewBuilder footerContent: () -> FooterContent
    ) {
        self.accessibilityIdentifier = accessibilityIdentifier
        _isOn = isOn
        footer = nil
        self.footerContent = footerContent()
        self.title = title
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    VStack(spacing: 8) {
        BitwardenToggle("Toggle", isOn: .constant(false))
            .contentBlock()

        BitwardenToggle("Toggle", isOn: .constant(true))
            .contentBlock()

        BitwardenToggle("Toggle", footer: "Footer text", isOn: .constant(false))
            .contentBlock()

        BitwardenToggle("Toggle", isOn: .constant(false)) {
            Button("Custom footer content") {}
                .styleGuide(.body)
        }
        .contentBlock()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
#endif
