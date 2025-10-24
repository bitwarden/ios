// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import SwiftUI
import XCTest

@testable import BitwardenShared

final class ProfileSwitcherToolbarViewTests: BitwardenTestCase {
    var processor: MockProcessor<ProfileSwitcherState, ProfileSwitcherAction, ProfileSwitcherEffect>!
    var subject: ProfileSwitcherToolbarView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        let account = ProfileSwitcherItem.anneAccount
        let state = ProfileSwitcherState(
            accounts: [account],
            activeAccountId: account.userId,
            allowLockAndLogout: true,
            isVisible: true,
        )
        processor = MockProcessor(state: state)
        subject = ProfileSwitcherToolbarView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    @ViewBuilder
    func snapshotSubject(title: String) -> some View {
        NavigationView {
            Spacer()
                .navigationBarTitle(title, displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        subject
                    }
                }
        }
    }

    /// Tapping the view dispatches the `.requestedProfileSwitcher` effect.
    @MainActor
    func test_tap_currentAccount() async throws {
        let view = try subject.inspect().find(asyncButtonWithAccessibilityLabel: Localizations.account)
        try await view.tap()

        XCTAssertEqual(
            processor.effects.last,
            .requestedProfileSwitcher(visible: !subject.store.state.isVisible),
        )
    }
}
