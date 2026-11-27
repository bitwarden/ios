import BitwardenKit
import Foundation
import Testing

// MARK: - RegionTypeTests

struct RegionTypeTests {
    // MARK: Tests

    /// `errorReporterName` returns the name used by the error reporter for each region.
    @Test(arguments: [
        (RegionType.europe, "EU"),
        (RegionType.gov, "Gov"),
        (RegionType.internal, "Internal"),
        (RegionType.selfHosted, "Self-Hosted"),
        (RegionType.unitedStates, "US"),
    ])
    func errorReporterName(region: RegionType, expectedName: String) {
        #expect(region.errorReporterName == expectedName)
    }

    /// `init(baseURL:)` resolves an environment base URL to the matching region.
    @Test(arguments: [
        (EnvironmentURLData.defaultUS.base, RegionType.unitedStates),
        (EnvironmentURLData.defaultEU.base, RegionType.europe),
        (URL(string: "https://bitwarden.pw"), RegionType.internal),
        (URL(string: "https://qa-team.sh.bitwarden.pw"), RegionType.internal),
        (URL(string: "https://notbitwarden.pw"), RegionType.selfHosted),
        (URL(string: "https://selfhosted.com"), RegionType.selfHosted),
        (nil, RegionType.selfHosted),
    ])
    func initBaseURL(baseURL: URL?, expectedRegion: RegionType) {
        #expect(RegionType(baseURL: baseURL) == expectedRegion)
    }
}
