import BitwardenResources
import SwiftUI

// MARK: - ActionCard

/// A view that displays a card representing an action that the user needs to take.
///
struct ActionCard<LeadingContent: View>: View {
    // MARK: Types

    /// A data model containing the properties for a button within an action card.
    ///
    struct ButtonState {
        // MARK: Properties

        /// An action to perform when the button is tapped.
        let action: () async -> Void

        /// The title of the button.
        let title: String

        // MARK: Initialization

        /// Initialize a `ButtonState`.
        ///
        /// - Parameters:
        ///   - title: The title of the button.
        ///   - action: An action to perform when the button is tapped.
        ///
        init(title: String, action: @escaping () async -> Void) {
            self.action = action
            self.title = title
        }
    }

    // MARK: Properties

    /// State that describes the action button.
    let actionButtonState: ButtonState?

    /// State that describes the dismiss button.
    let dismissButtonState: ButtonState?

    /// Optional content that is displayed at the leading edge of the title and message.
    let leadingContent: LeadingContent?

    /// The message to display in the card, below the title.
    let message: String?

    /// The title of the card.
    let title: String

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 8) {
                if let leadingContent {
                    leadingContent
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .styleGuide(.title2, weight: .semibold, includeLinePadding: false, includeLineSpacing: false)

                    if let message {
                        Text(message)
                            .styleGuide(.callout)
                    }
                }

                Spacer(minLength: 0)

                if let dismissButtonState {
                    AsyncButton(action: dismissButtonState.action) {
                        Image(asset: Asset.Images.close16, label: Text(dismissButtonState.title))
                            .imageStyle(.accessoryIcon16(color: SharedAsset.Colors.iconPrimary.swiftUIColor))
                            .padding(16) // Add padding to increase tappable area...
                    }
                    .padding(-16) // ...but remove it to not affect layout.
                }
            }

            if let actionButtonState {
                AsyncButton(actionButtonState.title, action: actionButtonState.action)
                    .buttonStyle(.primary(size: .medium))
            }
        }
        .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(SharedAsset.Colors.strokeBorder.swiftUIColor)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(SharedAsset.Colors.backgroundTertiary.swiftUIColor)
                )
        )
    }

    // MARK: Initialization

    /// Initialize an `ActionCard` with leading content.
    ///
    /// - Parameters:
    ///   - title: The title of the card.
    ///   - message: The message to display in the card.
    ///   - actionButtonState: State that describes the action button.
    ///   - dismissButtonState: State that describes the dismiss button.
    ///   - leadingContent: Content that is displayed at the leading edge of the title and message.
    ///
    init(
        title: String,
        message: String? = nil,
        actionButtonState: ButtonState? = nil,
        dismissButtonState: ButtonState? = nil,
        @ViewBuilder leadingContent: () -> LeadingContent
    ) {
        self.actionButtonState = actionButtonState
        self.dismissButtonState = dismissButtonState
        self.leadingContent = leadingContent()
        self.message = message
        self.title = title
    }

    /// Initialize an `ActionCard` with no leading content.
    ///
    /// - Parameters:
    ///   - title: The title of the card.
    ///   - message: The message to display in the card.
    ///   - actionButtonState: State that describes the action button.
    ///   - dismissButtonState: State that describes the dismiss button.
    ///
    init(
        title: String,
        message: String? = nil,
        actionButtonState: ButtonState? = nil,
        dismissButtonState: ButtonState? = nil
    ) where LeadingContent == EmptyView {
        self.actionButtonState = actionButtonState
        self.dismissButtonState = dismissButtonState
        leadingContent = nil
        self.message = message
        self.title = title
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    VStack {
        ActionCard(
            title: "Title",
            message: "Message"
        )

        ActionCard(
            title: "Title",
            message: "Message",
            actionButtonState: ActionCard.ButtonState(title: "Tap me!") {},
            dismissButtonState: ActionCard.ButtonState(title: "Dismiss") {}
        )

        ActionCard(
            title: "Title",
            message: "Message"
        ) {
            Asset.Images.warning24.swiftUIImage
        }

        ActionCard(
            title: "Title",
            message: "Message"
        ) {
            BitwardenBadge(badgeValue: "1")
        }
    }
    .scrollView()
}
#endif
