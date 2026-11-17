import SwiftUI

struct DesktopToolsView: View {
    @ObservedObject var model: DesktopController
    var compact = false
    @State private var query = ""
    private var matchingWindows: [DesktopWindow] {
        model.windows.filter { query.isEmpty || "\($0.app.name) \($0.title)".localizedCaseInsensitiveContains(query) }
    }
    private var selected: DesktopWindow? { model.windows.first(where: { $0.id == model.selectedID }) }
    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 14 : 22) {
            // 1. Find: search, refresh, and the permission help tucked into a menu.
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").foregroundStyle(CompanionStyle.muted)
                    TextField("Find an app or window", text: $query).textFieldStyle(.plain)
                }
                .padding(.horizontal, 10).frame(height: 30)
                .background(CompanionStyle.edge.opacity(0.05), in: Capsule())
                .overlay { Capsule().strokeBorder(CompanionStyle.edge.opacity(0.10), lineWidth: 0.75) }
                Button { model.refresh() } label: { Label("Refresh list", systemImage: "arrow.clockwise").modifier(ChompPill(primary: true)) }
                    .buttonStyle(.plain).focusEffectDisabled()
                Menu {
                    Button("Open Accessibility settings") { model.allowAccess() }
                    Button("Locate this copy of HeyChomp") { AccessibilityAccess.revealRunningApp() }
                } label: { Image(systemName: "lock.shield") }
                    .menuStyle(.borderlessButton).fixedSize().help("Enable this copy in macOS Privacy & Security, then return and refresh.")
            }
            Text(LocalizedStringKey(model.status)).font(.caption).foregroundStyle(CompanionStyle.muted).accessibilityIdentifier("desktop.status")

            // 2. Pick a window.
            ToolGroup(title: "Windows", detail: "Select one, then choose a layout") {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(matchingWindows) { window in windowRow(window) }
                        if matchingWindows.isEmpty {
                            OwnerSays(persona: .sig, text: model.apps.isEmpty ? LocalizedStringKey("Refresh to choose a window.") : LocalizedStringKey("No matching windows. Open a window outside full screen, then refresh."))
                        }
                    }
                }.frame(maxHeight: compact ? 150 : 240)
            }

            // 3. Arrange it: a small screen drawing for each layout.
            ToolGroup(title: "Layout", detail: selected.map { LocalizedStringKey($0.title.isEmpty ? $0.app.name : $0.title) } ?? "Select a window above to enable layouts") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: compact ? 4 : 8), spacing: 10) {
                    ForEach(WindowLayout.allCases) { layout in
                        Button { model.apply(layout) } label: {
                            VStack(spacing: 6) {
                                LayoutDiagram(layout: layout).frame(width: 52, height: 34)
                                Text(LocalizedStringKey(layout.title)).font(.system(size: 10)).lineLimit(1).minimumScaleFactor(0.8)
                            }.frame(maxWidth: .infinity).padding(.vertical, 8).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain).focusEffectDisabled()
                        .background(CompanionStyle.edge.opacity(0.03), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .disabled(model.selectedID == nil).opacity(model.selectedID == nil ? 0.45 : 1)
                        .help(Text(LocalizedStringKey(layout.title)))
                    }
                }
                Button("Undo last layout") { model.undo() }.buttonStyle(.plain).font(.caption.weight(.medium))
                    .foregroundStyle(CompanionStyle.accentInk).disabled(!model.canUndo).opacity(model.canUndo ? 1 : 0.4)
            }

            // 4. Open an app.
            let apps = model.apps.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }
            if !apps.isEmpty {
                ToolGroup(title: "Apps", detail: "Bring an app forward") {
                    FlowRow(apps: apps) { app in model.activate(app: app) }
                }
            }

            // 5. Behaviour.
            ToolGroup(title: "Behaviour") {
                ToolToggleRow(title: "Focus window under pointer", status: LocalizedStringKey(model.focusStatus), isOn: $model.focusFollowsPointer)
                if model.focusFollowsPointer { Button("Retry pointer focus") { model.retryPointerFocus() }.buttonStyle(CompanionButtonStyle(compact: true)) }
                Divider()
                ToolToggleRow(title: "Snap windows at screen edges", status: LocalizedStringKey(model.snapStatus), isOn: $model.edgeSnapping)
                if model.edgeSnapping { Button("Retry edge snapping") { model.retrySnapping() }.buttonStyle(CompanionButtonStyle(compact: true)) }
            }
            ToolGroup(title: "Dock, Maximize & Desktop Order") { DockSpacesSection(dockSpaces: model.dockSpaces, apps: model.apps) }
        }
        .onChange(of: query) { _, _ in
            if !matchingWindows.contains(where: { $0.id == model.selectedID }) { model.selectedID = nil }
        }
    }

    private func windowRow(_ window: DesktopWindow) -> some View {
        let isSelected = model.selectedID == window.id
        return HStack(spacing: 10) {
            Image(systemName: "macwindow").font(.system(size: 14)).foregroundStyle(isSelected ? CompanionStyle.accentInk : CompanionStyle.muted).frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                (window.title.isEmpty ? Text("Untitled window") : Text(verbatim: window.title)).font(.system(size: 13, weight: .medium)).lineLimit(1)
                Text(window.app.name).font(.caption).foregroundStyle(CompanionStyle.muted)
            }
            Spacer(minLength: 8)
            Button("Show") { model.activate(window: window.id) }.buttonStyle(.plain).font(.caption.weight(.semibold)).foregroundStyle(CompanionStyle.accentInk)
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(isSelected ? CompanionStyle.accent.opacity(0.14) : .clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture { model.selectedID = window.id }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Select \(window.title), \(window.app.name)")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

/// A tiny screen with the region a layout will use, like the macOS window tiling menu.
private struct LayoutDiagram: View {
    let layout: WindowLayout
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width, h = proxy.size.height
            let region: CGRect = switch layout {
            case .left: CGRect(x: 0, y: 0, width: w / 2, height: h)
            case .right: CGRect(x: w / 2, y: 0, width: w / 2, height: h)
            case .topLeft: CGRect(x: 0, y: 0, width: w / 2, height: h / 2)
            case .topRight: CGRect(x: w / 2, y: 0, width: w / 2, height: h / 2)
            case .bottomLeft: CGRect(x: 0, y: h / 2, width: w / 2, height: h / 2)
            case .bottomRight: CGRect(x: w / 2, y: h / 2, width: w / 2, height: h / 2)
            case .maximize: CGRect(x: 0, y: 0, width: w, height: h)
            case .center: CGRect(x: w * 0.2, y: h * 0.18, width: w * 0.6, height: h * 0.64)
            }
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 5, style: .continuous).strokeBorder(CompanionStyle.edge.opacity(0.25), lineWidth: 1)
                RoundedRectangle(cornerRadius: 3, style: .continuous).fill(CompanionStyle.accent.opacity(0.85))
                    .frame(width: max(0, region.width - 4), height: max(0, region.height - 4))
                    .offset(x: region.minX + 2, y: region.minY + 2)
            }
        }.accessibilityHidden(true)
    }
}

/// Apps as wrapping pills.
private struct FlowRow: View {
    let apps: [DesktopApp]
    let open: (DesktopApp) -> Void
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(apps) { app in
                Button { open(app) } label: {
                    Label(app.name, systemImage: "app").lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                        .modifier(ChompPill())
                }.buttonStyle(.plain).focusEffectDisabled().help(Text("Open \(app.name)"))
            }
        }
    }
}

private struct DockSpacesSection: View {
    @ObservedObject var dockSpaces: DockSpacesController
    let apps: [DesktopApp]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ToolToggleRow(title: "Dock window previews", isOn: $dockSpaces.dockPreviewEnabled)
            if dockSpaces.dockPreviewEnabled {
                if !apps.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(apps) { app in
                                Button(app.name) { dockSpaces.loadDockPreview(for: app) }
                                    .buttonStyle(.bordered).controlSize(.small)
                            }
                        }
                    }
                }
                if !dockSpaces.previewWindows.isEmpty {
                    ForEach(dockSpaces.previewWindows) { item in
                        HStack {
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(CompanionStyle.muted, lineWidth: 1)
                                .frame(width: 28 * item.aspectRatio, height: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title).font(.caption).lineLimit(1)
                                Text("\(Int(item.frame.width))×\(Int(item.frame.height)) · \(item.isMinimized ? "Minimized" : "Visible")")
                                    .font(.caption2).foregroundStyle(CompanionStyle.muted)
                            }
                            Spacer()
                            Button(item.isMinimized ? "Restore" : "Minimize") {
                                _ = dockSpaces.togglePreviewMinimize(item.id)
                            }.buttonStyle(.bordered).controlSize(.small)
                        }
                    }
                } else {
                    Text("Select a refreshed app above to preview its windows and minimize/restore state.").font(.caption).foregroundStyle(CompanionStyle.muted)
                }
            }

            Picker("Dock click behavior", selection: $dockSpaces.dockClickBehavior) {
                ForEach(DockClickBehavior.allCases, id: \.self) { Text(LocalizedStringKey($0.title)).tag($0) }
            }

            ToolToggleRow(title: "Green button maximizes to usable desktop", status: LocalizedStringKey(dockSpaces.zoomStatus), isOn: $dockSpaces.greenButtonMaximizes)

            ToolToggleRow(title: "Quit app when last window closes", isOn: $dockSpaces.autoQuitEnabled)
            if dockSpaces.autoQuitEnabled {
                Stepper("Auto-quit delay: \(dockSpaces.autoQuitDelaySeconds)s", value: $dockSpaces.autoQuitDelaySeconds, in: DockSpacesController.autoQuitDelayRange)
                    .font(.caption)
                Text(LocalizedStringKey(dockSpaces.autoQuitStatus)).font(.caption).foregroundStyle(CompanionStyle.muted)
            }

            ToolToggleRow(title: "Lock Desktop / Spaces order (disable auto-rearrange)", status: LocalizedStringKey(dockSpaces.spacesStatus), isOn: $dockSpaces.keepSpacesOrderFixed)
            if dockSpaces.savedOriginalMruSpaces != nil {
                Button("Restore original Spaces setting") { dockSpaces.restoreOriginalSpacesOrder() }
                    .buttonStyle(.bordered).controlSize(.small)
            }
        }
    }
}

