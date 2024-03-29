import BitwardenSdk
import Networking

@testable import AuthenticatorShared

extension ServiceContainer {
    static func withMocks(
        timeProvider: TimeProvider = MockTimeProvider(.currentTime)
    ) -> ServiceContainer {
        ServiceContainer(
            timeProvider: timeProvider
        )
    }
}
