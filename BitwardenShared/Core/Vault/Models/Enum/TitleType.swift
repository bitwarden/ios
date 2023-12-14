/// An enum that describes how a Identity title should be matched.
///
enum TitleType: String, Codable, Equatable, Hashable, Menuable {
    // swiftlint:disable identifier_name

    /// Mr title for adult males.
    case mr = "Mr"

    /// Mrs title for married or widowed women.
    case mrs = "Mrs"

    /// Ms title for women regardless of marital status.
    case ms = "Ms"

    /// Mx title for individuals who prefer not to specify their gender or identify as non-binary.
    case mx = "Mx"

    /// Dr title for individuals with a doctoral degree.
    case dr = "Dr"
    // swiftlint:enable identifier_name

    static var defaultStateTitle: String {
        "--\(Localizations.select)--"
    }

    var localizedName: String {
        switch self {
        case .mr: Localizations.mr
        case .mrs: Localizations.mrs
        case .ms: Localizations.ms
        case .mx: Localizations.mx
        case .dr: Localizations.dr
        }
    }
}

extension TitleType: CaseIterable {
    static var allCases: [TitleType] = [.mr, .mrs, .ms, .mx, .dr]
}
