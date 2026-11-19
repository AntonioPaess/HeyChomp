import Foundation

/// Dados fictícios do protótipo, num único lugar.
///
/// Tudo é fixo e escrito à mão para a terça, 17 de novembro, às 14:40, o mesmo
/// momento dos conceitos em `Design/Concepts/mobile-2026-11-17/`. Nada é lido
/// do aparelho e nada é calculado. A pessoa fictícia se chama Lia.
struct MockDataSource: DataSource {
    let userName = "Lia"
    let todayLabel = "Terça, 17 de novembro"

    // MARK: Equipe

    let teamStatus: [AgentStatus] = [
        AgentStatus(agent: .chomp, activity: .working, detail: "Montando seu resumo", badge: "Ativo"),
        AgentStatus(agent: .rita, activity: .working, detail: "Foco · 18 min restantes", badge: "Em foco"),
        AgentStatus(agent: .ada, activity: .idle, detail: "Nenhuma tarefa de código", badge: "Livre"),
        AgentStatus(agent: .gantt, activity: .working, detail: "Revisão do design às 16:00", badge: "1h20"),
        AgentStatus(agent: .elinor, activity: .idle, detail: "Novembro: 62% do orçamento", badge: "Livre"),
        AgentStatus(agent: .toni, activity: .idle, detail: "3 itens copiados hoje", badge: "Livre"),
    ]

    let suggestion = ChompSuggestion(
        text: "Você tem 1h20 livre antes da revisão das 16h. Quer que a Rita segure o foco até lá?",
        primaryAction: "Iniciar foco",
        secondaryAction: "Agora não",
        target: .rita
    )

    let permissions: [PermissionItem] = [
        PermissionItem(id: "notifications", title: "Notificações", detail: "Para o Gantt avisar antes dos compromissos.", symbol: "bell.badge", owner: .gantt),
        PermissionItem(id: "calendar", title: "Calendário", detail: "Para o Gantt ler e criar eventos.", symbol: "calendar", owner: .gantt),
        PermissionItem(id: "microphone", title: "Microfone", detail: "Para falar com o Chomp.", symbol: "mic", owner: .chomp),
        PermissionItem(id: "focus", title: "Modo Foco", detail: "Para a Rita silenciar o iPhone nas sessões.", symbol: "moon", owner: .rita),
    ]

    // MARK: Conversas

    let conversations: [Conversation] = [
        Conversation(
            id: "budget-reminder",
            title: "Revisar orçamento",
            timestamp: "14:38",
            messages: [
                ChatMessage(id: "m1", kind: .user, text: "Me lembra de revisar o orçamento antes da reunião de amanhã"),
                ChatMessage(id: "m2", kind: .agent(.chomp), text: "Combinado! Pedi para o Gantt e para a Elinor. Amanhã às 9h você recebe o resumo."),
                ChatMessage(id: "m3", kind: .handoff(Handoff(agent: .gantt, caption: "Gantt · lembrete criado", title: "Revisar orçamento", detail: "Quarta, 18 de nov. · 9:00")), text: ""),
                ChatMessage(id: "m4", kind: .handoff(Handoff(agent: .elinor, caption: "Elinor · vai preparar", title: "Resumo de novembro", detail: "Gastos, metas e próximas contas")), text: ""),
                ChatMessage(id: "m5", kind: .user, text: "E agora, o que eu faço primeiro?"),
                ChatMessage(id: "m6", kind: .typing(.chomp), text: ""),
            ],
            participants: [.chomp, .gantt, .elinor]
        ),
        Conversation(
            id: "focus-afternoon",
            title: "Foco da tarde",
            timestamp: "13:05",
            messages: [
                ChatMessage(id: "f1", kind: .user, text: "Quero duas horas sem notificação"),
                ChatMessage(id: "f2", kind: .agent(.chomp), text: "A Rita montou quatro pomodoros de 25 minutos, com pausa às 15h."),
                ChatMessage(id: "f3", kind: .handoff(Handoff(agent: .rita, caption: "Rita · foco iniciado", title: "Pomodoro 2 de 4", detail: "Pausa às 15:00")), text: ""),
            ],
            participants: [.chomp, .rita]
        ),
        Conversation(
            id: "pr-review",
            title: "Revisão do PR dos widgets",
            timestamp: "Ontem",
            messages: [
                ChatMessage(id: "c1", kind: .user, text: "O que falta no PR dos widgets?"),
                ChatMessage(id: "c2", kind: .agent(.chomp), text: "A Ada olhou: faltam as prévias do tema escuro e um teste do widget grande."),
                ChatMessage(id: "c3", kind: .handoff(Handoff(agent: .ada, caption: "Ada · revisão", title: "2 pendências", detail: "Prévias escuras · teste do grande")), text: ""),
            ],
            participants: [.chomp, .ada]
        ),
        Conversation(
            id: "clip-agenda",
            title: "Pauta copiada",
            timestamp: "Segunda",
            messages: [
                ChatMessage(id: "t1", kind: .user, text: "Guarda essa pauta para a revisão"),
                ChatMessage(id: "t2", kind: .agent(.chomp), text: "O Toni guardou e o Gantt anexou ao evento das 16h."),
            ],
            participants: [.chomp, .toni, .gantt]
        ),
    ]

    let chatSuggestions = ["Resumo do dia", "Iniciar foco", "Próximo evento", "Gastos do mês"]

    let voiceTranscript = "Me lembra de levar o carregador para a revisão das quatro"

    // MARK: Gantt

    let weekDays: [WeekDay] = [
        WeekDay(id: 16, weekday: "SEG", number: 16, hasEvents: true),
        WeekDay(id: 17, weekday: "TER", number: 17, hasEvents: true),
        WeekDay(id: 18, weekday: "QUA", number: 18, hasEvents: true),
        WeekDay(id: 19, weekday: "QUI", number: 19, hasEvents: false),
        WeekDay(id: 20, weekday: "SEX", number: 20, hasEvents: true),
        WeekDay(id: 21, weekday: "SÁB", number: 21, hasEvents: false),
        WeekDay(id: 22, weekday: "DOM", number: 22, hasEvents: false),
    ]

    let todayEvents: [CalendarEvent] = [
        CalendarEvent(id: "e1", time: "9:30", endTime: "10:00", title: "Daily do time", location: "Chamada", isPast: true),
        CalendarEvent(id: "e2", time: "13:30", endTime: "14:30", title: "Almoço com a Bia", location: "Centro", isPast: true),
        CalendarEvent(id: "e3", time: "16:00", endTime: "17:00", title: "Revisão do design", location: "Sala 2", isNext: true, relative: "em 1h20"),
        CalendarEvent(id: "e4", time: "18:30", endTime: "19:30", title: "Academia", location: nil),
        CalendarEvent(id: "e5", time: "21:00", endTime: nil, title: "Diário · 2 tarefas abertas", location: nil),
    ]

    let journal: [JournalEntry] = [
        JournalEntry(id: "j1", kind: .task, text: "Enviar pauta da revisão", state: .done),
        JournalEntry(id: "j2", kind: .task, text: "Revisar orçamento de novembro"),
        JournalEntry(id: "j3", kind: .event, text: "Revisão do design às 16h"),
        JournalEntry(id: "j4", kind: .task, text: "Responder a Bia sobre sábado", state: .migrated),
        JournalEntry(id: "j5", kind: .note, text: "Ideia: widget da equipe no iPad"),
        JournalEntry(id: "j6", kind: .task, text: "Comprar café"),
    ]

    // MARK: Rita

    let focusPresets: [FocusPreset] = [
        FocusPreset(id: "pomodoro", name: "Pomodoro", focusMinutes: 25, breakMinutes: 5),
        FocusPreset(id: "deep", name: "Profundo", focusMinutes: 50, breakMinutes: 10),
        FocusPreset(id: "short", name: "Curto", focusMinutes: 15, breakMinutes: 3),
    ]

    let focusSessions: [FocusSession] = [
        FocusSession(id: "s1", title: "Pomodoro 1", time: "14:00", duration: "25 min"),
        FocusSession(id: "s2", title: "Pomodoro 2", time: "14:30", duration: "em andamento", isCurrent: true),
        FocusSession(id: "s3", title: "Leitura", time: "10:15", duration: "50 min"),
    ]

    let focusSnapshot = FocusSnapshot(remaining: "18:42", progress: 0.26, cycleLabel: "Pomodoro 2 de 4", nextBreak: "Pausa às 15:00")

    // MARK: Elinor

    let budget = BudgetSummary(month: "Novembro", spent: "R$ 1.240", limit: "R$ 2.000", progress: 0.62, remainingNote: "Faltam R$ 760 para 13 dias")

    let categories: [SpendingCategory] = [
        SpendingCategory(id: "food", name: "Mercado e comida", symbol: "cart", amount: "R$ 520", progress: 0.42),
        SpendingCategory(id: "transport", name: "Transporte", symbol: "tram", amount: "R$ 210", progress: 0.17),
        SpendingCategory(id: "home", name: "Casa", symbol: "house", amount: "R$ 330", progress: 0.27),
        SpendingCategory(id: "fun", name: "Lazer", symbol: "popcorn", amount: "R$ 180", progress: 0.14),
    ]

    let transactions: [Transaction] = [
        Transaction(id: "t1", title: "Padaria Boa Massa", category: "Comida", amount: "− R$ 18,50", date: "Hoje"),
        Transaction(id: "t2", title: "Metrô", category: "Transporte", amount: "− R$ 4,25", date: "Hoje"),
        Transaction(id: "t3", title: "Supermercado", category: "Mercado", amount: "− R$ 132,90", date: "Ontem"),
        Transaction(id: "t4", title: "Cinema", category: "Lazer", amount: "− R$ 42,00", date: "Sábado"),
    ]

    let bills: [UpcomingBill] = [
        UpcomingBill(id: "b1", title: "Internet", due: "20 de nov.", amount: "R$ 99,90"),
        UpcomingBill(id: "b2", title: "Aluguel", due: "1º de dez.", amount: "R$ 1.800,00"),
    ]

    // MARK: Ada

    let codeProjects: [CodeProject] = [
        CodeProject(id: "mac", name: "heychomp-mac", branch: "design/redesign", pending: 2),
        CodeProject(id: "ios", name: "heychomp-ios", branch: "feature/prototipo", pending: 1),
        CodeProject(id: "site", name: "site", branch: "main", pending: 0),
    ]

    let codeTasks: [CodeTask] = [
        CodeTask(id: "c1", title: "Revisar o PR dos widgets", project: "heychomp-ios", state: .review, updated: "há 20 min"),
        CodeTask(id: "c2", title: "Separar as cores em um pacote compartilhado", project: "heychomp-mac", state: .inProgress, updated: "ontem"),
        CodeTask(id: "c3", title: "Corrigir o contraste no tema escuro", project: "heychomp-mac", state: .done, updated: "segunda"),
    ]

    let snippet = CodeSnippet(
        language: "Swift",
        title: "Cor do agente só em marcas",
        code: """
        Circle()
            .strokeBorder(agent.tint, lineWidth: 2)
            .frame(width: 50, height: 50)
        """
    )

    // MARK: Toni

    let clipboard: [ClipboardItem] = [
        ClipboardItem(id: "k1", kind: .text, content: "Pauta da revisão — versão final", source: "Notas", time: "14:21"),
        ClipboardItem(id: "k2", kind: .link, content: "figma.com/file/heychomp-mobile", source: "Safari", time: "13:58"),
        ClipboardItem(id: "k3", kind: .image, content: "Captura da tela inicial", source: "Fotos", time: "11:02"),
    ]

    let recentFiles: [FileItem] = [
        FileItem(id: "f1", name: "Pauta-revisao.pdf", detail: "PDF · 220 KB · hoje", symbol: "doc.richtext"),
        FileItem(id: "f2", name: "widgets-mix.png", detail: "Imagem · 1,2 MB · hoje", symbol: "photo"),
        FileItem(id: "f3", name: "Orçamento-nov.numbers", detail: "Planilha · 80 KB · ontem", symbol: "tablecells"),
    ]

    let audioOutputs: [AudioOutput] = [
        AudioOutput(id: "speaker", name: "Alto-falante do iPhone", symbol: "iphone"),
        AudioOutput(id: "airpods", name: "AirPods da Lia", symbol: "airpods"),
        AudioOutput(id: "mac", name: "MacBook (via HeyChomp)", symbol: "laptopcomputer"),
    ]

    let captureActions: [CaptureAction] = [
        CaptureAction(id: "photo", title: "Foto de documento", symbol: "doc.viewfinder"),
        CaptureAction(id: "screen", title: "Gravar a tela", symbol: "record.circle"),
        CaptureAction(id: "memo", title: "Nota de voz", symbol: "waveform"),
        CaptureAction(id: "scan", title: "Ler texto da câmera", symbol: "text.viewfinder"),
    ]

    // MARK: Chomp

    let recentHandoffs: [Handoff] = [
        Handoff(agent: .gantt, caption: "14:38 · Gantt", title: "Lembrete: revisar orçamento", detail: "Quarta, 9:00"),
        Handoff(agent: .elinor, caption: "14:38 · Elinor", title: "Resumo de novembro", detail: "Pronto amanhã cedo"),
        Handoff(agent: .rita, caption: "13:05 · Rita", title: "Quatro pomodoros", detail: "Pausa às 15:00"),
        Handoff(agent: .ada, caption: "Ontem · Ada", title: "Revisão do PR dos widgets", detail: "2 pendências"),
    ]
}
