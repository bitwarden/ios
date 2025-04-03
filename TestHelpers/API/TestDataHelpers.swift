import Foundation

/// A type that wraps fixture data for use in mocking responses during tests.
///
public enum TestDataHelpers {
    /// The default class used to determine the bundle to load files from.
    public static var defaultBundleClass: AnyClass?

    /// Loads the data from the provided file.
    public static func loadFromBundle(resource: String, extension: String, bundleClass: AnyClass? = nil) -> Data {
        let bundle: Bundle
        switch bundleClass {
        case .none:
            guard let defaultBundleClass else {
                fatalError("Class to determine test bundle from not set properly in the test case.")
            }
            bundle = Bundle(for: defaultBundleClass)
        case let .some(bundleClass):
            bundle = Bundle(for: bundleClass.self)
        }
        guard let url = bundle.url(forResource: resource, withExtension: `extension`) else {
            fatalError("Unable to locate file \(resource).\(`extension`) in the bundle \(bundle.bundleURL.lastPathComponent).")
        }
        do {
            return try Data(contentsOf: url)
        } catch {
            fatalError("Unable to load data from \(resource).\(`extension`) in the bundle \(bundle.bundleURL.lastPathComponent). Error: \(error)")
        }
    }

    /// Convenience function for loading data from a JSON file.
    public static func loadFromJsonBundle(resource: String, bundleClass: AnyClass? = nil) -> Data {
        loadFromBundle(resource: resource, extension: "json", bundleClass: bundleClass)
    }

    /// Convenience function for loading a JSON file into a UTF-8 string.
    public static func loadUTFStringFromJsonBundle(resource: String, bundleClass: AnyClass? = nil) -> String? {
        let data = loadFromJsonBundle(resource: resource, bundleClass: bundleClass)
        return String(data: data, encoding: .utf8)
    }
}
