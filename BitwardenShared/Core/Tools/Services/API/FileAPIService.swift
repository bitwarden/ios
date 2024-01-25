import Foundation
import Networking

/// A protocol for an API service used to make file requests.
///
protocol FileAPIService {
    /// Upload the file associated with a new attachment to a cipher..
    ///
    /// - Parameters:
    ///   - attachmentId: The id for the attachment.
    ///   - cipherId: The id for the cipher.
    ///   - data: The data representation of the file.
    ///   - type: The method for uploading the file.
    ///   - fileName: The name of the file.
    ///   - url: The URL to upload the file to.
    ///
    func uploadCipherAttachment( // swiftlint:disable:this function_parameter_count
        attachmentId: String,
        cipherId: String,
        data: Data,
        fileName: String,
        type: FileUploadType,
        url: URL
    ) async throws

    /// Upload the file associated with a new File type Send.
    ///
    /// - Parameters:
    ///   - data: The data representation of the file.
    ///   - type: The method for uploading the file.
    ///   - fileId: The id for the file.
    ///   - fileName: The name of the file.
    ///   - sendId: The id for the Send.
    ///   - url: The URL to upload the file to.
    ///
    func uploadSendFile( // swiftlint:disable:this function_parameter_count
        data: Data,
        type: FileUploadType,
        fileId: String,
        fileName: String,
        sendId: String,
        url: URL
    ) async throws
}

extension APIService: FileAPIService {
    func uploadCipherAttachment( // swiftlint:disable:this function_parameter_count
        attachmentId: String,
        cipherId: String,
        data: Data,
        fileName: String,
        type: FileUploadType,
        url: URL
    ) async throws {
        switch type {
        case .azure:
            try await azureUploadFile(data: data, url: url)
        case .direct:
            _ = try await apiService.send(DirectAttachmentUploadRequest(
                attachmentId: attachmentId,
                data: data,
                cipherId: cipherId,
                fileName: fileName
            ))
        }
    }

    func uploadSendFile( // swiftlint:disable:this function_parameter_count
        data: Data,
        type: FileUploadType,
        fileId: String,
        fileName: String,
        sendId: String,
        url: URL
    ) async throws {
        switch type {
        case .azure:
            try await azureUploadFile(data: data, url: url)
        case .direct:
            try await directUploadSendFile(
                data: data,
                fileId: fileId,
                fileName: fileName,
                sendId: sendId
            )
        }
    }

    // MARK: Private Methods

    /// Uploads a file directly to the server.
    ///
    /// - Parameters:
    ///   - data: The data representation of the file.
    ///   - fileId: The id of the file.
    ///   - fileName: The name of the file.
    ///   - sendId: The id of the Send.
    ///
    private func directUploadSendFile(data: Data, fileId: String, fileName: String, sendId: String) async throws {
        let request = DirectSendFileUploadRequest(
            data: data,
            fileName: fileName,
            fileId: fileId,
            sendId: sendId
        )
        _ = try await apiService.send(request)
    }

    /// Uploads a file to an Azure environment.
    ///
    /// - Parameters:
    ///   - data: The data representation of the file.
    ///   - url: The url to upload the file to.
    ///
    private func azureUploadFile(data: Data, url: URL) async throws {
        let request = AzureFileUploadRequest(data: data, url: url)
        let httpRequest = request.httpRequest
        _ = try await apiUnauthenticatedService.send(httpRequest)
    }
}
