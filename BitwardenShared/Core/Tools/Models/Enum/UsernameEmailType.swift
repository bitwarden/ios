/// The value to use when generating a plus-addressed or catch-all email.
///
enum UsernameEmailType: Int, Codable {
    /// Random values should be used to generate the email.
    case random = 0

    /// A website should be used to generate the email.
    case website = 1
}
