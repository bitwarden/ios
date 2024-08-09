import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - TOTPServiceTests

final class TOTPServiceTests: BitwardenTestCase {
    // MARK: Properties

    var clientService: MockClientService!
    var pasteboardService: MockPasteboardService!
    var stateService: MockStateService!
    var subject: DefaultTOTPService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        clientService = MockClientService()
        pasteboardService = MockPasteboardService()
        stateService = MockStateService()

        subject = DefaultTOTPService(
            clientService: clientService,
            pasteboardService: pasteboardService,
            stateService: stateService
        )
    }

    override func tearDown() {
        super.tearDown()

        clientService = nil
        pasteboardService = nil
        subject = nil
    }

    // MARK: Tests

    /// `copyTotpIfPossible(cipher:)` succeeds copying the code.
    func test_copyTotpIfPossible_succeeds() async throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                totp: "totp"
            )
        )
        stateService.activeAccount = .fixture()

        try await subject.copyTotpIfPossible(cipher: cipher)

        XCTAssertEqual(pasteboardService.copiedString, "123456")
    }

    /// `copyTotpIfPossible(cipher:)` succeeds copying the code when account is not premium
    /// but organization uses totp..
    func test_copyTotpIfPossible_succeedsOrganizationUseTotp() async throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                totp: "totp"
            ),
            organizationUseTotp: true
        )
        stateService.activeAccount = .fixture()
        stateService.doesActiveAccountHavePremiumResult = .success(false)

        try await subject.copyTotpIfPossible(cipher: cipher)

        XCTAssertEqual(pasteboardService.copiedString, "123456")
    }

    /// `copyTotpIfPossible(cipher:)` doesn't copy the code because cipher doesn't have login.
    func test_copyTotpIfPossible_noLogin() async throws {
        let cipher = CipherView.fixture(
            login: nil
        )
        stateService.activeAccount = .fixture()

        try await subject.copyTotpIfPossible(cipher: cipher)

        XCTAssertNil(pasteboardService.copiedString)
    }

    /// `copyTotpIfPossible(cipher:)` doesn't copy the code because cipher doesn't have totp.
    func test_copyTotpIfPossible_noTotp() async throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                totp: nil
            )
        )
        stateService.activeAccount = .fixture()

        try await subject.copyTotpIfPossible(cipher: cipher)

        XCTAssertNil(pasteboardService.copiedString)
    }

    /// `copyTotpIfPossible(cipher:)` doesn't copy the code because auto copying totp is disabled.
    func test_copyTotpIfPossible_autoTotpCopyDisabled() async throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                totp: "totp"
            )
        )
        stateService.activeAccount = .fixture()
        stateService.disableAutoTotpCopyByUserId = ["1": true]

        try await subject.copyTotpIfPossible(cipher: cipher)

        XCTAssertNil(pasteboardService.copiedString)
    }

    /// `copyTotpIfPossible(cipher:)` doesn't copy the code because user not premium and
    /// organization doesn't use totp.
    func test_copyTotpIfPossible_noPremiumNorOrgUseTotp() async throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                totp: "totp"
            )
        )
        stateService.activeAccount = .fixture()
        stateService.doesActiveAccountHavePremiumResult = .success(false)

        try await subject.copyTotpIfPossible(cipher: cipher)

        XCTAssertNil(pasteboardService.copiedString)
    }

    /// `copyTotpIfPossible(cipher:)` throws when getting disable auto totp copy.
    func test_copyTotpIfPossible_throwsDisableAutoTotpCopy() async throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                totp: "totp"
            )
        )

        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            try await subject.copyTotpIfPossible(cipher: cipher)
        }

        XCTAssertNil(pasteboardService.copiedString)
    }

    /// `copyTotpIfPossible(cipher:)` throws when getting if current account has premium.
    func test_copyTotpIfPossible_throwsAccountPremium() async throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                totp: "totp"
            )
        )
        stateService.activeAccount = .fixture()
        stateService.doesActiveAccountHavePremiumResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.copyTotpIfPossible(cipher: cipher)
        }

        XCTAssertNil(pasteboardService.copiedString)
    }

    /// `copyTotpIfPossible(cipher:)` throws when generating code.
    func test_copyTotpIfPossible_throwsGeneratingCode() async throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                totp: "totp"
            )
        )
        stateService.activeAccount = .fixture()
        clientService.mockVault.generateTOTPCodeResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.copyTotpIfPossible(cipher: cipher)
        }

        XCTAssertNil(pasteboardService.copiedString)
    }

    func test_getTOTPConfiguration_base32() throws {
        let config = try subject.getTOTPConfiguration(key: .standardTotpKey)
        XCTAssertEqual(config.totpKey, .standard(key: .standardTotpKey))
    }

    func test_getTOTPConfiguration_otp() throws {
        let config = try subject.getTOTPConfiguration(key: .otpAuthUriKeyComplete)
        XCTAssertEqual(config.totpKey, .otpAuthUri(.init(otpAuthKey: .otpAuthUriKeyComplete)!))
    }

    func test_getTOTPConfiguration_steam() throws {
        let config = try subject.getTOTPConfiguration(key: .steamUriKey)
        XCTAssertEqual(config.totpKey, .steamUri(key: .steamUriKeyIdentifier))
    }

    func test_getTOTPConfiguration_unknown() throws {
        let keyWithSpaces = "key with spaces"
        let config = try subject.getTOTPConfiguration(key: keyWithSpaces)
        XCTAssertEqual(config.totpKey, .standard(key: keyWithSpaces))
    }

    func test_getTOTPConfiguration_failure() {
        XCTAssertThrowsError(try subject.getTOTPConfiguration(key: nil)) { error in
            XCTAssertEqual(error as? TOTPServiceError, .invalidKeyFormat)
        }
    }
}
