import SwiftUI

// MARK: - NewDeviceNoticeView

/// A view that alerts the user to the new policy of sending emails to confirm new devices.
///
struct NewDeviceNoticeView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject public var store: Store<NewDeviceNoticeState, NewDeviceNoticeAction, NewDeviceNoticeEffect>

    var body: some View {
        HStack {
            Text("Hello world")
        }
        .task {
            await store.perform(.appeared)
        }
    }
}

// MARK: - NewDeviceNoticeView Previews

#if DEBUG
#Preview("New Device Notice") {
    NavigationView {
        NewDeviceNoticeView(
            store: Store(
                processor: StateProcessor(
                    state: NewDeviceNoticeState()
                )
            )
        )
    }
}
#endif
