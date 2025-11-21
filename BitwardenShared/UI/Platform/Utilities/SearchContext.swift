import SwiftUI

/// Helper context object to use on searches so we can debounce the search query input and improve performance.
class SearchContext: ObservableObject {
    /// The original published search query.
    @Published var query = ""
    /// The debounced published search query with a time interval of 0.25 seconds.
    @Published var debouncedQuery = ""

    /// Initializes the `SearchContext` and configures the debounce publisher.
    init() {
        $query
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .assign(to: &$debouncedQuery)
    }
}
