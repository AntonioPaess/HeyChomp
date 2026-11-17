import Foundation

enum CompanionIntroductionLanguage: String, CaseIterable, Identifiable {
    case english = "en", portuguese = "pt-BR"
    var id: String { rawValue }
    var name: String { self == .english ? "English" : "Português (Brasil)" }
}

struct CompanionIntroductionCopy {
    let headline: String
    let description: String
    let role: String
    static func forIntroduction(at time: Double, language: CompanionIntroductionLanguage = .english) -> Self {
        if time < CompanionTeamFormation.specialistStart {
            switch language {
            case .english:
                return .init(headline: "Meet the Companions.", description: "I'll introduce each one. Every Companion has a specialty.", role: "Your companion team")
            case .portuguese:
                return .init(headline: "Conheça os Companions.", description: "Vou apresentar cada um. Cada Companion tem sua especialidade.", role: "Sua equipe de companions")
            }
        }
        return forMember(CompanionTeamFormation.activeMember(at: time) ?? .sig, language: language)
    }
    static func forMember(_ member: CompanionAvatar, language: CompanionIntroductionLanguage = .english) -> Self {
        switch (language, member) {
        case (.english, .sig): .init(headline: "I'm Chomp, your orchestrator.", description: "Tell me what you need. I'll bring the right Companions and tools together.", role: "Your orchestrator")
        case (.english, .rita): .init(headline: "Breathe with me.", description: "Breaks, wellbeing and a gentler rhythm.", role: "Health & breaks")
        case (.english, .ada): .init(headline: "Code with less noise.", description: "GitHub, reviews and your next step.", role: "Code & GitHub")
        case (.english, .gantt): .init(headline: "One commitment at a time.", description: "Your calendar and a journal of how the day went.", role: "Calendar & journal")
        case (.english, .elinor): .init(headline: "Clarity for your decisions.", description: "A clearer view of your spending.", role: "Finances")
        case (.english, .toni): .init(headline: "From an idea to a message.", description: "Files, emails and thoughtful communication.", role: "Communication & files")
        case (.portuguese, .sig): .init(headline: "Sou Chomp, seu orquestrador.", description: "Diga o que precisa. Eu reúno os Companions e as ferramentas certas.", role: "Seu orquestrador")
        case (.portuguese, .rita): .init(headline: "Respira comigo.", description: "Foco, saúde e um ritmo mais leve.", role: "Foco e saúde")
        case (.portuguese, .ada): .init(headline: "Código com menos ruído.", description: "GitHub, revisões e próximos passos.", role: "Código e GitHub")
        case (.portuguese, .gantt): .init(headline: "Um compromisso por vez.", description: "Sua agenda e um diário de como foi o dia.", role: "Agenda e diário")
        case (.portuguese, .elinor): .init(headline: "Clareza para decidir.", description: "Uma visão mais clara dos seus gastos.", role: "Finanças")
        case (.portuguese, .toni): .init(headline: "Da ideia à mensagem.", description: "Arquivos, emails e comunicação com cuidado.", role: "Comunicação e arquivos")
        }
    }
}
