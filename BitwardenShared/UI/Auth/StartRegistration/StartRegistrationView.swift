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

    // MARK: View

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                email

                RegionSelector(regionName: store.state.region.baseUrlDescription) {
                    store.send(.regionTapped)
                }.padding(.bottom, 8)

                name.padding(.bottom, 8)
            }

            VStack(spacing: 24) {
                VStack(spacing: 24) {
                    termsAndPrivacyToggle
                }
                .padding(.top, 8)

                submitButton
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
    private var submitButton: some View {
        Button {
            Task {
                await store.perform(.startRegistration)
            }
        } label: {
            Text(Localizations.submit)
        }
        .accessibilityIdentifier("SubmitButton")
        .buttonStyle(.primary())
    }

    /// A toggle for the terms and privacy agreement.
    private var termsAndPrivacyToggle: some View {
        Toggle(isOn: store.binding(
            get: \.isTermsAndPrivacyToggleOn,
            send: StartRegistrationAction.toggleTermsAndPrivacy
        )) {
            Text("\(Localizations.acceptPolicies)\n\(termsOfServiceString ?? "") \(privacyPolicyString ?? "")")
                .styleGuide(.footnote)
        }
        .accessibilityAction(named: Localizations.termsOfService) {
            openURL(ExternalLinksConstants.termsOfService)
        }
        .accessibilityAction(named: Localizations.privacyPolicy) {
            openURL(ExternalLinksConstants.privacyPolicy)
        }
        .accessibilityIdentifier("AcceptPoliciesToggle")
        .foregroundColor(Color(asset: Asset.Colors.textPrimary))
        .toggleStyle(.bitwarden)
        .id(ViewIdentifier.StartRegistration.termsAndPrivacy)
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    StartRegistrationView(store: Store(processor: StateProcessor(state: StartRegistrationState())))
}
#endif
