/// Helper to dump options data so it's easier to assert in tests.
enum TextAutofillOptionsHelperDumper {
    /// Dumps the options into lines to be asserted more easily.
    static func dump(_ options: [(localizedOption: String, textToInsert: String)]) -> String {
        options.reduce(into: "") { result, option in
            result.append("\(option.localizedOption), \(option.textToInsert)")
            if let last = options.last, option != last {
                result.append("\n")
            }
        }
    }
}
