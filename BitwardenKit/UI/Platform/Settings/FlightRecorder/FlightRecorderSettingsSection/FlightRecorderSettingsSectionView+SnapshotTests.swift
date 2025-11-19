// swiftlint:disable:this file_name
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenKit

class FlightRecorderSettingsSectionViewSnapshotTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<
        FlightRecorderSettingsSectionState,
        FlightRecorderSettingsSectionAction,
        FlightRecorderSettingsSectionEffect,
    >!
    var subject: FlightRecorderSettingsSectionView!

    // MARK: Computed Properties

    /// Returns the subject view wrapped with padding and background for snapshot testing.
    var snapshotView: some View {
        ZStack(alignment: .top) {
            SharedAsset.Colors.backgroundPrimary.swiftUIColor.ignoresSafeArea()

            subject
                .padding()
        }
    }

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

    // MARK: Snapshots

    /// The flight recorder settings section view renders correctly when disabled.
    @MainActor
    func disabletest_snapshot_flightRecorderSettingsSection_disabled() {
        assertSnapshots(
            of: snapshotView,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// The flight recorder settings section view renders correctly when enabled.
    @MainActor
    func disabletest_snapshot_flightRecorderSettingsSection_enabled() {
        processor.state.activeLog = FlightRecorderData.LogMetadata(
            duration: .eightHours,
            startDate: Date(year: 2025, month: 5, day: 1, hour: 8),
        )
        assertSnapshots(
            of: snapshotView,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }
}
