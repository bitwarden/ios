// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenSdk
import BitwardenSdkMocks
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - BitwardenSdkCipherOperationsTests

struct BitwardenSdkCipherOperationsTests {
    // MARK: Properties

    /// An SDK API error message for an out of date cipher, in the format the SDK produces.
    let outOfDateMessage = """
    error in response: status code 400 Bad Request: {"message":"The cipher you are updating is out \
    of date.","validationErrors":null,"object":"error"}
    """

    // MARK: Tests - CipherCreateRequest

    /// `CipherCreateRequest(cipherView:)` maps the cipher view's properties to the request.
    @Test
    func cipherCreateRequest_init() throws {
        let archivedDate = Date(year: 2024, month: 1, day: 2)
        let field = FieldView.fixture(name: "Field", value: "Value")
        let login = LoginView.fixture(
            fido2Credentials: [.fixture(credentialId: "credential-id")],
            password: "password",
            username: "user",
        )
        let cipherView = CipherView.loginFixture(
            archivedDate: archivedDate,
            attachments: [.fixture()],
            collectionIds: ["collection-1"],
            favorite: true,
            fields: [field],
            folderId: "folder-1",
            key: "key",
            login: login,
            name: "Name",
            notes: "Notes",
            organizationId: "org-1",
            reprompt: .password,
        )

        let subject = try CipherCreateRequest(cipherView: cipherView)

        #expect(subject == CipherCreateRequest(
            organizationId: "org-1",
            collectionIds: ["collection-1"],
            folderId: "folder-1",
            name: "Name",
            notes: "Notes",
            favorite: true,
            reprompt: .password,
            type: .login(login),
            fields: [field],
            archivedDate: archivedDate,
        ))
    }

    /// `CipherCreateRequest(cipherView:)` sends empty fields if the cipher view has none.
    @Test
    func cipherCreateRequest_init_nilFields() throws {
        let subject = try CipherCreateRequest(cipherView: .fixture(fields: nil, login: .fixture()))
        #expect(subject.fields.isEmpty)
    }

    /// `CipherCreateRequest(cipherView:)` throws if the cipher view is missing its type data.
    @Test
    func cipherCreateRequest_init_missingTypeData() {
        #expect(throws: DataMappingError.invalidData) {
            try CipherCreateRequest(cipherView: .fixture(login: nil, type: .login))
        }
    }

    // MARK: Tests - CipherEditRequest

    /// `CipherEditRequest(cipherView:)` maps the cipher view's properties to the request,
    /// preserving the cipher key, revision date, and attachments.
    @Test
    func cipherEditRequest_init() throws {
        let archivedDate = Date(year: 2024, month: 1, day: 2)
        let revisionDate = Date(year: 2024, month: 3, day: 4)
        let attachment = AttachmentView.fixture(id: "attachment-1")
        let field = FieldView.fixture(name: "Field", value: "Value")
        let login = LoginView.fixture(password: "password", username: "user")
        let cipherView = CipherView.loginFixture(
            archivedDate: archivedDate,
            attachments: [attachment],
            favorite: true,
            fields: [field],
            folderId: "folder-1",
            id: "cipher-1",
            key: "key",
            login: login,
            name: "Name",
            notes: "Notes",
            organizationId: "org-1",
            reprompt: .password,
            revisionDate: revisionDate,
        )

        let subject = try CipherEditRequest(cipherView: cipherView)

        #expect(subject == CipherEditRequest(
            id: "cipher-1",
            organizationId: "org-1",
            folderId: "folder-1",
            favorite: true,
            reprompt: .password,
            name: "Name",
            notes: "Notes",
            fields: [field],
            type: .login(login),
            revisionDate: revisionDate,
            archivedDate: archivedDate,
            attachments: [attachment],
            key: "key",
        ))
    }

    /// `CipherEditRequest(cipherView:)` sends empty fields and attachments if the cipher view has
    /// none.
    @Test
    func cipherEditRequest_init_nilFieldsAndAttachments() throws {
        let subject = try CipherEditRequest(cipherView: .fixture(attachments: nil, fields: nil, login: .fixture()))
        #expect(subject.attachments.isEmpty)
        #expect(subject.fields.isEmpty)
    }

    /// `CipherEditRequest(cipherView:)` throws if the cipher view doesn't have an ID.
    @Test
    func cipherEditRequest_init_missingId() {
        #expect(throws: DataMappingError.missingId) {
            try CipherEditRequest(cipherView: .fixture(id: nil, login: .fixture()))
        }
    }

    /// `CipherEditRequest(cipherView:)` throws if the cipher view is missing its type data.
    @Test
    func cipherEditRequest_init_missingTypeData() {
        #expect(throws: DataMappingError.invalidData) {
            try CipherEditRequest(cipherView: .fixture(card: nil, type: .card))
        }
    }

    // MARK: Tests - CipherPartialEditRequest

    /// `CipherPartialEditRequest(cipherView:)` maps the folder and favorite status to the request.
    @Test
    func cipherPartialEditRequest_init() throws {
        let subject = try CipherPartialEditRequest(cipherView: .fixture(favorite: true, folderId: "folder-1", id: "1"))
        #expect(subject == CipherPartialEditRequest(id: "1", folderId: "folder-1", favorite: true))
    }

    /// `CipherPartialEditRequest(cipherView:)` throws if the cipher view doesn't have an ID.
    @Test
    func cipherPartialEditRequest_init_missingId() {
        #expect(throws: DataMappingError.missingId) {
            try CipherPartialEditRequest(cipherView: .fixture(id: nil))
        }
    }

    // MARK: Tests - CipherViewType

    /// `CipherViewType(cipherView:)` maps each cipher type's data.
    @Test
    func cipherViewType_init() throws {
        let bankAccount = CipherView.bankAccountFixture()
        let card = CipherView.cardFixture()
        let driversLicense = CipherView.driversLicenseFixture()
        let identity = CipherView.fixture(identity: .fixture(), type: .identity)
        let login = CipherView.loginFixture()
        let passport = CipherView.passportFixture()
        let secureNote = CipherView.fixture(secureNote: SecureNoteView(type: .generic), type: .secureNote)
        let sshKey = CipherView.fixture(sshKey: .fixture(), type: .sshKey)

        #expect(try CipherViewType(cipherView: bankAccount) == .bankAccount(#require(bankAccount.bankAccount)))
        #expect(try CipherViewType(cipherView: card) == .card(#require(card.card)))
        #expect(
            try CipherViewType(cipherView: driversLicense) == .driversLicense(#require(driversLicense.driversLicense)),
        )
        #expect(try CipherViewType(cipherView: identity) == .identity(#require(identity.identity)))
        #expect(try CipherViewType(cipherView: login) == .login(#require(login.login)))
        #expect(try CipherViewType(cipherView: passport) == .passport(#require(passport.passport)))
        #expect(try CipherViewType(cipherView: secureNote) == .secureNote(#require(secureNote.secureNote)))
        #expect(try CipherViewType(cipherView: sshKey) == .sshKey(#require(sshKey.sshKey)))
    }

    /// `CipherViewType(cipherView:)` throws if the data for the cipher's type is missing, even if
    /// data for another type is present.
    @Test
    func cipherViewType_init_missingTypeData() {
        #expect(throws: DataMappingError.invalidData) {
            try CipherViewType(cipherView: .fixture(login: .fixture(), sshKey: nil, type: .sshKey))
        }
    }

    // MARK: Tests - CiphersClientProtocol

    /// `createCipher(_:)` creates the cipher with the SDK and returns the created cipher.
    @Test
    func createCipher() async throws {
        let ciphersClient = MockCiphersClientProtocol()
        let createdCipher = CipherView.fixture(id: "created")
        ciphersClient.createReturnValue = createdCipher
        let cipherView = CipherView.fixture(id: nil, login: .fixture(username: "user"))

        let result = try await ciphersClient.createCipher(cipherView)

        #expect(result == createdCipher)
        #expect(try ciphersClient.createReceivedRequest == CipherCreateRequest(cipherView: cipherView))
    }

    /// `createCipher(_:)` converts a server error response to a `ServerError`.
    @Test
    func createCipher_serverError() async throws {
        let ciphersClient = MockCiphersClientProtocol()
        ciphersClient.createThrowableError = BitwardenSdk.BitwardenError.CreateCipher(.Api(message: outOfDateMessage))
        let serverError = try #require(ServerError(sdkApiErrorMessage: outOfDateMessage))

        await #expect(throws: serverError) {
            try await ciphersClient.createCipher(.fixture(login: .fixture()))
        }
    }

    /// `editCipher(_:)` edits the cipher with the SDK when the user can edit the cipher.
    @Test
    func editCipher() async throws {
        let ciphersClient = MockCiphersClientProtocol()
        let updatedCipher = CipherView.fixture(id: "1", name: "Updated")
        ciphersClient.editReturnValue = updatedCipher
        let cipherView = CipherView.fixture(edit: true, id: "1", login: .fixture())

        let result = try await ciphersClient.editCipher(cipherView)

        #expect(result == updatedCipher)
        #expect(try ciphersClient.editReceivedRequest == CipherEditRequest(cipherView: cipherView))
        #expect(!ciphersClient.editPartialCalled)
    }

    /// `editCipher(_:)` only updates the folder and favorite status with the SDK when the user
    /// can't edit the cipher.
    @Test
    func editCipher_cannotEdit() async throws {
        let ciphersClient = MockCiphersClientProtocol()
        let updatedCipher = CipherView.fixture(favorite: true, id: "1")
        ciphersClient.editPartialReturnValue = updatedCipher
        let cipherView = CipherView.fixture(edit: false, favorite: true, folderId: "folder-1", id: "1")

        let result = try await ciphersClient.editCipher(cipherView)

        #expect(result == updatedCipher)
        #expect(ciphersClient.editPartialReceivedRequest == CipherPartialEditRequest(
            id: "1",
            folderId: "folder-1",
            favorite: true,
        ))
        #expect(!ciphersClient.editCalled)
    }

    /// `editCipher(_:)` converts a server error response to a `ServerError`.
    @Test
    func editCipher_serverError() async throws {
        let ciphersClient = MockCiphersClientProtocol()
        ciphersClient.editThrowableError = BitwardenSdk.BitwardenError.EditCipher(.Api(message: outOfDateMessage))
        let serverError = try #require(ServerError(sdkApiErrorMessage: outOfDateMessage))

        await #expect(throws: serverError) {
            try await ciphersClient.editCipher(.fixture(id: "1", login: .fixture()))
        }
    }

    /// `editCipher(_:)` converts a server error response from a partial edit to a `ServerError`.
    @Test
    func editCipher_cannotEdit_serverError() async throws {
        let ciphersClient = MockCiphersClientProtocol()
        ciphersClient.editPartialThrowableError = BitwardenSdk.BitwardenError.EditCipher(
            .Api(message: outOfDateMessage),
        )
        let serverError = try #require(ServerError(sdkApiErrorMessage: outOfDateMessage))

        await #expect(throws: serverError) {
            try await ciphersClient.editCipher(.fixture(edit: false, id: "1"))
        }
    }

    // MARK: Tests - FileUploadType

    /// `FileUploadType(_:)` maps the SDK's attachment file upload type.
    @Test
    func fileUploadType_init() {
        #expect(FileUploadType(AttachmentFileUploadType.azure) == .azure)
        #expect(FileUploadType(AttachmentFileUploadType.direct) == .direct)
    }
}
