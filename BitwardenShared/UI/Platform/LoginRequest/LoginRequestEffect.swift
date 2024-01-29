// MARK: - LoginRequestEffect

/// Effects that can be processed by a `LoginRequestProcessor`.
enum LoginRequestEffect: Equatable {
    /// Answer the login request.
    ///
    /// - Parameter approve: Approve or deny the request.
    ///
    case answerRequest(approve: Bool)

    /// Load the user's email.
    case loadData

    /// Reload the request data.
    case reloadData
}
