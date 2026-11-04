import BitwardenResources
import SwiftUI

// MARK: - BitwardenToggle

/// A wrapper around a `Toggle` that is customized based on the Bitwarden design system.
///
public struct BitwardenToggle<TitleContent: View, FooterContent: View>: View {
    // MARK: Types

    /// A help button displayed adjacent to the toggle's title that opens an external link.
    ///
    struct HelpButton {
        /// The accessibility label for the help button. This is also used as the name of the
        /// custom accessibility action added to the toggle.
        let accessibilityLabel: String

        /// The URL to open when the help button is tapped.
        let url: URL
    }

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

    /// A help button displayed adjacent to the title, which opens an external link.
    let helpButton: HelpButton?

    /// An object used to open urls from this view.
    @Environment(\.openURL) private var openURL

    /// A binding for whether the toggle is on.
    @Binding var isOn: Bool

    /// The content containing the title of the toggle.
    let titleContent: TitleContent

    // MARK: View

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle(isOn: $isOn) {
                HStack(spacing: 8) {
                    titleContent

                    if let helpButton {
                        // SwiftUI merges a button within a toggle's label into the toggle's
                        // accessibility element and exposes it as a custom action, which is reachable
                        // from Full Keyboard Access (Tab+Z) and the VoiceOver actions rotor. The
                        // action's name comes from the button's label content, so the accessibility
                        // label must be applied to the image rather than the button.
                        Button {
                            openURL(helpButton.url)
                        } label: {
                            SharedAsset.Icons.questionCircle16.swiftUIImage
                                .scaledFrame(width: 16, height: 16)
                                .accessibilityLabel(helpButton.accessibilityLabel)
                        }
                        .buttonStyle(.fieldLabelIcon)
                    }
                }
            }
            .toggleStyle(.bitwarden)
            .padding(.vertical, 12)
            .accessibilityIdentifier(accessibilityIdentifier ?? "")
            .accessibilityLabel(accessibilityLabel ?? "")
            .padding(.horizontal, 16)

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
    ) where TitleContent == Text, FooterContent == EmptyView {
        self.accessibilityIdentifier = accessibilityIdentifier
        accessibilityLabel = title
        _isOn = isOn
        helpButton = nil
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
    ) where TitleContent == Text, FooterContent == EmptyView {
        self.accessibilityIdentifier = accessibilityIdentifier
        accessibilityLabel = title
        _isOn = isOn
        helpButton = nil
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
    ) where TitleContent == Text {
        self.accessibilityIdentifier = accessibilityIdentifier
        accessibilityLabel = title
        _isOn = isOn
        helpButton = nil
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
    ) where FooterContent == EmptyView {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.accessibilityLabel = accessibilityLabel
        self.titleContent = titleContent()
        _isOn = isOn
        helpButton = nil
        self.footer = footer
        footerContent = nil
    }

    /// Initialize a `BitwardenToggle` with a help button displayed adjacent to the title, which
    /// opens an external link. For accessibility, the help button is exposed as a custom action on
    /// the toggle, which is reachable from Full Keyboard Access (Tab+Z) and the VoiceOver actions rotor.
    ///
    /// - Parameters:
    ///   - footer: The footer text displayed below the toggle.
    ///   - isOn: A binding for whether the toggle is on.
    ///   - accessibilityIdentifier: The accessibility identifier for the toggle.
    ///   - accessibilityLabel: The accessibility label for the toggle.
    ///   - helpURL: The URL to open when the help button is tapped.
    ///   - helpAccessibilityLabel: The accessibility label for the help button.
    ///   - title: The content to display in the title of the toggle.
    ///
    public init(
        footer: String? = nil,
        isOn: Binding<Bool>,
        accessibilityIdentifier: String? = nil,
        accessibilityLabel: String? = nil,
        helpURL: URL,
        helpAccessibilityLabel: String = Localizations.learnMore,
        @ViewBuilder title titleContent: () -> TitleContent,
    ) where FooterContent == EmptyView {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.accessibilityLabel = accessibilityLabel
        self.titleContent = titleContent()
        _isOn = isOn
        helpButton = HelpButton(accessibilityLabel: helpAccessibilityLabel, url: helpURL)
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
            helpURL: URL(string: "https://bitwarden.com")!,
            title: {
                Text("Toggle")
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
