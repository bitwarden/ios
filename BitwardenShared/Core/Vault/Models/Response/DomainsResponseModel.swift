/// API response model for domain details.
///
struct DomainsResponseModel: Codable, Equatable {
    // MARK: Properties

    /// A list of equivalent domain.
    let equivalentDomains: [[String]]?

    /// A list of global equivalent domains.
    let globalEquivalentDomains: [GlobalDomains]?
}
