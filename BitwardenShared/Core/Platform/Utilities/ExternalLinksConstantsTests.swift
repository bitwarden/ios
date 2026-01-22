import BitwardenKit
import Foundation
import Testing

@testable import BitwardenShared

// MARK: - ExternalLinksConstantsTests

class ExternalLinksConstantsTests {
    // MARK: Tests

    @Test
    func upgradeToPremium() {
        let expected = URL("https://base.com/#/settings/subscription/premium?callToAction=upgradeToPremium")!
        #expect(ExternalLinksConstants.upgradeToPremium(base: URL("https://base.com")!) == expected)
    }
}
