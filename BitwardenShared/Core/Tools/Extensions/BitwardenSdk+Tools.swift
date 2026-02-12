// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenSdk

// MARK: - Sends

extension SendFileModel {
    init(sendFile: SendFile) {
        self.init(
            fileName: sendFile.fileName,
            id: sendFile.id,
            size: sendFile.size,
            sizeName: sendFile.sizeName,
        )
    }
}

extension SendResponseModel {
    init(send: Send) throws {
        guard let id = send.id, let accessId = send.accessId else { throw DataMappingError.missingId }
        self.init(
            accessCount: send.accessCount,
            accessId: accessId,
            authType: SendAuthType(authType: send.authType),
            deletionDate: send.deletionDate,
            disabled: send.disabled,
            emails: send.emails,
            expirationDate: send.expirationDate,
            file: send.file.map(SendFileModel.init),
            hideEmail: send.hideEmail,
            id: id,
            key: send.key,
            maxAccessCount: send.maxAccessCount,
            name: send.name,
            notes: send.notes,
            password: send.password,
            revisionDate: send.revisionDate,
            text: send.text.map(SendTextModel.init),
            type: SendType(sendType: send.type),
        )
    }
}

extension SendTextModel {
    init(sendText: SendText) {
        self.init(
            hidden: sendText.hidden,
            text: sendText.text,
        )
    }
}

extension SendType {
    init(sendType: BitwardenSdk.SendType) {
        switch sendType {
        case .file:
            self = .file
        case .text:
            self = .text
        }
    }
}

// MARK: - Sends (BitwardenSdk)

extension BitwardenSdk.Send {
    init(sendData: SendData) throws {
        guard let model = sendData.model else {
            throw DataMappingError.invalidData
        }
        self.init(sendResponseModel: model)
    }

    init(sendResponseModel model: SendResponseModel) {
        self.init(
            id: model.id,
            accessId: model.accessId,
            name: model.name,
            notes: model.notes,
            key: model.key,
            password: model.password,
            type: BitwardenSdk.SendType(type: model.type),
            file: model.file.map(SendFile.init),
            text: model.text.map(SendText.init),
            maxAccessCount: model.maxAccessCount,
            accessCount: model.accessCount,
            disabled: model.disabled,
            hideEmail: model.hideEmail,
            revisionDate: model.revisionDate,
            deletionDate: model.deletionDate,
            expirationDate: model.expirationDate,
            emails: model.emails,
            authType: model.authType?.sdkAuthType ?? .none,
        )
    }
}

extension BitwardenSdk.SendType {
    init(type: SendType) {
        switch type {
        case .file:
            self = .file
        case .text:
            self = .text
        }
    }
}

extension BitwardenSdk.SendFile {
    init(sendFileModel model: SendFileModel) {
        self.init(
            id: model.id,
            fileName: model.fileName,
            size: model.size,
            sizeName: model.sizeName,
        )
    }
}

extension BitwardenSdk.SendText {
    init(sendTextModel model: SendTextModel) {
        self.init(
            text: model.text,
            hidden: model.hidden,
        )
    }
}
