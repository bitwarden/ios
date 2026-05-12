import Testing

@testable import BitwardenShared

// MARK: - StorefrontServiceTests

struct StorefrontServiceTests {
    // MARK: Tests

    /// `isUSStorefront()` returns `true` when the storefront country code is "USA".
    @Test
    func isUSStorefront_usStorefront_returnsTrue() async {
        let subject = DefaultStorefrontService(countryCodeProvider: { "USA" })

        let result = await subject.isUSStorefront()

        #expect(result == true)
    }

    /// `isUSStorefront()` returns `false` when the storefront country code is not "USA".
    @Test
    func isUSStorefront_nonUSStorefront_returnsFalse() async {
        let subject = DefaultStorefrontService(countryCodeProvider: { "GBR" })

        let result = await subject.isUSStorefront()

        #expect(result == false)
    }

    /// `isUSStorefront()` returns `false` when the storefront is nil.
    @Test
    func isUSStorefront_nilStorefront_returnsFalse() async {
        let subject = DefaultStorefrontService(countryCodeProvider: { nil })

        let result = await subject.isUSStorefront()

        #expect(result == false)
    }
}
