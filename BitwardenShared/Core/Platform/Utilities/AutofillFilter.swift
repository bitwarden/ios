import BitwardenSdk

struct AutofillFilter: Menuable, Codable {
    var idType: AutofillFilterType
    var folderName: String?

    var localizedName: String {
        switch idType {
        case .none:
            "None"
        case .favorites:
            Localizations.favorites
        case .folder:
            folderName ?? "Unknown"
        }
    }

    init(idType: AutofillFilterType, folderName: String? = nil) {
        self.idType = idType
        self.folderName = folderName
    }
}

enum AutofillFilterType: Equatable, Hashable, Codable {
    case none
    case favorites
    case folder(Uuid)
}
