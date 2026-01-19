import Testing

@testable import BitwardenShared

class LoadingStateTests {
    // MARK: Tests

    /// `isLoading` returns `true` when the state is `.loading` or `false` otherwise.
    @Test
    func isLoading() {
        #expect(LoadingState<String>.loading(nil).isLoading == true)
        #expect(LoadingState<String>.loading("test").isLoading == true)

        #expect(LoadingState<String>.error(errorMessage: "An error occurred").isLoading == false)
        #expect(LoadingState<String>.data("Data").isLoading == false)
    }
}
