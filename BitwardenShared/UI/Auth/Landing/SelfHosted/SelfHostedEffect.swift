import Foundation

// MARK: - SelfHostedEffect

/// Effects performed by the `SelfHostedProcessor`.
///
enum SelfHostedEffect: Equatable {
    /// The self-hosted environment configuration was saved.
    case saveEnvironment

    /// Import a client certificate from file data.
    case importClientCertificate(Data, String)

    /// Import a client certificate using the stored data and entered password.
    case importClientCertificateWithPassword

    /// Remove the current client certificate.
    case removeClientCertificate

    // MARK: Equatable

    static func == (lhs: SelfHostedEffect, rhs: SelfHostedEffect) -> Bool {
        switch (lhs, rhs) {
        case let (.importClientCertificate(lhsData, lhsPassword), .importClientCertificate(rhsData, rhsPassword)):
            return lhsData == rhsData && lhsPassword == rhsPassword
        case (.importClientCertificateWithPassword, .importClientCertificateWithPassword),
             (.removeClientCertificate, .removeClientCertificate),
             (.saveEnvironment, .saveEnvironment):
            return true
        default:
            return false
        }
    }
}
