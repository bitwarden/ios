import Foundation

#if DEBUG

extension ItemListSection {
    static func digitsFixture(accountNames: Bool = false) -> ItemListSection { // swiftlint:disable:this function_body_length line_length
        ItemListSection(
            id: "Digits",
            items: [
                ItemListItem(
                    id: "5",
                    name: "Five",
                    accountName: accountNames ? "person@example.com" : nil,
                    itemType: .totp(
                        model: ItemListTotpItem(
                            itemView: .fixture(),
                            totpCode: TOTPCodeModel(
                                code: "12345",
                                codeGenerationDate: Date(),
                                period: 30
                            )
                        )
                    )
                ),
                ItemListItem(
                    id: "6",
                    name: "Six",
                    accountName: accountNames ? "person@example.com" : nil,
                    itemType: .totp(
                        model: ItemListTotpItem(
                            itemView: .fixture(),
                            totpCode: TOTPCodeModel(
                                code: "123456",
                                codeGenerationDate: Date(),
                                period: 30
                            )
                        )
                    )
                ),
                ItemListItem(
                    id: "7",
                    name: "Seven",
                    accountName: accountNames ? "person@example.com" : nil,
                    itemType: .totp(
                        model: ItemListTotpItem(
                            itemView: .fixture(),
                            totpCode: TOTPCodeModel(
                                code: "1234567",
                                codeGenerationDate: Date(),
                                period: 30
                            )
                        )
                    )
                ),
                ItemListItem(
                    id: "8",
                    name: "Eight",
                    accountName: accountNames ? "person@example.com" : nil,
                    itemType: .totp(
                        model: ItemListTotpItem(
                            itemView: .fixture(),
                            totpCode: TOTPCodeModel(
                                code: "12345678",
                                codeGenerationDate: Date(),
                                period: 30
                            )
                        )
                    )
                ),
                ItemListItem(
                    id: "9",
                    name: "Nine",
                    accountName: accountNames ? "person@example.com" : nil,
                    itemType: .totp(
                        model: ItemListTotpItem(
                            itemView: .fixture(),
                            totpCode: TOTPCodeModel(
                                code: "123456789",
                                codeGenerationDate: Date(),
                                period: 30
                            )
                        )
                    )
                ),
                ItemListItem(
                    id: "10",
                    name: "Ten",
                    accountName: accountNames ? "person@example.com" : nil,
                    itemType: .totp(
                        model: ItemListTotpItem(
                            itemView: .fixture(),
                            totpCode: TOTPCodeModel(
                                code: "1234567890",
                                codeGenerationDate: Date(),
                                period: 30
                            )
                        )
                    )
                ),
            ],
            name: "Digits"
        )
    }
}

#endif
