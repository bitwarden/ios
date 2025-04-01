import Foundation

/// A type that wraps fixture data for use in mocking responses during tests.
///
public enum TestDataHelpers {
    /// The class used to determine the bundle to load files from.
    public static var bundleClass: AnyClass?

    /// Loads the data from the provided file.
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

    /// Convenience function for loading data from a JSON file.
    public static func loadFromJsonBundle(resource: String) -> Data {
        loadFromBundle(resource: resource, extension: "json")
    }

    /// Convenience function for loading a JSON file into a UTF-8 string.
    public static func loadUTFStringFromJsonBundle(resource: String) -> String? {
        let data = loadFromJsonBundle(resource: resource)
        return String(data: data, encoding: .utf8)
    }
}
