// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenSdk
import Foundation

// MARK: - Sends

extension SendDataModel {
    init(sendItem: SendItem) {
        // The sealed cipher blob is stored by the API as-is.
        self.init(
            data: sendItem.data,
            encryptionVersion: Int(sendItem.encryptionVersion.rawValue),
            metadata: SendItemMetadataModel(itemId: sendItem.metadata.itemId),
        )
    }
}

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
        try self.init(
            accessCount: send.accessCount,
            accessId: accessId,
            authType: SendAuthType(authType: send.authType),
            data: send.data.map(SendDataModel.init),
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
        // TODO: PM-41094 - Share: Implement Share panel and vault item menu integration.
        case .item:
            self = .unknown
        }
    }
}

// MARK: - Sends (BitwardenSdk)

extension BitwardenSdk.Send {
    init(sendData: SendData) throws {
        guard let model = sendData.model else {
            throw DataMappingError.invalidData
        }
        try self.init(sendResponseModel: model)
    }

    init(sendResponseModel model: SendResponseModel) throws {
        guard let type = BitwardenSdk.SendType(type: model.type) else {
            throw DataMappingError.invalidData
        }
        try self.init(
            id: model.id,
            accessId: model.accessId,
            name: model.name,
            notes: model.notes,
            key: model.key,
            password: model.password,
            type: type,
            file: model.file.map(SendFile.init),
            text: model.text.map(SendText.init),
            data: model.data.map(SendItem.init),
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
    init?(type: SendType) {
        switch type {
        case .file:
            self = .file
        case .text:
            self = .text
        case .unknown:
            return nil
        }
    }
}

extension BitwardenSdk.SendItem {
    init(sendDataModel model: SendDataModel) throws {
        guard let data = model.data, let itemId = model.metadata?.itemId else {
            throw DataMappingError.invalidData
        }

        // A missing encryption version defaults to v1, matching the SDK.
        var encryptionVersion = BitwardenSdk.SendEncryptionType.v1
        if let rawVersion = model.encryptionVersion {
            guard let version = UInt8(exactly: rawVersion).flatMap(BitwardenSdk.SendEncryptionType.init) else {
                throw DataMappingError.invalidData
            }
            encryptionVersion = version
        }

        self.init(
            encryptionVersion: encryptionVersion,
            data: data,
            metadata: SendItemMetadata(itemId: itemId),
        )
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
