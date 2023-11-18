import SwiftUI

// MARK: - LandingView

/// A view that allows the user to input their email address to begin the login flow,
/// or allows the user to navigate to the account creation flow.
///
struct LandingView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject public var store: Store<LandingState, LandingAction, Void>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(decorative: Asset.Images.logo)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 45)

                Text(Localizations.loginOrCreateNewAccount)
                    .font(.styleGuide(.title2))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    .frame(maxWidth: .infinity)

                BitwardenTextField(
                    accessibilityIdentifier: "EmailAddressEntry",
                    title: Localizations.emailAddress,
                    text: store.binding(
                        get: \.email,
                        send: LandingAction.emailChanged
                    )
                )
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

                Button {
                    store.send(.regionPressed)
                } label: {
                    HStack(spacing: 4) {
                        Group {
                            Text("\(Localizations.loggingInOn): ")
                                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                                + Text(store.state.region.baseUrlDescription)
                                .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
                        }
                        .font(.styleGuide(.subheadline))

                        Image(decorative: Asset.Images.downTriangle)
                            .resizable()
                            .frame(width: 12, height: 12)
                            .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
                    }
                }
                .accessibilityIdentifier("RegionSelectorDropdown")

                Toggle(Localizations.rememberMe, isOn: store.binding(
                    get: { $0.isRememberMeOn },
                    send: { .rememberMeChanged($0) }
                ))
                .accessibilityIdentifier("RememberMeSwitch")
                .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                .toggleStyle(.bitwarden)

                Button(Localizations.continue) {
                    store.send(.continuePressed)
                }
                .accessibilityIdentifier("ContinueButton")
                .disabled(!store.state.isContinueButtonEnabled)
                .buttonStyle(.primary())

                HStack(spacing: 4) {
                    Text(Localizations.newAroundHere)
                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    Button(Localizations.createAccount) {
                        store.send(.createAccountPressed)
                    }
                    .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
                }
                .font(.styleGuide(.footnote))
            }
            .padding([.horizontal, .bottom], 16)
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        .navigationBarTitle(Localizations.bitwarden, displayMode: .inline)
    }
}

// MARK: - Previews

struct LandingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LandingView(
                store: Store(
                    processor: StateProcessor(
                        state: LandingState(
                            email: "",
                            isRememberMeOn: false
                        )
                    )
                )
            )
        }
        .previewDisplayName("Empty Email")

        NavigationView {
            LandingView(
                store: Store(
                    processor: StateProcessor(
                        state: LandingState(
                            email: "email@example.com",
                            isRememberMeOn: true
                        )
                    )
                )
            )
        }
        .previewDisplayName("Example Email")
    }
}
