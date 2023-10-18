import SwiftUI

/// A view containing the generator used to generate new usernames and passwords.
///
struct GeneratorView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<GeneratorState, GeneratorAction, Void>

    var body: some View {
        ScrollView {}
            .background(Asset.Colors.backgroundSecondary.swiftUIColor)
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle(Localizations.generator)
    }
}

// MARK: - Previews

struct GeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GeneratorView(store: Store(processor: StateProcessor(state: GeneratorState())))
        }
    }
}
