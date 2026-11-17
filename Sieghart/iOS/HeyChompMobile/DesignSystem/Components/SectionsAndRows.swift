import SwiftUI

/// Título de seção com ação opcional à direita ("Hoje" · "Ver agenda").
struct SectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.muted)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.accent)
            }
        }
        .padding(.horizontal, 4)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Linha de lista com ícone, título, detalhe e conteúdo à direita.
struct InfoRow<Trailing: View>: View {
    var symbol: String?
    var symbolTint: Color = Palette.muted
    let title: String
    var detail: String?
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 12) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(symbolTint)
                    .frame(width: 32, height: 32)
                    .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Palette.fill))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .medium)).foregroundStyle(Palette.ink)
                if let detail {
                    Text(detail).font(Typography.footnote).foregroundStyle(Palette.muted)
                }
            }
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

extension InfoRow where Trailing == EmptyView {
    init(symbol: String? = nil, symbolTint: Color = Palette.muted, title: String, detail: String? = nil) {
        self.init(symbol: symbol, symbolTint: symbolTint, title: title, detail: detail) { EmptyView() }
    }
}

/// Cartão de recurso que ainda não existe. Fica visível, mas desabilitado.
struct ComingSoonCard: View {
    let agent: Agent
    let title: String
    let detail: String
    var symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(agent.tint)
                .frame(width: 36, height: 36)
                .background(Circle().fill(agent.tint.opacity(0.12)))
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title).font(Typography.headline)
                    Spacer()
                    SoonPill(text: "Em breve")
                }
                Text(detail)
                    .font(Typography.footnote)
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .cardStyle()
        .opacity(0.85)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Recurso ainda não disponível")
    }
}

/// Cabeçalho das telas de agente: rosto com brilho, nome, papel, status e conversa.
struct AgentHeader: View {
    let agent: Agent
    let status: AgentStatus
    var onChat: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topLeading) {
                AgentDisc(agent: agent, size: 112)
                if status.isWorking {
                    TypingBadge(size: 26, outline: Palette.page).offset(x: 4, y: 6)
                }
            }
            Text(agent.name).font(Typography.title)
            Text(agent.summary)
                .font(Typography.callout)
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
            HStack(spacing: 8) {
                StatusPill(text: status.badge, isActive: status.isWorking)
                Text(status.detail).font(Typography.footnote).foregroundStyle(Palette.muted)
            }
            Button("Conversar com \(agent.name)", action: onChat)
                .buttonStyle(.chompSecondary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}
