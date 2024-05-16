import Foundation

/// A type that wraps import format fixture data for use in tests.
///
struct ImportTestData {
    let data: Data

    static func loadFromBundle(resource: String, extension: String) -> ImportTestData {
        let bundle = Bundle(for: AuthenticatorTestCase.self)
        guard let url = bundle.url(forResource: resource, withExtension: `extension`) else {
            fatalError("Unable to locate file \(resource).\(`extension`) in the bundle.")
        }
        do {
            return try ImportTestData(data: Data(contentsOf: url))
        } catch {
            fatalError("Unable to load data from \(resource).\(`extension`) in the bundle. Error: \(error)")
        }
    }

    static func loadFromJsonBundle(resource: String) -> ImportTestData {
        loadFromBundle(resource: resource, extension: "json")
    }
}

extension ImportTestData {
    static let bitwardenJson = loadFromJsonBundle(resource: "BitwardenExport")
    static let raivoJson = loadFromJsonBundle(resource: "RaivoExport")
}
