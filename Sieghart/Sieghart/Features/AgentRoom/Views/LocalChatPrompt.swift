import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct LocalChatPrompt: View {
    @ObservedObject var chat: LocalChatViewModel
    let conversation: LocalChatConversation
    var compact: Bool
    var active: Bool
    @Environment(\.islandPreview) private var preview
    @Environment(\.islandReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale
    @State private var followsReply = true
    private var working: Bool { chat.generatingID == conversation.id }
    private var en: Bool { locale.language.languageCode?.identifier == "en" }
    private var promptPlaceholder: String {
        if en { return "Ask \(conversation.persona.title)…" }
        let article = [.sig, .gantt].contains(conversation.persona) ? "ao" : "à"
        return "Pergunte \(article) \(conversation.persona.title)…"
    }
    private var needsScreenPermission: Bool {
        guard let reply = conversation.messages.last, reply.role == .assistant else { return false }
        return [false, true].contains { reply.text == ScreenInspectionFailure.permission.message(english: $0) }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            AgentChatBackground()
            VStack(alignment: .leading, spacing: 8) {
                headerBar
                transcript
                if !compact { recoverySections }
                if let attachments = chat.attachments[conversation.id], !attachments.isEmpty {
                    Group {
                        if preview { attachmentChips(attachments).frame(maxWidth: .infinity, alignment: .leading).clipped() }
                        else { ScrollView(.horizontal) { attachmentChips(attachments) }.scrollIndicators(.hidden) }
                    }.frame(height: 30)
                }
                composer
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
        .frame(minHeight: compact ? nil : 320)
        .frame(maxHeight: compact ? .infinity : nil)
        .padding(.bottom, 10)
        .dropDestination(for: URL.self) { urls, _ in
            guard !working, !urls.isEmpty else { return false }
            for url in urls.prefix(2) { Task { await chat.attach(url, to: conversation.id) } }
            return true
        }
        .animation(preview || reduceMotion ? nil : AdaRoomTheme.springAnimation, value: conversation.messages.count)
    }

    private var headerBar: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.38, green: 0.44, blue: 0.98).opacity(0.28),
                                Color(red: 0.62, green: 0.36, blue: 0.96).opacity(0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                if conversation.persona == .ada { AgentChatCompanion(
                    state: chat.states[conversation.id] ?? .ready,
                    active: active,
                    size: 22,
                    conversationID: conversation.id,
                    failureID: chat.failures[conversation.id],
                    submissionID: chat.submitted[conversation.id]
                )
                .allowsHitTesting(false)
                } else { CompanionCharacter(size: 22, avatar: conversation.persona.avatar, animates: false).allowsHitTesting(false) }
            }
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text(conversation.persona.title)
                        .font(AdaRoomTheme.titleFont(size: 12.5))
                        .foregroundStyle(AdaRoomTheme.assistantTextColor(for: colorScheme))
                    Circle()
                        .fill(working ? CompanionStyle.accent : chat.readiness.available ? Color.green.opacity(0.85) : .orange)
                        .frame(width: 5.5, height: 5.5).accessibilityHidden(true)
                }.accessibilityElement(children: .combine)
                    .accessibilityValue(working ? (en ? "Preparing reply" : "Preparando resposta") : chat.readiness.available ? (en ? "Ready" : "Pronto") : (en ? "Model unavailable" : "Modelo indisponível"))
                Text(en ? chat.modelName : chat.modelName.replacingOccurrences(of: "On this Mac", with: "Neste Mac"))
                    .font(AdaRoomTheme.badgeFont(size: 9.5))
                    .foregroundStyle(CompanionStyle.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            picker
            Button {
                followsReply.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: followsReply ? "arrow.down.circle.fill" : "arrow.down.circle")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(followsReply ? Color(red: 0.48, green: 0.56, blue: 0.98) : CompanionStyle.muted)
                    Text(en ? "Auto-scroll" : "Acompanhar")
                        .font(AdaRoomTheme.badgeFont(size: 9.5))
                }
                .foregroundStyle(followsReply ? CompanionStyle.ink.opacity(0.9) : CompanionStyle.muted)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(
                        followsReply ? Color(red: 0.48, green: 0.56, blue: 0.98).opacity(0.45) : Color.white.opacity(0.10),
                        lineWidth: 0.75
                    )
                }
            }
            .buttonStyle(.plain)
            .help(en ? "Automatically follow new replies" : "Acompanhar novas respostas automaticamente")
        }
    }

    private var transcript: some View {
        Group {
            if preview {
                GeometryReader { size in
                    VStack(alignment: .leading, spacing: 6) { rows }
                        .frame(width: size.size.width, alignment: .topLeading).fixedSize(horizontal: false, vertical: true)
                        .frame(height: size.size.height, alignment: followsReply ? .bottom : .top).clipped()
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 8) { rows }.padding(.vertical, 2)
                    }
                    .onChange(of: conversation.messages) { _, _ in if followsReply { proxy.scrollTo("chat-bottom", anchor: .bottom) } }
                    .onChange(of: conversation.id) { _, _ in scrollToSelection(proxy) }
                    .onChange(of: chat.messageFocus) { _, _ in scrollToSelection(proxy) }
                    .onChange(of: chat.notice) { _, _ in if compact && followsReply { proxy.scrollTo("chat-bottom", anchor: .bottom) } }
                    .onChange(of: chat.readiness) { _, _ in if compact && followsReply { proxy.scrollTo("chat-bottom", anchor: .bottom) } }
                    .onAppear { scrollToSelection(proxy) }
                }
            }
        }.frame(minHeight: compact ? 88 : 160).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    private func scrollToSelection(_ proxy: ScrollViewProxy) {
        if let focus = chat.messageFocus, focus.chatID == conversation.id {
            followsReply = false; proxy.scrollTo(focus.messageID, anchor: .center)
        } else {
            followsReply = true; proxy.scrollTo("chat-bottom", anchor: .bottom)
        }
    }
    @ViewBuilder private var rows: some View {
        if conversation.messages.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(en ? "A small next step, together." : "Um próximo passo, juntos.")
                    .font(AdaRoomTheme.titleFont(size: 14))
                    .foregroundStyle(AdaRoomTheme.assistantTextColor(for: colorScheme))
                Text(en ? "Ask, attach something, or tell me where you’re stuck." : "Pergunte, anexe um documento ou me diga onde você travou.")
                    .font(AdaRoomTheme.bodyFont(size: 12))
                    .foregroundStyle(CompanionStyle.muted)
            }.padding(.top, 18)
        }
        ForEach(conversation.messages.filter { $0.role != .system }) { message in
            VStack(alignment: .leading, spacing: 4) {
                AgentChatBubble(message: CodingMessage(id: message.id, role: message.role == .user ? .user : .assistant, text: message.text + (message.attachedFiles.map { "\n\n📎 " + $0.joined(separator: " · ") } ?? "")),
                    isStreaming: working && message.id == conversation.messages.last?.id)
                if chat.canSaveReply(message.id, in: conversation.id) {
                    if preview {
                        Label(en ? "Save" : "Salvar", systemImage: "bookmark")
                            .font(.caption).foregroundStyle(CompanionStyle.muted).padding(.leading, 10)
                    } else {
                    Menu {
                        Button(en ? "Save reply" : "Salvar resposta") { chat.saveReply(message.id, in: conversation.id) }
                        let blocks = CompanionArtifactLibrary.codeBlocks(in: message.text)
                        ForEach(blocks.indices, id: \.self) { index in
                            Button(en ? "Save code \(index + 1) · \(blocks[index].language)" : "Salvar código \(index + 1) · \(blocks[index].language)") {
                                chat.saveReply(message.id, in: conversation.id, codeBlock: index)
                            }
                        }
                    } label: { Label(en ? "Save" : "Salvar", systemImage: "bookmark") }
                    .menuStyle(.borderlessButton).fixedSize().font(.caption)
                    .foregroundStyle(CompanionStyle.muted).padding(.leading, 10)
                    .accessibilityLabel(en ? "Save reply to library" : "Salvar resposta na biblioteca")
                    }
                }
            }
            .padding(3)
            .background(CompanionStyle.accent.opacity(chat.messageFocus?.chatID == conversation.id && chat.messageFocus?.messageID == message.id ? 0.12 : 0), in: RoundedRectangle(cornerRadius: 18))
            .id(message.id)
            if let handoff = message.handoff {
                Button { chat.select(handoff.conversationID) } label: { Label(en ? "Continue with \(handoff.persona.title)" : "Continuar com \(handoff.persona.title)", systemImage: "arrow.up.right") }.buttonStyle(.bordered)
            }
            if let receipt = message.utilityReceipt, let awake = chat.awakeStatusProvider?() {
                KeepAwakeInlineCard(model: awake, receipt: receipt)
            }
        }
        if working && conversation.messages.last?.text.isEmpty == true {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    if active { AgentTypingDots() }
                    Text(en ? "\(conversation.persona.title) is preparing your reply…" : "\(conversation.persona.title) está preparando sua resposta…")
                        .font(AdaRoomTheme.badgeFont(size: 11))
                    if let started = chat.generationStartedAt { Text(started, style: .relative).font(.caption2).foregroundStyle(.secondary) }
                    Spacer(minLength: 32)
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
        }
        if compact { recoverySections }
        Color.clear.frame(height: 1).id("chat-bottom")
    }
    @ViewBuilder private var recoverySections: some View {
        if !chat.readiness.available { availability }
        if let notice = chat.notice { noticeCard(notice) }
        if needsScreenPermission {
            ScreenPermissionHelp(language: en ? "en-US" : "pt-BR", retry: {
                chat.retryScreenRequest(in: conversation.id)
            }, isRetrying: chat.generatingID != nil).padding(10)
        }
    }
    private func attachmentChips(_ documents: [CompanionDocument]) -> some View {
        HStack(spacing: 6) {
            ForEach(Array(documents.enumerated()), id: \.offset) { index, document in
                HStack(spacing: 6) {
                    Image(systemName: "doc.text").foregroundStyle(CompanionStyle.accentInk)
                    Text(document.name).lineLimit(1).truncationMode(.middle).frame(maxWidth: 180)
                    Button { chat.removeAttachment(at: index, from: conversation.id) } label: {
                        Image(systemName: "xmark.circle.fill")
                    }.buttonStyle(.plain).disabled(working)
                        .accessibilityLabel(en ? "Remove \(document.name)" : "Remover \(document.name)")
                }.font(.caption).padding(.horizontal, 9).padding(.vertical, 6)
                    .background(CompanionStyle.edge.opacity(0.06), in: Capsule()).help(document.name)
            }
        }.fixedSize(horizontal: true, vertical: false)
    }
    private var availability: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Model unavailable", systemImage: "apple.intelligence").font(.caption.weight(.semibold))
            Text(LocalizedStringKey(chat.readiness.reason ?? "The on-device model is unavailable."))
                .font(.caption).foregroundStyle(CompanionStyle.muted)
                .fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { availabilityActions }
                VStack(alignment: .leading, spacing: 8) { availabilityActions }
            }
        }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .background(CompanionStyle.edge.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }
    @ViewBuilder private var availabilityActions: some View {
        Button("Check again") { Task { await chat.prepare() } }.buttonStyle(CompanionButtonStyle(compact: true)).disabled(chat.loading)
        Button("Apple Intelligence settings") { NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Siri-Settings.extension")!) }
            .buttonStyle(CompanionButtonStyle(compact: true))
    }
    private func noticeCard(_ notice: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill").foregroundStyle(CompanionStyle.accentInk).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizedStringKey(notice)).fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
                if let detail = chat.noticeDetail {
                    DisclosureGroup("Technical details") {
                        ScrollView { Text(detail).font(.caption).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }
                            .frame(maxHeight: 80)
                    }.id(notice + detail)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
            Button { chat.notice = nil } label: { Image(systemName: "xmark") }
                .buttonStyle(.plain).padding(3).accessibilityLabel("Dismiss notice")
        }.font(.caption).foregroundStyle(CompanionStyle.muted).padding(10)
            .background(CompanionStyle.accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }
    private var picker: some View {
        Group {
            if preview {
                pickerLabel.frame(maxWidth: 190)
            } else {
                Menu {
                    ForEach(chat.conversations) { value in Button(value.title) { chat.select(value.id) } }
                    Divider()
                    Menu("New chat with…") {
                        ForEach(LocalChatPersona.allCases, id: \.rawValue) { persona in
                            Button(persona.title) { Task { _ = await chat.create(persona) } }
                        }
                    }
                    Button("Delete this conversation", role: .destructive) { Task { await chat.delete(conversation.id) } }
                } label: { pickerLabel }.menuStyle(.borderlessButton).frame(maxWidth: 190)
            }
        }
    }
    private var pickerLabel: some View {
        HStack(spacing: 5) {
            Circle().fill(Color(red: 0.48, green: 0.56, blue: 0.98)).frame(width: 6, height: 6)
            Text(conversation.title).lineLimit(1)
            Image(systemName: "chevron.up.chevron.down").font(.system(size: 8))
        }.font(AdaRoomTheme.badgeFont(size: 10)).foregroundStyle(CompanionStyle.ink.opacity(0.85))
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay { Capsule().strokeBorder(Color(red: 0.48, green: 0.56, blue: 0.98).opacity(0.32), lineWidth: 0.75) }
    }
    private var composer: some View {
        HStack(spacing: 8) {
            Button {
                let panel = NSOpenPanel(); panel.canChooseDirectories = false; panel.allowsMultipleSelection = false
                panel.allowedContentTypes = [.pdf, .plainText, .sourceCode, .json, .commaSeparatedText]
                if panel.runModal() == .OK, let url = panel.url { Task { await chat.attach(url, to: conversation.id) } }
            } label: { Image(systemName: "paperclip") }.buttonStyle(.plain).disabled(working).help(en ? "Attach document" : "Anexar documento")
            if preview {
                Text(chat.drafts[conversation.id].flatMap { $0.isEmpty ? nil : $0 } ?? promptPlaceholder)
                    .font(AdaRoomTheme.bodyFont(size: 13)).foregroundStyle(CompanionStyle.muted).frame(maxWidth: .infinity, alignment: .leading)
            } else {
                AgentChatComposer(text: Binding(get: { chat.drafts[conversation.id] ?? "" }, set: { chat.drafts[conversation.id] = $0 }),
                    focusID: conversation.id, placeholder: promptPlaceholder) { chat.send(to: conversation.id) }
                    .frame(height: 28)
            }
            if working {
                Button { chat.stop() } label: { Image(systemName: "stop.fill").font(.system(size: 11)).foregroundStyle(.white) }
                    .buttonStyle(AgentChatSendStyle()).help(en ? "Stop reply" : "Interromper resposta").accessibilityLabel(en ? "Stop reply" : "Interromper resposta")
            } else {
                Button { chat.send(to: conversation.id) } label: { Image(systemName: "arrow.up").font(.system(size: 13, weight: .bold)).foregroundStyle(.white) }
                    .buttonStyle(AgentChatSendStyle()).disabled(!chat.canSend).opacity(chat.canSend ? 1 : 0.4)
                    .help(chat.generatingID == nil ? (en ? "Send message" : "Enviar mensagem") : (en ? "Another conversation is replying. Wait or stop that reply." : "Outra conversa está respondendo. Aguarde ou interrompa a resposta."))
                    .accessibilityLabel(en ? "Send message to \(conversation.persona.title)" : "Enviar mensagem para \(conversation.persona.title)")
            }
        }.padding(.horizontal, 11).padding(.vertical, 6)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(AdaRoomTheme.subtleBorderGradient(for: colorScheme, isUser: false), lineWidth: 0.95)
            }
    }
}
