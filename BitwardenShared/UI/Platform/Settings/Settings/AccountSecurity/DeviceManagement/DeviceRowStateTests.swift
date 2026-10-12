import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - DeviceRowStateTests

struct DeviceRowStateTests {
    // MARK: Tests

    /// `formattedFirstLogin` formats the device's first-login date as "MMM d, yyyy, h:mm:ss a",
    /// including seconds.
    @Test
    func formattedFirstLogin() {
        let firstLogin = Date(timeIntervalSince1970: 1_718_020_800)
        let subject = DeviceRowState(device: .fixture(firstLogin: firstLogin))

        let expectedDateFormatter = DateFormatter()
        expectedDateFormatter.locale = Locale.current
        expectedDateFormatter.setLocalizedDateFormatFromTemplate("MMM d, yyyy")

        let expectedTimeFormatter = DateFormatter()
        expectedTimeFormatter.locale = Locale.current
        expectedTimeFormatter.setLocalizedDateFormatFromTemplate("jj:mm:ss")

        let expected = "\(expectedDateFormatter.string(from: firstLogin)), " +
            "\(expectedTimeFormatter.string(from: firstLogin))"
        #expect(subject.formattedFirstLogin == expected)
    }
}
