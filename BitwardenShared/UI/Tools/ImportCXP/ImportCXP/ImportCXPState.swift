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

    /// Whether the CXP import feature is available.
    var isFeatureUnvailable: Bool = false

    /// The title of the main button.
    var mainButtonTitle: String {
        return switch status {
        case .start:
            Localizations.continue
        case .importing:
            ""
        case .success:
            Localizations.showVault
        case .failure:
            Localizations.retryImport
        }
    }

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

    /// Whether to show the cancel button.
    var showCancelButton: Bool {
        return switch status {
        case .importing, .success:
            false
        case .start, .failure:
            true
        }
    }

    /// The current status of the import process.
    var status: ImportCXPStatus = .start
}
