import Foundation

// MARK: - SelfHostedAction

/// Actions handled by the `SelfHostedProcessor`.
///
enum SelfHostedAction: Equatable {
    /// The API server URL has changed.
    case apiUrlChanged(String)

    /// The view was dismissed.
    case dismiss

    /// The icons server URL has changed.
    case iconsUrlChanged(String)

    /// The identity server URL has changed.
    case identityUrlChanged(String)

    /// The server URL has changed.
    case serverUrlChanged(String)

    /// The web vault server URL has changed.
    case webVaultUrlChanged(String)

    /// The user tapped to configure client certificate.
    case clientCertificateConfigureTapped

    /// The user tapped to import a client certificate.
    case importCertificateTapped

    /// A certificate file was selected.
    case certificateFileSelected(Result<URL, Error>)

    /// The certificate password changed.
    case certificatePasswordChanged(String)

    /// The certificate importer was dismissed.
    case dismissCertificateImporter

    /// The password prompt was dismissed.
    case dismissPasswordPrompt

    /// The user confirmed the password for certificate import.
    case confirmCertificatePassword

    /// The user tapped to remove the client certificate.
    case removeCertificate

    /// The client certificate import sheet was dismissed.
    case clientCertificateSheetDismissed

    // MARK: Equatable

    static func == (lhs: SelfHostedAction, rhs: SelfHostedAction) -> Bool {
        switch (lhs, rhs) {
        case let (.apiUrlChanged(lhsUrl), .apiUrlChanged(rhsUrl)):
            return lhsUrl == rhsUrl
        case (.dismiss, .dismiss):
            return true
        case let (.iconsUrlChanged(lhsUrl), .iconsUrlChanged(rhsUrl)):
            return lhsUrl == rhsUrl
        case let (.identityUrlChanged(lhsUrl), .identityUrlChanged(rhsUrl)):
            return lhsUrl == rhsUrl
        case let (.serverUrlChanged(lhsUrl), .serverUrlChanged(rhsUrl)):
            return lhsUrl == rhsUrl
        case let (.webVaultUrlChanged(lhsUrl), .webVaultUrlChanged(rhsUrl)):
            return lhsUrl == rhsUrl
        case (.clientCertificateConfigureTapped, .clientCertificateConfigureTapped):
            return true
        case (.importCertificateTapped, .importCertificateTapped):
            return true
        case let (.certificateFileSelected(lhsResult), .certificateFileSelected(rhsResult)):
            // Compare Results by comparing success URLs or failure error descriptions
            switch (lhsResult, rhsResult) {
            case let (.success(lhsUrl), .success(rhsUrl)):
                return lhsUrl == rhsUrl
            case let (.failure(lhsError), .failure(rhsError)):
                return lhsError.localizedDescription == rhsError.localizedDescription
            default:
                return false
            }
        case let (.certificatePasswordChanged(lhsPassword), .certificatePasswordChanged(rhsPassword)):
            return lhsPassword == rhsPassword
        case (.dismissCertificateImporter, .dismissCertificateImporter):
            return true
        case (.dismissPasswordPrompt, .dismissPasswordPrompt):
            return true
        case (.confirmCertificatePassword, .confirmCertificatePassword):
            return true
        case (.removeCertificate, .removeCertificate):
            return true
        case (.clientCertificateSheetDismissed, .clientCertificateSheetDismissed):
            return true
        default:
            return false
        }
    }
}
