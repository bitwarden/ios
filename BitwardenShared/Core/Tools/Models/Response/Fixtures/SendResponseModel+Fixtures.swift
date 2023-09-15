import Foundation

@testable import BitwardenShared

extension SendResponseModel {
    static func fixture(
        accessCount: Int = 0,
        accessId: String? = nil,
        deletionDate: Date,
        disabled: Bool = false,
        expirationDate: Date? = nil,
        file: SendFileModel? = nil,
        hideEmail: Bool = false,
        id: String = UUID().uuidString,
        key: String? = nil,
        maxAccessCount: Int? = nil,
        name: String? = nil,
        notes: String? = nil,
        password: String? = nil,
        revisionDate: Date,
        text: SendTextModel? = nil,
        type: SendType = .text
    ) -> SendResponseModel {
        self.init(
            accessCount: accessCount,
            accessId: accessId,
            deletionDate: deletionDate,
            disabled: disabled,
            expirationDate: expirationDate,
            file: file,
            hideEmail: hideEmail,
            id: id,
            key: key,
            maxAccessCount: maxAccessCount,
            name: name,
            notes: notes,
            password: password,
            revisionDate: revisionDate,
            text: text,
            type: type
        )
    }
}
