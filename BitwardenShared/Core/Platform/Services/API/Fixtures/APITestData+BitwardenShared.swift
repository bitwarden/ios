import TestHelpers

/// `APITestData` helpers that load the resource from the `BitwardenShared` bundle.
extension APITestData {
    static func loadFromBundle(resource: String, extension: String) -> APITestData {
        loadFromBundle(resource: resource, extension: `extension`, bundle: .bitwardenShared)
    }

    static func loadFromJsonBundle(resource: String) -> APITestData {
        loadFromJsonBundle(resource: resource, bundle: .bitwardenShared)
    }
}
