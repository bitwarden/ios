import BitwardenSdk

@testable import BitwardenShared

extension PendingAdminLoginRequest {
    static func fixture(
        id: String = "ID",
        authRequestResponse: AuthRequestResponse = AuthRequestResponse.fixture()
    ) -> PendingAdminLoginRequest {
        PendingAdminLoginRequest(
            id: id,
            authRequestResponse: authRequestResponse
        )
    }
}
