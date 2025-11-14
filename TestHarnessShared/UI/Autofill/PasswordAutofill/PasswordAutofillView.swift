import BitwardenKit
import SwiftUI

/// A view that displays a form for testing password autofill functionality.
///
struct PasswordAutofillView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<PasswordAutofillState, PasswordAutofillAction, PasswordAutofillEffect>

    // MARK: View

    var body: some View {
        content
            .navigationTitle(store.state.title)
            .navigationBarTitleDisplayMode(.large)
    }

    // MARK: Private Views

    /// The main content view.
    private var content: some View {
        Form {
            Section {
                TextField(
                    "Username",
                    text: store.binding(
                        get: \.username,
                        send: PasswordAutofillAction.usernameChanged
                    )
                )
                .textContentType(.username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                SecureField(
                    "Password",
                    text: store.binding(
                        get: \.password,
                        send: PasswordAutofillAction.passwordChanged
                    )
                )
                .textContentType(.password)
            } header: {
                Text("Credentials")
            } footer: {
                Text("Use this form to test password autofill functionality.")
            }

            Section {
                if !store.state.username.isEmpty || !store.state.password.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        if !store.state.username.isEmpty {
                            Text("Username: \(store.state.username)")
                                .styleGuide(.body)
                        }
                        if !store.state.password.isEmpty {
                            Text("Password: \(String(repeating: "•", count: store.state.password.count))")
                                .styleGuide(.body)
                        }
                    }
                } else {
                    Text("Enter credentials above")
                        .foregroundColor(.secondary)
                        .styleGuide(.body)
                }
            } header: {
                Text("Form Values")
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    NavigationView {
        PasswordAutofillView(store: Store(processor: StateProcessor(state: PasswordAutofillState())))
    }
}
#endif
