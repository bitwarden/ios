// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class MasterPasswordGeneratorViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<
        MasterPasswordGeneratorState,
        MasterPasswordGeneratorAction,
        MasterPasswordGeneratorEffect,
    >!
    var subject: MasterPasswordGeneratorView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        let state = MasterPasswordGeneratorState(generatedPassword: "Imma-Little-Teapot2")
        processor = MockProcessor(state: state)
        subject = MasterPasswordGeneratorView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The master password generator view renders correctly.
    @MainActor
    func disabletest_snapshot_masterPasswordGenerator() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .tallPortraitAX5(heightMultiple: 2),
                .defaultLandscape,
            ],
        )
    }
}
