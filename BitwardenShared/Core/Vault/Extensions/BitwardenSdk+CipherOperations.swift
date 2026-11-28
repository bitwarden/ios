// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenSdk

// MARK: - CipherCreateRequest

extension CipherCreateRequest {
    /// Initializes a `CipherCreateRequest` from a new `CipherView`.
    ///
    /// The SDK generates a new cipher key when creating the cipher and encrypts all of the cipher's
    /// data with it, so any `key` on the view isn't sent. Attachments aren't sent since their keys
    /// are encrypted with the view's cipher key; attachments are added after the cipher is created.
    ///
    /// - Parameter cipherView: The cipher view to create.
    /// - Throws: `DataMappingError.invalidData` if the view's type-specific data is missing.
    ///
    init(cipherView: CipherView) throws {
        try self.init(
            organizationId: cipherView.organizationId,
            collectionIds: cipherView.collectionIds,
            folderId: cipherView.folderId,
            name: cipherView.name,
            notes: cipherView.notes,
            favorite: cipherView.favorite,
            reprompt: cipherView.reprompt,
            type: CipherViewType(cipherView: cipherView),
            fields: cipherView.fields ?? [],
            archivedDate: cipherView.archivedDate,
        )
    }
}

// MARK: - CipherEditRequest

extension CipherEditRequest {
    /// Initializes a `CipherEditRequest` from an existing `CipherView`.
    ///
    /// This mirrors the SDK's `CipherView` to `CipherEditRequest` conversion. The cipher's `key` is
    /// preserved so data encrypted with it (e.g. Fido2 credentials and attachment keys) remains
    /// decryptable. Password history isn't sent; the SDK derives it from the stored cipher.
    ///
    /// - Parameter cipherView: The cipher view containing the edits.
    /// - Throws: `DataMappingError.missingId` if the view doesn't have an ID, or
    ///   `DataMappingError.invalidData` if the view's type-specific data is missing.
    ///
    init(cipherView: CipherView) throws {
        guard let id = cipherView.id else { throw DataMappingError.missingId }
        try self.init(
            id: id,
            organizationId: cipherView.organizationId,
            folderId: cipherView.folderId,
            favorite: cipherView.favorite,
            reprompt: cipherView.reprompt,
            name: cipherView.name,
            notes: cipherView.notes,
            fields: cipherView.fields ?? [],
            type: CipherViewType(cipherView: cipherView),
            revisionDate: cipherView.revisionDate,
            archivedDate: cipherView.archivedDate,
            attachments: cipherView.attachments ?? [],
            key: cipherView.key,
        )
    }
}

// MARK: - CipherPartialEditRequest

extension CipherPartialEditRequest {
    /// Initializes a `CipherPartialEditRequest` from an existing `CipherView`, used to update the
    /// folder and favorite status of a cipher that the user doesn't have permission to edit.
    ///
    /// - Parameter cipherView: The cipher view containing the edits.
    /// - Throws: `DataMappingError.missingId` if the view doesn't have an ID.
    ///
    init(cipherView: CipherView) throws {
        guard let id = cipherView.id else { throw DataMappingError.missingId }
        self.init(
            id: id,
            folderId: cipherView.folderId,
            favorite: cipherView.favorite,
        )
    }
}

// MARK: - CipherViewType

extension CipherViewType {
    /// Initializes a `CipherViewType` from the type-specific data of a `CipherView`.
    ///
    /// - Parameter cipherView: The cipher view containing the type-specific data.
    /// - Throws: `DataMappingError.invalidData` if the data for the view's type is missing.
    ///
    init(cipherView: CipherView) throws {
        let viewType: CipherViewType? = switch cipherView.type {
        case .bankAccount: cipherView.bankAccount.map(CipherViewType.bankAccount)
        case .card: cipherView.card.map(CipherViewType.card)
        case .driversLicense: cipherView.driversLicense.map(CipherViewType.driversLicense)
        case .identity: cipherView.identity.map(CipherViewType.identity)
        case .login: cipherView.login.map(CipherViewType.login)
        case .passport: cipherView.passport.map(CipherViewType.passport)
        case .secureNote: cipherView.secureNote.map(CipherViewType.secureNote)
        case .sshKey: cipherView.sshKey.map(CipherViewType.sshKey)
        }
        guard let viewType else { throw DataMappingError.invalidData }
        self = viewType
    }
}

// MARK: - CiphersClientProtocol

extension CiphersClientProtocol {
    /// Creates a new cipher with the SDK, which saves it to the server and local storage.
    ///
    /// - Parameter cipherView: The cipher view to create.
    /// - Returns: The created cipher.
    /// - Throws: A `ServerError` if the server rejected the request, otherwise the underlying error.
    ///
    func createCipher(_ cipherView: CipherView) async throws -> CipherView {
        let request = try CipherCreateRequest(cipherView: cipherView)
        return try await ServerError.mappingSdkApiErrors {
            try await create(request: request)
        }
    }

    /// Saves the edits to an existing cipher with the SDK, which saves it to the server and local
    /// storage. If the user doesn't have permission to edit the cipher, only the folder and
    /// favorite status are updated.
    ///
    /// - Parameter cipherView: The cipher view containing the edits.
    /// - Returns: The updated cipher.
    /// - Throws: A `ServerError` if the server rejected the request (e.g. the cipher is out of
    ///   date), otherwise the underlying error.
    ///
    func editCipher(_ cipherView: CipherView) async throws -> CipherView {
        if cipherView.edit {
            let request = try CipherEditRequest(cipherView: cipherView)
            return try await ServerError.mappingSdkApiErrors {
                try await edit(request: request)
            }
        } else {
            let request = try CipherPartialEditRequest(cipherView: cipherView)
            return try await ServerError.mappingSdkApiErrors {
                try await editPartial(request: request)
            }
        }
    }
}
