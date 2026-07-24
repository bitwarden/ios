import BitwardenSdk
import Foundation

// MARK: - SafariExtensionMatchedLoginResolver

struct SafariExtensionMatchedLoginResolver: SafariExtensionMatchedLoginResolving {
    private let cipherMatchingHelperFactory: CipherMatchingHelperFactory
    private let ciphersClientWrapperService: CiphersClientWrapperService
    private let cipherService: CipherService
    private let stateService: StateService

    init(
        cipherMatchingHelperFactory: CipherMatchingHelperFactory,
        ciphersClientWrapperService: CiphersClientWrapperService,
        cipherService: CipherService,
        stateService: StateService,
    ) {
        self.cipherMatchingHelperFactory = cipherMatchingHelperFactory
        self.ciphersClientWrapperService = ciphersClientWrapperService
        self.cipherService = cipherService
        self.stateService = stateService
    }

    func resolveMatchedLogin(for request: SafariExtensionRequest) async throws -> SafariExtensionMatchedLogin? {
        guard let uri = request.urlString, !uri.isEmpty else {
            return nil
        }

        let ciphers = try await cipherService.fetchAllCiphers()
        guard !ciphers.isEmpty else {
            return nil
        }

        let matchingHelper = await cipherMatchingHelperFactory.make(uri: uri)
        let ciphersById = Dictionary(uniqueKeysWithValues: ciphers.compactMap { cipher in
            cipher.id.map { ($0, cipher) }
        })

        var matchedLogin: SafariExtensionMatchedLogin?
        await ciphersClientWrapperService.decryptAndProcessCiphersInBatch(
            ciphers: ciphers,
            onCipher: { decryptedCipher in
                guard matchedLogin == nil,
                      matchingHelper.doesCipherMatch(cipher: decryptedCipher, archiveVaultItemsFF: false) != .none,
                      let id = decryptedCipher.id,
                      let sourceCipher = ciphersById[id] else {
                    return
                }

                matchedLogin = SafariExtensionMatchedLogin(
                    id: id,
                    username: decryptedCipher.type.loginListView?.username,
                    password: sourceCipher.login?.password,
                    urlString: sourceCipher.login?.uris?.first?.uri,
                )
            },
        )

        _ = stateService
        return matchedLogin
    }
}

#if DEBUG && targetEnvironment(simulator)
struct SafariExtensionSimulatorLocalVaultResolver: SafariExtensionMatchedLoginResolving {
    private let cipherService: CipherService
    private let fallbackResolver: any SafariExtensionMatchedLoginResolving

    init(
        cipherService: CipherService,
        fallbackResolver: any SafariExtensionMatchedLoginResolving
    ) {
        self.cipherService = cipherService
        self.fallbackResolver = fallbackResolver
    }

    func resolveMatchedLogin(for request: SafariExtensionRequest) async throws -> SafariExtensionMatchedLogin? {
        guard let requestURLString = request.urlString,
              let requestURL = URL(string: requestURLString),
              let requestHost = requestURL.host else {
            return try? await fallbackResolver.resolveMatchedLogin(for: request)
        }

        if Self.isLocalFixtureURL(requestURL) {
            return SafariExtensionMatchedLogin(
                id: "safari-fixture-cipher",
                username: "safari-fixture@example.com",
                password: "safari-fixture-password",
                urlString: requestURLString,
            )
        }

        if let matchedLogin = try? await fallbackResolver.resolveMatchedLogin(for: request) {
            return matchedLogin
        }

        for cipher in try await cipherService.fetchAllCiphers() {
            guard cipher.id == "safari-fixture-cipher" || cipher.name == "Bitwarden Safari Dev Fixture",
                  let login = cipher.login,
                  let username = login.username,
                  let password = login.password,
                  let id = cipher.id,
                  login.uris?.contains(where: { uri in
                      guard let uriString = uri.uri,
                            let storedURL = URL(string: uriString),
                            let storedHost = storedURL.host else {
                          return false
                      }
                      return uriString == requestURLString || storedHost == requestHost
                  }) == true else {
                continue
            }

            return SafariExtensionMatchedLogin(
                id: id,
                username: username,
                password: password,
                urlString: login.uris?.first?.uri,
            )
        }

        return nil
    }

    private static func isLocalFixtureURL(_ url: URL) -> Bool {
        guard let host = url.host else {
            return false
        }
        return ["localhost", "127.0.0.1", "::1"].contains(host)
            && url.port == 8123
            && url.path.hasSuffix("/login.html")
    }
}
#endif
