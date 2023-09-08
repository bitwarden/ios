import SwiftUI

// MARK: - LoginView

/// A view that allows the user to input their master password to complete the
/// login flow, or allows the user to navigate to separate views for alternate
/// forms of login.
///
struct LoginView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<LoginState, LoginAction, Void>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Master Password")
                    .font(.system(.footnote))

                HStack {
                    if store.state.isMasterPasswordRevealed {
                        TextField("", text: store.binding(
                            get: { $0.masterPassword },
                            send: { .masterPasswordChanged($0) }
                        ))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .textContentType(.password)
                    } else {
                        SecureField("", text: store.binding(
                            get: { $0.masterPassword },
                            send: { .masterPasswordChanged($0) }
                        ))
                    }

                    Button {
                        store.send(.revealMasterPasswordFieldPressed)
                    } label: {
                        Image(systemName: store.state.isMasterPasswordRevealed ? "eye.slash" : "eye")
                    }
                }

                Button("Get master password hint") {
                    store.send(.getMasterPasswordHintPressed)
                }
                .font(.system(.footnote))

                Button {
                    store.send(.loginWithMasterPasswordPressed)
                } label: {
                    Text("Log in with master password")
                        .bold()
                        .foregroundColor(.white)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if store.state.isLoginWithDeviceEnabled {
                    Button {
                        store.send(.loginWithDevicePressed)
                    } label: {
                        Text("Login with device")
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
                    Text("Enterprise single sign-on")
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

                Text("Logging in as \(store.state.username) on \(store.state.region)")
                Button("Not you?") {
                    store.send(.notYouPressed)
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .navigationTitle("Bitwarden")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        store.send(.morePressed)
                    } label: {
                        Label("Options", systemImage: "ellipsis")
                    }
                }
            }
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
                            isLoginWithDeviceEnabled: true
                        )
                    )
                )
            )
        }
        .previewDisplayName("With Device")
    }
}
