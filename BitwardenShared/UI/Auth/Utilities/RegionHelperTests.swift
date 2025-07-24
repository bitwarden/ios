import BitwardenKit
import BitwardenResources
import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - RegionHelperTests

class RegionHelperTests: BitwardenTestCase {
    // MARK: Properties

    var subject: RegionHelper!
    var regionDelegate: MockRegionDelegate!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var stateService: MockStateService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator<AuthRoute, AuthEvent>()
        stateService = MockStateService()
        regionDelegate = MockRegionDelegate()

        subject = RegionHelper(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: regionDelegate,
            stateService: stateService
        )
        subject.delegate = regionDelegate
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// `presentRegionSelectorAlert(title:currentRegion)` shows alert and tap bitwarden.com.
    @MainActor
    func test_presentRegionSelectorAlert_us() async throws {
        await subject.presentRegionSelectorAlert(title: Localizations.creatingOn, currentRegion: .unitedStates)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, Localizations.creatingOn)
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.alertActions.count, 4)

        XCTAssertEqual(alert.alertActions[0].title, "bitwarden.com")
        try await alert.tapAction(title: "bitwarden.com")
        XCTAssertTrue(regionDelegate.setRegionCalled)
        XCTAssertEqual(regionDelegate.setRegionType, .unitedStates)
        XCTAssertEqual(regionDelegate.setRegionUrls, RegionType.unitedStates.defaultURLs)
    }

    /// `presentRegionSelectorAlert(title:currentRegion)` shows alert and tap bitwarden.eu.
    @MainActor
    func test_presentRegionSelectorAlert_eu() async throws {
        await subject.presentRegionSelectorAlert(title: Localizations.creatingOn, currentRegion: .unitedStates)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, Localizations.creatingOn)
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.alertActions.count, 4)

        XCTAssertEqual(alert.alertActions[1].title, "bitwarden.eu")
        try await alert.tapAction(title: "bitwarden.eu")
        XCTAssertTrue(regionDelegate.setRegionCalled)
        XCTAssertEqual(regionDelegate.setRegionType, .europe)
        XCTAssertEqual(regionDelegate.setRegionUrls, RegionType.europe.defaultURLs)
    }

    /// `presentRegionSelectorAlert(title:currentRegion)` shows alert and tap selfhosted.
    @MainActor
    func test_presentRegionSelectorAlert_selfHosted() async throws {
        await subject.presentRegionSelectorAlert(title: Localizations.creatingOn, currentRegion: .europe)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, Localizations.creatingOn)
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.alertActions.count, 4)

        XCTAssertEqual(alert.alertActions[2].title, Localizations.selfHosted)
        try await alert.tapAction(title: Localizations.selfHosted)
        XCTAssertEqual(coordinator.routes.last, .selfHosted(currentRegion: .europe))
    }

    /// `presentRegionSelectorAlert(title:currentRegion)` with current region as nil default to us
    @MainActor
    func test_presentRegionSelectorAlert_nil() async throws {
        await subject.presentRegionSelectorAlert(title: Localizations.loggingInOn, currentRegion: nil)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, Localizations.loggingInOn)
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.alertActions.count, 4)

        XCTAssertEqual(alert.alertActions[2].title, Localizations.selfHosted)
        try await alert.tapAction(title: Localizations.selfHosted)
        XCTAssertEqual(coordinator.routes.last, .selfHosted(currentRegion: .unitedStates))
    }

    /// `loadRegion()` with pre auth region as nil default to us
    func test_loadRegion_nil() async throws {
        stateService.preAuthEnvironmentURLs = nil
        await subject.loadRegion()
        XCTAssertTrue(regionDelegate.setRegionCalled)
        XCTAssertEqual(regionDelegate.setRegionType, .unitedStates)
        XCTAssertEqual(regionDelegate.setRegionUrls, RegionType.unitedStates.defaultURLs)
    }

    /// `loadRegion()` with pre auth region
    func test_loadRegion_us() async throws {
        stateService.preAuthEnvironmentURLs = .defaultUS
        await subject.loadRegion()
        XCTAssertTrue(regionDelegate.setRegionCalled)
        XCTAssertEqual(regionDelegate.setRegionType, .unitedStates)
        XCTAssertEqual(regionDelegate.setRegionUrls, RegionType.unitedStates.defaultURLs)
    }

    /// `loadRegion()` with pre auth region
    func test_loadRegion_eu() async throws {
        stateService.preAuthEnvironmentURLs = .defaultEU
        await subject.loadRegion()
        XCTAssertTrue(regionDelegate.setRegionCalled)
        XCTAssertEqual(regionDelegate.setRegionType, .europe)
        XCTAssertEqual(regionDelegate.setRegionUrls, RegionType.europe.defaultURLs)
    }

    /// `loadRegion()` with pre auth region
    func test_loadRegion_selfHosted() async throws {
        stateService.preAuthEnvironmentURLs = EnvironmentURLData(base: URL(string: "https://selfhosted.com"))
        await subject.loadRegion()
        XCTAssertTrue(regionDelegate.setRegionCalled)
        XCTAssertEqual(regionDelegate.setRegionType, .selfHosted)
        XCTAssertEqual(regionDelegate.setRegionUrls, EnvironmentURLData(base: URL(string: "https://selfhosted.com")))
    }
}

class MockRegionDelegate: RegionDelegate {
    var setRegionCalled = false
    var setRegionType: RegionType?
    var setRegionUrls: EnvironmentURLData?

    func setRegion(_ region: RegionType, _ urls: EnvironmentURLData) async {
        setRegionCalled = true
        setRegionType = region
        setRegionUrls = urls
    }
}
