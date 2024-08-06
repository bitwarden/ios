@testable import BitwardenShared

class MockAuthProfileSwitchDelegate: AuthProfileSwitchDelegate {
    var onProfileSwitchedMocker = InvocationMocker<(oldUserId: String?, activeUserId: String)>()

    func onProfileSwitched(oldUserId: String?, activeUserId: String) async throws {
        onProfileSwitchedMocker.invoke(param: (oldUserId, activeUserId))
    }
}
