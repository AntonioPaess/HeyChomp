import SwiftUI

#if DEBUG
extension View {
    /// Injeta o ambiente do app nas prévias do Xcode.
    @MainActor
    func previewEnvironment(onboarded: Bool = true) -> some View {
        let model = AppModel(data: MockDataSource())
        model.hasCompletedOnboarding = onboarded
        return self
            .environment(model)
            .environment(AppRouter())
    }
}
#endif
