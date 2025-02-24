import Foundation

extension Data {
    /// Returns a `String` of the data decoded to JSON and pretty printed.
    ///
    var prettyPrintedJson: String? {
        guard let object = try? JSONSerialization.jsonObject(with: self),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let prettyPrintedString = String(data: data, encoding: .utf8) else {
            return nil
        }
        return prettyPrintedString
    }
}

extension String {
    /// Returns a pretty printed JSON string.
    ///
    var prettyPrintedJson: String? {
        Data(utf8).prettyPrintedJson
    }
}
