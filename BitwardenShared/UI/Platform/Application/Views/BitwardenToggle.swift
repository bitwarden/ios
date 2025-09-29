import BitwardenResources
import SwiftUI

// MARK: - BitwardenToggle

/// A wrapper around a `Toggle` that is customized based on the Bitwarden design system.
///
struct BitwardenToggle<TitleContent: View, FooterContent: View>: View {
    // MARK: Properties

    /// The accessibility identifier for the toggle.
    let accessibilityIdentifier: String?

    /// The accessibility label for the toggle.
    let accessibilityLabel: String?

    /// The footer text displayed below the toggle.
    let footer: String?

    /// The footer content displayed below the toggle. This can be used for more customized content
    /// than just plain text. The `footer` string will take precedence over this if provided.
    let footerContent: FooterContent?

    /// A binding for whether the toggle is on.
    @Binding var isOn: Bool

    /// The content containing the title of the toggle.
    let titleContent: TitleContent

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle(isOn: $isOn) {
                titleContent
            }
            .toggleStyle(.bitwarden)
            .padding(.vertical, 12)
            .accessibilityIdentifier(accessibilityIdentifier ?? "")
            .accessibilityLabel(accessibilityLabel ?? "")

            if footer != nil || footerContent != nil {
                Divider()

                Group {
                    if let footer {
                        Text(footer)
                            .styleGuide(.subheadline)
                            .foregroundColor(Color(asset: SharedAsset.Colors.textSecondary))
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
    ) where TitleContent == Text, FooterContent == EmptyView {
        self.accessibilityIdentifier = accessibilityIdentifier
        accessibilityLabel = title
        _isOn = isOn
        footer = nil
        footerContent = nil
        titleContent = Text(title)
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
    ) where TitleContent == Text, FooterContent == EmptyView {
        self.accessibilityIdentifier = accessibilityIdentifier
        accessibilityLabel = title
        _isOn = isOn
        self.footer = footer
        footerContent = nil
        titleContent = Text(title)
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
    ) where TitleContent == Text {
        self.accessibilityIdentifier = accessibilityIdentifier
        accessibilityLabel = title
        _isOn = isOn
        footer = nil
        self.footerContent = footerContent()
        titleContent = Text(title)
    }

    /// Initialize a `BitwardenToggle` with no footer.
    ///
    /// - Parameters:
    ///   - footer: The footer text displayed below the toggle.
    ///   - isOn: A binding for whether the toggle is on.
    ///   - accessibilityIdentifier: The accessibility identifier for the toggle.
    ///   - accessibilityLabel: The accessibility label for the toggle.
    ///   - title: The content to display in the title of the toggle.
    ///
    init(
        footer: String? = nil,
        isOn: Binding<Bool>,
        accessibilityIdentifier: String? = nil,
        accessibilityLabel: String? = nil,
        @ViewBuilder title titleContent: () -> TitleContent
    ) where FooterContent == EmptyView {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.accessibilityLabel = accessibilityLabel
        self.titleContent = titleContent()
        _isOn = isOn
        self.footer = footer
        footerContent = nil
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

        BitwardenToggle(isOn: .constant(true)) {
            HStack(spacing: 8) {
                Text("Toggle")

                Button {} label: {
                    Asset.Images.cog16.swiftUIImage
                }
                .buttonStyle(.fieldLabelIcon)
            }
        }
        .contentBlock()

        BitwardenToggle("Toggle", footer: "Footer text", isOn: .constant(false))
            .contentBlock()

        BitwardenToggle("Toggle", isOn: .constant(false)) {
            Button("Custom footer content") {}
                .buttonStyle(.bitwardenBorderless)
                .padding(.vertical, 14)
        }
        .contentBlock()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
#endif
