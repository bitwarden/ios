// swiftlint:disable:this file_name

import BitwardenSdk
import Foundation

@testable import BitwardenShared

extension Send {
    static func fixture(
        accessCount: UInt32 = 0,
        accessId: String = "ACCESS_ID",
        deletionDate: Date = Date(year: 2024, month: 01, day: 01),
        disabled: Bool = false,
        expirationDate: Date? = nil,
        file: SendFileModel? = nil,
        hideEmail: Bool = false,
        id: String? = "1",
        key: String = "KEY",
        maxAccessCount: UInt32? = nil,
        name: String = "Test Send",
        notes: String? = nil,
        password: String? = nil,
        revisionDate: Date = Date(year: 2024, month: 01, day: 01),
        text: SendTextModel? = nil,
        type: BitwardenShared.SendType = .text
    ) -> Send {
        self.init(
            id: id,
            accessId: accessId,
            name: name,
            notes: notes,
            key: key,
            password: password,
            type: SendType(type: type),
            file: file.map(SendFile.init),
            text: text.map(SendText.init),
            maxAccessCount: maxAccessCount,
            accessCount: accessCount,
            disabled: disabled,
            hideEmail: hideEmail,
            revisionDate: revisionDate,
            deletionDate: deletionDate,
            expirationDate: expirationDate
        )
    }
}
