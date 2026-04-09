// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class IntroCarouselViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<IntroCarouselState, IntroCarouselAction, IntroCarouselEffect>!
    var subject: IntroCarouselView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: IntroCarouselState())

        subject = IntroCarouselView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The intro carousel page 1 renders correctly.
    func disabletest_snapshot_introCarousel_page1() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5, .defaultLandscape],
        )
    }

    /// The intro carousel page 2 renders correctly.
    @MainActor
    func disabletest_snapshot_introCarousel_page2() {
        processor.state.currentPageIndex = 1
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5, .defaultLandscape],
        )
    }

    /// The intro carousel page 3 renders correctly.
    @MainActor
    func disabletest_snapshot_introCarousel_page3() {
        processor.state.currentPageIndex = 2
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5, .defaultLandscape],
        )
    }

    /// The intro carousel page 4 renders correctly.
    @MainActor
    func disabletest_snapshot_introCarousel_page4() {
        processor.state.currentPageIndex = 3
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5, .defaultLandscape],
        )
    }
}
