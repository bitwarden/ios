import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - DeviceRowStateTests

struct DeviceRowStateTests {
    // MARK: Tests

    /// `formattedFirstLogin` formats the device's first-login date with medium date and short
    /// time styles.
    @Test
    func formattedFirstLogin() {
        let firstLogin = Date(timeIntervalSince1970: 1_718_020_800)
        let subject = DeviceRowState(device: .fixture(firstLogin: firstLogin))

        let expectedFormatter = DateFormatter()
        expectedFormatter.dateStyle = .medium
        expectedFormatter.timeStyle = .short

        #expect(subject.formattedFirstLogin == expectedFormatter.string(from: firstLogin))
    }
}
