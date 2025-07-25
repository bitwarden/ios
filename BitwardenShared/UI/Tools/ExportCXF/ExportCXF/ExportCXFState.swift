import BitwardenResources

struct ExportCXFState: Equatable, Sendable {
    // MARK: Types

    /// The status of the export process.
    enum ExportCXFStatus: Equatable, Sendable {
        /// The export flow is at the start point.
        case start

        /// The export flow is prepared to be executed with the selected items.
        case prepared(itemsToExport: [CXFCredentialsResult])

        /// The export flow failed.
        case failure(message: String)
    }

    // MARK: Properties

    /// Whether the Credential Exchange export feature is unavailable.
    var isFeatureUnavailable: Bool = false

    /// The title of the main button.
    var mainButtonTitle: String {
        return switch status {
        case .start:
            ""
        case .prepared:
            Localizations.exportItems
        case .failure:
            Localizations.retryExport
        }
    }

    /// The main icon to be displayed.
    var mainIcon: ImageAsset {
        return switch status {
        case .prepared, .start:
            Asset.Images.fileUpload24
        case .failure:
            Asset.Images.circleX16
        }
    }

    /// The message to display on the page header.
    var message: String {
        return switch status {
        case .prepared, .start:
            Localizations.exportPasswordsPasskeysCreditCardsAndAnyPersonalIdentityInformation
        case let .failure(message):
            message
        }
    }

    /// Whether the main button should be shown.
    var showMainButton: Bool {
        guard !isFeatureUnavailable else {
            return false
        }

        return switch status {
        case .failure, .prepared:
            true
        case .start:
            false
        }
    }

    /// The title to display on the page header.
    var title: String {
        return switch status {
        case .prepared, .start:
            Localizations.exportItems
        case .failure:
            Localizations.exportFailed
        }
    }

    /// The current status of the export process.
    var status: ExportCXFStatus = .start
}
