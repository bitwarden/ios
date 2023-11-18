import SwiftUI

// MARK: - LoginView

/// A view that allows the user to input their master password to complete the
/// login flow, or allows the user to navigate to separate views for alternate
/// forms of login.
///
struct LoginView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<LoginState, LoginAction, LoginEffect>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                textField

                loginButtons

                loggingInAs
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .frame(maxWidth: .infinity)
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        .navigationTitle(Localizations.bitwarden)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    store.send(.morePressed)
                } label: {
                    Label {
                        Text(Localizations.options)
                    } icon: {
                        Asset.Images.verticalKabob.swiftUIImage
                    }
                }
                .tint(Asset.Colors.primaryBitwarden.swiftUIColor)
            }
        }
        .task {
            await store.perform(.appeared)
        }
    }

    /// The text field along with the master password hint button.
    @ViewBuilder var textField: some View {
        VStack(alignment: .leading, spacing: 8) {
            BitwardenTextField(
                accessibilityIdentifier: "MasterPasswordEntry",
                title: Localizations.masterPassword,
                isPasswordVisible: store.binding(
                    get: \.isMasterPasswordRevealed,
                    send: LoginAction.revealMasterPasswordFieldPressed
                ),
                passwordVisibilityAccessibilityId: "PasswordVisibilityToggle",
                text: store.binding(
                    get: \.masterPassword,
                    send: LoginAction.masterPasswordChanged
                )
            )
            .textContentType(.password)
            .textInputAutocapitalization(.never)

            Button(Localizations.getMasterPasswordwordHint) {
                store.send(.getMasterPasswordHintPressed)
            }
            .accessibilityIdentifier("GetMasterPasswordHintLabel")
            .font(.styleGuide(.subheadline))
            .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
        }
    }

    /// The set of login option buttons.
    @ViewBuilder var loginButtons: some View {
        VStack(alignment: .center, spacing: 12) {
            Button(Localizations.logInWithMasterPassword) {
                Task {
                    await store.perform(.loginWithMasterPasswordPressed)
                }
            }
            .accessibilityIdentifier("LogInWithMasterPasswordButton")
            .buttonStyle(.primary())

            if store.state.isLoginWithDeviceVisible {
                Button {
                    store.send(.loginWithDevicePressed)
                } label: {
                    HStack(spacing: 8) {
                        Image(decorative: Asset.Images.mobile)
                        Text(Localizations.logInWithDevice)
                    }
                }
                .accessibilityIdentifier("LogInWithAnotherDeviceButton")
                .buttonStyle(.secondary())
            }

            Button {
                store.send(.enterpriseSingleSignOnPressed)
            } label: {
                HStack(spacing: 8) {
                    Image(decorative: Asset.Images.bwiProvider)
                    Text(Localizations.logInSso)
                }
            }
            .accessibilityIdentifier("LogInWithSsoButton")
            .buttonStyle(.secondary())
        }
    }

    /// The "logging in as..." text along with the not you button.
    @ViewBuilder var loggingInAs: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Localizations.loggedInAsOn(store.state.username, store.state.region.baseUrlDescription))
                .accessibilityIdentifier("LoggingInAsLabel")
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)

            Button(Localizations.notYou) {
                store.send(.notYouPressed)
            }
            .accessibilityIdentifier("NotYouLabel")
            .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
        }
        .font(.styleGuide(.footnote))
    }
}

// MARK: - Previews

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LoginView(
                store: Store(
                    processor: StateProcessor(
                        state: LoginState()
                    )
                )
            )
        }
        .previewDisplayName("Empty")

        NavigationView {
            LoginView(
                store: Store(
                    processor: StateProcessor(
                        state: LoginState(
                            isLoginWithDeviceVisible: true
                        )
                    )
                )
            )
        }
        .previewDisplayName("With Device")
    }
}
