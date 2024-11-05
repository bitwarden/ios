import XCTest

@testable import BitwardenShared

// MARK: - ExtensionActivationProcessorTests

class ExtensionActivationProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var appExtensionDelegate: MockAppExtensionDelegate!
    var configService: MockConfigService!
    var subject: ExtensionActivationProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appExtensionDelegate = MockAppExtensionDelegate()
        configService = MockConfigService()
        subject = ExtensionActivationProcessor(
            appExtensionDelegate: appExtensionDelegate,
            services: ServiceContainer.withMocks(configService: configService),
            state: ExtensionActivationState(extensionType: .autofillExtension)
        )
    }

    override func tearDown() {
        super.tearDown()

        appExtensionDelegate = nil
        configService = nil
        subject = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.cancelTapped` notifies the delegate to cancel the extension.
    @MainActor
    func test_receive_cancelTapped() {
        subject.receive(.cancelTapped)

        XCTAssertTrue(appExtensionDelegate.didCancelCalled)
    }

    /// `perform(.appeared)` with feature flag for .nativeCreateAccountFlow set to true
    @MainActor
    func test_perform_appeared_loadFeatureFlag_true() async {
        configService.featureFlagsBool[.nativeCreateAccountFlow] = true
        subject.state.isNativeCreateAccountFeatureFlagEnabled = false

        await subject.perform(.appeared)
        XCTAssertTrue(subject.state.isNativeCreateAccountFeatureFlagEnabled)
    }

    /// `perform(.appeared)` with feature flag for .nativeCreateAccountFlow set to false
    @MainActor
    func test_perform_appeared_loadsFeatureFlag_false() async {
        configService.featureFlagsBool[.nativeCreateAccountFlow] = false
        subject.state.isNativeCreateAccountFeatureFlagEnabled = true

        await subject.perform(.appeared)
        XCTAssertFalse(subject.state.isNativeCreateAccountFeatureFlagEnabled)
    }

    /// `perform(.appeared)` with feature flag defaulting to false
    @MainActor
    func test_perform_appeared_loadsFeatureFlag_nil() async {
        configService.featureFlagsBool[.nativeCreateAccountFlow] = nil
        subject.state.isNativeCreateAccountFeatureFlagEnabled = true

        await subject.perform(.appeared)
        XCTAssertFalse(subject.state.isNativeCreateAccountFeatureFlagEnabled)
    }
}
