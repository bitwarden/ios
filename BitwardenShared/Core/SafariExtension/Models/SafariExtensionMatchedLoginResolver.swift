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
