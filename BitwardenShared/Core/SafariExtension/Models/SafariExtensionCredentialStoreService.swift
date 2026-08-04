import BitwardenKit
import BitwardenSdk
import Foundation

protocol SafariExtensionCredentialStoring {
    func saveCredential(
        for request: SafariExtensionRequest,
        matchedLogin: SafariExtensionMatchedLogin?,
        submissionAction: SafariExtensionSubmissionAction
    ) async throws
}

final class SafariExtensionCredentialStoreService: SafariExtensionCredentialStoring {
    private let cipherService: CipherService
    private let clientService: ClientService
    private let nowProvider: () -> Date

    init(
        cipherService: CipherService,
        clientService: ClientService,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.cipherService = cipherService
        self.clientService = clientService
        self.nowProvider = nowProvider
    }

    func saveCredential(
        for request: SafariExtensionRequest,
        matchedLogin: SafariExtensionMatchedLogin?,
        submissionAction: SafariExtensionSubmissionAction
    ) async throws {
        let cipherView = try await makeCipherView(
            for: request,
            matchedLogin: matchedLogin,
            submissionAction: submissionAction
        )
        let encryptionContext = try await clientService.vault().ciphers().encrypt(cipherView: cipherView)

        switch submissionAction {
        case .saveNewLogin:
            try await cipherService.addCipherWithServer(
                encryptionContext.cipher,
                encryptedFor: encryptionContext.encryptedFor
            )
        case .updateExistingLogin, .updatePassword:
            try await cipherService.updateCipherWithServer(
                encryptionContext.cipher,
                encryptedFor: encryptionContext.encryptedFor
            )
        default:
            break
        }
    }

    private func makeCipherView(
        for request: SafariExtensionRequest,
        matchedLogin: SafariExtensionMatchedLogin?,
        submissionAction: SafariExtensionSubmissionAction
    ) async throws -> CipherView {
        switch submissionAction {
        case .saveNewLogin:
            return CipherView(
                id: nil,
                organizationId: nil,
                folderId: nil,
                collectionIds: [],
                key: nil,
                name: resolvedName(for: request, fallback: "Login", prefersURLFallback: true),
                notes: normalized(request.notes),
                type: .login,
                login: BitwardenSdk.LoginView(
                    username: normalized(request.username),
                    password: normalized(request.password),
                    passwordRevisionDate: normalized(request.password) == nil ? nil : nowProvider(),
                    uris: resolvedUris(from: request.urlString),
                    totp: nil,
                    autofillOnPageLoad: nil,
                    fido2Credentials: nil
                ),
                identity: nil,
                card: nil,
                secureNote: nil,
                sshKey: nil,
                favorite: false,
                reprompt: .none,
                organizationUseTotp: false,
                edit: true,
                permissions: nil,
                viewPassword: true,
                localData: nil,
                attachments: nil,
                attachmentDecryptionFailures: nil,
                fields: nil,
                passwordHistory: nil,
                creationDate: nowProvider(),
                deletedDate: nil,
                revisionDate: nowProvider(),
                archivedDate: nil
            )
        case .updateExistingLogin, .updatePassword:
            guard let cipherID = matchedLogin?.id,
                  let existingCipher = try await cipherService.fetchCipher(withId: cipherID) else {
                throw CocoaError(.fileNoSuchFile)
            }
            let existingCipherView = try await clientService.vault().ciphers().decrypt(cipher: existingCipher)
            let existingLogin = existingCipherView.login
            let password = normalized(request.password) ?? existingLogin?.password
            let updatedLogin = BitwardenSdk.LoginView(
                username: submissionAction == .updatePassword
                    ? existingLogin?.username
                    : normalized(request.username) ?? existingLogin?.username,
                password: password,
                passwordRevisionDate: password == existingLogin?.password
                    ? existingLogin?.passwordRevisionDate
                    : nowProvider(),
                uris: resolvedUris(from: request.urlString) ?? existingLogin?.uris,
                totp: existingLogin?.totp,
                autofillOnPageLoad: existingLogin?.autofillOnPageLoad,
                fido2Credentials: existingLogin?.fido2Credentials
            )
            return CipherView(
                id: existingCipherView.id,
                organizationId: existingCipherView.organizationId,
                folderId: existingCipherView.folderId,
                collectionIds: existingCipherView.collectionIds,
                key: existingCipherView.key,
                name: resolvedName(for: request, fallback: existingCipherView.name, prefersURLFallback: false),
                notes: normalized(request.notes) ?? existingCipherView.notes,
                type: existingCipherView.type,
                login: updatedLogin,
                identity: existingCipherView.identity,
                card: existingCipherView.card,
                secureNote: existingCipherView.secureNote,
                sshKey: existingCipherView.sshKey,
                favorite: existingCipherView.favorite,
                reprompt: existingCipherView.reprompt,
                organizationUseTotp: existingCipherView.organizationUseTotp,
                edit: existingCipherView.edit,
                permissions: existingCipherView.permissions,
                viewPassword: existingCipherView.viewPassword,
                localData: existingCipherView.localData,
                attachments: existingCipherView.attachments,
                attachmentDecryptionFailures: existingCipherView.attachmentDecryptionFailures,
                fields: existingCipherView.fields,
                passwordHistory: existingCipherView.passwordHistory,
                creationDate: existingCipherView.creationDate,
                deletedDate: existingCipherView.deletedDate,
                revisionDate: nowProvider(),
                archivedDate: existingCipherView.archivedDate
            )
        default:
            throw CocoaError(.coderInvalidValue)
        }
    }

    private func normalized(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private func resolvedName(for request: SafariExtensionRequest, fallback: String, prefersURLFallback: Bool) -> String {
        if let loginTitle = normalized(request.loginTitle) {
            return loginTitle
        }
        if prefersURLFallback,
           let host = normalized(request.urlString).flatMap({ URL(string: $0)?.host }) {
            return host
        }
        return fallback
    }

    private func resolvedUris(from urlString: String?) -> [LoginUriView]? {
        guard let urlString = normalized(urlString) else {
            return nil
        }
        return [LoginUriView(uri: urlString, match: nil, uriChecksum: nil)]
    }
}
