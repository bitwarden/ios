@testable import BitwardenShared

class MockRegionSelectionDelegate: RegionSelectionDelegate {
    var regions: [RegionType] = []

    func regionSelected(_ region: RegionType) {
        regions.append(region)
    }
}
