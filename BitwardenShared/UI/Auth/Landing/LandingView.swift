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
                Text("Log in or create a new account to access your secure vault.")
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                TextField("Email", text: store.binding(
                    get: { $0.email },
                    send: { .emailChanged($0) }
                ))
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)

                Button {
                    store.send(.regionPressed)
                } label: {
                    HStack(spacing: 4) {
                        Text("Region:")
                            .foregroundColor(.primary)
                        Text("US")
                            .foregroundColor(.blue)
                        Image(systemName: "chevron.down")
                    }
                    .font(.system(.footnote))
                }

                Toggle("Remember me", isOn: store.binding(
                    get: { $0.isRememberMeOn },
                    send: { .rememberMeChanged($0) }
                ))

                Button {
                    store.send(.continuePressed)
                } label: {
                    Text("Continue")
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                HStack(spacing: 4) {
                    Text("New around here?")
                    Button("Create account") {
                        store.send(.createAccountPressed)
                    }
                }
                .font(.system(.footnote))
            }
            .padding(.horizontal)
        }
        .navigationBarTitle("Bitwarden", displayMode: .inline)
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
