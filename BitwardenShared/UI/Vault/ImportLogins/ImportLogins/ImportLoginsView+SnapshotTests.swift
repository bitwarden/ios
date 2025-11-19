// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class ImportLoginsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ImportLoginsState, ImportLoginsAction, ImportLoginsEffect>!
    var subject: ImportLoginsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: ImportLoginsState(mode: .vault))

        subject = ImportLoginsView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The import logins intro page renders correctly.
    @MainActor
    func disabletest_snapshot_importLoginsIntro() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2), .defaultLandscape],
        )
    }

    /// The import logins step 1 page renders correctly.
    @MainActor
    func disabletest_snapshot_importLoginsStep1() {
        processor.state.page = .step1
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2.5), .defaultLandscape],
        )
    }

    /// The import logins step 2 page renders correctly.
    @MainActor
    func disabletest_snapshot_importLoginsStep2() {
        processor.state.page = .step2
        processor.state.webVaultHost = "vault.bitwarden.com"
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2), .defaultLandscape],
        )
    }

    /// The import logins step 3 page renders correctly.
    @MainActor
    func disabletest_snapshot_importLoginsStep3() {
        processor.state.page = .step3
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2.5), .defaultLandscape],
        )
    }
}
