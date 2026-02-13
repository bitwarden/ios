import Foundation

// MARK: - SelfHostedState

/// An object that defines the current state of a `SelfHostedView`.
///
struct SelfHostedState: Equatable {
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

    /// The client certificate configuration.
    var clientCertificateConfiguration: ClientCertificateConfiguration = .disabled

    /// Whether the client certificate import sheet is presented.
    var isClientCertificateSheetPresented: Bool = false

    /// Whether the certificate importer is showing.
    var showingCertificateImporter: Bool = false

    /// Whether the password prompt is showing.
    var showingPasswordPrompt: Bool = false

    /// The password for the certificate being imported.
    var certificatePassword: String = ""

    /// The certificate data temporarily stored while waiting for password input.
    var pendingCertificateData: Data?
}
