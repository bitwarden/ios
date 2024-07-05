import SwiftUI

// MARK: - StartRegistrationView

/// A view that allows the user to create an account.
///
struct StartRegistrationView: View {
    // MARK: Properties

    /// An action that opens URLs.
    @Environment(\.openURL) private var openURL

    /// The store used to render the view.
    @ObservedObject var store: Store<StartRegistrationState, StartRegistrationAction, StartRegistrationEffect>

    /// The privacy policy attributed string used in navigating to Bitwarden's Privacy Policy website.
    let privacyPolicyString: AttributedString? = try? AttributedString(
        markdown: "[\(Localizations.privacyPolicy)](\(ExternalLinksConstants.privacyPolicy))"
    )

    /// The terms of service attributed string used in navigating to Bitwarden's Terms of Service website.
    let termsOfServiceString: AttributedString? = try? AttributedString(
        markdown: "[\(Localizations.termsOfService),](\(ExternalLinksConstants.termsOfService))"
    )

    /// The unsubscribe marketing attributed string used in navigating to Bitwarden's website.
    let unsubscribeString: AttributedString? = try? AttributedString(
        markdown: "[\(Localizations.unsubscribe),](\(ExternalLinksConstants.unsubscribe))"
    )

    // MARK: View

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                email

                RegionSelector(regionName: store.state.region.baseUrlDescription) {
                    store.send(.regionTapped)
                }.padding(.bottom, 8)

                name.padding(.bottom, 16)

                receiveMarketingToggle.padding(.bottom, 16)

                continueButton.padding(.bottom, 16)

                termsAndPrivacyText.padding(.bottom, 16)
            }
        }.navigationBar(title: Localizations.createAccount, titleDisplayMode: .inline)
            .scrollView()
            .task {
                await store.perform(.appeared)
            }
            .toolbar {
                cancelToolbarItem {
                    store.send(.dismiss)
                }
            }
            .toast(store.binding(
                get: \.toast,
                send: StartRegistrationAction.toastShown
            ))
    }

    // MARK: Private views

    /// The text fields for the user's email and password.
    private var email: some View {
        BitwardenTextField(
            title: Localizations.emailAddress,
            text: store.binding(
                get: \.emailText,
                send: StartRegistrationAction.emailTextChanged
            ),
            accessibilityIdentifier: "EmailAddressEntry"
        )
        .textFieldConfiguration(.email).padding(.bottom, 8)
    }

    /// The text fields for the user's email and password.
    private var name: some View {
        BitwardenTextField(
            title: Localizations.name,
            text: store.binding(
                get: \.nameText,
                send: StartRegistrationAction.nameTextChanged
            ),
            accessibilityIdentifier: "nameEntry"
        )
        .textFieldConfiguration(.username)
    }

    /// The button pressed when the user attempts to create the account.
    private var continueButton: some View {
        Button {
            Task {
                await store.perform(.startRegistration)
            }
        } label: {
            Text(Localizations.continue)
        }
        .accessibilityIdentifier("ContinueButton")
        .buttonStyle(.primary())
    }

    /// The button pressed when the user attempts to create the account.
    private var termsAndPrivacyText: some View {
        Text(.init(store.state.termsAndPrivacyDisclaimerText))
            .styleGuide(.footnote)
            .tint(Asset.Colors.primaryBitwarden.swiftUIColor)
            .padding([.bottom], 32)
            .multilineTextAlignment(.center)
    }

    /// A toggle for the terms and privacy agreement.
    @ViewBuilder private var receiveMarketingToggle: some View {
        if store.state.showReceiveMarketingToggle {
            Toggle(isOn: store.binding(
                get: \.isReceiveMarketingToggleOn,
                send: StartRegistrationAction.toggleReceiveMarketing
            )) {
                Text(.init(store.state.receiveMarketingEmailsText))
                    .tint(Asset.Colors.primaryBitwarden.swiftUIColor)
                    .styleGuide(.subheadline)
            }
            .accessibilityIdentifier("ReceiveMarketingToggle")
            .foregroundColor(Color(asset: Asset.Colors.textPrimary))
            .toggleStyle(.bitwarden)
            .id(ViewIdentifier.StartRegistration.receiveMarketing)
        }
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    StartRegistrationView(store: Store(processor: StateProcessor(state: StartRegistrationState())))
}
#endif
