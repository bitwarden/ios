import BitwardenSdk

/// Builder to be used to create helper objects for the Credential Exchange flow.
protocol CXFCredentialsResultBuilder {
    /// Builds the credentials result for the Credential Exchange flow UI.
    /// - Parameter ciphers: Ciphers to build the results.
    /// - Returns: Returns an array to be used in the Credential Exchange UI.
    func build(from ciphers: [Cipher]) -> [CXFCredentialsResult]
}

struct DefaultCXFCredentialsResultBuilder: CXFCredentialsResultBuilder {
    func build(from ciphers: [BitwardenSdk.Cipher]) -> [CXFCredentialsResult] {
        [
            CXFCredentialsResult(
                count: ciphers.count { $0.type == .login && $0.login?.fido2Credentials?.isEmpty != false },
                type: .password,
            ),
            CXFCredentialsResult(
                count: ciphers.count { $0.type == .login && $0.login?.fido2Credentials?.isEmpty == false },
                type: .passkey,
            ),
            CXFCredentialsResult(
                count: ciphers.count { $0.type == .card },
                type: .card,
            ),
            CXFCredentialsResult(
                count: ciphers.count { $0.type == .identity },
                type: .identity,
            ),
            CXFCredentialsResult(
                count: ciphers.count { $0.type == .secureNote },
                type: .secureNote,
            ),
            CXFCredentialsResult(
                count: ciphers.count { $0.type == .sshKey },
                type: .sshKey,
            ),
        ]
    }
}
