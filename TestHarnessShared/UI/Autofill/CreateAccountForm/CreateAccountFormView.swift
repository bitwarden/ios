import BitwardenKit
import SwiftUI
import UIKit

/// A view that displays an account creation form for testing credential-provider save functionality.
///
struct CreateAccountFormView: View {
    // MARK: Private Types

    private enum Field: Hashable {
        case confirmPassword
        case email
        case password
    }

    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<CreateAccountFormState, CreateAccountFormAction, CreateAccountFormEffect>

    // MARK: Private Properties

    @FocusState private var focusedField: Field?

    /// Password rules applied to both password fields.
    ///
    /// Rules: minimum 10 characters, uppercase + lowercase + digit + special character required.
    private let passwordRules = UITextInputPasswordRules(
        descriptor: "minlength: 10; required: upper; required: lower; required: digit; required: special;",
    )

    // MARK: View

    var body: some View {
        content
            .navigationTitle(store.state.title)
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: store.state.accountCreationCount) { count in
                if count > 0 {
                    // Resigning focus from all fields after a .newPassword form submission
                    // causes iOS to detect the completed account-creation flow and prompt
                    // the active credential provider to save the new credential.
                    focusedField = nil
                }
            }
    }

    // MARK: Private Views

    /// The main content view.
    private var content: some View {
        Form {
            credentialsSection
            if store.state.isAccountCreated {
                resultSection
            }
        }
    }

    /// The credentials input section.
    private var credentialsSection: some View {
        Section {
            TextField(
                Localizations.username,
                text: store.binding(
                    get: \.email,
                    send: CreateAccountFormAction.emailChanged,
                ),
            )
            .accessibilityIdentifier("EmailEntry")
            .focused($focusedField, equals: .email)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            PasswordRulesSecureField(
                accessibilityIdentifier: "PasswordEntry",
                placeholder: Localizations.password,
                passwordRules: passwordRules,
                textContentType: .newPassword,
                text: store.binding(
                    get: \.password,
                    send: CreateAccountFormAction.passwordChanged,
                ),
            )
            .focused($focusedField, equals: .password)
            .frame(height: 44)

            PasswordRulesSecureField(
                accessibilityIdentifier: "ConfirmPasswordEntry",
                placeholder: Localizations.confirmPassword,
                passwordRules: passwordRules,
                textContentType: .newPassword,
                text: store.binding(
                    get: \.confirmPassword,
                    send: CreateAccountFormAction.confirmPasswordChanged,
                ),
            )
            .focused($focusedField, equals: .confirmPassword)
            .frame(height: 44)

            if let errorMessage = store.state.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .styleGuide(.subheadline)
                    .accessibilityIdentifier("ErrorMessage")
            }

            Button(Localizations.createAccount) {
                Task {
                    await store.perform(.createAccount)
                }
            }
            .accessibilityIdentifier("CreateAccountButton")
            .disabled(
                store.state.email.isEmpty
                    || store.state.password.isEmpty
                    || store.state.confirmPassword.isEmpty,
            )
            .buttonStyle(.primary(shouldFillWidth: true))
        } header: {
            Text(Localizations.accountDetails)
        } footer: {
            Text(Localizations.createAccountFormDescriptionLong)
        }
    }

    /// The result section shown after a successful account creation.
    private var resultSection: some View {
        Section {
            Label(Localizations.accountCreatedSuccessfully, systemImage: "checkmark.circle.fill")
                .foregroundColor(.green)
                .styleGuide(.body)
                .accessibilityIdentifier("AccountCreatedLabel")
        } header: {
            Text(Localizations.result)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    NavigationView {
        CreateAccountFormView(store: Store(processor: StateProcessor(state: CreateAccountFormState())))
    }
}
#endif
