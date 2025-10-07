import BitwardenSdk

extension Fido2CredentialListView {
    static func fixture(
        credentialId: String = "1",
        rpId: String = "myApp.com",
        userHandle: String? = nil,
        userName: String? = nil,
        userDisplayName: String? = nil,
        counter: String = "0",
    ) -> Fido2CredentialListView {
        .init(
            credentialId: credentialId,
            rpId: rpId,
            userHandle: userHandle,
            userName: userName,
            userDisplayName: userDisplayName,
            counter: counter,
        )
    }
}
