import BitwardenSdkMocks

public extension MockPlatformClientService {
    /// The `MockClientFido2Service` wired to `fido2ReturnValue`.
    var mockFido2: MockClientFido2Service {
        guard let mock = fido2ReturnValue as? MockClientFido2Service else {
            preconditionFailure(
                "fido2ReturnValue is not a MockClientFido2Service. "
                    + "Use MockPlatformClientService.withMocks() to ensure it is wired correctly.",
            )
        }
        return mock
    }

    /// The `MockStateClientProtocol` wired to `stateReturnValue`.
    var mockState: MockStateClientProtocol {
        guard let mock = stateReturnValue as? MockStateClientProtocol else {
            preconditionFailure(
                "stateReturnValue is not a MockStateClientProtocol. "
                    + "Use MockPlatformClientService.withMocks() to ensure it is wired correctly.",
            )
        }
        return mock
    }

    /// Creates a `MockPlatformClientService` with nested mocks pre-wired as return values.
    ///
    /// - Parameters:
    ///   - fido2: The mock to return from `fido2()`. Defaults to a new `MockClientFido2Service`.
    ///   - state: The mock to return from `state()`. Defaults to a new `MockStateClientProtocol`.
    ///
    static func withMocks(
        fido2: MockClientFido2Service = MockClientFido2Service.withMocks(),
        state: MockStateClientProtocol = MockStateClientProtocol(),
    ) -> MockPlatformClientService {
        let mock = MockPlatformClientService()
        mock.fido2ReturnValue = fido2
        mock.stateReturnValue = state
        return mock
    }
}
