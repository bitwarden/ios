import Foundation

// MARK: - ImportCXPState

/// The state used to present the `ImportCXPView`.
///
struct ImportCXPState: Equatable, Sendable {
    // MARK: Types

    /// The status of the import process.
    enum ImportCXPStatus: Equatable, Sendable {
        /// The import flow is at the start point.
        case start

        /// The import flow is in progress.
        case importing

        /// The import flow succeded.
        case success(totalImportedCredentials: Int, credentialsByTypeCount: [ImportedCredentialsResult])

        /// The import flow failed.
        case failure(message: String)
    }

    // MARK: Properties

    /// The token used in `ASCredentialImportManager` to get the credentials to import.
    var credentialImportToken: UUID?

    /// The message to display on the page header.
    var message: String {
        return switch status {
        case .start:
            Localizations.startImportCXPDescriptionLong
        case .importing:
            ""
        case let .success(total, _):
            Localizations.itemsSuccessfullyImported(total)
        case let .failure(message):
            message
        }
    }

    /// The title to display on the page header.
    var title: String {
        return switch status {
        case .start:
            Localizations.importPasswords
        case .importing:
            Localizations.importingEllipsis
        case .success:
            Localizations.importSuccessful
        case .failure:
            Localizations.importFailed
        }
    }

    /// The current status of the import process.
    var status: ImportCXPStatus = .start
}
