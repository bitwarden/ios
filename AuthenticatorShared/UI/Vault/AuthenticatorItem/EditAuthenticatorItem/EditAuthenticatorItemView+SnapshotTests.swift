// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AuthenticatorShared

// MARK: - EditAuthenticatorItemViewTests

class EditAuthenticatorItemViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<
        EditAuthenticatorItemState,
        EditAuthenticatorItemAction,
        EditAuthenticatorItemEffect,
    >!
    var subject: EditAuthenticatorItemView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        let state = AuthenticatorItemState(
            existing: AuthenticatorItemView.fixture(),
        )!

        processor = MockProcessor(state: state)
        subject = EditAuthenticatorItemView(
            store: Store(processor: processor),
        )
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Private

    /// Returns an edit state for an existing item with the advanced section and TOTP type configured.
    @MainActor
    private func makeState(
        isAdvancedExpanded: Bool,
        totpType: TotpTypeOptions,
    ) -> EditAuthenticatorItemState {
        AuthenticatorItemState(
            accountName: "Account",
            algorithm: .sha1,
            configuration: .existing(
                authenticatorItemView: AuthenticatorItemView.fixture(),
            ),
            digits: 6,
            id: "1",
            isAdvancedExpanded: isAdvancedExpanded,
            isFavorited: false,
            issuer: "Issuer",
            name: "Example",
            period: .thirty,
            secret: "example",
            totpState: LoginTOTPState(
                authKeyModel: TOTPKeyModel(authenticatorKey: "example")!,
                codeModel: TOTPCodeModel(
                    code: "123456",
                    codeGenerationDate: Date(timeIntervalSinceReferenceDate: 0),
                    period: 30,
                ),
            ),
            totpType: totpType,
        )
        .editState
    }

    // MARK: Tests

    /// Test a snapshot of the view with the advanced section collapsed.
    @MainActor
    func test_snapshot_advancedClosed() {
        processor.state = makeState(isAdvancedExpanded: false, totpType: .totp)
        assertSnapshot(of: subject.navStackWrapped, as: .portrait(heightMultiple: 1.25))
    }

    /// Test a snapshot of the view with the advanced section expanded for a TOTP item.
    @MainActor
    func test_snapshot_advancedOpen_totp() {
        processor.state = makeState(isAdvancedExpanded: true, totpType: .totp)
        assertSnapshot(of: subject.navStackWrapped, as: .portrait(heightMultiple: 1.25))
    }

    /// Test a snapshot of the view with the advanced section expanded for a Steam item.
    @MainActor
    func test_snapshot_advancedOpen_steam() {
        processor.state = makeState(isAdvancedExpanded: true, totpType: .steam)
        assertSnapshot(of: subject.navStackWrapped, as: .portrait(heightMultiple: 1.25))
    }
}
