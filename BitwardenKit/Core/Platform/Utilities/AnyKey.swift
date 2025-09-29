/// `AnyKey` is a `CodingKey` type that can be used for encoding and decoding keys for custom
/// key decoding strategies.
public struct AnyKey: CodingKey {
    public let stringValue: String
    public let intValue: Int?

    public init(stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    public init(intValue: Int) {
        stringValue = String(intValue)
        self.intValue = intValue
    }
}
