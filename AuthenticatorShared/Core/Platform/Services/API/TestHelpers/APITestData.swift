import Foundation

/// A type that wraps fixture data for use in mocking API responses during tests.
///
struct APITestData {
    let data: Data

    static func loadFromBundle(resource: String, extension: String) -> APITestData {
        let bundle = Bundle(for: AuthenticatorTestCase.self)
        guard let url = bundle.url(forResource: resource, withExtension: `extension`) else {
            fatalError("Unable to locate file \(resource).\(`extension`) in the bundle.")
        }
        do {
            return try APITestData(data: Data(contentsOf: url))
        } catch {
            fatalError("Unable to load data from \(resource).\(`extension`) in the bundle. Error: \(error)")
        }
    }

    static func loadFromJsonBundle(resource: String) -> APITestData {
        loadFromBundle(resource: resource, extension: "json")
    }
}

extension APITestData {
    static let bitwardenErrorMessage = loadFromJsonBundle(resource: "BitwardenErrorMessage")
}
