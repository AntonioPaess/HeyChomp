import Foundation

/// Evento da agenda do Gantt. O horário é texto fixo: o protótipo não calcula datas.
struct CalendarEvent: Identifiable, Hashable, Sendable {
    let id: String
    var time: String
    var endTime: String?
    var title: String
    var location: String?
    /// Destacado como próximo compromisso.
    var isNext: Bool = false
    /// Já passou (aparece apagado).
    var isPast: Bool = false
    /// Texto relativo ("em 1h20"), só para o próximo.
    var relative: String?
}

/// Dia na faixa semanal da agenda.
struct WeekDay: Identifiable, Hashable, Sendable {
    let id: Int
    var weekday: String
    var number: Int
    var hasEvents: Bool
}

/// Item do bullet journal, com os símbolos clássicos do método.
struct JournalEntry: Identifiable, Hashable, Sendable {
    enum Kind: String, Hashable, Sendable {
        case task = "•"
        case event = "○"
        case note = "–"
    }
    enum State: Hashable, Sendable {
        case open, done, migrated
    }

    let id: String
    var kind: Kind
    var text: String
    var state: State = .open
}
