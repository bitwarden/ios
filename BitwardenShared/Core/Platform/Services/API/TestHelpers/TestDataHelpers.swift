import Foundation

class BitwardenTestCaseBundleClass {}

/// A type that wraps fixture data for use in mocking responses during tests.
///
enum TestDataHelpers {
    static func loadFromBundle(resource: String, extension: String) -> Data {
        let bundle = Bundle(for: BitwardenTestCaseBundleClass.self)
        guard let url = bundle.url(forResource: resource, withExtension: `extension`) else {
            fatalError("Unable to locate file \(resource).\(`extension`) in the bundle.")
        }
        do {
            return try Data(contentsOf: url)
        } catch {
            fatalError("Unable to load data from \(resource).\(`extension`) in the bundle. Error: \(error)")
        }
    }

    static func loadFromJsonBundle(resource: String) -> Data {
        loadFromBundle(resource: resource, extension: "json")
    }

    static func loadUTFStringFromJsonBundle(resource: String) -> String? {
        let data = loadFromJsonBundle(resource: resource)
        return String(data: data, encoding: .utf8)
    }
}
