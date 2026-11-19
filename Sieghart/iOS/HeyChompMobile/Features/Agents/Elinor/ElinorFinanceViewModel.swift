import SwiftUI

/// Finanças da Elinor: só leitura de valores fictícios.
@MainActor
@Observable
final class ElinorFinanceViewModel {
    let status: AgentStatus
    let budget: BudgetSummary
    let categories: [SpendingCategory]
    let transactions: [Transaction]
    let bills: [UpcomingBill]

    /// Oculta valores na tela (por exemplo, em público).
    var hidesValues = false

    init(data: any DataSource = MockDataSource()) {
        status = data.status(of: .elinor)
        budget = data.budget
        categories = data.categories
        transactions = data.transactions
        bills = data.bills
    }

    func display(_ value: String) -> String { hidesValues ? "R$ •••" : value }
}
