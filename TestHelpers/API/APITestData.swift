import Foundation

/// A type that wraps fixture data for use in mocking API responses during tests.
///
public struct APITestData {
    /// The fixture data for the API response.
    public let data: Data

    /// Initializer for APITestData with test-provided data.
    public init(data: Data) {
        self.data = data
    }

    /// Loads test data from a provided file in the test class's bundle.
    public static func loadFromBundle(resource: String, extension: String, bundle: Bundle) -> APITestData {
        let data = TestDataHelpers.loadFromBundle(resource: resource, extension: `extension`, bundle: bundle)
        return APITestData(data: data)
    }

    /// Loads test data from a provided JSON file in the test class's bundle.
    public static func loadFromJsonBundle(resource: String, bundle: Bundle) -> APITestData {
        loadFromBundle(resource: resource, extension: "json", bundle: bundle)
    }
}
