import SwiftUI

// Widgets da tela de início. Só aparência: o toque não faz nada na galeria.
// Numa extensão WidgetKit, cada um vira o conteúdo de um `Widget` com
// `containerBackground` no lugar de `WidgetFrame`.

/// Médio: balão do Chomp e campo "Pergunte ao Chomp", com ele espiando o campo.
struct AskChompWidget: View {
    let userName: String

    var body: some View {
        WidgetFrame(family: .medium, glow: .chomp) {
            VStack(spacing: 0) {
                HStack {
                    Spacer(minLength: 84)
                    Text("Boa tarde, \(userName)! O que vamos resolver agora?")
                        .font(.system(size: 15))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.card))
                }
                Spacer()
                HStack(spacing: 6) {
                    Text("Pergunte ao Chomp").font(.system(size: 15)).foregroundStyle(Palette.muted)
                    Spacer()
                    Image(systemName: "keyboard").foregroundStyle(Palette.muted).frame(width: 36, height: 36)
                    Image(systemName: "mic.fill")
                        .foregroundStyle(Palette.onAccent)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Palette.accent))
                }
                .padding(.leading, 18)
                .padding(.trailing, 6)
                .frame(height: 52)
                .background(Capsule().fill(Palette.inset))
                .overlay(alignment: .topLeading) {
                    PeekImage(agent: .chomp, width: 80)
                        .offset(x: 4, y: -40)
                        .overlay(alignment: .topLeading) { TypingBadge(size: 20).offset(x: 0, y: -34) }
                }
            }
            .padding(12)
        }
    }
}

/// Pequeno: rosto do Chomp com o selo de digitando e as etapas passando.
struct ChompFaceWidget: View {
    let steps: [String]

    var body: some View {
        WidgetFrame(family: .small, glow: .chomp, glowIntensity: 0.38) {
            VStack(spacing: 0) {
                Text("Chomp").font(.system(size: 11, weight: .semibold)).foregroundStyle(Palette.muted)
                Image(Agent.chomp.portraitImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 92, height: 84)
                    .overlay(alignment: .topLeading) { TypingBadge(size: 22).offset(x: -6, y: 14) }
                Spacer(minLength: 0)
                StepTicker(steps: steps)
            }
            .padding(.vertical, 11)
        }
    }
}

/// Pequeno: quatro da equipe em círculos com brilho.
struct TeamGridWidget: View {
    let agents: [Agent]

    var body: some View {
        WidgetFrame(family: .small) {
            LazyVGrid(columns: [GridItem(.fixed(64), spacing: 10), GridItem(.fixed(64), spacing: 10)], spacing: 10) {
                ForEach(agents) { AgentDisc(agent: $0, size: 64) }
            }
        }
    }
}

/// Médio: data e três eventos, com o Gantt espiando a lista.
struct AgendaWidget: View {
    let events: [CalendarEvent]

    var body: some View {
        WidgetFrame(family: .medium, glow: .gantt, glowIntensity: 0.22) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TERÇA").font(.system(size: 13, weight: .bold)).foregroundStyle(Agent.gantt.tint)
                    Text("17").font(Typography.number(44))
                    Text("3 eventos\n1 lembrete").font(.system(size: 12)).foregroundStyle(Palette.muted).padding(.top, 4)
                }
                .frame(width: 84, alignment: .leading)
                .padding(.top, 4)
                WidgetInset(agent: .gantt, peekWidth: 62) {
                    VStack(spacing: 0) {
                        ForEach(events) { EventLine(event: $0, compact: true) }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 14)
                }
                .padding(.top, 30)
            }
            .padding(12)
        }
    }
}

/// Pequeno: foco da Rita, com ela espiando o anel.
struct FocusWidget: View {
    let focus: FocusSnapshot

    var body: some View {
        WidgetFrame(family: .small, glow: .rita, glowIntensity: 0.30) {
            VStack(alignment: .trailing, spacing: 0) {
                Text("Rita").font(.system(size: 11, weight: .semibold)).foregroundStyle(Palette.muted)
                Spacer()
                WidgetInset(agent: .rita, peekWidth: 68) {
                    HStack(spacing: 8) {
                        ProgressRing(progress: focus.progress, tint: Agent.rita.tint, lineWidth: 7) {
                            Text(focus.remaining).font(Typography.number(16))
                        }
                        .frame(width: 68, height: 68)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Foco").font(.system(size: 13, weight: .bold))
                            Text(focus.cycleLabel).font(.system(size: 11)).foregroundStyle(Palette.muted)
                        }
                    }
                    .padding(12)
                }
                .frame(height: 96)
            }
            .padding(10)
            .padding(.top, 3)
        }
    }
}

/// Pequeno: último item copiado, com o Toni espiando.
struct ClipboardWidget: View {
    let item: ClipboardItem?
    let extraCount: Int

    var body: some View {
        WidgetFrame(family: .small, glow: .toni, glowIntensity: 0.26) {
            VStack(alignment: .trailing, spacing: 0) {
                Text("Toni").font(.system(size: 11, weight: .semibold)).foregroundStyle(Palette.muted)
                Spacer()
                WidgetInset(agent: .toni, peekWidth: 68) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Copiado agora", systemImage: "doc.on.clipboard")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundStyle(Palette.muted)
                        Text("“\(item?.content ?? "")”")
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(2)
                        Text("+ \(extraCount) itens recentes").font(.system(size: 11.5)).foregroundStyle(Palette.muted)
                    }
                    .padding(12)
                }
                .frame(height: 96)
            }
            .padding(10)
            .padding(.top, 3)
        }
    }
}

/// Grande: os seis de rosto com o status e a pergunta ao Chomp no rodapé.
struct TeamWidget: View {
    let team: [AgentStatus]

    var body: some View {
        WidgetFrame(family: .large) {
            VStack(spacing: 12) {
                HStack {
                    Text("Equipe").font(.system(size: 15, weight: .bold))
                    Spacer()
                    Text("\(team.filter(\.isWorking).count) trabalhando")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(Palette.muted)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(team) { status in
                        VStack(spacing: 5) {
                            AgentDisc(agent: status.agent, size: 78)
                                .overlay(alignment: .topLeading) {
                                    if status.isWorking { TypingBadge(size: 20) }
                                }
                            Text(status.agent.name).font(.system(size: 13, weight: .bold))
                            Text(status.badge).font(.system(size: 11)).foregroundStyle(Palette.muted)
                        }
                    }
                }
                Spacer(minLength: 0)
                HStack {
                    Text("Pergunte ao Chomp").font(.system(size: 14)).foregroundStyle(Palette.muted)
                    Spacer()
                    Image(systemName: "mic.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Palette.onAccent)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Palette.accent))
                }
                .padding(.leading, 16)
                .padding(.trailing, 4)
                .frame(height: 42)
                .background(Capsule().fill(Palette.inset))
            }
            .padding(14)
        }
    }
}
