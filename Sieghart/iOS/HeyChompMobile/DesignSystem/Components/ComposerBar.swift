import SwiftUI

/// Barra "Pergunte ao Chomp" da tela inicial.
///
/// Não é um campo de texto: tocar no texto abre a conversa, o microfone abre a
/// sessão de voz e o "+" abre os anexos do Toni. Fica fixa embaixo, como nos
/// apps de assistente.
struct AskChompBar: View {
    var placeholder = "Pergunte ao Chomp"
    var onPlus: () -> Void
    var onText: () -> Void
    var onMic: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            CircleIconButton(symbol: "plus", label: "Anexar", action: onPlus)
            Button(action: onText) {
                Text(placeholder)
                    .font(Typography.body)
                    .foregroundStyle(Palette.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Abre a conversa com o Chomp")
            MicButton(action: onMic)
        }
        .composerSurface()
    }
}

/// Barra de mensagem editável da conversa.
struct MessageComposer: View {
    @Binding var text: String
    var onPlus: () -> Void
    var onMic: () -> Void
    var onSend: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            CircleIconButton(symbol: "plus", label: "Anexar", action: onPlus)
            TextField("Mensagem", text: $text, axis: .vertical)
                .font(Typography.body)
                .lineLimit(1...4)
                .submitLabel(.send)
                .onSubmit(onSend)
            if text.trimmingCharacters(in: .whitespaces).isEmpty {
                MicButton(action: onMic)
            } else {
                Button(action: onSend) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Palette.onAccent)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(Palette.accent))
                }
                .accessibilityLabel("Enviar")
            }
        }
        .composerSurface()
    }
}

/// Botão redondo menta do microfone.
struct MicButton: View {
    var size: CGFloat = 42
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "mic.fill")
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(Palette.onAccent)
                .frame(width: size, height: size)
                .background(Circle().fill(Palette.accent))
        }
        .accessibilityLabel("Falar com o Chomp")
    }
}

/// Botão redondo neutro com um símbolo.
struct CircleIconButton: View {
    let symbol: String
    let label: String
    var size: CGFloat = 40
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(width: size, height: size)
                .background(Circle().fill(Palette.fill))
        }
        .accessibilityLabel(label)
    }
}

private extension View {
    func composerSurface() -> some View {
        self.padding(.leading, 8)
            .padding(.trailing, 7)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Palette.card)
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Palette.hairline, lineWidth: 0.5)
            )
    }
}
