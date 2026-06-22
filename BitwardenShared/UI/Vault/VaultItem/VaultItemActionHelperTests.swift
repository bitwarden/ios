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
    let errorReporter: MockErrorReporter
    let vaultRepository: MockVaultRepository
    let subject: VaultItemActionHelper

    // MARK: Initialization

    init() {
        coordinator = MockCoordinator<VaultItemRoute, VaultItemEvent>()
        errorReporter = MockErrorReporter()
        vaultRepository = MockVaultRepository()
        subject = DefaultVaultItemActionHelper(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                vaultRepository: vaultRepository,
            ),
        )
    }

    // MARK: Tests

    /// `archive(cipher:handleNavigateToPremiumUpgrade:completionHandler:)` shows the archive
    /// unavailable alert when the user does not have Premium.
    @Test
    func archive_noPremium() async throws {
        var navigatedToPremiumUpgrade = false
        var completionCalled = false
        let cipher = CipherView.loginFixture(id: "123")

        vaultRepository.doesActiveAccountHavePremiumResult = false

        await subject.archive(
            cipher: cipher,
            handleNavigateToPremiumUpgrade: { navigatedToPremiumUpgrade = true },
            completionHandler: { completionCalled = true },
        )

        let alert = try #require(coordinator.alertShown.last)
        #expect(alert.title == Localizations.archiveUnavailable)
        #expect(alert.message == Localizations.archivingItemsIsAPremiumFeatureDescriptionLong)
        #expect(vaultRepository.archiveCipher.isEmpty)
        #expect(!completionCalled)

        try await alert.tapAction(title: Localizations.upgradeToPremium)
        #expect(navigatedToPremiumUpgrade)
    }

    /// `archive(cipher:handleNavigateToPremiumUpgrade:completionHandler:)` shows the confirmation
    /// alert and archives the cipher when the user has Premium and confirms.
    @Test
    func archive_success() async throws {
        var completionCalled = false
        let cipher = CipherView.loginFixture(id: "123")

        vaultRepository.doesActiveAccountHavePremiumResult = true

        await subject.archive(
            cipher: cipher,
            handleNavigateToPremiumUpgrade: {},
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

    /// `archive(cipher:handleNavigateToPremiumUpgrade:completionHandler:)` does not archive when
    /// the user cancels the confirmation alert.
    @Test
    func archive_confirmationCancel() async throws {
        var completionCalled = false
        let cipher = CipherView.loginFixture(id: "123")

        vaultRepository.doesActiveAccountHavePremiumResult = true

        await subject.archive(
            cipher: cipher,
            handleNavigateToPremiumUpgrade: {},
            completionHandler: { completionCalled = true },
        )

        let confirmAlert = try #require(coordinator.alertShown.last)
        #expect(confirmAlert.title == Localizations.archiveItem)

        try await confirmAlert.tapCancel()

        #expect(vaultRepository.archiveCipher.isEmpty)
        #expect(!completionCalled)
    }

    /// `archive(cipher:handleNavigateToPremiumUpgrade:completionHandler:)` shows an error alert
    /// when archiving fails.
    @Test
    func archive_error() async throws {
        var completionCalled = false
        let cipher = CipherView.loginFixture(id: "123")

        vaultRepository.doesActiveAccountHavePremiumResult = true
        vaultRepository.archiveCipherResult = .failure(BitwardenTestError.example)

        await subject.archive(
            cipher: cipher,
            handleNavigateToPremiumUpgrade: {},
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
