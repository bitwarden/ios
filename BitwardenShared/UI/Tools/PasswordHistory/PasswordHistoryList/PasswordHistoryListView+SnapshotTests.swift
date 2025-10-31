// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import SnapshotTesting
import XCTest

import SwiftUI

@testable import BitwardenShared

class PasswordHistoryListViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<PasswordHistoryListState, PasswordHistoryListAction, PasswordHistoryListEffect>!
    var subject: PasswordHistoryListView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: PasswordHistoryListState())
        let store = Store(processor: processor)

        subject = PasswordHistoryListView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// Test a snapshot of the generator history view's empty state.
    func disabletest_snapshot_generatorHistoryViewEmpty() {
        assertSnapshot(
            of: subject,
            as: .defaultPortrait,
        )
    }

    /// Test a snapshot of the generator history displaying a list of generated values.
    @MainActor
    func disabletest_snapshot_generatorHistoryViewList() {
        processor.state.passwordHistory = [
            PasswordHistoryView(
                password: "8gr6uY8CLYQwzr#",
                lastUsedDate: Date(year: 2023, month: 11, day: 1, hour: 8, minute: 30),
            ),
            PasswordHistoryView(
                password: "%w4&D*48&CD&j2",
                lastUsedDate: Date(year: 2023, month: 10, day: 20, hour: 11, minute: 42),
            ),
            PasswordHistoryView(
                password: "03n@5bq!fw5k1!5cdfad6wes1u05b3hls$kbko&d#if4%cckowywt7sh8d*3%cxng553l&4" +
                    "7e4ywrt3l%dl537sonc6iw2*#r#*grwiw1@%#czm6ox64@m9u%im21*u#",
                lastUsedDate: Date(year: 2023, month: 0, day: 14, hour: 18, minute: 24),
            ),
        ]
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitAX5],
        )
    }
}
