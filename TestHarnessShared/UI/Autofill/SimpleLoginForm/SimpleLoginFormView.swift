import BitwardenKit
import SwiftUI

/// A view that displays a simple login form for testing autofill functionality.
///
struct SimpleLoginFormView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<SimpleLoginFormState, SimpleLoginFormAction, SimpleLoginFormEffect>

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
                    Localizations.username,
                    text: store.binding(
                        get: \.username,
                        send: SimpleLoginFormAction.usernameChanged,
                    ),
                )
                .textContentType(.username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                SecureField(
                    Localizations.password,
                    text: store.binding(
                        get: \.password,
                        send: SimpleLoginFormAction.passwordChanged,
                    ),
                )
                .textContentType(.password)
            } header: {
                Text(Localizations.credentials)
            } footer: {
                Text(Localizations.simpleLoginFormDescription)
            }

            Section {
                if !store.state.username.isEmpty || !store.state.password.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        if !store.state.username.isEmpty {
                            Text(Localizations.usernameValue(store.state.username))
                                .styleGuide(.body)
                        }
                        if !store.state.password.isEmpty {
                            Text(Localizations.passwordValue(String(repeating: "•", count: store.state.password.count)))
                                .styleGuide(.body)
                        }
                    }
                } else {
                    Text(Localizations.enterCredentialsAbove)
                        .foregroundColor(.secondary)
                        .styleGuide(.body)
                }
            } header: {
                Text(Localizations.formValues)
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    NavigationView {
        SimpleLoginFormView(store: Store(processor: StateProcessor(state: SimpleLoginFormState())))
    }
}
#endif
