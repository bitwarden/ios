import Foundation

/// A type that wraps fixture data for use in mocking responses during tests.
///
public enum TestDataHelpers {
    /// The default bundle to try loading files from.
    public static var defaultBundle: Bundle?

    /// Loads the data from the provided file.
    public static func loadFromBundle(resource: String, extension: String, bundle: Bundle? = nil) -> Data {
        let resolvedBundle: Bundle
        switch bundle {
        case .none:
            guard let defaultBundle else {
                fatalError("Default test data bundle from not set properly in the test case.")
            }
            resolvedBundle = defaultBundle
        case let .some(bundle):
            resolvedBundle = bundle
        }
        guard let url = resolvedBundle.url(forResource: resource, withExtension: `extension`) else {
            // swiftlint:disable:next line_length
            fatalError("Unable to locate file \(resource).\(`extension`) in the bundle \(resolvedBundle.bundleURL.lastPathComponent).")
        }
        do {
            return try Data(contentsOf: url)
        } catch {
            // swiftlint:disable:next line_length
            fatalError("Unable to load data from \(resource).\(`extension`) in the bundle \(resolvedBundle.bundleURL.lastPathComponent). Error: \(error)")
        }
    }

    /// Convenience function for loading data from a JSON file.
    public static func loadFromJsonBundle(resource: String, bundle: Bundle? = nil) -> Data {
        loadFromBundle(resource: resource, extension: "json", bundle: bundle)
    }

    /// Convenience function for loading a JSON file into a UTF-8 string.
    public static func loadUTFStringFromJsonBundle(resource: String, bundle: Bundle? = nil) -> String? {
        let data = loadFromJsonBundle(resource: resource, bundle: bundle)
        return String(data: data, encoding: .utf8)
    }
}
