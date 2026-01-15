// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class AboutViewTests: BitwardenTestCase {
    // MARK: Properties

    let copyrightText = "© Bitwarden Inc. 2015-2023" // Copyrights with snapshot tests shouldn't be dynamic
    let version = "Version: 1.0.0 (1)"

    var processor: MockProcessor<AboutState, AboutAction, AboutEffect>!
    var subject: AboutView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AboutState(copyrightText: copyrightText, version: version))
        let store = Store(processor: processor)

        subject = AboutView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The default view renders correctly.
    @MainActor
    func disabletest_snapshot_default() {
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
