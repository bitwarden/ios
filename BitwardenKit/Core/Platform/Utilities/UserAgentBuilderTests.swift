import BitwardenKit
import BitwardenKitMocks
import Testing

/// Tests for `UserAgentBuilder`.
struct UserAgentBuilderTests {
    // MARK: Tests

    /// `value` returns the correctly formatted user agent string.
    @Test
    func value() {
        let subject = UserAgentBuilder(
            appName: "Bitwarden_Mobile",
            appVersion: "2024.1.0",
            systemDevice: MockSystemDevice(
                model: "iPhone",
                systemName: "iOS",
                systemVersion: "17.0",
            ),
        )

        #expect(subject.value == "Bitwarden_Mobile/2024.1.0 (iOS 17.0; Model iPhone)")
    }
}
