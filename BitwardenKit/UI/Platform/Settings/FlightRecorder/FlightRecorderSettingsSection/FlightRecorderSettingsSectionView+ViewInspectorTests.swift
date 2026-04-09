// swiftlint:disable:this file_name
import BitwardenKitMocks
import BitwardenResources
import TestHelpers
import ViewInspector
import XCTest

@testable import BitwardenKit

class FlightRecorderSettingsSectionViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<
        FlightRecorderSettingsSectionState,
        FlightRecorderSettingsSectionAction,
        FlightRecorderSettingsSectionEffect,
    >!
    var subject: FlightRecorderSettingsSectionView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: FlightRecorderSettingsSectionState())
        let store = Store(processor: processor)

        subject = FlightRecorderSettingsSectionView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Toggling the Flight Recorder toggle on dispatches the `.toggleFlightRecorder(true)` effect.
    @MainActor
    func test_toggle_on() async throws {
        let toggle = try subject.inspect().find(toggleWithAccessibilityLabel: Localizations.flightRecorder)
        try toggle.tap()
        try await waitForAsync { !self.processor.effects.isEmpty }
        XCTAssertEqual(processor.effects.last, .toggleFlightRecorder(true))
    }

    /// Toggling the Flight Recorder toggle off dispatches the `.toggleFlightRecorder(false)` effect.
    @MainActor
    func test_toggle_off() async throws {
        let toggle = try subject.inspect().find(toggleWithAccessibilityLabel: Localizations.flightRecorder)
        processor.state.activeLog = FlightRecorderData.LogMetadata(
            duration: .eightHours,
            startDate: Date(year: 2025, month: 5, day: 1),
        )
        try toggle.tap()
        try await waitForAsync { !self.processor.effects.isEmpty }
        XCTAssertEqual(processor.effects.last, .toggleFlightRecorder(false))
    }

    /// Tapping the view recorded logs button dispatches the `.viewLogsTapped` action.
    @MainActor
    func test_viewLogsButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.viewRecordedLogs)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .viewLogsTapped)
    }
}
