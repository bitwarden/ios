import Foundation

/// A type that wraps fixture data for use in mocking API responses during tests.
///
struct APITestData {
    let data: Data

    static func loadFromBundle(resource: String, extension: String) -> APITestData {
        let data = TestDataHelpers.loadFromBundle(resource: resource, extension: `extension`)
        return APITestData(data: data)
    }

    static func loadFromJsonBundle(resource: String) -> APITestData {
        loadFromBundle(resource: resource, extension: "json")
    }
}

extension APITestData {
    static let bitwardenErrorMessage = loadFromJsonBundle(resource: "BitwardenErrorMessage")
}
