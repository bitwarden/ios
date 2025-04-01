import Foundation

/// A type that wraps fixture data for use in mocking responses during tests.
///
public enum TestDataHelpers {
    /// Fill me
    public static var bundleClass: AnyClass?

    /// Fill me
    public static func loadFromBundle(resource: String, extension: String) -> Data {
        guard let bundleClass else {
            fatalError("Class to determine test bundle from not set properly in the test case.")
        }
        let bundle = Bundle(for: bundleClass.self)
        guard let url = bundle.url(forResource: resource, withExtension: `extension`) else {
            fatalError("Unable to locate file \(resource).\(`extension`) in the bundle.")
        }
        do {
            return try Data(contentsOf: url)
        } catch {
            fatalError("Unable to load data from \(resource).\(`extension`) in the bundle. Error: \(error)")
        }
    }

    /// Fill me
    public static func loadFromJsonBundle(resource: String) -> Data {
        loadFromBundle(resource: resource, extension: "json")
    }

    /// Fill me
    public static func loadUTFStringFromJsonBundle(resource: String) -> String? {
        let data = loadFromJsonBundle(resource: resource)
        return String(data: data, encoding: .utf8)
    }
}
