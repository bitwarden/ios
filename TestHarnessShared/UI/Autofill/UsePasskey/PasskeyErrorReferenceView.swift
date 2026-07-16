import BitwardenKit
import SwiftUI

/// A sheet listing the error states that can occur while parsing and verifying a passkey
/// assertion on the use passkey test screen.
///
struct PasskeyErrorReferenceView: View {
    // MARK: Properties

    /// A closure called when the user dismisses the sheet.
    let onDismiss: () -> Void

    // MARK: View

    var body: some View {
        NavigationView {
            List {
                clientDataErrorsSection
                verificationErrorsSection
            }
            .navigationTitle(Localizations.passkeyErrorReference)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                closeToolbarItem {
                    onDismiss()
                }
            }
        }
    }

    // MARK: Private Views

    /// Errors that can occur while parsing the assertion's `clientDataJSON` payload.
    private var clientDataErrorsSection: some View {
        Section {
            Text(Localizations.malformedClientDataJSONReceived)
            Text(Localizations.missingClientDataTypeReceived)
            Text(Localizations.missingClientDataChallengeReceived)
            Text(Localizations.malformedClientDataChallengeReceived)
        } header: {
            Text(Localizations.clientDataErrors)
        }
    }

    /// Errors that can occur while verifying the parsed assertion against a stored credential.
    private var verificationErrorsSection: some View {
        Section {
            Text(Localizations.credentialNotFoundReceived)
            Text(Localizations.authDataTooShortReceived)
            Text(Localizations.rpIdHashMismatchReceived)
            Text(Localizations.userPresenceNotAssertedReceived)
            Text(Localizations.unexpectedAssertionClientDataTypeReceived("webauthn.create"))
            Text(Localizations.challengeMismatchReceived)
            Text(Localizations.signatureInvalidReceived)
        } header: {
            Text(Localizations.verificationErrors)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    PasskeyErrorReferenceView(onDismiss: {})
}
#endif
