import Cocoa
#if canImport(Sparkle)
import Sparkle
#endif

// MARK: - Event tap callback (must be file-scope for use as C function pointer)

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let ptr = refcon else { return Unmanaged.passRetained(event) }
    return Unmanaged<AppDelegate>.fromOpaque(ptr).takeUnretainedValue().processKeyEvent(event)
}

// MARK: - Icon library

let symbolLibrary: [(category: String, symbols: [String])] = [
    ("Audio", [
        "waveform", "waveform.path.ecg", "waveform.badge.plus", "waveform.badge.mic",
        "headphones", "headphones.circle", "mic", "mic.fill", "mic.slash",
        "speaker.wave.1", "speaker.wave.2", "speaker.wave.3", "speaker.slash",
        "music.note", "music.quarternote.3", "music.note.list", "music.mic",
        "dial.min", "dial.max", "metronome", "metronome.fill",
        "guitars", "guitars.fill", "piano.fill",
    ]),
    ("Transport", [
        "play.fill", "play.circle", "play.circle.fill",
        "pause.fill", "pause.circle",
        "stop.fill", "stop.circle",
        "record.circle", "record.circle.fill",
        "forward.fill", "backward.fill",
        "forward.end.fill", "backward.end.fill",
        "repeat", "repeat.1", "shuffle", "infinity",
    ]),
    ("Edit", [
        "scissors", "scissors.badge.ellipsis",
        "arrow.uturn.backward", "arrow.uturn.forward",
        "arrow.clockwise", "arrow.counterclockwise",
        "doc.on.doc", "doc.on.clipboard",
        "pencil", "pencil.circle",
        "trash", "trash.circle",
        "checkmark.circle", "xmark.circle",
        "plus.circle", "minus.circle",
    ]),
    ("Tools", [
        "applescript", "applescript.fill",
        "terminal", "terminal.fill",
        "command", "command.circle",
        "gear", "gear.circle",
        "wrench.and.screwdriver", "wrench.and.screwdriver.fill",
        "bolt", "bolt.fill", "bolt.circle",
        "wand.and.stars", "wand.and.rays", "sparkles",
    ]),
    ("Files", [
        "folder", "folder.fill", "folder.badge.plus",
        "doc", "doc.fill", "doc.text",
        "tray", "tray.fill", "archivebox",
        "externaldrive", "internaldrive", "icloud",
    ]),
    ("Misc", [
        "star", "star.fill", "star.circle",
        "heart", "heart.fill",
        "flag", "flag.fill", "flag.circle",
        "bookmark", "bookmark.fill",
        "tag", "tag.fill",
        "bell", "bell.fill", "bell.slash",
        "eye", "eye.slash",
        "hand.thumbsup", "hand.thumbsup.fill",
    ]),
]

// MARK: - Icon picker helper

final class SymbolSelector: NSObject {
    var selected: String
    private var buttonMap: [NSButton: String] = [:]
    private var reverseMap: [String: NSButton] = [:]

    init(initial: String) { selected = initial }

    func register(_ btn: NSButton, symbol: String) {
        buttonMap[btn] = symbol
        reverseMap[symbol] = btn
        btn.target = self
        btn.action = #selector(pick(_:))
        if symbol == selected { highlight(btn) }
    }

    @objc func pick(_ sender: NSButton) {
        reverseMap[selected].flatMap { $0 }?.layer?.backgroundColor = nil
        selected = buttonMap[sender] ?? selected
        highlight(sender)
    }

    private func highlight(_ btn: NSButton) {
        btn.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.35).cgColor
    }
}

// MARK: - Model

enum ActionType: String, Codable {
    case app     // launch an application
    case script  // run an .applescript file
    // Legacy — present in old configs, auto-migrated on load
    case ptMenu
    case ptKey
    case shell
}

struct LauncherButton: Codable {
    var title: String
    var type: ActionType
    var appPath: String?        // .app
    var scriptPath: String?     // .script — absolute path to .applescript file
    var symbol: String?
    // Legacy fields kept for migration only:
    var menuPath: [String]?
    var key: String?
    var modifiers: [String]?
    var script: String?
    var targetApp: String?
}

struct Config: Codable {
    var columns: Int
    var buttonSize: Double
    var padding: Double?
    var targetApp: String
    var followApp: String?
    var buttons: [LauncherButton]

    var resolvedPadding: CGFloat { CGFloat(padding ?? 8) }

    static func makeDefault() -> Config {
        Config(
            columns: 3,
            buttonSize: 52,
            padding: 6,
            targetApp: "Pro Tools",
            followApp: "Pro Tools",
            buttons: [
                LauncherButton(title: "RX Connect", type: .ptMenu, symbol: "waveform.path.ecg",
                               menuPath: ["AudioSuite", "Noise Reduction", "RX 11 Connect"]),
                LauncherButton(title: "De-click",   type: .ptMenu, symbol: "waveform",
                               menuPath: ["AudioSuite", "Noise Reduction", "RX 11 De-click"]),
            ]
        )
    }
}

// MARK: - Config storage

final class ConfigStore {
    static let shared = ConfigStore()

    let directoryURL: URL
    let fileURL: URL
    var scriptsURL: URL { directoryURL.appendingPathComponent("scripts", isDirectory: true) }

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        directoryURL = base.appendingPathComponent("PTLauncher", isDirectory: true)
        fileURL = directoryURL.appendingPathComponent("config.json")
    }

    func load() -> Config {
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: scriptsURL, withIntermediateDirectories: true)
        if let data = try? Data(contentsOf: fileURL),
           let cfg = try? JSONDecoder().decode(Config.self, from: data) { return cfg }
        let def = Config.makeDefault()
        save(def)
        return def
    }

    func save(_ cfg: Config) {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        if let data = try? enc.encode(cfg) { try? data.write(to: fileURL) }
    }
}

// MARK: - Views

final class StripView: NSView {
    private var dragIndicatorLayer: CALayer?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }
    override func makeBackingLayer() -> CALayer {
        let l = CALayer()
        l.backgroundColor = NSColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 0.97).cgColor
        l.cornerRadius = 10
        l.masksToBounds = true
        return l
    }

    func showDragIndicator(at x: CGFloat) {
        if dragIndicatorLayer == nil {
            let l = CALayer()
            l.backgroundColor = NSColor.controlAccentColor.cgColor
            l.cornerRadius = 1.5
            layer?.addSublayer(l)
            dragIndicatorLayer = l
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        dragIndicatorLayer?.frame = CGRect(x: x - 1.5, y: 4, width: 3, height: bounds.height - 8)
        CATransaction.commit()
    }

    func hideDragIndicator() {
        dragIndicatorLayer?.removeFromSuperlayer()
        dragIndicatorLayer = nil
    }
}

final class PanelButton: NSButton {
    var buttonIndex: Int = 0
    var onDragMove: ((CGFloat) -> Void)?
    var onDragEnd: ((CGFloat) -> Void)?

    override func rightMouseDown(with event: NSEvent) {
        if let menu = self.menu { NSMenu.popUpContextMenu(menu, with: event, for: self) }
        else { super.rightMouseDown(with: event) }
    }

    override func mouseDown(with event: NSEvent) {
        guard let window = window else { super.mouseDown(with: event); return }
        let startX = event.locationInWindow.x
        var dragging = false

        while true {
            guard let next = window.nextEvent(matching: [.leftMouseUp, .leftMouseDragged]) else { break }
            if next.type == .leftMouseDragged {
                if !dragging && abs(next.locationInWindow.x - startX) > 8 {
                    dragging = true
                    alphaValue = 0.45
                }
                if dragging { onDragMove?(next.locationInWindow.x) }
            } else {
                alphaValue = 1.0
                if dragging {
                    onDragEnd?(next.locationInWindow.x)
                } else {
                    if let t = target, let a = action { NSApp.sendAction(a, to: t, from: self) }
                }
                break
            }
        }
    }
}

// MARK: - App delegate

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var panel: NSPanel!
    var statusItem: NSStatusItem!
    var config = Config.makeDefault()
    let originDefaultsKey = "PTLauncher.windowOrigin"
    var configWatcher: DispatchSourceFileSystemObject?
    var hotkeysEnabled = false
    var hotkeyTap: CFMachPort?
    var hotkeyRunLoopSource: CFRunLoopSource?

    // Sparkle auto-updater. startingUpdater:true begins scheduled background
    // checks against the appcast (configured via the SU* keys in Info.plist).
    // Compiled in only when the Sparkle framework is on the search path
    // (build.sh / release.sh); dev.sh's plain Cocoa build skips it.
    #if canImport(Sparkle)
    var updaterController: SPUStandardUpdaterController!
    #endif

    func applicationDidFinishLaunching(_ note: Notification) {
        config = ConfigStore.shared.load()
        migrateToScriptFiles()
        #if canImport(Sparkle)
        updaterController = SPUStandardUpdaterController(startingUpdater: true,
                                                        updaterDelegate: nil,
                                                        userDriverDelegate: nil)
        #endif
        buildPanel()
        rebuildGrid()
        setupStatusItem()
        registerActivationObservers()
        startConfigWatcher()
        updateVisibility()
    }

    // MARK: Migration — convert old ptMenu/ptKey/shell buttons to .script files

    func migrateToScriptFiles() {
        var changed = false
        for i in config.buttons.indices {
            let b = config.buttons[i]
            switch b.type {
            case .ptMenu:
                guard let path = b.menuPath, !path.isEmpty else { continue }
                let url = makeScriptURL(for: b.title)
                let src = menuActionSource(target: b.targetApp ?? config.targetApp, menuPath: path)
                try? src.write(to: url, atomically: true, encoding: .utf8)
                config.buttons[i].type = .script
                config.buttons[i].scriptPath = url.path
                config.buttons[i].menuPath = nil
                changed = true
            case .ptKey:
                guard let key = b.key else { continue }
                let url = makeScriptURL(for: b.title)
                let src = keystrokeSource(target: b.targetApp ?? config.targetApp,
                                          key: key, modifiers: b.modifiers ?? [])
                try? src.write(to: url, atomically: true, encoding: .utf8)
                config.buttons[i].type = .script
                config.buttons[i].scriptPath = url.path
                config.buttons[i].key = nil
                config.buttons[i].modifiers = nil
                changed = true
            case .shell:
                // If it was already backed by an .applescript file, just update the type.
                if let existing = b.scriptPath, existing.hasSuffix(".applescript") {
                    config.buttons[i].type = .script
                    changed = true
                } else if let existing = b.script, let path = legacyApplescriptPath(from: existing) {
                    config.buttons[i].type = .script
                    config.buttons[i].scriptPath = path
                    config.buttons[i].script = nil
                    changed = true
                } else if let cmd = b.script {
                    // Wrap inline shell command in an applescript.
                    let url = makeScriptURL(for: b.title)
                    let safeCmd = cmd.replacingOccurrences(of: "\\", with: "\\\\")
                                     .replacingOccurrences(of: "\"", with: "\\\"")
                    let src = "do shell script \"\(safeCmd)\""
                    try? src.write(to: url, atomically: true, encoding: .utf8)
                    config.buttons[i].type = .script
                    config.buttons[i].scriptPath = url.path
                    config.buttons[i].script = nil
                    changed = true
                }
            default:
                break
            }
        }
        if changed { ConfigStore.shared.save(config) }
    }

    // MARK: Script source generators

    func menuActionSource(target: String, menuPath: [String]) -> String {
        func esc(_ s: String) -> String {
            s.replacingOccurrences(of: "\\", with: "\\\\")
             .replacingOccurrences(of: "\"", with: "\\\"")
        }
        let n = menuPath.count
        var ref = "menu item \"\(esc(menuPath[n - 1]))\""
        if n >= 3 {
            for i in stride(from: n - 2, through: 1, by: -1) {
                ref += " of menu \"\(esc(menuPath[i]))\" of menu item \"\(esc(menuPath[i]))\""
            }
        }
        ref += " of menu \"\(esc(menuPath[0]))\" of menu bar item \"\(esc(menuPath[0]))\" of menu bar 1"
        return """
        tell application "\(target)" to activate
        delay 0.15
        tell application "System Events"
            tell process "\(target)"
                set frontmost to true
                click \(ref)
            end tell
        end tell
        """
    }

    func keystrokeSource(target: String, key: String, modifiers: [String]) -> String {
        let mods = modifiers.compactMap { m -> String? in
            switch m.lowercased() {
            case "command", "cmd": return "command down"
            case "option", "opt", "alt": return "option down"
            case "control", "ctrl": return "control down"
            case "shift": return "shift down"
            default: return nil
            }
        }
        let using = mods.isEmpty ? "" : " using {\(mods.joined(separator: ", "))}"
        let safeKey = key.replacingOccurrences(of: "\"", with: "\\\"")
        return """
        tell application "\(target)" to activate
        delay 0.1
        tell application "System Events"
            keystroke "\(safeKey)"\(using)
        end tell
        """
    }

    // MARK: Config file watcher

    func startConfigWatcher() {
        let path = ConfigStore.shared.fileURL.path
        guard FileManager.default.fileExists(atPath: path) else { return }
        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: .write, queue: .main)
        source.setEventHandler { [weak self] in self?.reloadConfig() }
        source.setCancelHandler { close(fd) }
        source.resume()
        configWatcher = source
    }

    // MARK: Status item

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let btn = statusItem.button {
            btn.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "PT Launcher")
            btn.target = self
            btn.action = #selector(togglePanel)
        }
    }

    @objc func togglePanel() {
        if panel.isVisible { panel.orderOut(nil) } else { panel.orderFrontRegardless() }
    }

    // MARK: Follow-app visibility

    func registerActivationObservers() {
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(self, selector: #selector(frontAppChanged(_:)),
                       name: NSWorkspace.didActivateApplicationNotification, object: nil)
        nc.addObserver(self, selector: #selector(frontAppChanged(_:)),
                       name: NSWorkspace.didDeactivateApplicationNotification, object: nil)
        nc.addObserver(self, selector: #selector(frontAppChanged(_:)),
                       name: NSWorkspace.didTerminateApplicationNotification, object: nil)
    }

    @objc func frontAppChanged(_ note: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in self?.updateVisibility() }
    }

    func matches(_ app: NSRunningApplication?, target: String) -> Bool {
        guard let app = app else { return false }
        if let bid = app.bundleIdentifier,
           bid.localizedCaseInsensitiveContains("protools") || bid.localizedCaseInsensitiveContains("avid"),
           target.localizedCaseInsensitiveContains("pro tools") { return true }
        if let name = app.localizedName {
            if name.compare(target, options: .caseInsensitive) == .orderedSame { return true }
            if name.localizedCaseInsensitiveContains(target) { return true }
        }
        return false
    }

    func updateVisibility() {
        let target = (config.followApp ?? config.targetApp).trimmingCharacters(in: .whitespaces)
        if target.isEmpty || target == "*" || target.lowercased() == "all" {
            if !panel.isVisible { panel.orderFrontRegardless() }
            return
        }
        if matches(NSWorkspace.shared.frontmostApplication, target: target) {
            if !panel.isVisible { panel.orderFrontRegardless() }
        } else {
            if panel.isVisible { panel.orderOut(nil) }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool { false }

    // MARK: Window

    func buildPanel() {
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 280, height: 100),
                        styleMask: [.nonactivatingPanel], backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isMovableByWindowBackground = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.delegate = self
        if let s = UserDefaults.standard.string(forKey: originDefaultsKey) {
            panel.setFrameOrigin(NSPointFromString(s))
        } else {
            panel.center()
        }
    }

    func windowDidMove(_ notification: Notification) {
        UserDefaults.standard.set(NSStringFromPoint(panel.frame.origin), forKey: originDefaultsKey)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool { NSApp.terminate(nil); return false }

    // MARK: Grid

    func rebuildGrid() {
        let pad = config.resolvedPadding
        let size = CGFloat(config.buttonSize)
        let total = config.buttons.count + 1

        let contentW = pad + CGFloat(total) * (size + pad)
        let contentH = size + 2 * pad
        let strip = StripView(frame: NSRect(x: 0, y: 0, width: contentW, height: contentH))

        for (i, b) in config.buttons.enumerated() {
            let btnX = pad + CGFloat(i) * (size + pad)
            let btn = PanelButton(frame: NSRect(x: btnX, y: pad, width: size, height: size))
            configure(btn, with: b, index: i)
            btn.buttonIndex = i
            btn.onDragMove = { [weak strip, weak self] windowX in
                guard let self = self, let strip = strip else { return }
                let localX = strip.convert(NSPoint(x: windowX, y: 0), from: nil).x
                let dropIdx = self.dropIndex(forLocalX: localX)
                strip.showDragIndicator(at: self.indicatorX(forDropIndex: dropIdx))
            }
            btn.onDragEnd = { [weak self, weak strip] windowX in
                strip?.hideDragIndicator()
                guard let self = self else { return }
                let s = self.panel.contentView as? StripView
                s?.hideDragIndicator()
                let localX = (self.panel.contentView as? StripView).map {
                    $0.convert(NSPoint(x: windowX, y: 0), from: nil).x
                } ?? windowX
                let toIdx = self.dropIndex(forLocalX: localX)
                if toIdx != i { self.reorderButton(from: i, to: toIdx) }
            }
            strip.addSubview(btn)

            if hotkeysEnabled && i < 9 {
                let label = NSTextField(labelWithString: "\(i + 1)")
                label.font = NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .bold)
                label.textColor = NSColor.white.withAlphaComponent(0.85)
                label.isEditable = false
                label.drawsBackground = false
                label.isBordered = false
                label.sizeToFit()
                label.frame = NSRect(x: btnX + 3, y: pad + size - label.frame.height - 2,
                                     width: label.frame.width, height: label.frame.height)
                strip.addSubview(label)
            }
        }

        let gearX = pad + CGFloat(config.buttons.count) * (size + pad)
        let gear = PanelButton(frame: NSRect(x: gearX, y: pad, width: size, height: size))
        gear.bezelStyle = .regularSquare
        gear.imagePosition = .imageOnly
        gear.title = ""
        gear.toolTip = "Add / Settings"
        if let img = NSImage(systemSymbolName: "plus.circle", accessibilityDescription: nil) {
            img.size = NSSize(width: size * 0.72, height: size * 0.72)
            gear.image = img
        }
        gear.imageScaling = .scaleProportionallyUpOrDown
        gear.target = self
        gear.action = #selector(showMainMenu(_:))
        strip.addSubview(gear)

        let oldFrame = panel.frame
        panel.contentView = strip
        var newFrame = panel.frameRect(forContentRect: NSRect(origin: .zero, size: NSSize(width: contentW, height: contentH)))
        newFrame.origin = NSPoint(x: oldFrame.origin.x, y: oldFrame.maxY - newFrame.height)
        panel.setFrame(newFrame, display: true, animate: false)
    }

    func configure(_ btn: PanelButton, with model: LauncherButton, index: Int) {
        btn.bezelStyle = .regularSquare
        btn.imagePosition = .imageOnly
        btn.imageScaling = .scaleProportionallyUpOrDown
        btn.title = ""
        btn.toolTip = model.title
        btn.tag = index
        btn.target = self
        btn.action = #selector(buttonTapped(_:))

        let iconSize = CGFloat(config.buttonSize) * 0.72
        if model.type == .app, let p = model.appPath {
            let icon = NSWorkspace.shared.icon(forFile: p)
            icon.size = NSSize(width: iconSize, height: iconSize)
            btn.image = icon
        } else {
            let symbol = model.symbol ?? defaultSymbol(for: model.type)
            if let img = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) {
                img.size = NSSize(width: iconSize, height: iconSize)
                btn.image = img
            }
        }

        let menu = NSMenu()
        if model.scriptPath != nil {
            let edit = NSMenuItem(title: "Edit Script\u{2026}", action: #selector(editScript(_:)), keyEquivalent: "")
            edit.target = self; edit.tag = index
            menu.addItem(edit)
        }
        let changeIcon = NSMenuItem(title: "Change Icon\u{2026}", action: #selector(changeIcon(_:)), keyEquivalent: "")
        changeIcon.target = self; changeIcon.tag = index
        menu.addItem(changeIcon)
        menu.addItem(.separator())
        let remove = NSMenuItem(title: "Remove \u{201C}\(model.title)\u{201D}", action: #selector(removeButton(_:)), keyEquivalent: "")
        remove.target = self; remove.tag = index
        menu.addItem(remove)
        menu.addItem(.separator())
        appendGlobalItems(to: menu)
        btn.menu = menu
    }

    func defaultSymbol(for type: ActionType) -> String {
        switch type {
        case .app: return "app"
        case .script: return "applescript"
        case .ptMenu: return "slider.horizontal.3"
        case .ptKey: return "command"
        case .shell: return "terminal"
        }
    }

    // MARK: Run

    @objc func buttonTapped(_ sender: NSButton) {
        let idx = sender.tag
        guard idx >= 0 && idx < config.buttons.count else { return }
        run(config.buttons[idx])
    }

    func run(_ b: LauncherButton) {
        switch b.type {
        case .app:
            guard let p = b.appPath else { return }
            NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: p),
                                               configuration: NSWorkspace.OpenConfiguration(),
                                               completionHandler: nil)
        case .script:
            guard let path = b.scriptPath else { return }
            runAppleScriptFile(URL(fileURLWithPath: path))
        // Legacy fallbacks (should have been migrated, but just in case):
        case .ptMenu:
            guard let path = b.menuPath, !path.isEmpty else { return }
            runAppleScript(menuActionSource(target: b.targetApp ?? config.targetApp, menuPath: path))
        case .ptKey:
            guard let key = b.key else { return }
            runAppleScript(keystrokeSource(target: b.targetApp ?? config.targetApp, key: key, modifiers: b.modifiers ?? []))
        case .shell:
            if let path = b.scriptPath { runAppleScriptFile(URL(fileURLWithPath: path)) }
            else if let cmd = b.script { runShell(cmd) }
        }
    }

    func runAppleScriptFile(_ url: URL) {
        var loadErr: NSDictionary?
        guard let script = NSAppleScript(contentsOf: url, error: &loadErr) else {
            let msg = (loadErr?[NSAppleScript.errorMessage] as? String) ?? "\(loadErr as Any)"
            showError("Could not load script:\n\(msg)")
            return
        }
        var runErr: NSDictionary?
        script.executeAndReturnError(&runErr)
        if let err = runErr {
            let msg = (err[NSAppleScript.errorMessage] as? String) ?? "\(err)"
            showError("Script failed:\n\(msg)\n\nIf this is the first run, grant PT Launcher access under System Settings → Privacy & Security → Accessibility and Automation, then try again.")
        }
    }

    func runAppleScript(_ source: String) {
        var err: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&err)
        if let err = err {
            let msg = (err[NSAppleScript.errorMessage] as? String) ?? "\(err)"
            showError("Action failed:\n\(msg)")
        }
    }

    func runShell(_ command: String) {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", command]
        try? task.run()
    }

    // MARK: Add menu

    @objc func showMainMenu(_ sender: NSButton) {
        let menu = NSMenu()
        appendGlobalItems(to: menu)
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height), in: sender)
    }

    func appendGlobalItems(to menu: NSMenu) {
        let addApp = NSMenuItem(title: "Add Application\u{2026}", action: #selector(addApplication), keyEquivalent: "")
        addApp.target = self
        menu.addItem(addApp)

        let addPT = NSMenuItem(title: "Add Pro Tools Action\u{2026}", action: #selector(addMenuAction), keyEquivalent: "")
        addPT.target = self
        menu.addItem(addPT)

        let addKey = NSMenuItem(title: "Add Keystroke Action\u{2026}", action: #selector(addKeyAction), keyEquivalent: "")
        addKey.target = self
        menu.addItem(addKey)

        let addScript = NSMenuItem(title: "Add Custom Script\u{2026}", action: #selector(addScriptAction), keyEquivalent: "")
        addScript.target = self
        menu.addItem(addScript)

        menu.addItem(.separator())

        let hotkeys = NSMenuItem(title: "Number Hotkeys (1\u{2013}9)", action: #selector(toggleHotkeys), keyEquivalent: "")
        hotkeys.target = self
        hotkeys.state = hotkeysEnabled ? .on : .off
        menu.addItem(hotkeys)

        menu.addItem(.separator())

        #if canImport(Sparkle)
        let upd = NSMenuItem(title: "Check for Updates\u{2026}", action: #selector(checkForUpdates(_:)), keyEquivalent: "")
        upd.target = self
        menu.addItem(upd)

        menu.addItem(.separator())
        #endif

        let quit = NSMenuItem(title: "Quit PT Launcher", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    #if canImport(Sparkle)
    @objc func checkForUpdates(_ sender: Any?) {
        updaterController?.checkForUpdates(sender)
    }
    #endif

    @objc func addApplication() {
        let p = NSOpenPanel()
        p.allowsMultipleSelection = false
        p.canChooseDirectories = false
        p.canChooseFiles = true
        p.allowedFileTypes = ["app"]
        p.directoryURL = URL(fileURLWithPath: "/Applications")
        NSApp.activate(ignoringOtherApps: true)
        guard p.runModal() == .OK, let url = p.url else { return }
        let name = url.deletingPathExtension().lastPathComponent
        config.buttons.append(LauncherButton(title: name, type: .app, appPath: url.path, symbol: "app"))
        persistAndRebuild()
    }

    @objc func addMenuAction() {
        guard let title = prompt("New Pro Tools action", "Button label:", "") else { return }
        guard let pathStr = prompt("Menu path",
                                   "Menu path separated by \" > \".\nExample: AudioSuite > Noise Reduction > RX 11 Connect",
                                   "AudioSuite > Noise Reduction > ") else { return }
        let path = pathStr.components(separatedBy: ">")
                          .map { $0.trimmingCharacters(in: .whitespaces) }
                          .filter { !$0.isEmpty }
        guard !path.isEmpty else { return }
        let url = makeScriptURL(for: title)
        let src = menuActionSource(target: config.targetApp, menuPath: path)
        try? src.write(to: url, atomically: true, encoding: .utf8)
        openInScriptEditor(url)
        config.buttons.append(LauncherButton(title: title, type: .script, scriptPath: url.path, symbol: "slider.horizontal.3"))
        persistAndRebuild()
    }

    @objc func addKeyAction() {
        guard let title = prompt("New keystroke action", "Button label:", "") else { return }
        guard let key = prompt("Key", "Single key to press (e.g. p):", "") else { return }
        let modStr = prompt("Modifiers", "Comma-separated (command, option, control, shift). Leave blank for none:", "command") ?? ""
        let mods = modStr.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let url = makeScriptURL(for: title)
        let src = keystrokeSource(target: config.targetApp, key: key, modifiers: mods)
        try? src.write(to: url, atomically: true, encoding: .utf8)
        openInScriptEditor(url)
        config.buttons.append(LauncherButton(title: title, type: .script, scriptPath: url.path, symbol: "command"))
        persistAndRebuild()
    }

    @objc func addScriptAction() {
        guard let title = prompt("New custom script", "Button label:", "") else { return }
        let url = makeScriptURL(for: title)
        writeScriptTemplate(to: url, buttonTitle: title)
        config.buttons.append(LauncherButton(title: title, type: .script, scriptPath: url.path, symbol: "applescript"))
        persistAndRebuild()
        openInScriptEditor(url)
    }

    @objc func editScript(_ sender: NSMenuItem) {
        let idx = sender.tag
        guard idx >= 0 && idx < config.buttons.count,
              let path = config.buttons[idx].scriptPath else { return }
        openInScriptEditor(URL(fileURLWithPath: path))
    }

    @objc func changeIcon(_ sender: NSMenuItem) {
        let idx = sender.tag
        guard idx >= 0 && idx < config.buttons.count else { return }
        let current = config.buttons[idx].symbol ?? ""
        showIconPicker(current: current) { [weak self] symbol in
            self?.config.buttons[idx].symbol = symbol
            self?.persistAndRebuild()
        }
    }

    func showIconPicker(current: String, completion: @escaping (String) -> Void) {
        let cellSize: CGFloat = 44
        let cols = 10
        let allSymbols = symbolLibrary.flatMap { $0.symbols }
        let rows = Int(ceil(Double(allSymbols.count) / Double(cols)))
        let gridW = CGFloat(cols) * cellSize
        let gridH = CGFloat(rows) * cellSize

        let selector = SymbolSelector(initial: current)

        let container = NSView(frame: NSRect(x: 0, y: 0, width: gridW, height: gridH))
        for (i, sym) in allSymbols.enumerated() {
            let col = i % cols
            let row = i / cols
            let x = CGFloat(col) * cellSize
            let y = gridH - CGFloat(row + 1) * cellSize
            let btn = NSButton(frame: NSRect(x: x, y: y, width: cellSize, height: cellSize))
            btn.bezelStyle = .regularSquare
            btn.imagePosition = .imageOnly
            btn.imageScaling = .scaleProportionallyUpOrDown
            btn.toolTip = sym
            btn.wantsLayer = true
            btn.layer?.cornerRadius = 6
            if let img = NSImage(systemSymbolName: sym, accessibilityDescription: nil) {
                img.size = NSSize(width: 22, height: 22)
                btn.image = img
            }
            selector.register(btn, symbol: sym)
            container.addSubview(btn)
        }

        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: gridW, height: min(gridH, 308)))
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.documentView = container

        let alert = NSAlert()
        alert.messageText = "Choose an Icon"
        alert.informativeText = "Click an icon to select it. Hover for the symbol name."
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.accessoryView = scroll
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            completion(selector.selected)
        }
    }

    @objc func removeButton(_ sender: NSMenuItem) {
        let idx = sender.tag
        guard idx >= 0 && idx < config.buttons.count else { return }
        config.buttons.remove(at: idx)
        persistAndRebuild()
    }

    @objc func reloadConfig() {
        config = ConfigStore.shared.load()
        migrateToScriptFiles()
        rebuildGrid()
    }

    @objc func quit() { NSApp.terminate(nil) }

    func persistAndRebuild() {
        ConfigStore.shared.save(config)
        rebuildGrid()
    }

    // MARK: Script file helpers

    func makeScriptURL(for title: String) -> URL {
        let dir = ConfigStore.shared.scriptsURL
        let safe = title
            .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " -_")).inverted)
            .joined()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "_")
        let base = safe.isEmpty ? "script" : safe
        var url = dir.appendingPathComponent("\(base).applescript")
        var n = 2
        while FileManager.default.fileExists(atPath: url.path) {
            url = dir.appendingPathComponent("\(base)_\(n).applescript")
            n += 1
        }
        return url
    }

    func writeScriptTemplate(to url: URL, buttonTitle: String) {
        let template = """
        -- PT Launcher: \(buttonTitle)
        -- Edit this script and save (⌘S). Changes take effect immediately next time you click the button.
        -- Press ⌘K to compile and check for syntax errors.
        --
        -- ── Examples ─────────────────────────────────────────────────────────────────
        --
        -- Click a Pro Tools menu item:
        --   tell application "Pro Tools" to activate
        --   delay 0.2
        --   tell application "System Events"
        --       tell process "Pro Tools"
        --           click menu item "RX 11 Connect" of menu "Noise Reduction" ¬
        --               of menu item "Noise Reduction" of menu "AudioSuite" ¬
        --               of menu bar item "AudioSuite" of menu bar 1
        --       end tell
        --   end tell
        --
        -- Click a button in an open plugin window:
        --   tell application "System Events"
        --       tell process "iZotope RX 11 Audio Editor"
        --           click button "Send to iZotope RX" of window 1
        --       end tell
        --   end tell
        --
        -- Run a shell command:
        --   do shell script "open ~/Desktop/MySong.ptx"
        -- ─────────────────────────────────────────────────────────────────────────────

        """
        try? template.write(to: url, atomically: true, encoding: .utf8)
    }

    func openInScriptEditor(_ url: URL) {
        let scriptEditor = URL(fileURLWithPath: "/System/Applications/Script Editor.app")
        let app = FileManager.default.fileExists(atPath: scriptEditor.path)
            ? scriptEditor
            : URL(fileURLWithPath: "/System/Applications/TextEdit.app")
        NSWorkspace.shared.open([url], withApplicationAt: app,
                                configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
    }

    func legacyApplescriptPath(from script: String?) -> String? {
        guard let s = script?.trimmingCharacters(in: .whitespaces),
              s.hasPrefix("osascript \""), s.hasSuffix("\"") else { return nil }
        let inner = String(s.dropFirst("osascript \"".count).dropLast(1))
        return inner.hasSuffix(".applescript") ? inner : nil
    }

    // MARK: Hotkeys

    @objc func toggleHotkeys() {
        hotkeysEnabled.toggle()
        if hotkeysEnabled { installEventTap() } else { removeEventTap() }
        rebuildGrid()
    }

    func installEventTap() {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            hotkeysEnabled = false
            showError("PT Launcher needs Accessibility permission to override number hotkeys.\n\nGo to System Settings \u{2192} Privacy & Security \u{2192} Accessibility and enable PT Launcher, then try again.")
            return
        }
        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        hotkeyTap = tap
        hotkeyRunLoopSource = src
    }

    func removeEventTap() {
        if let tap = hotkeyTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            hotkeyTap = nil
        }
        if let src = hotkeyRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
            hotkeyRunLoopSource = nil
        }
    }

    func processKeyEvent(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        guard hotkeysEnabled else { return Unmanaged.passRetained(event) }
        let target = (config.followApp ?? config.targetApp).trimmingCharacters(in: .whitespaces)
        guard !target.isEmpty, matches(NSWorkspace.shared.frontmostApplication, target: target) else {
            return Unmanaged.passRetained(event)
        }
        guard !isFrontAppTextFieldFocused() else { return Unmanaged.passRetained(event) }
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        // Number key keycodes (US layout): 1=18 2=19 3=20 4=21 5=23 6=22 7=26 8=28 9=25
        let map: [Int64: Int] = [18: 0, 19: 1, 20: 2, 21: 3, 23: 4, 22: 5, 26: 6, 28: 7, 25: 8]
        guard let idx = map[keyCode], idx < config.buttons.count else {
            return Unmanaged.passRetained(event)
        }
        let button = config.buttons[idx]
        DispatchQueue.main.async { self.run(button) }
        return nil  // consume — Pro Tools won't see this keypress
    }

    func isFrontAppTextFieldFocused() -> Bool {
        guard let app = NSWorkspace.shared.frontmostApplication else { return false }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var focused: AnyObject?
        guard AXUIElementCopyAttributeValue(axApp, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let element = focused else { return false }
        var role: AnyObject?
        AXUIElementCopyAttributeValue(element as! AXUIElement, kAXRoleAttribute as CFString, &role)
        let r = role as? String ?? ""
        return r == kAXTextFieldRole || r == kAXTextAreaRole || r == kAXComboBoxRole
    }

    // MARK: Drag reorder

    func dropIndex(forLocalX x: CGFloat) -> Int {
        let pad = config.resolvedPadding
        let size = CGFloat(config.buttonSize)
        for i in 0..<config.buttons.count {
            let center = pad + CGFloat(i) * (size + pad) + size / 2
            if x < center { return i }
        }
        return config.buttons.count
    }

    func indicatorX(forDropIndex idx: Int) -> CGFloat {
        let pad = config.resolvedPadding
        let size = CGFloat(config.buttonSize)
        if idx == 0 { return pad * 0.5 }
        return pad + CGFloat(idx) * (size + pad) - pad * 0.5
    }

    func reorderButton(from fromIdx: Int, to toIdx: Int) {
        guard fromIdx >= 0, fromIdx < config.buttons.count,
              toIdx >= 0, toIdx <= config.buttons.count,
              fromIdx != toIdx else { return }
        let btn = config.buttons.remove(at: fromIdx)
        let insertAt = toIdx > fromIdx ? toIdx - 1 : toIdx
        config.buttons.insert(btn, at: insertAt)
        persistAndRebuild()
    }

    // MARK: Helpers

    func prompt(_ title: String, _ message: String, _ defaultValue: String) -> String? {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 24))
        field.stringValue = defaultValue
        alert.accessoryView = field
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        let v = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return v.isEmpty ? nil : v
    }

    func showError(_ text: String) {
        let alert = NSAlert()
        alert.messageText = "PT Launcher"
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}

// MARK: - Entry point

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
