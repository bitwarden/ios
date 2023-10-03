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
            VStack(alignment: .leading) {
                BitwardenTextField(
                    title: Localizations.masterPassword,
                    contentType: .password,
                    isPasswordVisible: store.binding(
                        get: { $0.isMasterPasswordRevealed },
                        send: { .revealMasterPasswordFieldPressed($0) }
                    ),
                    text: store.binding(
                        get: { $0.masterPassword },
                        send: { .masterPasswordChanged($0) }
                    )
                )

                Button(Localizations.getMasterPasswordwordHint) {
                    store.send(.getMasterPasswordHintPressed)
                }
                .font(.system(.footnote))

                Button {
                    Task {
                        await store.perform(.loginWithMasterPasswordPressed)
                    }
                } label: {
                    Text(Localizations.logInWithMasterPassword)
                        .bold()
                        .foregroundColor(.white)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if store.state.isLoginWithDeviceVisible {
                    Button {
                        store.send(.loginWithDevicePressed)
                    } label: {
                        Text(Localizations.logInWithDevice)
                            .foregroundColor(.gray)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.gray)
                            }
                    }
                }

                Button {
                    store.send(.enterpriseSingleSignOnPressed)
                } label: {
                    Text(Localizations.logInSso)
                        .foregroundColor(.gray)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.gray)
                        }
                }

                Spacer()
                    .frame(height: 12)

                Text(Localizations.loggedInAsOn(store.state.username, store.state.region))
                Button(Localizations.notYou) {
                    store.send(.notYouPressed)
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .navigationTitle(Localizations.bitwarden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        store.send(.morePressed)
                    } label: {
                        Label {
                            Text(Localizations.options)
                        } icon: {
                            Asset.Images.moreVert.swiftUIImage
                        }
                    }
                }
            }
        }
        .task {
            await store.perform(.appeared)
        }
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
