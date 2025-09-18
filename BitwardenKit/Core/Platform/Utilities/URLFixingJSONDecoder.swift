import Foundation

// MARK: - URLFixingJSONDecoder

/// Custom Decoder that fixes data to decode so if there's something that should be converted to URL
/// but can't because of lacking scheme, it will prefix it with "http" when it's an IP address and with
/// "https" in any other case.
public class URLFixingJSONDecoder: JSONDecoder, @unchecked Sendable {
    /// The property names of the JSON to decode that are an array of URL objects.
    private let urlArrayPropertyNames: [String]

    /// initializes a `URLFixingJSONDecoder`.
    /// - Parameter urlArrayPropertyNames: The property names of the JSON to decode that are an array of URL objects.
    /// These properties will go through this custom URL fixing logic.
    public init(urlArrayPropertyNames: [String]) {
        self.urlArrayPropertyNames = urlArrayPropertyNames
    }

    override public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        let fixedData = try preprocessURLs(in: data)
        return try super.decode(type, from: fixedData)
    }

    /// Performs the preprocessing of the data and fixes the URL properties if needed.
    /// - Parameter data: The Data to process and fix if needed.
    /// - Returns: The fixed data.
    private func preprocessURLs(in data: Data) throws -> Data {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) else {
            return data
        }

        let fixedObject = fixURLsInObject(jsonObject)
        return try JSONSerialization.data(withJSONObject: fixedObject)
    }

    /// Traverses the JSON object and fixes the URL array properties if needed.
    /// - Parameter object: The JSON object to check.
    /// - Returns: The fixed JSON object.
    private func fixURLsInObject(_ object: Any) -> Any {
        if let dictionary = object as? [String: Any] {
            var fixedDict = [String: Any]()
            for (key, value) in dictionary {
                if isURLArrayProperty(key), let urlArray = value as? [String] {
                    // Auto-detect URL array properties
                    fixedDict[key] = urlArray.map { $0.fixURLIfNeeded() }
                } else {
                    // Recursively process nested objects
                    fixedDict[key] = fixURLsInObject(value)
                }
            }
            return fixedDict
        } else if let array = object as? [Any] {
            return array.map { fixURLsInObject($0) }
        } else {
            return object
        }
    }

    /// Checks whether the `key` passed is one of the property names configured for URL arrays.
    /// - Parameter key: JSON key to check.
    /// - Returns: `true` if the `key` is one of the property names, `false` otherwise.
    private func isURLArrayProperty(_ key: String) -> Bool {
        let lowercasedKey = key.lowercased()
        return urlArrayPropertyNames.contains { lowercasedKey == $0 }
    }
}
