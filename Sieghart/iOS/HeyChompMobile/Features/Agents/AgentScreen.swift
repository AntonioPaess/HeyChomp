import SwiftUI

/// Moldura comum das telas de agente: brilho na cor dele no topo, cabeçalho
/// com rosto e status, e o conteúdo específico embaixo.
struct AgentScreen<Content: View>: View {
    let agent: Agent
    let status: AgentStatus
    @ViewBuilder var content: () -> Content
    @Environment(AppRouter.self) private var router

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.sectionSpacing) {
                AgentHeader(agent: agent, status: status) { router.push(.chat(nil)) }
                content()
            }
            .padding(.horizontal, Metrics.screenPadding)
            .padding(.bottom, 32)
        }
        .background(
            ZStack(alignment: .top) {
                Palette.page
                RadialGradient(colors: [agent.tint.opacity(0.22), .clear], center: .top, startRadius: 0, endRadius: 320)
                    .frame(height: 360)
            }
            .ignoresSafeArea()
        )
        .navigationTitle(agent.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
