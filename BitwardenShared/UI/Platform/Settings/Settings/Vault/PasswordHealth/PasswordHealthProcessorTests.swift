import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class PasswordHealthProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var errorReporter: MockErrorReporter!
    var vaultRepository: MockVaultRepository!
    var subject: PasswordHealthProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<SettingsRoute, SettingsEvent>()
        errorReporter = MockErrorReporter()
        vaultRepository = MockVaultRepository()

        subject = PasswordHealthProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                vaultRepository: vaultRepository,
            ),
            state: PasswordHealthState(),
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        vaultRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.loadData` sets the loading state to `.data([])` when the vault
    /// contains no login ciphers.
    @MainActor
    func test_perform_loadData_empty() async {
        vaultRepository.ciphersSubject.send([])

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.loadingState, .data([]))
    }

    /// `perform(_:)` with `.loadData` logs an error and falls back to `.data([])` when the
    /// cipher publisher fails.
    @MainActor
    func test_perform_loadData_error() async {
        vaultRepository.ciphersSubject.send(completion: .failure(BitwardenTestError.example))

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.loadingState, .data([]))
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    // MARK: reusedPasswordGroups Tests

    /// `reusedPasswordGroups(from:)` returns an empty array when no passwords are reused.
    @MainActor
    func test_reusedPasswordGroups_noReuse() {
        let cipher1 = CipherListView.fixture(id: "1", name: "Alpha")
        let cipher2 = CipherListView.fixture(id: "2", name: "Beta")

        let cipherView1 = CipherView.fixture(id: "1", login: .fixture(password: "unique-password-1"))
        let cipherView2 = CipherView.fixture(id: "2", login: .fixture(password: "unique-password-2"))

        let groups = subject.reusedPasswordGroups(from: [
            (listView: cipher1, cipherView: cipherView1),
            (listView: cipher2, cipherView: cipherView2),
        ])

        XCTAssertTrue(groups.isEmpty)
    }

    /// `reusedPasswordGroups(from:)` returns groups for ciphers that share the same password.
    @MainActor
    func test_reusedPasswordGroups_returnsGroups() throws {
        let cipher1 = CipherListView.fixture(id: "1", name: "Alpha")
        let cipher2 = CipherListView.fixture(id: "2", name: "Beta")
        let cipher3 = CipherListView.fixture(id: "3", name: "Gamma")

        let sharedPassword = "shared-secret"
        let uniquePassword = "unique-secret"

        let cipherView1 = CipherView.fixture(id: "1", login: .fixture(password: sharedPassword))
        let cipherView2 = CipherView.fixture(id: "2", login: .fixture(password: sharedPassword))
        let cipherView3 = CipherView.fixture(id: "3", login: .fixture(password: uniquePassword))

        let groups = subject.reusedPasswordGroups(from: [
            (listView: cipher1, cipherView: cipherView1),
            (listView: cipher2, cipherView: cipherView2),
            (listView: cipher3, cipherView: cipherView3),
        ])

        XCTAssertEqual(groups.count, 1)
        let group = try XCTUnwrap(groups.first)
        XCTAssertEqual(group.ciphers.count, 2)
        // Names should be sorted alphabetically within the group.
        XCTAssertEqual(group.ciphers.map(\.name), ["Alpha", "Beta"])
    }

    /// `reusedPasswordGroups(from:)` ignores ciphers with empty passwords.
    @MainActor
    func test_reusedPasswordGroups_ignoresEmptyPasswords() {
        let cipher1 = CipherListView.fixture(id: "1", name: "Alpha")
        let cipher2 = CipherListView.fixture(id: "2", name: "Beta")

        let cipherView1 = CipherView.fixture(id: "1", login: .fixture(password: ""))
        let cipherView2 = CipherView.fixture(id: "2", login: .fixture(password: ""))

        let groups = subject.reusedPasswordGroups(from: [
            (listView: cipher1, cipherView: cipherView1),
            (listView: cipher2, cipherView: cipherView2),
        ])

        XCTAssertTrue(groups.isEmpty)
    }

    /// `reusedPasswordGroups(from:)` ignores ciphers that have no login password (nil).
    @MainActor
    func test_reusedPasswordGroups_ignoresNilPasswords() {
        let cipher1 = CipherListView.fixture(id: "1", name: "Alpha")
        let cipher2 = CipherListView.fixture(id: "2", name: "Beta")

        let cipherView1 = CipherView.fixture(id: "1", login: .fixture(password: nil))
        let cipherView2 = CipherView.fixture(id: "2", login: .fixture(password: nil))

        let groups = subject.reusedPasswordGroups(from: [
            (listView: cipher1, cipherView: cipherView1),
            (listView: cipher2, cipherView: cipherView2),
        ])

        XCTAssertTrue(groups.isEmpty)
    }

    /// `reusedPasswordGroups(from:)` sorts groups by descending cipher count.
    @MainActor
    func test_reusedPasswordGroups_sortedByCount() {
        let cipher1 = CipherListView.fixture(id: "1", name: "A")
        let cipher2 = CipherListView.fixture(id: "2", name: "B")
        let cipher3 = CipherListView.fixture(id: "3", name: "C")
        let cipher4 = CipherListView.fixture(id: "4", name: "D")
        let cipher5 = CipherListView.fixture(id: "5", name: "E")

        let cipherView1 = CipherView.fixture(id: "1", login: .fixture(password: "aaa"))
        let cipherView2 = CipherView.fixture(id: "2", login: .fixture(password: "aaa"))
        let cipherView3 = CipherView.fixture(id: "3", login: .fixture(password: "aaa"))
        let cipherView4 = CipherView.fixture(id: "4", login: .fixture(password: "bbb"))
        let cipherView5 = CipherView.fixture(id: "5", login: .fixture(password: "bbb"))

        let groups = subject.reusedPasswordGroups(from: [
            (listView: cipher1, cipherView: cipherView1),
            (listView: cipher2, cipherView: cipherView2),
            (listView: cipher3, cipherView: cipherView3),
            (listView: cipher4, cipherView: cipherView4),
            (listView: cipher5, cipherView: cipherView5),
        ])

        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[0].ciphers.count, 3) // "aaa" group has 3
        XCTAssertEqual(groups[1].ciphers.count, 2) // "bbb" group has 2
    }

    /// `receive(_:)` with `.itemPressed` does not navigate (future TODO).
    @MainActor
    func test_receive_itemPressed() {
        let cipher = CipherListView.fixture()
        subject.receive(.itemPressed(cipher))

        XCTAssertTrue(coordinator.routes.isEmpty)
    }
}
