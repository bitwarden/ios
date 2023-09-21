@testable import BitwardenShared

extension State {
    static func fixture(
        accounts: [String: Account] = ["1": .fixture()],
        activeUserId: String? = "1"
    ) -> State {
        State(
            accounts: accounts,
            activeUserId: activeUserId
        )
    }
}
