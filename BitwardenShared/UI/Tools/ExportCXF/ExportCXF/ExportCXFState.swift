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

    /// The title of the main button.
    var mainButtonTitle: String {
        return switch status {
        case .start:
            Localizations.continue
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

    /// The title to show in the section for each state.
    var sectionTitle: String {
        return switch status {
        case .prepared:
            Localizations.selectedItems
        case .start:
            Localizations.exportOptions
        case .failure:
            ""
        }
    }

    /// Whether the main button should be shown.
    var showMainButton: Bool = true

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

    /// The number of items to export.
    var totalItemsToExport: Int = 0
}
