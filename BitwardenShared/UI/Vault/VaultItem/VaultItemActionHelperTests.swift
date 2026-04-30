import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared

// MARK: - VaultItemActionHelperTests

@MainActor
struct VaultItemActionHelperTests {
    // MARK: Properties

    let coordinator: MockCoordinator<VaultItemRoute, VaultItemEvent>
    let environmentService: MockEnvironmentService
    let errorReporter: MockErrorReporter
    let vaultRepository: MockVaultRepository
    let subject: VaultItemActionHelper

    // MARK: Initialization

    init() {
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

    // MARK: Tests

    /// `archive(cipher:handleOpenURL:completionHandler:)` shows the archive unavailable alert
    /// when the user does not have premium.
    @Test
    func archive_noPremium() async throws {
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

        let alert = try #require(coordinator.alertShown.last)
        #expect(alert.title == Localizations.archiveUnavailable)
        #expect(alert.message == Localizations.archivingItemsIsAPremiumFeatureDescriptionLong)
        #expect(vaultRepository.archiveCipher.isEmpty)
        #expect(!completionCalled)

        try await alert.tapAction(title: Localizations.upgradeToPremium)
        #expect(openedURL == URL(string: "https://example.com/someURLToUpgradeToPremium"))
    }

    /// `archive(cipher:handleOpenURL:completionHandler:)` shows the confirmation alert and
    /// archives the cipher when the user has premium and confirms.
    @Test
    func archive_success() async throws {
        var completionCalled = false
        let cipher = CipherView.loginFixture(id: "123")

        vaultRepository.doesActiveAccountHavePremiumResult = true

        await subject.archive(
            cipher: cipher,
            handleOpenURL: { _ in },
            completionHandler: { completionCalled = true },
        )

        let confirmAlert = try #require(coordinator.alertShown.last)
        #expect(confirmAlert.title == Localizations.archiveItem)
        #expect(vaultRepository.archiveCipher.isEmpty)
        #expect(!completionCalled)

        vaultRepository.archiveCipherResult = .success(())
        try await confirmAlert.tapAction(title: Localizations.archive)

        #expect(coordinator.loadingOverlaysShown.last?.title == Localizations.sendingToArchive)
        #expect(vaultRepository.archiveCipher.last?.id == "123")
        #expect(completionCalled)
        #expect(errorReporter.errors.isEmpty)
    }

    /// `archive(cipher:handleOpenURL:completionHandler:)` does not archive when the user cancels
    /// the confirmation alert.
    @Test
    func archive_confirmationCancel() async throws {
        var completionCalled = false
        let cipher = CipherView.loginFixture(id: "123")

        vaultRepository.doesActiveAccountHavePremiumResult = true

        await subject.archive(
            cipher: cipher,
            handleOpenURL: { _ in },
            completionHandler: { completionCalled = true },
        )

        let confirmAlert = try #require(coordinator.alertShown.last)
        #expect(confirmAlert.title == Localizations.archiveItem)

        try await confirmAlert.tapCancel()

        #expect(vaultRepository.archiveCipher.isEmpty)
        #expect(!completionCalled)
    }

    /// `archive(cipher:handleOpenURL:completionHandler:)` shows an error alert when archiving fails.
    @Test
    func archive_error() async throws {
        var completionCalled = false
        let cipher = CipherView.loginFixture(id: "123")

        vaultRepository.doesActiveAccountHavePremiumResult = true
        vaultRepository.archiveCipherResult = .failure(BitwardenTestError.example)

        await subject.archive(
            cipher: cipher,
            handleOpenURL: { _ in },
            completionHandler: { completionCalled = true },
        )

        let confirmAlert = try #require(coordinator.alertShown.last)
        try await confirmAlert.tapAction(title: Localizations.archive)

        #expect(coordinator.errorAlertsShown.count == 1)
        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
        #expect(!completionCalled)
    }

    /// `unarchive(cipher:completionHandler:)` shows the confirmation alert and unarchives
    /// the cipher when the user confirms.
    @Test
    func unarchive_success() async throws {
        var completionCalled = false
        let cipher = CipherView.loginFixture(archivedDate: .now, id: "123")

        vaultRepository.unarchiveCipherResult = .success(())

        await subject.unarchive(
            cipher: cipher,
            completionHandler: { completionCalled = true },
        )

        #expect(coordinator.loadingOverlaysShown.last?.title == Localizations.movingItemToVault)
        #expect(vaultRepository.unarchiveCipher.last?.id == "123")
        #expect(completionCalled)
        #expect(errorReporter.errors.isEmpty)
    }

    /// `unarchive(cipher:completionHandler:)` shows an error alert when unarchiving fails.
    @Test
    func unarchive_error() async throws {
        var completionCalled = false
        let cipher = CipherView.loginFixture(archivedDate: .now, id: "123")

        vaultRepository.unarchiveCipherResult = .failure(BitwardenTestError.example)

        await subject.unarchive(
            cipher: cipher,
            completionHandler: { completionCalled = true },
        )

        #expect(coordinator.errorAlertsShown.count == 1)
        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
        #expect(!completionCalled)
    }
}
