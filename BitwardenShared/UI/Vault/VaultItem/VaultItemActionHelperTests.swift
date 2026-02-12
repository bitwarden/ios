import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - VaultItemActionHelperTests

class VaultItemActionHelperTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<VaultItemRoute, VaultItemEvent>!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var vaultRepository: MockVaultRepository!
    var subject: VaultItemActionHelper!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<VaultItemRoute, VaultItemEvent>()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        vaultRepository = MockVaultRepository()
        subject = DefaultVaultItemActionHelper(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                environmentService: environmentService,
                errorReporter: errorReporter,
                vaultRepository: vaultRepository,
            ),
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        environmentService = nil
        errorReporter = nil
        vaultRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// `archive(cipher:handleOpenURL:completionHandler:)` shows the archive unavailable alert
    /// when the user does not have premium.
    @MainActor
    func test_archive_noPremium() async {
        var openedURL: URL?
        var completionCalled = false
        let cipher = CipherView.loginFixture(id: "123")

        vaultRepository.doesActiveAccountHavePremiumResult = false
        environmentService.upgradeToPremiumURL = URL(
            string: "https://example.com/someURLToUpgradeToPremium",
        )!

        await subject.archive(
            cipher: cipher,
            handleOpenURL: { openedURL = $0 },
            completionHandler: { completionCalled = true },
        )

        let alert = coordinator.alertShown.last
        XCTAssertEqual(alert?.title, Localizations.archiveUnavailable)
        XCTAssertEqual(alert?.message, Localizations.archivingItemsIsAPremiumFeatureDescriptionLong)

        XCTAssertTrue(vaultRepository.archiveCipher.isEmpty)
        XCTAssertFalse(completionCalled)

        try? await alert?.tapAction(title: Localizations.upgradeToPremium)
        XCTAssertEqual(
            openedURL,
            URL(string: "https://example.com/someURLToUpgradeToPremium"),
        )
    }

    /// `archive(cipher:handleOpenURL:completionHandler:)` shows the confirmation alert and
    /// archives the cipher when the user has premium and confirms.
    @MainActor
    func test_archive_success() async throws {
        var completionCalled = false
        let cipher = CipherView.loginFixture(id: "123")

        vaultRepository.doesActiveAccountHavePremiumResult = true
        vaultRepository.archiveCipherResult = .success(())

        await subject.archive(
            cipher: cipher,
            handleOpenURL: { _ in },
            completionHandler: { completionCalled = true },
        )

        XCTAssertEqual(coordinator.loadingOverlaysShown.last?.title, Localizations.sendingToArchive)

        XCTAssertEqual(vaultRepository.archiveCipher.last?.id, "123")
        XCTAssertTrue(completionCalled)
        XCTAssertNil(errorReporter.errors.first)
    }

    /// `archive(cipher:handleOpenURL:completionHandler:)` shows an error alert when archiving fails.
    @MainActor
    func test_archive_error() async throws {
        var completionCalled = false
        let cipher = CipherView.loginFixture(id: "123")

        vaultRepository.doesActiveAccountHavePremiumResult = true
        vaultRepository.archiveCipherResult = .failure(BitwardenTestError.example)

        await subject.archive(
            cipher: cipher,
            handleOpenURL: { _ in },
            completionHandler: { completionCalled = true },
        )

        XCTAssertEqual(coordinator.errorAlertsShown.count, 1)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertFalse(completionCalled)
    }

    /// `unarchive(cipher:completionHandler:)` shows the confirmation alert and unarchives
    /// the cipher when the user confirms.
    @MainActor
    func test_unarchive_success() async throws {
        var completionCalled = false
        let cipher = CipherView.loginFixture(archivedDate: .now, id: "123")

        vaultRepository.unarchiveCipherResult = .success(())

        await subject.unarchive(
            cipher: cipher,
            completionHandler: { completionCalled = true },
        )

        XCTAssertEqual(coordinator.loadingOverlaysShown.last?.title, Localizations.movingItemToVault)

        XCTAssertEqual(vaultRepository.unarchiveCipher.last?.id, "123")
        XCTAssertTrue(completionCalled)
        XCTAssertNil(errorReporter.errors.first)
    }

    /// `unarchive(cipher:completionHandler:)` shows an error alert when unarchiving fails.
    @MainActor
    func test_unarchive_error() async throws {
        var completionCalled = false
        let cipher = CipherView.loginFixture(archivedDate: .now, id: "123")

        vaultRepository.unarchiveCipherResult = .failure(BitwardenTestError.example)

        await subject.unarchive(
            cipher: cipher,
            completionHandler: { completionCalled = true },
        )

        XCTAssertEqual(coordinator.errorAlertsShown.count, 1)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertFalse(completionCalled)
    }
}
