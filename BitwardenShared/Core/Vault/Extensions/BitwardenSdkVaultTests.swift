// swiftlint:disable:this file_name
// swiftlint:disable file_length

import BitwardenKitMocks
import BitwardenSdk
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - BitwardenSdk.CipherType

class BitwardenSdkVaultBitwardenCipherTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(type:)` initializes the SDK cipher type based on the cipher type.
    func test_init_byCipherType() {
        XCTAssertEqual(BitwardenSdk.CipherType(.login), .login)
        XCTAssertEqual(BitwardenSdk.CipherType(.card), .card)
        XCTAssertEqual(BitwardenSdk.CipherType(.identity), .identity)
        XCTAssertEqual(BitwardenSdk.CipherType(.secureNote), .secureNote)
        XCTAssertEqual(BitwardenSdk.CipherType(.sshKey), .sshKey)
        XCTAssertEqual(BitwardenSdk.CipherType(.bankAccount), .bankAccount)
        XCTAssertEqual(BitwardenSdk.CipherType(.driversLicense), .driversLicense)
        XCTAssertEqual(BitwardenSdk.CipherType(.passport), .passport)
    }
}

// MARK: - Cipher

class BitwardenSdkVaultCipherTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(responseModel:)` inits the correct Cipher from CipherDetailsResponseModel with `.sshKey` type.
    func test_init_fromCipherDetailsResponseModelWithSSHKey() {
        let responseModel = CipherDetailsResponseModel.fixture(
            id: "1",
            sshKey: .fixture(),
            type: .sshKey,
        )
        let cipher = Cipher(responseModel: responseModel)
        XCTAssertEqual(cipher.id, responseModel.id)
        XCTAssertEqual(Int(cipher.type.rawValue), responseModel.type.rawValue)
        XCTAssertEqual(cipher.sshKey?.publicKey, responseModel.sshKey?.publicKey)
        XCTAssertEqual(cipher.sshKey?.privateKey, responseModel.sshKey?.privateKey)
        XCTAssertEqual(cipher.sshKey?.fingerprint, responseModel.sshKey?.keyFingerprint)
    }
}

// MARK: - CipherDetailsResponseModel

class BitwardenSdkVaultCipherDetailsResponseModelTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(cipher:)` Inits a cipher details response model from an SDK cipher without id throws.
    func test_init_fromSdkNoIdThrows() throws {
        let cipher = Cipher.fixture(
            id: nil,
        )
        XCTAssertThrowsError(try CipherDetailsResponseModel(cipher: cipher))
    }

    /// `init(cipher:)` Inits a cipher details response model from an SDK cipher that is an SSH key.
    func test_init_fromSdkCipherSSHKey() throws {
        let cipher = Cipher.fixture(
            id: "1",
            sshKey: .fixture(),
            type: .sshKey,
        )
        let responseModel = try CipherDetailsResponseModel(cipher: cipher)
        XCTAssertEqual(responseModel.id, cipher.id)
        XCTAssertEqual(responseModel.sshKey?.privateKey, cipher.sshKey?.privateKey)
        XCTAssertEqual(responseModel.sshKey?.publicKey, cipher.sshKey?.publicKey)
        XCTAssertEqual(responseModel.sshKey?.keyFingerprint, cipher.sshKey?.fingerprint)
    }
}

// MARK: - CipherListViewType

class BitwardenSdkCipherListViewTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// `isLogin` returns whether the type is a login.
    func test_isLogin() {
        XCTAssertTrue(CipherListViewType.login(.fixture()).isLogin)
        XCTAssertFalse(CipherListViewType.card(.init(brand: nil)).isLogin)
        XCTAssertFalse(CipherListViewType.identity.isLogin)
        XCTAssertFalse(CipherListViewType.secureNote.isLogin)
        XCTAssertFalse(CipherListViewType.sshKey.isLogin)
    }

    /// `loginListView` returns the `LoginListView` when the type is `.login`.
    func test_loginListView() {
        let expectedResult = LoginListView.fixture(fido2Credentials: [.fixture()], hasFido2: true)
        XCTAssertEqual(
            CipherListViewType.login(expectedResult).loginListView,
            expectedResult,
        )
        XCTAssertNil(CipherListViewType.card(.init(brand: nil)).loginListView)
        XCTAssertNil(CipherListViewType.identity.loginListView)
        XCTAssertNil(CipherListViewType.secureNote.loginListView)
        XCTAssertNil(CipherListViewType.sshKey.loginListView)
    }
}

// MARK: - CipherBankAccountModel

class BitwardenSdkVaultCipherBankAccountModelTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(bankAccount:)` Inits cipher bank account model from the SDK one.
    func test_init_fromSdkBankAccount() {
        let model = CipherBankAccountModel(
            bankAccount: .init(
                bankName: "bankName",
                nameOnAccount: "nameOnAccount",
                accountType: "accountType",
                accountNumber: "accountNumber",
                routingNumber: "routingNumber",
                branchNumber: "branchNumber",
                pin: "pin",
                swiftCode: "swiftCode",
                iban: "iban",
                bankContactPhone: "bankContactPhone",
            ),
        )

        XCTAssertEqual(model.accountNumber, "accountNumber")
        XCTAssertEqual(model.accountType, "accountType")
        XCTAssertEqual(model.bankContactPhone, "bankContactPhone")
        XCTAssertEqual(model.bankName, "bankName")
        XCTAssertEqual(model.branchNumber, "branchNumber")
        XCTAssertEqual(model.iban, "iban")
        XCTAssertEqual(model.nameOnAccount, "nameOnAccount")
        XCTAssertEqual(model.pin, "pin")
        XCTAssertEqual(model.routingNumber, "routingNumber")
        XCTAssertEqual(model.swiftCode, "swiftCode")
    }
}

// MARK: - CipherDriversLicenseModel

class BitwardenSdkVaultCipherDriversLicenseModelTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(driversLicense:)` Inits cipher driver's license model from the SDK one.
    func test_init_fromSdkDriversLicense() {
        let model = CipherDriversLicenseModel(
            driversLicense: .init(
                firstName: "firstName",
                middleName: "middleName",
                lastName: "lastName",
                dateOfBirth: "dateOfBirth",
                licenseNumber: "licenseNumber",
                issuingCountry: "issuingCountry",
                issuingState: "issuingState",
                issueDate: "issueDate",
                expirationDate: "expirationDate",
                issuingAuthority: "issuingAuthority",
                licenseClass: "licenseClass",
            ),
        )

        XCTAssertEqual(model.dateOfBirth, "dateOfBirth")
        XCTAssertEqual(model.expirationDate, "expirationDate")
        XCTAssertEqual(model.firstName, "firstName")
        XCTAssertEqual(model.issueDate, "issueDate")
        XCTAssertEqual(model.issuingAuthority, "issuingAuthority")
        XCTAssertEqual(model.issuingCountry, "issuingCountry")
        XCTAssertEqual(model.issuingState, "issuingState")
        XCTAssertEqual(model.lastName, "lastName")
        XCTAssertEqual(model.licenseClass, "licenseClass")
        XCTAssertEqual(model.licenseNumber, "licenseNumber")
        XCTAssertEqual(model.middleName, "middleName")
    }
}

// MARK: - CipherPassportModel

class BitwardenSdkVaultCipherPassportModelTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(passport:)` Inits cipher passport model from the SDK one.
    func test_init_fromSdkPassport() {
        let model = CipherPassportModel(
            passport: .init(
                surname: "surname",
                givenName: "givenName",
                dateOfBirth: "dateOfBirth",
                sex: "sex",
                birthPlace: "birthPlace",
                nationality: "nationality",
                issuingCountry: "issuingCountry",
                passportNumber: "passportNumber",
                passportType: "passportType",
                nationalIdentificationNumber: "nationalIdentificationNumber",
                issuingAuthority: "issuingAuthority",
                issueDate: "issueDate",
                expirationDate: "expirationDate",
            ),
        )

        XCTAssertEqual(model.birthPlace, "birthPlace")
        XCTAssertEqual(model.dateOfBirth, "dateOfBirth")
        XCTAssertEqual(model.expirationDate, "expirationDate")
        XCTAssertEqual(model.givenName, "givenName")
        XCTAssertEqual(model.issueDate, "issueDate")
        XCTAssertEqual(model.issuingAuthority, "issuingAuthority")
        XCTAssertEqual(model.issuingCountry, "issuingCountry")
        XCTAssertEqual(model.nationalIdentificationNumber, "nationalIdentificationNumber")
        XCTAssertEqual(model.nationality, "nationality")
        XCTAssertEqual(model.passportNumber, "passportNumber")
        XCTAssertEqual(model.passportType, "passportType")
        XCTAssertEqual(model.sex, "sex")
        XCTAssertEqual(model.surname, "surname")
    }
}

// MARK: - CipherSSHKeyModel

class BitwardenSdkVaultCipherSSHKeyModelTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(sshKey:)` Inits cipher SSH key model from the SDK one.
    func test_init_fromSdkSSHKey() {
        let model = CipherSSHKeyModel(
            sshKey: .init(
                privateKey: "privateKey",
                publicKey: "publicKey",
                fingerprint: "fingerprint",
            ),
        )

        XCTAssertEqual(model.privateKey, "privateKey")
        XCTAssertEqual(model.publicKey, "publicKey")
        XCTAssertEqual(model.keyFingerprint, "fingerprint")
    }
}

// MARK: - CipherType

class BitwardenSdkVaultCipherTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(type:)` initializes the cipher type based on the SDK cipher type.
    func test_init_bySdkCipherType() {
        XCTAssertEqual(CipherType(type: .login), .login)
        XCTAssertEqual(CipherType(type: .card), .card)
        XCTAssertEqual(CipherType(type: .identity), .identity)
        XCTAssertEqual(CipherType(type: .secureNote), .secureNote)
        XCTAssertEqual(CipherType(type: .sshKey), .sshKey)
        XCTAssertEqual(CipherType(type: .bankAccount), .bankAccount)
        XCTAssertEqual(CipherType(type: .driversLicense), .driversLicense)
        XCTAssertEqual(CipherType(type: .passport), .passport)
    }

    /// `init(type:)` initializes the SDK cipher type based on the cipher list view type.
    func test_init_byCipherListViewType() {
        XCTAssertEqual(CipherType(CipherListViewType.login(.fixture())), .login)
        XCTAssertEqual(CipherType(CipherListViewType.card(.fixture())), .card)
        XCTAssertEqual(CipherType(CipherListViewType.identity), .identity)
        XCTAssertEqual(CipherType(CipherListViewType.secureNote), .secureNote)
        XCTAssertEqual(CipherType(CipherListViewType.sshKey), .sshKey)
        XCTAssertEqual(CipherType(CipherListViewType.bankAccount), .bankAccount)
        XCTAssertEqual(CipherType(CipherListViewType.driversLicense), .driversLicense)
        XCTAssertEqual(CipherType(CipherListViewType.passport), .passport)
    }
}

// MARK: - CipherView

class CipherViewTests: BitwardenTestCase {
    // MARK: Properties

    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        timeProvider = MockTimeProvider(.mockTime(Date(year: 2024, month: 6, day: 28)))
    }

    override func tearDown() {
        super.tearDown()

        timeProvider = nil
    }

    // MARK: Tests

    /// `init(fido2CredentialNewView:timeProvider:)` initializes correctly
    func test_init_fido2CredentialNewView_defaultValues() {
        let fido2CredentialNewView = Fido2CredentialNewView.fixture()
        let subject = CipherView(fido2CredentialNewView: fido2CredentialNewView, timeProvider: timeProvider)
        XCTAssertEqual(
            subject,
            CipherView(
                id: nil,
                organizationId: nil,
                folderId: nil,
                collectionIds: [],
                key: nil,
                name: "myApp.com",
                notes: nil,
                type: .login,
                login: BitwardenSdk.LoginView(
                    username: "",
                    password: nil,
                    passwordRevisionDate: nil,
                    uris: [
                        LoginUriView(uri: "myApp.com", match: nil, uriChecksum: nil),
                    ],
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
                edit: false,
                permissions: nil,
                viewPassword: true,
                localData: nil,
                attachments: nil,
                attachmentDecryptionFailures: nil,
                fields: nil,
                passwordHistory: nil,
                creationDate: timeProvider.presentTime,
                deletedDate: nil,
                revisionDate: timeProvider.presentTime,
                archivedDate: nil,
            ),
        )
    }

    /// `init(fido2CredentialNewView:timeProvider:)` initializes correctly with rpName and username
    func test_init_fido2CredentialNewView_rpNameUsername() { // swiftlint:disable:this function_body_length
        let fido2CredentialNewView = Fido2CredentialNewView.fixture(
            userName: "username",
            rpName: "MyApp",
        )
        let subject = CipherView(fido2CredentialNewView: fido2CredentialNewView, timeProvider: timeProvider)
        XCTAssertEqual(
            subject,
            CipherView(
                id: nil,
                organizationId: nil,
                folderId: nil,
                collectionIds: [],
                key: nil,
                name: "MyApp",
                notes: nil,
                type: .login,
                login: BitwardenSdk.LoginView(
                    username: "username",
                    password: nil,
                    passwordRevisionDate: nil,
                    uris: [
                        LoginUriView(uri: "myApp.com", match: nil, uriChecksum: nil),
                    ],
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
                edit: false,
                permissions: nil,
                viewPassword: true,
                localData: nil,
                attachments: nil,
                attachmentDecryptionFailures: nil,
                fields: nil,
                passwordHistory: nil,
                creationDate: timeProvider.presentTime,
                deletedDate: nil,
                revisionDate: timeProvider.presentTime,
                archivedDate: nil,
            ),
        )
    }
}

// MARK: - Collection

class BitwardenSdkVaultBitwardenCollectionTests: BitwardenTestCase {
    /// `init(collectionDetailsResponseModel:)` sets `manage` with the value in the model
    /// if the server sent a value
    func test_init_manageNotNull() {
        let trueManage = CollectionDetailsResponseModel.fixture(manage: true)
        XCTAssertTrue(Collection(collectionDetailsResponseModel: trueManage).manage)

        let falseManage = CollectionDetailsResponseModel.fixture(manage: false)
        XCTAssertFalse(Collection(collectionDetailsResponseModel: falseManage).manage)
    }

    /// `init(collectionDetailsResponseModel:)` sets `manage` based on `readOnly`
    /// if the server did not send a value for `manage`
    func test_init_manageNull() {
        let trueReadOnly = CollectionDetailsResponseModel.fixture(manage: nil, readOnly: true)
        XCTAssertFalse(Collection(collectionDetailsResponseModel: trueReadOnly).manage)

        let falseReadOnly = CollectionDetailsResponseModel.fixture(manage: nil, readOnly: false)
        XCTAssertTrue(Collection(collectionDetailsResponseModel: falseReadOnly).manage)
    }
}
