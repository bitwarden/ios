import BitwardenKit
import SwiftUI

extension View {
    /// A view modifier that informs the guided tour the spotlight region of the
    /// view and assigns an identifier to the view.
    ///
    /// - Parameters:
    ///   - step: The guided tour step.
    ///   - perform: A closure called when the size or origin of the view changes.
    /// - Returns: A copy of the view with the guided tour step modifier applied.
    ///
    func guidedTourStep(_ step: GuidedTourStep, perform: @escaping (CGRect) -> Void) -> some View {
        onFrameChanged(id: step.id) { origin, size in
            perform(CGRect(origin: origin, size: size))
        }
        .id(step)
    }
}
