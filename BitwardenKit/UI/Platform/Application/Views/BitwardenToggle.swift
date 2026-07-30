import BitwardenResources
import SwiftUI

// MARK: - BitwardenToggle

/// A wrapper around a `Toggle` that is customized based on the Bitwarden design system.
///
public struct BitwardenToggle<TitleContent: View, FooterContent: View, AccessoryContent: View>: View {
    // MARK: Properties

    /// The accessibility identifier for the toggle.
    let accessibilityIdentifier: String?

    /// The accessibility label for the toggle.
    let accessibilityLabel: String?

    /// Additional content displayed adjacent to the title, outside of the toggle's own
    /// accessibility element so it remains independently reachable by VoiceOver (e.g. an
    /// info button that opens an external link).
    let accessoryContent: AccessoryContent?

    /// The footer text displayed below the toggle.
    let footer: String?

    /// The footer content displayed below the toggle. This can be used for more customized content
    /// than just plain text. The `footer` string will take precedence over this if provided.
    let footerContent: FooterContent?

    /// A value indicating whether the toggle is currently enabled or disabled.
    @Environment(\.isEnabled) private var isEnabled

    /// A binding for whether the toggle is on.
    @Binding var isOn: Bool

    /// The content containing the title of the toggle.
    let titleContent: TitleContent

    // MARK: View

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let accessoryContent {
                HStack(spacing: 8) {
                    titleContent
                        .bitwardenToggleLabelStyle(isEnabled: isEnabled)
                    accessoryContent
                    Spacer(minLength: 0)
                    Toggle(isOn: $isOn) { EmptyView() }
                        .labelsHidden()
                        .toggleStyle(.bitwarden)
                        .accessibilityIdentifier(accessibilityIdentifier ?? "")
                        .accessibilityLabel(accessibilityLabel ?? "")
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard isEnabled else { return }
                    isOn.toggle()
                }
            } else {
                Toggle(isOn: $isOn) {
                    titleContent
                }
                .toggleStyle(.bitwarden)
                .padding(.vertical, 12)
                .accessibilityIdentifier(accessibilityIdentifier ?? "")
                .accessibilityLabel(accessibilityLabel ?? "")
                .padding(.horizontal, 16)
            }

            if footer != nil || footerContent != nil {
                Divider()
                    .padding(.leading, 16)
                Group {
                    if let footer {
                        Text(footer)
                            .styleGuide(.subheadline)
                            .foregroundColor(Color(asset: SharedAsset.Colors.textSecondary))
                            .padding(.vertical, 12)
                    } else if let footerContent {
                        footerContent
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: Initialization

    /// Initialize a `BitwardenToggle` with no footer.
    ///
    /// - Parameters:
    ///   - title: The title of the toggle.
    ///   - isOn: A binding for whether the toggle is on.
    ///   - accessibilityIdentifier: The accessibility identifier for the toggle.
    ///
    public init(
        _ title: String,
        isOn: Binding<Bool>,
        accessibilityIdentifier: String? = nil,
    ) where TitleContent == Text, FooterContent == EmptyView, AccessoryContent == EmptyView {
        self.accessibilityIdentifier = accessibilityIdentifier
        accessibilityLabel = title
        _isOn = isOn
        accessoryContent = nil
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
    public init(
        _ title: String,
        footer: String,
        isOn: Binding<Bool>,
        accessibilityIdentifier: String? = nil,
    ) where TitleContent == Text, FooterContent == EmptyView, AccessoryContent == EmptyView {
        self.accessibilityIdentifier = accessibilityIdentifier
        accessibilityLabel = title
        _isOn = isOn
        accessoryContent = nil
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
    public init(
        _ title: String,
        isOn: Binding<Bool>,
        accessibilityIdentifier: String? = nil,
        @ViewBuilder footerContent: () -> FooterContent,
    ) where TitleContent == Text, AccessoryContent == EmptyView {
        self.accessibilityIdentifier = accessibilityIdentifier
        accessibilityLabel = title
        _isOn = isOn
        accessoryContent = nil
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
    public init(
        footer: String? = nil,
        isOn: Binding<Bool>,
        accessibilityIdentifier: String? = nil,
        accessibilityLabel: String? = nil,
        @ViewBuilder title titleContent: () -> TitleContent,
    ) where FooterContent == EmptyView, AccessoryContent == EmptyView {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.accessibilityLabel = accessibilityLabel
        self.titleContent = titleContent()
        _isOn = isOn
        accessoryContent = nil
        self.footer = footer
        footerContent = nil
    }

    /// Initialize a `BitwardenToggle` with accessory content displayed adjacent to the title,
    /// outside of the toggle's own accessibility element. This is useful for elements like an
    /// info button that need to remain independently reachable by VoiceOver.
    ///
    /// - Parameters:
    ///   - footer: The footer text displayed below the toggle.
    ///   - isOn: A binding for whether the toggle is on.
    ///   - accessibilityIdentifier: The accessibility identifier for the toggle.
    ///   - accessibilityLabel: The accessibility label for the toggle.
    ///   - title: The content to display in the title of the toggle.
    ///   - accessory: The accessory content displayed adjacent to the title.
    ///
    public init(
        footer: String? = nil,
        isOn: Binding<Bool>,
        accessibilityIdentifier: String? = nil,
        accessibilityLabel: String? = nil,
        @ViewBuilder title titleContent: () -> TitleContent,
        @ViewBuilder accessory accessoryContent: () -> AccessoryContent,
    ) where FooterContent == EmptyView {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.accessibilityLabel = accessibilityLabel
        self.titleContent = titleContent()
        _isOn = isOn
        self.accessoryContent = accessoryContent()
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

        BitwardenToggle(
            isOn: .constant(true),
            title: {
                Text("Toggle")
            },
            accessory: {
                Button {} label: {
                    SharedAsset.Icons.cog16.swiftUIImage
                }
                .buttonStyle(.fieldLabelIcon)
            },
        )
        .contentBlock()

        BitwardenToggle("Toggle", footer: "Footer text", isOn: .constant(false))
            .contentBlock()

        BitwardenToggle(
            "Toggle",
            footer: "Footer text that's too long on purpose so truncation is triggered.",
            isOn: .constant(true),
        )
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
