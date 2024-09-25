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

    // MARK: View

    var body: some View {
        VStack(spacing: 16) {
            if store.state.isCreateAccountFeatureFlagEnabled {
                Image(decorative: Asset.Images.vaultIllustration)
                    .resizable()
                    .frame(width: 132, height: 132)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
            }

            name

            VStack(alignment: .leading, spacing: 0) {
                email
                    .padding(.bottom, 8)

                RegionSelector(
                    selectorLabel: Localizations.creatingOn,
                    regionName: store.state.region.baseUrlDescription
                ) {
                    await store.perform(.regionTapped)
                }
            }

            receiveMarketingToggle

            continueButton

            termsAndPrivacyText
                .frame(maxWidth: .infinity)
        }
        .navigationBar(title: Localizations.createAccount, titleDisplayMode: .inline)
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
        .textFieldConfiguration(.email)
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
        Text(LocalizedStringKey(store.state.termsAndPrivacyDisclaimerText))
            .styleGuide(.footnote)
            .tint(Asset.Colors.textInteraction.swiftUIColor)
            .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
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
                Text(LocalizedStringKey(store.state.receiveMarketingEmailsText))
                    .tint(Asset.Colors.textInteraction.swiftUIColor)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
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
