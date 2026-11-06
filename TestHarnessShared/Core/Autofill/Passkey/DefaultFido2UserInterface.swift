import BitwardenSdk
import Foundation

// MARK: - DefaultFido2UserInterface

/// A minimal `Fido2UserInterface` implementation for the passkey scenarios. There's
/// no vault, biometrics, or master password reprompt to mediate here, so this always approves
/// user checks and synthesizes a single throwaway login item for new credentials.
///
final class DefaultFido2UserInterface: Fido2UserInterface, Sendable {
    // MARK: Methods

    func checkUser(options: CheckUserOptions, hint: UiHint) async throws -> CheckUserResult {
        CheckUserResult(userPresent: true, userVerified: true)
    }

    func checkUserAndPickCredentialForCreation(
        options: CheckUserOptions,
        newCredential: Fido2CredentialNewView,
    ) async throws -> CheckUserAndPickCredentialForCreationResult {
        let cipherView = CipherView(
            id: UUID().uuidString,
            organizationId: nil,
            folderId: nil,
            collectionIds: [],
            key: nil,
            name: newCredential.rpName ?? newCredential.rpId,
            notes: nil,
            type: .login,
            login: LoginView(
                username: newCredential.userName,
                password: nil,
                passwordRevisionDate: nil,
                uris: nil,
                totp: nil,
                autofillOnPageLoad: nil,
                fido2Credentials: nil,
            ),
            identity: nil,
            card: nil,
            secureNote: nil,
            sshKey: nil,
            bankAccount: nil,
            driversLicense: nil,
            passport: nil,
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
            creationDate: newCredential.creationDate,
            deletedDate: nil,
            revisionDate: newCredential.creationDate,
            archivedDate: nil,
        )
        return CheckUserAndPickCredentialForCreationResult(
            cipher: CipherViewWrapper(cipher: cipherView),
            checkUserResult: CheckUserResult(userPresent: true, userVerified: true),
        )
    }

    func isVerificationEnabled() -> Bool {
        false
    }

    func pickCredentialForAuthentication(availableCredentials: [CipherView]) async throws -> CipherViewWrapper {
        guard availableCredentials.count == 1, let onlyCredential = availableCredentials.first else {
            throw availableCredentials.isEmpty
                ? PasskeyError.noMatchingCredential
                : PasskeyError.ambiguousCredential
        }
        return CipherViewWrapper(cipher: onlyCredential)
    }
}
