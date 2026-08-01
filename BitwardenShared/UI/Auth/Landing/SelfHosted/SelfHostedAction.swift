import Foundation

// MARK: - SelfHostedAction

/// Actions handled by the `SelfHostedProcessor`.
///
enum SelfHostedAction: Equatable {
    // MARK: URL Actions

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

    // MARK: Custom Header Actions

    /// The user tapped to add a custom header field.
    case addHeaderTapped

    /// The name of a custom header field has changed.
    case headerNameChanged(id: UUID, name: String)

    /// The value of a custom header field has changed.
    case headerValueChanged(id: UUID, value: String)

    /// The visibility of a custom header field's value has changed.
    case headerValueVisibilityChanged(id: UUID, isVisible: Bool)

    /// The user tapped to remove a custom header field.
    case removeHeaderTapped(id: UUID)

    // MARK: Certificate Actions

    /// A certificate file was selected.
    case certificateFileSelected(Result<URL, Error>)

    /// The user submitted a certificate alias and password.
    case certificateInfoSubmitted(alias: String, password: String)

    /// The user confirmed overwriting an existing certificate alias.
    case confirmOverwriteCertificate

    /// A dialog was dismissed.
    case dialogDismiss

    /// The user dismissed the certificate file importer.
    case dismissCertificateImporter

    /// The user tapped to import a client certificate.
    case importCertificateTapped

    /// The user tapped to remove the current certificate.
    case removeCertificateTapped

    // MARK: Equatable

    static func == (lhs: SelfHostedAction, rhs: SelfHostedAction) -> Bool {
        switch (lhs, rhs) {
        case let (.apiUrlChanged(lhsUrl), .apiUrlChanged(rhsUrl)):
            lhsUrl == rhsUrl
        case (.dismiss, .dismiss):
            true
        case let (.iconsUrlChanged(lhsUrl), .iconsUrlChanged(rhsUrl)):
            lhsUrl == rhsUrl
        case let (.identityUrlChanged(lhsUrl), .identityUrlChanged(rhsUrl)):
            lhsUrl == rhsUrl
        case let (.serverUrlChanged(lhsUrl), .serverUrlChanged(rhsUrl)):
            lhsUrl == rhsUrl
        case let (.webVaultUrlChanged(lhsUrl), .webVaultUrlChanged(rhsUrl)):
            lhsUrl == rhsUrl
        case (.addHeaderTapped, .addHeaderTapped):
            true
        case let (.headerNameChanged(lhsId, lhsName), .headerNameChanged(rhsId, rhsName)):
            lhsId == rhsId && lhsName == rhsName
        case let (.headerValueChanged(lhsId, lhsValue), .headerValueChanged(rhsId, rhsValue)):
            lhsId == rhsId && lhsValue == rhsValue
        case let (
            .headerValueVisibilityChanged(lhsId, lhsIsVisible),
            .headerValueVisibilityChanged(rhsId, rhsIsVisible),
        ):
            lhsId == rhsId && lhsIsVisible == rhsIsVisible
        case let (.removeHeaderTapped(lhsId), .removeHeaderTapped(rhsId)):
            lhsId == rhsId
        case let (.certificateFileSelected(lhsResult), .certificateFileSelected(rhsResult)):
            switch (lhsResult, rhsResult) {
            case let (.success(lhsUrl), .success(rhsUrl)):
                lhsUrl == rhsUrl
            case let (.failure(lhsError), .failure(rhsError)):
                lhsError.localizedDescription == rhsError.localizedDescription
            default:
                false
            }
        case let (.certificateInfoSubmitted(lhsAlias, lhsPassword), .certificateInfoSubmitted(rhsAlias, rhsPassword)):
            lhsAlias == rhsAlias && lhsPassword == rhsPassword
        case (.confirmOverwriteCertificate, .confirmOverwriteCertificate):
            true
        case (.dialogDismiss, .dialogDismiss):
            true
        case (.dismissCertificateImporter, .dismissCertificateImporter):
            true
        case (.importCertificateTapped, .importCertificateTapped):
            true
        case (.removeCertificateTapped, .removeCertificateTapped):
            true
        default:
            false
        }
    }
}
