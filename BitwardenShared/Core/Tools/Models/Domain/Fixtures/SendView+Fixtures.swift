import BitwardenSdk
import Foundation

extension SendView {
    static func fixture(
        id: String = "id",
        accessId: String = "accessId",
        name: String = "name",
        notes: String? = nil,
        key: String = "key",
        password: String? = nil,
        type: SendType = .text,
        file: SendFileView? = nil,
        text: SendTextView? = nil,
        maxAccessCount: UInt32? = nil,
        accessCount: UInt32 = 0,
        disabled: Bool = false,
        hideEmail: Bool = false,
        revisionDate: DateTime = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
        deletionDate: DateTime = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
        expirationDate: DateTime? = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41)
    ) -> SendView {
        SendView(
            id: id,
            accessId: accessId,
            name: name,
            notes: notes,
            key: key,
            password: password,
            type: type,
            file: file,
            text: text,
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
