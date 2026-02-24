import BitwardenKit
import BitwardenSdk
import Foundation

#if DEBUG
extension SendView {
    static func fixture(
        id: String? = "id",
        accessId: String = "accessId",
        name: String = "name",
        notes: String? = nil,
        key: String = "key",
        newPassword: String? = nil,
        hasPassword: Bool = false,
        type: BitwardenSdk.SendType = .text,
        file: SendFileView? = nil,
        text: SendTextView? = nil,
        maxAccessCount: UInt32? = nil,
        accessCount: UInt32 = 0,
        disabled: Bool = false,
        hideEmail: Bool = false,
        revisionDate: DateTime = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
        deletionDate: DateTime = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
        expirationDate: DateTime? = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
        emails: [String] = [],
        authType: AuthType = .none,
    ) -> SendView {
        SendView(
            id: id,
            accessId: accessId,
            name: name,
            notes: notes,
            key: key,
            newPassword: newPassword,
            hasPassword: hasPassword,
            type: type,
            file: file,
            text: text,
            maxAccessCount: maxAccessCount,
            accessCount: accessCount,
            disabled: disabled,
            hideEmail: hideEmail,
            revisionDate: revisionDate,
            deletionDate: deletionDate,
            expirationDate: expirationDate,
            emails: emails,
            authType: authType,
        )
    }
}

extension SendFileView {
    static func fixture(
        id: String? = nil,
        fileName: String = "fileName",
        size: String? = nil,
        sizeName: String? = nil,
    ) -> SendFileView {
        SendFileView(
            id: id,
            fileName: fileName,
            size: size,
            sizeName: sizeName,
        )
    }
}

extension SendTextView {
    static func fixture(
        hidden: Bool = false,
        text: String = "text",
    ) -> SendTextView {
        SendTextView(
            text: text,
            hidden: hidden,
        )
    }
}
#endif
