import SwiftUI

// Tela bloqueada e atividades ao vivo.
//
// Os acessórios simulam o modo monocromático do iOS (branco translúcido).
// No WidgetKit, eles virariam as famílias `.accessoryCircular`,
// `.accessoryRectangular` e `.accessoryInline`.

/// Tela bloqueada completa: em linha, circulares, retangular e Live Activity.
struct LockScreenPreview: View {
    let nextEvent: CalendarEvent?
    let focus: FocusSnapshot

    var body: some View {
        VStack(spacing: 0) {
            Label("Revisão às 16h", systemImage: "sparkle")
                .font(.system(size: 15, weight: .semibold))
                .padding(.top, 26)
            Text("14:40")
                .font(.system(size: 88, weight: .semibold, design: .rounded))
                .padding(.top, -2)
            HStack(spacing: 10) {
                AccessoryCircle {
                    VStack(spacing: 2) {
                        ChompMark(width: 40, height: 24, fill: .white.opacity(0.95), eye: Color(hex: 0x2A2A2A))
                        Text("Falar").font(.system(size: 10, weight: .bold))
                    }
                }
                AccessoryCircle {
                    ProgressRing(progress: focus.progress, tint: .white, lineWidth: 5, track: .white.opacity(0.25)) {
                        VStack(spacing: 0) {
                            Text("18").font(Typography.number(18))
                            Text("Foco").font(.system(size: 10, weight: .semibold)).opacity(0.8)
                        }
                    }
                    .padding(5)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Label("Gantt · \(nextEvent?.relative ?? "")", systemImage: "calendar")
                        .font(.system(size: 12, weight: .semibold)).opacity(0.8)
                    Text(nextEvent?.title ?? "").font(.system(size: 15, weight: .bold)).lineLimit(1)
                    Text("\(nextEvent?.time ?? "") · \(nextEvent?.location ?? "")").font(.system(size: 12.5)).opacity(0.8)
                }
                .padding(.horizontal, 11)
                .frame(width: 158, height: 72, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white.opacity(0.16)))
            }
            .padding(.top, 10)

            Spacer(minLength: 40)
            SummaryLiveActivity()
                .padding(.horizontal, 10)
                .padding(.bottom, 14)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 520)
        .background(
            LinearGradient(colors: [Color(hex: 0x4E8F7C), Color(hex: 0x5B5492)], startPoint: .top, endPoint: .bottom)
        )
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
    }
}

private struct AccessoryCircle<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(width: 72, height: 72)
            .background(Circle().fill(.white.opacity(0.16)))
    }
}

/// Dynamic Island expandida durante a sessão de voz.
struct DynamicIslandVoice: View {
    var body: some View {
        HStack(spacing: 12) {
            ChompMark()
            VStack(alignment: .leading, spacing: 0) {
                Text("0:42").font(Typography.number(17, weight: .semibold))
                Text("Chomp ouvindo…").font(.system(size: 14)).opacity(0.6)
            }
            Spacer()
            Image(systemName: "mic.fill")
                .frame(width: 48, height: 48)
                .background(Circle().fill(Color(hex: 0x3A3A3C)))
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .bold))
                .frame(width: 48, height: 48)
                .background(Circle().fill(Palette.destructive))
        }
        .foregroundStyle(.white)
        .padding(.leading, 14)
        .padding(.trailing, 12)
        .frame(height: 78)
        .background(Capsule().fill(.black))
    }
}

/// Live Activity com a resposta do Chomp pronta.
struct SummaryLiveActivity: View {
    var body: some View {
        HStack(spacing: 12) {
            AgentDisc(agent: .chomp, size: 58)
                .overlay(alignment: .topLeading) { TypingBadge(size: 20, outline: Palette.night).offset(x: -4, y: -2) }
            VStack(alignment: .leading, spacing: 2) {
                Text("Seu resumo do dia está pronto").font(.system(size: 15, weight: .semibold))
                Text("3 itens · Gantt e Rita ajudaram").font(.system(size: 13)).opacity(0.6)
            }
            Spacer(minLength: 0)
            Image(systemName: "arrow.right")
                .font(.system(size: 16, weight: .bold))
                .frame(width: 40, height: 40)
                .background(Circle().fill(.white.opacity(0.14)))
        }
        .foregroundStyle(.white)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Palette.night.opacity(0.9)))
        .environment(\.colorScheme, .dark)
    }
}

/// Live Activity do foco, com a Rita espiando o cronômetro.
struct FocusLiveActivity: View {
    let focus: FocusSnapshot

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                PeekImage(agent: .rita, width: 66)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Rita · Foco").font(.system(size: 13, weight: .semibold)).foregroundStyle(Agent.rita.tint)
                    Text(focus.remaining).font(Typography.number(30))
                }
                Spacer()
                Image(systemName: "pause.fill").frame(width: 42, height: 42).background(Circle().fill(.white.opacity(0.14)))
                Image(systemName: "stop.fill").frame(width: 42, height: 42).background(Circle().fill(.white.opacity(0.14)))
            }
            ProgressTrack(progress: focus.progress, tint: Agent.rita.tint)
            HStack {
                Text(focus.cycleLabel)
                Spacer()
                Text(focus.nextBreak)
            }
            .font(.system(size: 12))
            .opacity(0.65)
        }
        .foregroundStyle(.white)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color(hex: 0x121214)))
        .environment(\.colorScheme, .dark)
    }
}
