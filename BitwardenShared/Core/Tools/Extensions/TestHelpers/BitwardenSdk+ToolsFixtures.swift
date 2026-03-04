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
        emails: String? = nil,
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
        type: BitwardenShared.SendType = .text,
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
            expirationDate: expirationDate,
            emails: emails,
            authType: AuthType.none,
        )
    }
}

extension SendFileModel {
    static func fixture(
        id: String? = nil,
        fileName: String = "fileName",
        size: String? = nil,
        sizeName: String? = nil,
    ) -> SendFileModel {
        SendFileModel(
            fileName: fileName,
            id: id,
            size: size,
            sizeName: sizeName,
        )
    }
}

extension SendTextModel {
    static func fixture(
        hidden: Bool = false,
        text: String = "text",
    ) -> SendTextModel {
        SendTextModel(
            hidden: hidden,
            text: text,
        )
    }
}
