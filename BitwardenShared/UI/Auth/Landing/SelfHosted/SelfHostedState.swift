import Foundation

// MARK: - SelfHostedState

/// An object that defines the current state of a `SelfHostedView`.
///
struct SelfHostedState: Equatable {
    // MARK: Subtypes

    /// Represents the possible dialog states for the client certificate section.
    ///
    enum DialogState: Equatable {
        /// A confirmation dialog presented when the entered alias matches an existing certificate.
        case confirmOverwriteAlias(alias: String, certificateData: Data, password: String)

        /// An error dialog.
        case error(message: String)

        /// The alias and password input dialog shown after a certificate file is selected.
        case setCertificateData(certificateData: Data)
    }

    // MARK: Environment URLs

    /// The API server URL.
    var apiServerUrl: String = ""

    /// The icons server URL.
    var iconsServerUrl: String = ""

    /// The identity server URL.
    var identityServerUrl: String = ""

    /// The server URL.
    var serverUrl: String = ""

    /// The web vault server URL.
    var webVaultServerUrl: String = ""

    // MARK: Client Certificate

    /// The alias of the currently configured client certificate.
    var keyAlias: String = ""

    /// The SHA-256 fingerprint of the currently configured client certificate.
    var keyFingerprint: String = ""

    // MARK: Certificate Import Dialog

    /// The active dialog state for the client certificate section.
    var dialog: DialogState?

    /// The certificate data temporarily stored while waiting for password input.
    var pendingCertificateData: Data?

    /// Whether the certificate file importer is showing.
    var showingCertificateImporter: Bool = false
}
