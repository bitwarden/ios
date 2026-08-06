// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenKitMocks
import Testing

@testable import AuthenticatorShared

// MARK: - StateServiceTOTPItemDisplayStateServiceTests

struct StateServiceTOTPItemDisplayStateServiceTests {
    // MARK: Properties

    let appSettingsStore: MockAppSettingsStore
    let subject: DefaultStateService

    // MARK: Initialization

    init() {
        appSettingsStore = MockAppSettingsStore()
        subject = DefaultStateService(
            appSettingsStore: appSettingsStore,
            dataStore: DataStore(errorReporter: MockErrorReporter(), storeType: .memory),
        )
    }

    // MARK: Tests - showNextTOTPCode

    /// `getShowNextTOTPCode()` returns `false` when no value has been set.
    @Test
    func getShowNextTOTPCode_defaultsFalse() async {
        let result = await subject.getShowNextTOTPCode()
        #expect(result == false)
    }

    /// `setShowNextTOTPCode(_:)` persists the value through `AppSettingsStore`.
    @Test
    func setShowNextTOTPCode_persistsToAppSettingsStore() async {
        await subject.setShowNextTOTPCode(true)
        #expect(appSettingsStore.showNextTOTPCode == true)

        let result = await subject.getShowNextTOTPCode()
        #expect(result == true)
    }

    // MARK: Tests - showWebIcons

    /// `getShowWebIcons()` returns `true` when no value has been set (web icons enabled by default).
    @Test
    func getShowWebIcons_defaultsTrue() async {
        let result = await subject.getShowWebIcons()
        #expect(result == true)
    }

    /// `setShowWebIcons(_:)` persists the value through `AppSettingsStore`.
    @Test
    func setShowWebIcons_persistsToAppSettingsStore() async {
        await subject.setShowWebIcons(false)
        #expect(appSettingsStore.disableWebIcons == true)

        let result = await subject.getShowWebIcons()
        #expect(result == false)
    }
}
