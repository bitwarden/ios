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
        VStack(spacing: 24) {
            if verticalSizeClass == .regular {
                VStack(spacing: 24) {
                    Asset.Images.Illustrations.businessWarning.swiftUIImage
                        .resizable()
                        .frame(width: 124, height: 124)

                    textPortion
                }
                .padding(.top, 16)
            } else {
                HStack(spacing: 32) {
                    Asset.Images.Illustrations.businessWarning.swiftUIImage
                        .resizable()
                        .frame(width: 100, height: 100)

                    textPortion
                }
                .padding(.horizontal, 80)
                .padding(.top, 16)
            }

            toggleCard

            AsyncButton(Localizations.continue) {
                await store.perform(.continueTapped)
            }
            .buttonStyle(.primary())
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
        .multilineTextAlignment(.center)
        .scrollView()
    }

    private var textPortion: some View {
        VStack(spacing: 12) {
            Text(Localizations.importantNotice)
                .styleGuide(.title2, weight: .semibold)

            Text(Localizations.bitwardenWillSendACodeToYourAccountEmailDescriptionLong)
                .styleGuide(.body)
        }
    }

    private var toggleCard: some View {
        ContentBlock {
            Text(LocalizedStringKey(Localizations.doYouHaveReliableAccessToYourEmail(
                store.state.emailAddress.withoutAutomaticEmailLinks()
            )))
            .styleGuide(.body)
            .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
            .padding(16)

            Toggle(Localizations.yesICanReliablyAccessMyEmail, isOn: store.binding(
                get: \.canAccessEmail,
                send: EmailAccessAction.canAccessEmailChanged
            ))
            .toggleStyle(.bitwarden)
            .accessibilityIdentifier("AccessEmailToggle")
            .padding(16)
        }
        .multilineTextAlignment(.leading)
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
