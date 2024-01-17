// swiftlint:disable:this file_name

import BitwardenSdk
import Foundation

@testable import BitwardenShared

extension Send {
    static func fixture(
        accessCount: UInt32 = 0,
        accessId: String? = "ACCESS_ID",
        deletionDate: Date = Date(),
        disabled: Bool = false,
        expirationDate: Date? = nil,
        file: SendFileModel? = nil,
        hideEmail: Bool = false,
        id: String? = UUID().uuidString,
        key: String = "KEY",
        maxAccessCount: UInt32? = nil,
        name: String = "Test Send",
        notes: String? = nil,
        password: String? = nil,
        revisionDate: Date = Date(),
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
