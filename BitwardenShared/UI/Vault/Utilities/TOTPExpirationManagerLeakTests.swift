import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

class TOTPExpirationManagerLeakTests: BitwardenTestCase {
    /// Regression test for the retain cycle in `DefaultTOTPExpirationManager`
    /// where the Timer scheduled in `init` captured `self` strongly,
    /// preventing `deinit` (and therefore `cleanup()`) from ever running.
    ///
    /// Uses a weak reference to assert the manager deallocates after its
    /// only strong reference is dropped. `leaks(1)`-based audits don't
    /// catch this class of bug because the Timer is held by the main
    /// RunLoop, keeping everything reachable from a process root.
    @MainActor
    func test_deallocatesAfterCallerReleasesReference() async throws {
        weak var weakManager: DefaultTOTPExpirationManager?

        do {
            let manager = DefaultTOTPExpirationManager(
                timeProvider: MockTimeProvider(.currentTime),
                onExpiration: { _ in },
            )
            weakManager = manager
        }

        // Let any in-flight work settle so deinit (if it could fire) would have.
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertNil(
            weakManager,
            """
            DefaultTOTPExpirationManager should deallocate after the caller \
            releases its reference; a retain cycle in the Timer's block \
            prevents deinit from running.
            """,
        )
    }
}
