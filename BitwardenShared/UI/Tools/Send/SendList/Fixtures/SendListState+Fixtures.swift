import Foundation

@testable import BitwardenShared

extension SendListState {
    static var empty: SendListState {
        SendListState()
    }

    static var content: SendListState {
        let date = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41)
        return SendListState(
            sections: [
                SendListSection(
                    id: "1",
                    isCountDisplayed: false,
                    items: [
                        SendListItem(
                            id: "11",
                            itemType: .group(.text, 42)
                        ),
                        SendListItem(
                            id: "12",
                            itemType: .group(.file, 1)
                        ),
                    ],
                    name: "Types"
                ),
                SendListSection(
                    id: "2",
                    isCountDisplayed: true,
                    items: [
                        SendListItem(
                            sendView: .init(
                                id: "21",
                                accessId: "21",
                                name: "File Send",
                                notes: nil,
                                key: "",
                                newPassword: nil,
                                hasPassword: false,
                                type: .file,
                                file: nil,
                                text: nil,
                                maxAccessCount: nil,
                                accessCount: 0,
                                disabled: false,
                                hideEmail: false,
                                revisionDate: date,
                                deletionDate: date.advanced(by: 100),
                                expirationDate: date.advanced(by: 100)
                            )
                        )!,
                        SendListItem(
                            sendView: .init(
                                id: "22",
                                accessId: "22",
                                name: "Text Send",
                                notes: nil,
                                key: "",
                                newPassword: nil,
                                hasPassword: false,
                                type: .text,
                                file: nil,
                                text: nil,
                                maxAccessCount: nil,
                                accessCount: 0,
                                disabled: false,
                                hideEmail: false,
                                revisionDate: date,
                                deletionDate: date.advanced(by: 100),
                                expirationDate: date.advanced(by: 100)
                            )
                        )!,
                        SendListItem(
                            sendView: .init(
                                id: "23",
                                accessId: "23",
                                name: "All Statuses",
                                notes: nil,
                                key: "",
                                newPassword: nil,
                                hasPassword: true,
                                type: .text,
                                file: nil,
                                text: nil,
                                maxAccessCount: 1,
                                accessCount: 1,
                                disabled: true,
                                hideEmail: true,
                                revisionDate: date,
                                deletionDate: date,
                                expirationDate: date.advanced(by: -1)
                            )
                        )!,
                    ],
                    name: "All sends"
                ),
            ]
        )
    }
}
