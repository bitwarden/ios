// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - VaultGroupViewTests

class VaultGroupViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultGroupState, VaultGroupAction, VaultGroupEffect>!
    var subject: VaultGroupView!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(
            state: VaultGroupState(
                searchVaultFilterType: .allVaults,
                vaultFilterType: .allVaults,
            ),
        )
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2023, month: 12, day: 31)))
        subject = VaultGroupView(
            store: Store(processor: processor),
            timeProvider: timeProvider,
        )
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
        timeProvider = nil
    }

    // MARK: Snapshots

    @MainActor
    func disabletest_snapshot_empty_login() {
        processor.state.loadingState = .data([])
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_empty_card() {
        processor.state.group = .card
        processor.state.loadingState = .data([])
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_empty_identity() {
        processor.state.group = .identity
        processor.state.loadingState = .data([])
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_empty_note() {
        processor.state.group = .secureNote
        processor.state.loadingState = .data([])
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_emptyCollection() {
        processor.state.group = .collection(id: "id", name: "name", organizationId: "12345")
        processor.state.loadingState = .data([])
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_emptyFolder() {
        processor.state.group = .folder(id: "id", name: "name")
        processor.state.loadingState = .data([])
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_emptySSHKey() {
        processor.state.group = .sshKey
        processor.state.loadingState = .data([])
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_emptyTrash() {
        processor.state.group = .trash
        processor.state.loadingState = .data([])
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_loading() {
        processor.state.loadingState = .loading(nil)
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_multipleItems() { // swiftlint:disable:this function_body_length
        processor.state.loadingState = .data(
            [
                VaultListSection(
                    id: "Items",
                    items: [
                        .fixture(
                            cipherListView: .fixture(
                                id: "1",
                                login: .fixture(
                                    username: "email@example.com",
                                ),
                                name: "Example",
                                subtitle: "email@example.com",
                            ),
                        ),
                        .fixture(
                            cipherListView: .fixture(
                                id: "2",
                                login: .fixture(
                                    username: "An equally long subtitle that should also take up more than one line",
                                ),
                                name: "An extra long name that should take up more than one line",
                                subtitle: "An equally long subtitle that should also take up more than one line",
                            ),
                        ),
                        .fixture(
                            cipherListView: .fixture(
                                id: "3",
                                login: .fixture(
                                    username: "email@example.com",
                                ),
                                name: "Example",
                                subtitle: "email@example.com",
                            ),
                        ),
                        .fixture(
                            cipherListView: .fixture(
                                id: "4",
                                login: .fixture(
                                    username: "email@example.com",
                                ),
                                name: "Example",
                                subtitle: "email@example.com",
                            ),
                        ),
                    ],
                    name: Localizations.items,
                ),
            ],
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_oneItem() {
        processor.state.loadingState = .data(
            [
                VaultListSection(
                    id: "Items",
                    items: [
                        .fixture(cipherListView: .fixture(
                            login: .fixture(username: "email@example.com"),
                            name: "Example",
                        )),
                    ],
                    name: Localizations.items,
                ),
            ],
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_search_oneItem() {
        processor.state.isSearching = true
        processor.state.searchResults = [
            .fixture(cipherListView: .fixture(
                login: .fixture(username: "email@example.com"),
                name: "Example",
            )),
        ]
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_search_oneTOTPItem() {
        timeProvider.timeConfig = .mockTime(
            .init(
                year: 2023,
                month: 5,
                day: 19,
                second: 33,
            ),
        )
        processor.state.isSearching = true
        processor.state.searchResults = [
            .fixtureTOTP(
                name: "Example Name",
                totp: .fixture(
                    loginListView: .fixture(
                        username: "username",
                    ),
                    totpCode: .init(
                        code: "034543",
                        codeGenerationDate: timeProvider.presentTime,
                        period: 30,
                    ),
                ),
            ),
        ]
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
