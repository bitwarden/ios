// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import SnapshotTesting
import SwiftUI
import XCTest

// MARK: - TOTPCodeDisplayTests

final class TOTPCodeDisplayTests: BitwardenTestCase {
    // MARK: Properties

    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        timeProvider = MockTimeProvider(.mockTime(Date(year: 2023, month: 12, day: 31)))
    }

    override func tearDown() {
        super.tearDown()

        timeProvider = nil
    }

    // MARK: Tests

    /// Snapshot: current code only, no next code, normal timer color.
    func disabletest_snapshot_TOTPCodeDisplay_currentCodeOnly() {
        let subject = TOTPCodeDisplay(
            currentCode: TOTPCodeModel(
                code: "123456",
                codeGenerationDate: Date(year: 2023, month: 12, day: 31),
                period: 30,
            ),
            nextCode: nil,
            showNextTOTPCode: false,
            timeProvider: timeProvider,
        )
        assertSnapshots(
            of: subject,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultPortraitAX5,
            ],
        )
    }

    /// Snapshot: next code visible — within `nextTOTPCodePreviewThreshold` and setting enabled.
    func disabletest_snapshot_TOTPCodeDisplay_nextCode_visible() {
        timeProvider = MockTimeProvider(
            .mockTime(Date(year: 2023, month: 12, day: 31, hour: 0, minute: 0, second: 22)),
        )
        let subject = TOTPCodeDisplay(
            currentCode: TOTPCodeModel(
                code: "123456",
                codeGenerationDate: Date(year: 2023, month: 12, day: 31),
                period: 30,
            ),
            nextCode: TOTPCodeModel(
                code: "789012",
                codeGenerationDate: Date(year: 2023, month: 12, day: 31),
                period: 30,
            ),
            showNextTOTPCode: true,
            timeProvider: timeProvider,
        )
        assertSnapshots(
            of: subject,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultPortraitAX5,
            ],
        )
    }

    /// Snapshot: next code suppressed — within threshold but setting disabled.
    func disabletest_snapshot_TOTPCodeDisplay_nextCode_settingOff() {
        timeProvider = MockTimeProvider(
            .mockTime(Date(year: 2023, month: 12, day: 31, hour: 0, minute: 0, second: 22)),
        )
        let subject = TOTPCodeDisplay(
            currentCode: TOTPCodeModel(
                code: "123456",
                codeGenerationDate: Date(year: 2023, month: 12, day: 31),
                period: 30,
            ),
            nextCode: TOTPCodeModel(
                code: "789012",
                codeGenerationDate: Date(year: 2023, month: 12, day: 31),
                period: 30,
            ),
            showNextTOTPCode: false,
            timeProvider: timeProvider,
        )
        assertSnapshots(
            of: subject,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultPortraitAX5,
            ],
        )
    }

    /// Snapshot: urgent timer color — within `totpUrgentCountdownThreshold`, next code also visible.
    func disabletest_snapshot_TOTPCodeDisplay_urgentColor() {
        timeProvider = MockTimeProvider(
            .mockTime(Date(year: 2023, month: 12, day: 31, hour: 0, minute: 0, second: 25)),
        )
        let subject = TOTPCodeDisplay(
            currentCode: TOTPCodeModel(
                code: "123456",
                codeGenerationDate: Date(year: 2023, month: 12, day: 31),
                period: 30,
            ),
            nextCode: TOTPCodeModel(
                code: "789012",
                codeGenerationDate: Date(year: 2023, month: 12, day: 31),
                period: 30,
            ),
            showNextTOTPCode: true,
            timeProvider: timeProvider,
        )
        assertSnapshots(
            of: subject,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultPortraitAX5,
            ],
        )
    }
}
