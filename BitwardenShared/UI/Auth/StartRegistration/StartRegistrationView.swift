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
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                mainContent
                    .frame(minHeight: store.state.isCreateAccountFeatureFlagEnabled ? geometry.size.height : 0)
            }
            .frame(width: geometry.size.width)
        }
        .background(Asset.Colors.backgroundPrimary.swiftUIColor)
        .navigationBar(title: Localizations.createAccount, titleDisplayMode: .inline)
        .task {
            await store.perform(.appeared)
        }
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }
        }
        .toast(
            store.binding(
                get: \.toast,
                send: StartRegistrationAction.toastShown
            )
        )
    }

    // MARK: Private views

    /// The main content of the view.
    private var mainContent: some View {
        VStack(spacing: 0) {
            if store.state.isCreateAccountFeatureFlagEnabled {
                Spacer()

                Image(decorative: Asset.Images.logo)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Asset.Colors.iconSecondary.swiftUIColor)
                    .frame(maxWidth: .infinity, maxHeight: 34)
                    .padding(.horizontal, 12)

                Spacer()
            }

            registrationDetails
        }
        .padding([.horizontal, .vertical], 16)
    }

    /// The section of the view containing input fields, and action buttons.
    private var registrationDetails: some View {
        VStack(spacing: 16) {
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
    }

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

#Preview("Native Create Account Flow") {
    StartRegistrationView(
        store: Store(
            processor: StateProcessor(
                state: StartRegistrationState(
                    isCreateAccountFeatureFlagEnabled: true
                )
            )
        )
    )
}
#endif
