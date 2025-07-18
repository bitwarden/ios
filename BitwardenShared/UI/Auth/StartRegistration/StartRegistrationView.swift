import BitwardenResources
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
        mainContent
            .navigationBar(
                title: Localizations.createAccount,
                titleDisplayMode: .inline
            )
            .onDisappear {
                store.send(.disappeared)
            }
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

    /// The text fields for the user's email and password.
    private var email: some View {
        BitwardenTextField(
            title: Localizations.emailAddress,
            text: store.binding(
                get: \.emailText,
                send: StartRegistrationAction.emailTextChanged
            ),
            accessibilityIdentifier: "EmailAddressEntry",
            footerContent: {
                RegionSelector(
                    selectorLabel: Localizations.creatingOn,
                    regionName: store.state.region.baseURLDescription
                ) {
                    await store.perform(.regionTapped)
                }
                .padding(.vertical, 14)
            }
        )
        .textFieldConfiguration(.email)
    }

    /// The main content view that displays a scrollable layout of registration details.
    private var mainContent: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                Spacer(minLength: 24)

                Image(decorative: Asset.Images.logo)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(SharedAsset.Colors.iconSecondary.swiftUIColor)
                    .frame(maxWidth: .infinity, maxHeight: 34)
                    .padding(.horizontal, 12)

                Spacer(minLength: 24)

                registrationDetails
            }
            .padding(.top, 0)
            .padding(.bottom, 16)
            .frame(minHeight: proxy.size.height)
            .scrollView(addVerticalPadding: false, showsIndicators: false)
        }
    }

    /// The text fields for the user's email and password.
    private var name: some View {
        BitwardenTextField(
            title: Localizations.name,
            text: store.binding(
                get: \.nameText,
                send: StartRegistrationAction.nameTextChanged
            ),
            accessibilityIdentifier: "NameEntry"
        )
        .textFieldConfiguration(.username)
    }

    /// A toggle for the terms and privacy agreement.
    @ViewBuilder private var receiveMarketingToggle: some View {
        if store.state.showReceiveMarketingToggle {
            BitwardenToggle(isOn: store.binding(
                get: \.isReceiveMarketingToggleOn,
                send: StartRegistrationAction.toggleReceiveMarketing
            )) {
                Text(LocalizedStringKey(store.state.receiveMarketingEmailsText))
                    .tint(SharedAsset.Colors.textInteraction.swiftUIColor)
                    .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .styleGuide(.subheadline)
            }
            .accessibilityIdentifier("ReceiveMarketingToggle")
            .contentBlock()
            .id(ViewIdentifier.StartRegistration.receiveMarketing)
        }
    }

    /// The section of the view containing input fields, and action buttons.
    private var registrationDetails: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                name
                email
                receiveMarketingToggle
            }

            continueButton
            termsAndPrivacyText
        }
    }

    /// The button pressed when the user attempts to create the account.
    private var termsAndPrivacyText: some View {
        Text(LocalizedStringKey(store.state.termsAndPrivacyDisclaimerText))
            .styleGuide(.footnote)
            .tint(SharedAsset.Colors.textInteraction.swiftUIColor)
            .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
            .padding([.bottom], 32)
            .multilineTextAlignment(.center)
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
                state: StartRegistrationState()
            )
        )
    )
}
#endif
