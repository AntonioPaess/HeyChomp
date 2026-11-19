import SwiftUI

/// Raiz: primeiro uso ou pilha de navegação a partir da tela inicial.
///
/// Também apresenta as folhas e a sessão de voz, que podem ser abertas de
/// qualquer tela pelo `AppRouter`.
struct RootView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        Group {
            if appModel.hasCompletedOnboarding {
                NavigationStack(path: $router.path) {
                    HomeView(viewModel: HomeViewModel(data: appModel.data))
                        .navigationDestination(for: Route.self) { route in
                            ScreenFactory.view(for: route, data: appModel.data)
                        }
                }
                .transition(.opacity)
            } else {
                OnboardingView(viewModel: OnboardingViewModel(data: appModel.data))
                    .transition(.opacity)
            }
        }
        .sheet(item: $router.sheet) { sheet in
            ScreenFactory.view(for: sheet, data: appModel.data)
        }
        .fullScreenCover(isPresented: $router.isVoiceSessionPresented) {
            VoiceSessionView(viewModel: VoiceSessionViewModel(data: appModel.data))
        }
    }
}
