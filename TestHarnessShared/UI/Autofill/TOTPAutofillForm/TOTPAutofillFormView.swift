import BitwardenKit
import SwiftUI

/// A view that displays a TOTP autofill form for testing one-time code autofill functionality.
///
struct TOTPAutofillFormView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<TOTPAutofillFormState, TOTPAutofillFormAction, Void>

    // MARK: View

    var body: some View {
        content
            .navigationTitle(Localizations.totpAutofillForm)
            .navigationBarTitleDisplayMode(.large)
    }

    // MARK: Private Views

    /// The main content view.
    private var content: some View {
        Form {
            Section {
                TextField(
                    Localizations.totpCode,
                    text: store.binding(
                        get: \.totpCode,
                        send: TOTPAutofillFormAction.totpCodeChanged,
                    ),
                )
                .textContentType(.oneTimeCode)
                .keyboardType(.default)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityIdentifier(AccessibilityIdentifier.TOTPForm.totpCodeTextField)
            } header: {
                Text(Localizations.totpCode)
            } footer: {
                Text(Localizations.tapTheTOTPCodeFieldAndSelectDescriptionLong)
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    NavigationView {
        TOTPAutofillFormView(store: Store(processor: StateProcessor(state: TOTPAutofillFormState())))
    }
}
#endif
