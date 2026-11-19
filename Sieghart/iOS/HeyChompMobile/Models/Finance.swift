import Foundation

/// Resumo do mês feito pela Elinor. Valores são texto fixo, já formatados em reais.
struct BudgetSummary: Hashable, Sendable {
    var month: String
    var spent: String
    var limit: String
    var progress: Double
    var remainingNote: String
}

struct SpendingCategory: Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    var symbol: String
    var amount: String
    var progress: Double
}

struct Transaction: Identifiable, Hashable, Sendable {
    let id: String
    var title: String
    var category: String
    var amount: String
    var date: String
}

struct UpcomingBill: Identifiable, Hashable, Sendable {
    let id: String
    var title: String
    var due: String
    var amount: String
}
