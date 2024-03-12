/// A data model containing the options used to generate a username, which is persisted between app
/// launches to maintain the user's selected options.
///
struct UsernameGenerationOptions: Codable, Equatable {
    // MARK: Properties

    /// The addy.io API access token to generate a forwarded email alias.
    var anonAddyApiAccessToken: String?

    /// The domain name used to generate a forwarded email alias with addy.io.
    var anonAddyDomainName: String?

    /// Whether to capitalize the random word.
    var capitalizeRandomWordUsername: Bool?

    /// The user's domain for generating catch all emails.
    var catchAllEmailDomain: String?

    /// The type of value to use when generating a catch-all email.
    var catchAllEmailType: UsernameEmailType?

    /// The DuckDuckGo API key used to generate a forwarded email alias.
    var duckDuckGoApiKey: String?

    /// The Fastmail API Key used to generate a forwarded email alias.
    var fastMailApiKey: String?

    /// The Firefox Relay API access token used to generate a forwarded email alias.
    var firefoxRelayApiAccessToken: String?

    /// The ForwardEmail API key used to generate a forwarded email alias.
    var forwardEmailApiKey: String?

    /// The ForwardEmail domain name used to generate a forwarded email alias.
    var forwardEmailDomainName: String?

    /// Whether the random word should include numbers.
    var includeNumberRandomWordUsername: Bool?

    /// The user's email for generating plus addressed emails.
    var plusAddressedEmail: String?

    /// The type of value to use when generating a plus-addressed email.
    var plusAddressedEmailType: UsernameEmailType?

    /// The service used to generate a forwarded email alias.
    var serviceType: ForwardedEmailServiceType?

    /// The simple login API key used to generate a forwarded email alias.
    var simpleLoginApiKey: String?

    /// The type of username to generate.
    var type: UsernameGeneratorType?
}
