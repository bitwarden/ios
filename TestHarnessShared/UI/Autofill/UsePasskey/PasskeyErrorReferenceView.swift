import BitwardenKit
import SwiftUI

/// A sheet listing the error states that can occur while parsing and verifying a passkey
/// assertion on the use passkey test screen.
///
struct PasskeyErrorReferenceView: View {
    // MARK: Types

    /// A single documented error state, describing what triggers it and the message a tester
    /// would see if it occurred during a real assertion attempt.
    private struct ErrorReferenceItem: Identifiable {
        /// A short, human-readable name for the error state.
        let title: String

        /// An explanation of the condition that causes this error.
        let explanation: String

        /// The exact message a tester would see in the assertion result if this error occurred.
        let message: String

        var id: String { title }
    }

    // MARK: Properties

    /// A closure called when the user dismisses the sheet.
    let onDismiss: () -> Void

    /// Errors that can occur while parsing the assertion's `clientDataJSON` payload, in the order
    /// they're checked.
    private let clientDataErrors = [
        ErrorReferenceItem(
            title: Localizations.malformedClientDataJSONTitle,
            explanation: Localizations.malformedClientDataJSONExplanationLong,
            message: Localizations.malformedClientDataJSONReceived,
        ),
        ErrorReferenceItem(
            title: Localizations.missingClientDataTypeTitle,
            explanation: Localizations.missingClientDataTypeExplanationLong,
            message: Localizations.missingClientDataTypeReceived,
        ),
        ErrorReferenceItem(
            title: Localizations.missingClientDataChallengeTitle,
            explanation: Localizations.missingClientDataChallengeExplanationLong,
            message: Localizations.missingClientDataChallengeReceived,
        ),
        ErrorReferenceItem(
            title: Localizations.malformedClientDataChallengeTitle,
            explanation: Localizations.malformedClientDataChallengeExplanationLong,
            message: Localizations.malformedClientDataChallengeReceived,
        ),
    ]

    /// Errors that can occur while verifying the parsed assertion against a stored credential, in
    /// the order they're checked.
    private let verificationErrors = [
        ErrorReferenceItem(
            title: Localizations.credentialNotFoundTitle,
            explanation: Localizations.credentialNotFoundExplanationLong,
            message: Localizations.credentialNotFoundReceived,
        ),
        ErrorReferenceItem(
            title: Localizations.authDataTooShort,
            explanation: Localizations.authDataTooShortExplanationLong,
            message: Localizations.authDataTooShortReceived,
        ),
        ErrorReferenceItem(
            title: Localizations.rpIdHashMismatchTitle,
            explanation: Localizations.rpIdHashMismatchExplanationLong,
            message: Localizations.rpIdHashMismatchReceived,
        ),
        ErrorReferenceItem(
            title: Localizations.userPresenceNotAssertedTitle,
            explanation: Localizations.userPresenceNotAssertedExplanationLong,
            message: Localizations.userPresenceNotAssertedReceived,
        ),
        ErrorReferenceItem(
            title: Localizations.unexpectedAssertionClientDataTypeTitle,
            explanation: Localizations.unexpectedAssertionClientDataTypeExplanationLong,
            message: Localizations.unexpectedAssertionClientDataTypeReceived("webauthn.create"),
        ),
        ErrorReferenceItem(
            title: Localizations.challengeMismatchTitle,
            explanation: Localizations.challengeMismatchExplanationLong,
            message: Localizations.challengeMismatchReceived,
        ),
        ErrorReferenceItem(
            title: Localizations.signatureInvalidTitle,
            explanation: Localizations.signatureInvalidExplanationLong,
            message: Localizations.signatureInvalidReceived,
        ),
    ]

    // MARK: View

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text(Localizations.passkeyErrorReferenceDescriptionLong)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding()

                List {
                    errorSection(
                        header: Localizations.clientDataErrors,
                        footer: Localizations.clientDataErrorsDescriptionLong,
                        systemImage: "doc.text.magnifyingglass",
                        items: clientDataErrors,
                    )
                    errorSection(
                        header: Localizations.verificationErrors,
                        footer: Localizations.verificationErrorsDescriptionLong,
                        systemImage: "checkmark.shield",
                        items: verificationErrors,
                    )
                }
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

    /// Builds a `Section` listing the given error reference items, with a labeled header and a
    /// footer describing when this category of error is checked.
    ///
    /// - Parameters:
    ///   - header: The section's header text.
    ///   - footer: The section's footer text.
    ///   - systemImage: The SF Symbol shown alongside the header.
    ///   - items: The error reference items to list.
    ///
    private func errorSection(
        header: String,
        footer: String,
        systemImage: String,
        items: [ErrorReferenceItem],
    ) -> some View {
        Section {
            ForEach(items) { item in
                errorRow(item)
            }
        } header: {
            Label(header, systemImage: systemImage)
        } footer: {
            Text(footer)
        }
    }

    /// Builds a row displaying an error reference item's title, explanation, and the exact
    /// message a tester would see if it occurred.
    private func errorRow(_ item: ErrorReferenceItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.headline)
            Text(item.explanation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(Localizations.xColonY(Localizations.messageShown, item.message))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    PasskeyErrorReferenceView(onDismiss: {})
}
#endif
