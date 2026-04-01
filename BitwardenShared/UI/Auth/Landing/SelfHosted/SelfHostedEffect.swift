import Foundation

// MARK: - SelfHostedEffect

/// Effects performed by the `SelfHostedProcessor`.
///
enum SelfHostedEffect: Equatable {
    /// The view appeared.
    case appeared

    /// Import a client certificate with the given data, alias, and password.
    case importClientCertificate(data: Data, alias: String, password: String)

    /// Remove the current client certificate.
    case removeClientCertificate

    /// The self-hosted environment configuration was saved.
    case saveEnvironment
}
