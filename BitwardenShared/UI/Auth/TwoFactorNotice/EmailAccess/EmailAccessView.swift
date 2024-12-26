import SwiftUI
import SwiftUIIntrospect

// MARK: - EmailAccessView

/// A view that alerts the user to the new policy of sending emails to confirm new devices.
///
struct EmailAccessView: View {
    // MARK: Properties

    /// An environment variable for getting the vertical size class of the view.
    @Environment(\.verticalSizeClass) var verticalSizeClass

    /// The `Store` for this view.
    @ObservedObject public var store: Store<EmailAccessState, EmailAccessAction, EmailAccessEffect>

    var body: some View {
        VStack(spacing: 12) {
            PageHeaderView(
                image: Asset.Images.Illustrations.businessWarning.swiftUIImage,
                title: Localizations.importantNotice,
                message: Localizations.bitwardenWillSendACodeToYourAccountEmailDescriptionLong
            )

            toggleCard

            VStack(spacing: 12) {
                AsyncButton(Localizations.continue) {
                    await store.perform(.continueTapped)
                }
                .buttonStyle(.primary())
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
        .multilineTextAlignment(.center)
        .scrollView()
    }

    private var toggleCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(Localizations.doYouHaveReliableAccessToYourEmail(
                // Adding the Word Joiner character (U+2060) in the middle of the email address
                // keeps the markdown rendering from making the email address a tappable link.
                store.state.emailAddress.replacingOccurrences(of: "@", with: "\u{2060}@")
            )))
            .styleGuide(.body)
            .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)

            Divider()

            Toggle(Localizations.yesICanReliablyAccessMyEmail, isOn: store.binding(
                get: \.canAccessEmail,
                send: EmailAccessAction.canAccessEmailChanged
            ))
            .toggleStyle(.bitwarden)
            .accessibilityIdentifier("AccessEmailToggle")
        }
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Asset.Colors.backgroundSecondary.swiftUIColor)
        .cornerRadius(10)
    }
}

// MARK: - EmailAccessView Previews

#if DEBUG
#Preview("Email Access") {
    NavigationView {
        EmailAccessView(
            store: Store(
                processor: StateProcessor(
                    state: EmailAccessState(
                        allowDelay: true,
                        emailAddress: "person@example.com"
                    )
                )
            )
        )
    }
}
#endif
