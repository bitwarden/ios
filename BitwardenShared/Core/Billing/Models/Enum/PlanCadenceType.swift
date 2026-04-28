// MARK: - PlanCadenceType

/// The billing cadence for a subscription plan.
///
enum PlanCadenceType: String, Codable, Equatable, Sendable {
    /// An annual billing cadence.
    case annually

    /// A monthly billing cadence.
    case monthly
}
