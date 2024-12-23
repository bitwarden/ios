/// `AnyKey` is a `CodingKey` type that can be used for encoding and decoding keys for custom
/// key decoding strategies.
struct AnyKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    init(intValue: Int) {
        stringValue = String(intValue)
        self.intValue = intValue
    }
}
