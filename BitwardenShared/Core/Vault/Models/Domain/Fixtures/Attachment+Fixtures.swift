import BitwardenSdk

extension Attachment {
    static func fixture(
        id: String? = "1",
        url: String? = nil,
        size: String? = nil,
        sizeName: String? = nil,
        fileName: String? = nil,
        key: String? = nil
    ) -> Attachment {
        .init(
            id: id,
            url: url,
            size: size,
            sizeName: sizeName,
            fileName: fileName,
            key: key
        )
    }
}
