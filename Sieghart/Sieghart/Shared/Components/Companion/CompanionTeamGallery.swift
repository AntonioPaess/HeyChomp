import SwiftUI

// Selecting a card rehearses that specialist; it never changes the principal.
struct CompanionTeamGallery: View {
    var animates: Bool
    var compact = false
    var onAda: (() -> Void)?
    @State private var inspected: CompanionAvatar?
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(CompanionAvatar.allCases) { member in
                CompanionInteraction(action: {
                    if member == .ada, let onAda { onAda() }
                    else if compact { CompanionMotionStudioWindow.shared.present(member: member, animates: animates) }
                    else { inspected = member }
                }) {
                    VStack(spacing: 7) {
                        CompanionCharacter(size: compact ? 52 : 78, avatar: member, animates: animates)
                        Text(member.name).font(.callout.weight(.semibold))
                        Text(LocalizedStringKey(member.subtitle)).font(.system(size: compact ? 9 : 11)).foregroundStyle(CompanionStyle.muted).lineLimit(1).minimumScaleFactor(0.7)
                        if !compact { Text(LocalizedStringKey(member == .sig ? "Main companion" : "Specialist")).font(.caption2).foregroundStyle(CompanionStyle.muted) }
                    }.frame(maxWidth: .infinity).padding(compact ? 9 : 16).modifier(WorkspaceSurface(radius: 18))
                }.accessibilityLabel(member == .ada && onAda != nil ? "Ada. Open her room." : "\(member.name). \(member.subtitle). Explore movements.")
            }
        }.sheet(item: $inspected) { member in CompanionMotionStudio(initialMember: member, animates: animates) }
    }
}

struct CompanionTeamDock: View {
    var animates: Bool
    var events: CompanionEventCenter? = nil
    /// A teammate who stepped out of the row to talk (e.g. Rita peeking over her nudge).
    var away: CompanionAvatar? = nil
    var onAda: (() -> Void)?
    var onSelect: ((CompanionAvatar) -> Void)? = nil
    var body: some View {
        HStack(spacing: CompanionHomeLayout.dockSpacing) {
            ForEach(CompanionAvatar.specialists.filter { $0 != away }) { member in
                Group {
                    if let onSelect {
                        Button { onSelect(member) } label: { portrait(member) }.buttonStyle(.plain).help(member.subtitle)
                    } else if member == .ada, let onAda {
                        Button(action: onAda) { portrait(member) }.buttonStyle(.plain)
                            .accessibilityLabel("Ada. Open her room.").help("Open Ada’s room")
                    } else { portrait(member) }
                }.frame(maxWidth: .infinity).padding(.vertical, 4)
            }
        }.padding(.horizontal, 4).frame(height: CompanionHomeLayout.dockHeight)
    }
    private func portrait(_ member: CompanionAvatar) -> some View {
        VStack(spacing: 2) {
                    ZStack(alignment: .bottom) {
                        // A soft floor so the team stands on the island's lit lip.
                        Ellipse().fill(Color.black.opacity(0.35)).frame(width: 30, height: 6).blur(radius: 2).offset(y: 2)
                        if let events {
                            CompanionTaskCharacter(events: events, avatar: member, size: CompanionHomeLayout.dockAvatarSize, animates: animates, supporting: true)
                        } else { CompanionCharacter(size: CompanionHomeLayout.dockAvatarSize, avatar: member, animates: animates) }
                    }
                    Text(member.name).font(.system(size: 9, weight: .medium)).foregroundStyle(CompanionStyle.muted)
        }.frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(member.name), \(member.subtitle). Specialist introduction.")
            .help(member.subtitle)
    }
}
