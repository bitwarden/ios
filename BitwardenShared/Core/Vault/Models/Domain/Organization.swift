/// A domain model containing the details of an organization.
///
struct Organization: Equatable {
    // MARK: Properties

    /// The organization's identifier.
    let id: String

    /// The organization's name.
    let name: String
}

extension Organization {
    init?(responseModel: ProfileOrganizationResponseModel) {
        guard let name = responseModel.name else { return nil }
        self.init(id: responseModel.id, name: name)
    }
}
