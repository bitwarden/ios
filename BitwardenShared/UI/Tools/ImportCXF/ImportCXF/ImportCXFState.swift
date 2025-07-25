import BitwardenResources
import Foundation

// MARK: - ImportCXFState

/// The state used to present the `ImportCXFView`.
///
struct ImportCXFState: Equatable, Sendable {
    // MARK: Types

    /// The status of the import process.
    enum ImportCXFStatus: Equatable, Sendable {
        /// The import flow is at the start point.
        case start

        /// The import flow is in progress.
        case importing

        /// The import flow succeded.
        case success(totalImportedCredentials: Int, importedResults: [CXFCredentialsResult])

        /// The import flow failed.
        case failure(message: String)
    }

    // MARK: Properties

    /// The token used in `ASCredentialImportManager` to get the credentials to import.
    var credentialImportToken: UUID?

    /// Whether the Credential Exchange import feature is unavailable.
    var isFeatureUnavailable: Bool = false

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

    /// The main icon to be displayed.
    var mainIcon: ImageAsset {
        return switch status {
        case .importing, .start:
            Asset.Images.fileUpload24
        case .success:
            Asset.Images.checkCircle24
        case .failure:
            Asset.Images.circleX16
        }
    }

    /// The message to display on the page header.
    var message: String {
        return switch status {
        case .start:
            Localizations.startImportCXFDescriptionLong
        case .importing:
            Localizations.pleaseDoNotCloseTheApp
        case let .success(total, _):
            Localizations.itemsSuccessfullyImported(total)
        case let .failure(message):
            message
        }
    }

    /// The progress of importing credentials.
    var progress = 0.0

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
            isFeatureUnavailable ? Localizations.importNotAvailable : Localizations.importFailed
        }
    }

    /// Whether to show the cancel button.
    var showCancelButton: Bool {
        return switch status {
        case .importing, .success:
            false
        case .failure, .start:
            true
        }
    }

    /// Whether to show the main button.
    var showMainButton: Bool {
        status != .importing && !isFeatureUnavailable
    }

    /// The current status of the import process.
    var status: ImportCXFStatus = .start
}
