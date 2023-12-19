import BitwardenSdk
import Foundation

@testable import BitwardenShared

extension FolderView {
    static func fixture(
        id: Uuid = "",
        name: String = "",
        revisionDate: Date = Date.now
    ) -> FolderView {
        self.init(id: id, name: name, revisionDate: revisionDate)
    }
}

extension Folder {
    static func fixture(
        id: Uuid = "",
        name: String = "",
        revisionDate: Date = Date.now
    ) -> Folder {
        self.init(id: id, name: name, revisionDate: revisionDate)
    }
}
