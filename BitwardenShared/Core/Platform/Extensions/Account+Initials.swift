import Foundation

extension Account {
    /// A function to convert a name or user email to initials
    ///   - Parameter profile: The profile to use for the initials
    ///   - Returns: A `String?` representing user initials
    ///
    func initials() -> String? {
        var initials: String?
        if let name = profile.name,
           !name.isEmpty {
            initials = extractInitials(
                from: name
            )
        } else {
            // Create a separators set that includes punctuation characters and symbols
            let separators = CharacterSet.punctuationCharacters
                .union(.symbols)

            // Extract initials from the part of the email before '@'
            if let emailPrefix = profile.email.components(separatedBy: "@").first {
                return extractInitials(
                    from: emailPrefix,
                    separators: separators
                )
            }
        }
        guard let initials else { return nil }
        return initials
    }

    /// A function to convert a string to component initials
    ///   - Parameters:
    ///     - string: The string to be converted to initials
    ///     - limit: The maximum number of initials
    ///     - separators: The characters used to separate string components
    ///   - Returns: A `String?` representing component initials
    ///
    private func extractInitials(
        from string: String,
        limit: Int = 2,
        separators: CharacterSet = .whitespacesAndNewlines
    ) -> String? {
        var initials: String?
        let components = string.components(separatedBy: separators)
        if let firstComponent = components.first, components.count == 1 {
            // If there's only one component, return up to the first two characters of it
            initials = String(firstComponent.prefix(2)).uppercased()
        } else {
            // Otherwise, proceed with the usual logic to get the first character of each component
            initials = components
                .compactMap { component in
                    component.first
                }
                .prefix(limit)
                .map { String($0) }
                .joined()
        }
        guard let initials,
              !initials.isEmpty else { return nil }
        return initials.uppercased()
    }
}
