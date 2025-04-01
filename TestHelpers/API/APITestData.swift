import Foundation

/// A type that wraps fixture data for use in mocking API responses during tests.
///
public struct APITestData {
    /// Fill me
    public let data: Data

    /// Fill me
    public static func loadFromBundle(resource: String, extension: String) -> APITestData {
        let data = TestDataHelpers.loadFromBundle(resource: resource, extension: `extension`)
        return APITestData(data: data)
    }

    /// Fill me
    public static func loadFromJsonBundle(resource: String) -> APITestData {
        loadFromBundle(resource: resource, extension: "json")
    }

    /// Fill me
    public init(data: Data) {
        self.data = data
    }
}

/// Fill me
public extension APITestData {
    /// Fill me
    static let bitwardenErrorMessage = loadFromJsonBundle(resource: "BitwardenErrorMessage")
}
