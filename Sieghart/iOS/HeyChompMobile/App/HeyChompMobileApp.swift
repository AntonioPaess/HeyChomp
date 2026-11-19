import SwiftUI

/// Ponto de entrada do protótipo do HeyChomp para iPhone.
///
/// Monta o estado global (`AppModel`), a navegação (`AppRouter`) e aplica as
/// opções de lançamento (`LaunchOptions`). Não há rede, persistência nem
/// permissões reais: todos os dados vêm de `MockDataSource`.
@main
struct HeyChompMobileApp: App {
    @State private var appModel: AppModel
    @State private var router: AppRouter

    init() {
        let options = LaunchOptions.current
        let model = AppModel(data: MockDataSource())
        let router = AppRouter()
        options.apply(to: model, router: router)
        _appModel = State(initialValue: model)
        _router = State(initialValue: router)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
                .environment(router)
                .preferredColorScheme(appModel.appearance.colorScheme)
                .tint(Palette.accent)
        }
    }
}
