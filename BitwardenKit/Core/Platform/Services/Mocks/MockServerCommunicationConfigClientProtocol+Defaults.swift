import BitwardenSdk
import BitwardenSdkMocks

public extension MockServerCommunicationConfigClientProtocol {
    /// Creates a `MockServerCommunicationConfigClientProtocol` pre-configured with default return
    /// values (matching a `.direct` bootstrap with no cookies).
    ///
    static func withDefaults() -> MockServerCommunicationConfigClientProtocol {
        let mock = MockServerCommunicationConfigClientProtocol()
        mock.cookiesReturnValue = []
        mock.getConfigReturnValue = ServerCommunicationConfig(bootstrap: .direct)
        mock.getCookiesReturnValue = []
        mock.needsBootstrapReturnValue = false
        return mock
    }
}
