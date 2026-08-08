import Foundation

// MARK: - SelfHostedState

/// An object that defines the current state of a `SelfHostedView`.
///
struct SelfHostedState: Equatable {
    // MARK: Subtypes

    /// A single editable custom header name/value pair.
    ///
    struct CustomHeaderField: Equatable, Identifiable {
        /// A unique identifier for the field, used to target edits and removals.
        let id: UUID

        /// Whether the header value, which may contain a credential, is shown in plain text.
        var isValueVisible: Bool

        /// The header name.
        var name: String

        /// The header value.
        var value: String

        /// Initialize a `CustomHeaderField`.
        ///
        /// - Parameters:
        ///   - id: A unique identifier for the field.
        ///   - isValueVisible: Whether the header value is shown in plain text.
        ///   - name: The header name.
        ///   - value: The header value.
        ///
        init(id: UUID = UUID(), isValueVisible: Bool = false, name: String = "", value: String = "") {
            self.id = id
            self.isValueVisible = isValueVisible
            self.name = name
            self.value = value
        }
    }

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

    // MARK: Custom Headers

    /// The custom header fields being edited.
    var customHeaders: [CustomHeaderField] = []

    /// The identifier of the currently stored custom headers.
    var customHeadersId: String = ""

    /// The custom header fields as a dictionary of trimmed, non-empty name/value pairs.
    var customHeadersDictionary: [String: String] {
        customHeaders.reduce(into: [:]) { result, field in
            let name = field.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let value = field.value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, !value.isEmpty else { return }
            result[name] = value
        }
    }

    // MARK: Certificate Import Dialog

    /// The active dialog state for the client certificate section.
    var dialog: DialogState?

    /// The certificate data temporarily stored while waiting for password input.
    var pendingCertificateData: Data?

    /// Whether the certificate file importer is showing.
    var showingCertificateImporter: Bool = false
}
