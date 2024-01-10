import BitwardenSdk
import Foundation
import Networking

struct SendRequestModel: JSONRequestBody {
    var deletionDate: Date
    var disabled: Bool
    var expirationDate: Date?
    var file: SendFileModel?
    var hideEmail: Bool?
    var key: String
    var maxAccessCount: Int32?
    var name: String?
    var notes: String?
    var password: String?
    var text: SendTextModel?
}
