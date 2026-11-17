import SwiftUI

/// Tela da Elinor: orçamento do mês, categorias, próximas contas, lançamentos
/// e Apple Pay (em breve).
struct ElinorFinanceView: View {
    @State private var viewModel: ElinorFinanceViewModel

    init(viewModel: ElinorFinanceViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        AgentScreen(agent: .elinor, status: viewModel.status) {
            PerchedCard(agent: .elinor, caption: viewModel.budget.month) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(viewModel.display(viewModel.budget.spent)).font(Typography.number(36))
                        Text("de \(viewModel.display(viewModel.budget.limit))").font(Typography.callout).foregroundStyle(Palette.muted)
                        Spacer()
                        Button {
                            withAnimation(Motion.feedback) { viewModel.hidesValues.toggle() }
                        } label: {
                            Image(systemName: viewModel.hidesValues ? "eye.slash" : "eye")
                        }
                        .foregroundStyle(Palette.muted)
                        .accessibilityLabel(viewModel.hidesValues ? "Mostrar valores" : "Ocultar valores")
                    }
                    ProgressTrack(progress: viewModel.budget.progress, tint: Agent.elinor.tint, height: 8)
                    Text(viewModel.budget.remainingNote).font(Typography.footnote).foregroundStyle(Palette.muted)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Categorias")
                VStack(spacing: 12) {
                    ForEach(viewModel.categories) { category in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label(category.name, systemImage: category.symbol).font(Typography.callout)
                                Spacer()
                                Text(viewModel.display(category.amount)).font(.system(size: 15, weight: .semibold).monospacedDigit())
                            }
                            ProgressTrack(progress: category.progress, tint: Agent.elinor.tint)
                        }
                    }
                }
                .cardStyle()
            }

            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Próximas contas")
                VStack(spacing: 0) {
                    ForEach(viewModel.bills) { bill in
                        InfoRow(symbol: "calendar.badge.clock", symbolTint: Agent.elinor.tint, title: bill.title, detail: bill.due) {
                            Text(viewModel.display(bill.amount)).font(.system(size: 15, weight: .semibold).monospacedDigit())
                        }
                        if bill.id != viewModel.bills.last?.id { Divider().padding(.leading, 44) }
                    }
                }
                .cardStyle(padding: 14)
            }

            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Lançamentos")
                VStack(spacing: 0) {
                    ForEach(viewModel.transactions) { item in
                        InfoRow(title: item.title, detail: "\(item.category) · \(item.date)") {
                            Text(viewModel.display(item.amount)).font(.system(size: 15, weight: .medium).monospacedDigit()).foregroundStyle(Palette.ink)
                        }
                        if item.id != viewModel.transactions.last?.id { Divider() }
                    }
                }
                .cardStyle(padding: 14)
            }

            ComingSoonCard(agent: .elinor, title: "Apple Pay", detail: "Ver compras do Apple Pay direto no resumo. Ainda não existe: os valores acima são fictícios.", symbol: "creditcard")
        }
    }
}

#Preview("Elinor") {
    NavigationStack { ElinorFinanceView(viewModel: ElinorFinanceViewModel()) }
        .previewEnvironment()
}
