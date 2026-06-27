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

// Names that aren't available on the running macOS just render blank (configure()
// guards with `if let img`), so it's safe to include newer symbols.
let symbolLibrary: [(category: String, symbols: [String])] = [
    ("Audio", [
        "waveform", "waveform.circle", "waveform.circle.fill", "waveform.path",
        "waveform.path.ecg", "waveform.path.ecg.rectangle",
        "waveform.path.badge.plus", "waveform.path.badge.minus",
        "waveform.badge.plus", "waveform.badge.minus", "waveform.badge.mic",
        "dot.radiowaves.left.and.right", "dot.radiowaves.right",
        "antenna.radiowaves.left.and.right",
        "headphones", "headphones.circle", "headphones.circle.fill",
        "earpods", "airpods", "airpodspro",
        "hifispeaker", "hifispeaker.fill", "homepod", "homepod.fill",
        "mic", "mic.fill", "mic.circle", "mic.circle.fill", "mic.slash", "mic.slash.fill",
        "speaker", "speaker.fill", "speaker.wave.1", "speaker.wave.2", "speaker.wave.3",
        "speaker.wave.2.circle", "speaker.slash", "speaker.zzz",
        "music.note", "music.note.list", "music.note.house", "music.quarternote.3",
        "music.mic", "metronome", "metronome.fill",
        "guitars", "guitars.fill", "pianokeys", "ear", "ear.fill", "amplifier",
    ]),
    ("Transport", [
        "play", "play.fill", "play.circle", "play.circle.fill", "play.rectangle.fill",
        "pause", "pause.fill", "pause.circle", "pause.circle.fill",
        "playpause", "playpause.fill",
        "stop", "stop.fill", "stop.circle", "stop.circle.fill",
        "record.circle", "record.circle.fill",
        "forward", "forward.fill", "backward", "backward.fill",
        "forward.end.fill", "backward.end.fill", "forward.frame.fill", "backward.frame.fill",
        "gobackward", "goforward", "gobackward.10", "goforward.10",
        "repeat", "repeat.1", "shuffle", "infinity",
        "timer", "stopwatch", "stopwatch.fill", "speedometer",
    ]),
    ("Edit", [
        "scissors", "scissors.circle", "scissors.badge.ellipsis",
        "lasso", "crop", "crop.rotate", "selection.pin.in.out",
        "arrow.uturn.backward", "arrow.uturn.forward",
        "arrow.uturn.left.circle", "arrow.uturn.right.circle",
        "arrow.clockwise", "arrow.counterclockwise",
        "doc.on.doc", "doc.on.clipboard",
        "pencil", "pencil.circle", "pencil.tip", "pencil.and.outline",
        "square.and.pencil", "highlighter",
        "trash", "trash.circle", "trash.fill",
        "delete.left", "delete.right",
        "checkmark", "checkmark.circle", "checkmark.seal",
        "xmark", "xmark.circle", "xmark.seal",
        "plus", "plus.circle", "minus", "minus.circle", "plusminus",
    ]),
    ("Tools", [
        "applescript", "applescript.fill", "terminal", "terminal.fill",
        "command", "command.circle", "command.square", "option", "control",
        "gear", "gearshape", "gearshape.fill", "gearshape.2",
        "slider.horizontal.3", "slider.horizontal.below.rectangle", "switch.2",
        "dial.min", "dial.max", "dial.low", "dial.medium", "dial.high",
        "wrench.and.screwdriver", "wrench.and.screwdriver.fill",
        "hammer", "hammer.fill", "screwdriver", "wrench.adjustable",
        "bolt", "bolt.fill", "bolt.circle", "bolt.horizontal",
        "cpu", "memorychip", "gauge", "ruler", "level",
        "paintbrush", "paintbrush.pointed", "eyedropper",
        "lightbulb", "lightbulb.fill", "flame", "flame.fill",
        "wand.and.stars", "wand.and.rays", "sparkle", "sparkles", "powerplug",
    ]),
    ("Files", [
        "folder", "folder.fill", "folder.circle", "folder.badge.plus", "folder.badge.gearshape",
        "doc", "doc.fill", "doc.text", "doc.text.fill", "doc.richtext", "doc.badge.plus",
        "square.and.arrow.up", "square.and.arrow.down",
        "tray", "tray.fill", "tray.full", "tray.and.arrow.down", "tray.and.arrow.up",
        "archivebox", "archivebox.fill", "shippingbox",
        "externaldrive", "externaldrive.fill", "internaldrive", "opticaldiscdrive",
        "server.rack", "icloud", "icloud.fill", "icloud.and.arrow.up", "icloud.and.arrow.down",
    ]),
    ("Arrows", [
        "arrow.right", "arrow.left", "arrow.up", "arrow.down",
        "arrow.right.circle", "arrow.left.circle", "arrow.up.circle", "arrow.down.circle",
        "arrow.up.arrow.down", "arrow.left.arrow.right",
        "arrow.up.right", "arrow.down.right", "arrow.up.left", "arrow.down.left",
        "arrow.triangle.2.circlepath", "arrow.clockwise.circle", "arrow.counterclockwise.circle",
        "arrow.uturn.up", "arrow.uturn.down",
        "arrowshape.turn.up.right", "arrowshape.turn.up.left",
        "chevron.right", "chevron.left", "chevron.up", "chevron.down",
        "chevron.right.circle", "chevron.up.circle",
    ]),
    ("Shapes", [
        "circle", "circle.fill", "square", "square.fill",
        "triangle", "triangle.fill", "diamond", "diamond.fill",
        "hexagon", "hexagon.fill", "octagon", "octagon.fill",
        "seal", "seal.fill", "rhombus", "rhombus.fill", "capsule", "oval",
        "app", "app.fill", "rectangle", "rectangle.fill",
        "square.grid.2x2", "square.grid.3x3", "circle.grid.2x2",
    ]),
    ("Misc", [
        "star", "star.fill", "star.circle", "star.circle.fill",
        "heart", "heart.fill", "heart.circle", "bolt.heart",
        "flag", "flag.fill", "flag.circle", "flag.checkered",
        "bookmark", "bookmark.fill", "bookmark.circle",
        "tag", "tag.fill", "tag.circle",
        "pin", "pin.fill", "mappin", "mappin.circle",
        "bell", "bell.fill", "bell.slash", "bell.badge", "bell.circle",
        "eye", "eye.fill", "eye.slash", "eye.circle",
        "hand.thumbsup", "hand.thumbsup.fill", "hand.thumbsdown", "hand.thumbsdown.fill",
        "hand.raised", "hand.raised.fill", "hand.point.up.left",
        "person", "person.fill", "person.circle",
        "clock", "clock.fill", "calendar", "calendar.badge.clock",
        "lock", "lock.fill", "lock.open", "key", "key.fill",
        "wifi", "globe", "globe.americas",
        "moon", "moon.fill", "sun.max", "sun.max.fill", "cloud", "cloud.fill",
        "paperplane", "paperplane.fill", "envelope", "envelope.fill",
        "questionmark.circle", "exclamationmark.triangle", "info.circle",
        "number", "textformat", "character",
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
    // Optional custom global shortcut (overrides the positional 1-9 key).
    var shortcutKeyCode: Int?
    var shortcutModifiers: [String]?   // any of: command, option, control, shift
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
    // Modifier required for the positional 1-9 shortcuts: none/command/option/control/shift.
    // Default "option" — Pro Tools' transport/nudge fields are invisible to accessibility,
    // so bare number keys can't be made safe; a modifier avoids the collision.
    var numberHotkeyModifier: String? = nil

    var resolvedPadding: CGFloat { CGFloat(padding ?? 8) }
    var resolvedNumberModifier: String { (numberHotkeyModifier ?? "option").lowercased() }

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
        // First run on this machine: seed the bundled default scripts.
        let def = seededDefault()
        save(def)
        return def
    }

    // First-run config. If the app bundle ships scripts in Resources/scripts
    // (added by build.sh from the repo's default_scripts/ folder), copy each
    // into the user's scripts folder and make a button for it. Otherwise fall
    // back to the built-in default.
    func seededDefault() -> Config {
        guard let resDir = Bundle.main.resourceURL?.appendingPathComponent("scripts", isDirectory: true),
              let items = try? FileManager.default.contentsOfDirectory(at: resDir, includingPropertiesForKeys: nil)
        else { return Config.makeDefault() }

        let scripts = items
            .filter { $0.pathExtension == "applescript" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        guard !scripts.isEmpty else { return Config.makeDefault() }

        var buttons: [LauncherButton] = []
        for src in scripts {
            let dst = scriptsURL.appendingPathComponent(src.lastPathComponent)
            if !FileManager.default.fileExists(atPath: dst.path) {
                try? FileManager.default.copyItem(at: src, to: dst)
            }
            let title = src.deletingPathExtension().lastPathComponent
                .replacingOccurrences(of: "_", with: " ")
            buttons.append(LauncherButton(title: title, type: .script,
                                          scriptPath: dst.path, symbol: "waveform.path.ecg"))
        }
        return Config(columns: 3, buttonSize: 52, padding: 6,
                      targetApp: "Pro Tools", followApp: "Pro Tools", buttons: buttons)
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

            if hotkeysEnabled {
                // Show the custom shortcut if assigned, otherwise the positional 1-9
                // prefixed with the required modifier symbol.
                var badge: String? = shortcutDisplay(for: b)
                if badge == nil && i < 9 { badge = numberModifierSymbol() + "\(i + 1)" }
                if let text = badge {
                    let label = NSTextField(labelWithString: text)
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
        if let sc = shortcutDisplay(for: model) {
            btn.toolTip = "\(model.title)  (\(sc))"
        } else {
            btn.toolTip = model.title
        }
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

        let scTitle = shortcutDisplay(for: model).map { "Set Shortcut\u{2026} (now \($0))" } ?? "Set Shortcut\u{2026}"
        let setSC = NSMenuItem(title: scTitle, action: #selector(setShortcut(_:)), keyEquivalent: "")
        setSC.target = self; setSC.tag = index
        menu.addItem(setSC)
        if model.shortcutKeyCode != nil {
            let clearSC = NSMenuItem(title: "Clear Shortcut", action: #selector(clearShortcut(_:)), keyEquivalent: "")
            clearSC.target = self; clearSC.tag = index
            menu.addItem(clearSC)
        }

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

        let hotkeys = NSMenuItem(title: "Keyboard Shortcuts (1\u{2013}9 + custom)", action: #selector(toggleHotkeys), keyEquivalent: "")
        hotkeys.target = self
        hotkeys.state = hotkeysEnabled ? .on : .off
        menu.addItem(hotkeys)

        // Submenu: which modifier the positional 1-9 keys require.
        let modItem = NSMenuItem(title: "Number Key Modifier", action: nil, keyEquivalent: "")
        let modMenu = NSMenu()
        let current = config.resolvedNumberModifier
        for (label, value) in [("\u{2325} Option (recommended)", "option"),
                               ("\u{2318} Command", "command"),
                               ("\u{2303} Control", "control"),
                               ("\u{21E7} Shift", "shift"),
                               ("None (bare 1\u{2013}9 \u{2014} unsafe in Pro Tools)", "none")] {
            let mi = NSMenuItem(title: label, action: #selector(setNumberModifier(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = value
            mi.state = (current == value) ? .on : .off
            modMenu.addItem(mi)
        }
        modItem.submenu = modMenu
        menu.addItem(modItem)

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
        // Only show symbols that actually render on this macOS version.
        let allSymbols = symbolLibrary.flatMap { $0.symbols }
            .filter { NSImage(systemSymbolName: $0, accessibilityDescription: nil) != nil }
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
        -- PT Launcher button: \(buttonTitle)
        --
        -- ==========================================================================
        --  NOT SURE HOW TO WRITE THIS? Let Claude (or ChatGPT) do it for you.
        --   1. Select all of this (Cmd-A), copy it (Cmd-C).
        --   2. Paste it into Claude and finish this sentence:
        --        "Make this PT Launcher button ______."
        --      examples:
        --        "run the iZotope RX De-hum plugin on the selected clip"
        --        "bounce the session to disk"
        --        "open my most recent Pro Tools session"
        --   3. Claude gives you a finished script. Replace EVERYTHING in this file
        --      with it, then Save (Cmd-S). Click the button to run it.
        -- ==========================================================================
        --
        -- --------------------------------------------------------------------------
        --  CONTEXT FOR CLAUDE  (read before writing the script)
        -- --------------------------------------------------------------------------
        --  * This file is an AppleScript that the macOS app "PT Launcher" runs when
        --    the user clicks a button. Reply with a COMPLETE AppleScript and nothing
        --    else. The user just wants it to work; assume they won't edit the code.
        --  * Pro Tools has no real scripting API, so automate it the way a person
        --    would: bring it to the front, then drive its menus with System Events
        --    GUI scripting. PT Launcher already has Accessibility + Automation
        --    permission, so GUI scripting is allowed.
        --  * Target app name and process name are both "Pro Tools".
        --  * Menu and button NAMES must match EXACTLY what the user sees on screen,
        --    including version numbers (e.g. "RX 11 Connect", not "RX Connect").
        --    AudioSuite plugins live under category submenus, e.g.
        --    AudioSuite > Noise Reduction > <plugin name>. If you are not certain of
        --    the exact wording, ask the user to read it off their own AudioSuite menu.
        --  * Put a short "delay 0.2" after activating Pro Tools so its menus are ready.
        --  * Keep it simple and add one comment line saying what it does.
        --
        --  THINGS YOU CAN DO (working examples):
        --
        --  -- Run an AudioSuite plugin on the selected clip:
        --  tell application "Pro Tools" to activate
        --  delay 0.2
        --  tell application "System Events" to tell process "Pro Tools"
        --      click menu item "RX 11 Connect" of menu "Noise Reduction" of menu item "Noise Reduction" of menu "AudioSuite" of menu bar item "AudioSuite" of menu bar 1
        --  end tell
        --
        --  -- Send a Pro Tools key command (whatever the user has assigned):
        --  tell application "Pro Tools" to activate
        --  delay 0.1
        --  tell application "System Events" to keystroke "b" using {command down}
        --
        --  -- Click a button inside an open plugin/dialog window:
        --  tell application "System Events" to tell process "Pro Tools"
        --      click button "Render" of window 1
        --  end tell
        --
        --  -- Open another app or a file:
        --  do shell script "open -a 'Logic Pro'"
        --  do shell script "open ~/Desktop/MySession.ptx"
        --
        --  GOTCHAS:
        --  * "Can't find menu item X" means the wording is wrong or the menu wasn't
        --    open yet -- check exact spelling and add a small delay.
        --  * Clicking the button shows any error in a popup, so it's safe to test.
        -- --------------------------------------------------------------------------
        --
        -- Write the script below (and delete these comments once it works):

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
            showError("PT Launcher needs Accessibility permission to use keyboard shortcuts.\n\nGo to System Settings \u{2192} Privacy & Security \u{2192} Accessibility and enable PT Launcher, then try again.")
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

        // Modifiers currently held (ignoring caps lock / fn).
        let flags = event.flags
        var modSet = Set<String>()
        if flags.contains(.maskCommand) { modSet.insert("command") }
        if flags.contains(.maskAlternate) { modSet.insert("option") }
        if flags.contains(.maskControl) { modSet.insert("control") }
        if flags.contains(.maskShift) { modSet.insert("shift") }

        // 1. Custom per-button shortcuts take priority.
        for b in config.buttons {
            if let kc = b.shortcutKeyCode, Int64(kc) == keyCode,
               Set(b.shortcutModifiers ?? []) == modSet {
                DispatchQueue.main.async { self.run(b) }
                return nil  // consume — supersedes Pro Tools' shortcut
            }
        }

        // 2. Positional number keys 1-9. A required modifier (default Option)
        //    avoids colliding with typing values into Pro Tools fields, which are
        //    invisible to accessibility. Only fires for buttons without a custom shortcut.
        // Number key keycodes (US layout): 1=18 2=19 3=20 4=21 5=23 6=22 7=26 8=28 9=25
        let map: [Int64: Int] = [18: 0, 19: 1, 20: 2, 21: 3, 23: 4, 22: 5, 26: 6, 28: 7, 25: 8]
        let numMod = config.resolvedNumberModifier
        let requiredMods: Set<String> = (numMod == "none") ? [] : [numMod]
        if modSet == requiredMods, let idx = map[keyCode], idx < config.buttons.count,
           config.buttons[idx].shortcutKeyCode == nil {
            let button = config.buttons[idx]
            DispatchQueue.main.async { self.run(button) }
            return nil  // consume — Pro Tools won't see this keypress
        }

        return Unmanaged.passRetained(event)
    }

    // MARK: Shortcut capture / display

    // Maps the small set of key codes we display nicely; everything else shows as "key N".
    static let keyCodeNames: [Int: String] = [
        18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6", 26: "7", 28: "8", 25: "9", 29: "0",
        0: "A", 11: "B", 8: "C", 2: "D", 14: "E", 3: "F", 5: "G", 4: "H", 34: "I", 38: "J",
        40: "K", 37: "L", 46: "M", 45: "N", 31: "O", 35: "P", 12: "Q", 15: "R", 1: "S", 17: "T",
        32: "U", 9: "V", 13: "W", 7: "X", 16: "Y", 6: "Z",
        49: "Space", 36: "Return", 48: "Tab", 53: "Esc",
        123: "Left", 124: "Right", 125: "Down", 126: "Up",
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8",
        101: "F9", 109: "F10", 103: "F11", 111: "F12"
    ]

    func shortcutDisplay(for b: LauncherButton) -> String? {
        guard let kc = b.shortcutKeyCode else { return nil }
        var s = ""
        let mods = b.shortcutModifiers ?? []
        if mods.contains("control") { s += "\u{2303}" }   // ⌃
        if mods.contains("option")  { s += "\u{2325}" }   // ⌥
        if mods.contains("shift")   { s += "\u{21E7}" }   // ⇧
        if mods.contains("command") { s += "\u{2318}" }   // ⌘
        s += AppDelegate.keyCodeNames[kc] ?? "key \(kc)"
        return s
    }

    func modifierSymbol(_ name: String) -> String {
        switch name {
        case "command": return "\u{2318}"  // ⌘
        case "option":  return "\u{2325}"  // ⌥
        case "control": return "\u{2303}"  // ⌃
        case "shift":   return "\u{21E7}"  // ⇧
        default:        return ""           // none
        }
    }

    func numberModifierSymbol() -> String { modifierSymbol(config.resolvedNumberModifier) }

    @objc func setNumberModifier(_ sender: NSMenuItem) {
        guard let mod = sender.representedObject as? String else { return }
        config.numberHotkeyModifier = mod
        persistAndRebuild()
    }

    @objc func setShortcut(_ sender: NSMenuItem) {
        let index = sender.tag
        guard index >= 0 && index < config.buttons.count else { return }
        let title = config.buttons[index].title

        let alert = NSAlert()
        alert.messageText = "Set Shortcut"
        alert.informativeText = "Press the key combination for \u{201C}\(title)\u{201D}.\nIt fires this button (and overrides Pro Tools) while Pro Tools is active.\n\nPress Esc to cancel."
        alert.addButton(withTitle: "Cancel")

        var captured: (Int, [String])?
        let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { ev in
            if ev.keyCode == 53 { NSApp.stopModal(); return nil }  // Esc cancels
            var mods: [String] = []
            if ev.modifierFlags.contains(.control) { mods.append("control") }
            if ev.modifierFlags.contains(.option)  { mods.append("option") }
            if ev.modifierFlags.contains(.shift)   { mods.append("shift") }
            if ev.modifierFlags.contains(.command) { mods.append("command") }
            captured = (Int(ev.keyCode), mods)
            NSApp.stopModal()
            return nil
        }
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
        if let m = monitor { NSEvent.removeMonitor(m) }

        if let (kc, mods) = captured {
            config.buttons[index].shortcutKeyCode = kc
            config.buttons[index].shortcutModifiers = mods
            persistAndRebuild()
            if !hotkeysEnabled {
                showError("Shortcut saved. Turn on \u{201C}Keyboard Shortcuts\u{201D} in the menu to use it.")
            }
        }
    }

    @objc func clearShortcut(_ sender: NSMenuItem) {
        let index = sender.tag
        guard index >= 0 && index < config.buttons.count else { return }
        config.buttons[index].shortcutKeyCode = nil
        config.buttons[index].shortcutModifiers = nil
        persistAndRebuild()
    }

    func isFrontAppTextFieldFocused() -> Bool {
        guard let app = NSWorkspace.shared.frontmostApplication else { return false }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var focused: AnyObject?
        guard AXUIElementCopyAttributeValue(axApp, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let elementAny = focused else { return false }
        let element = elementAny as! AXUIElement

        func attr(_ name: String) -> AnyObject? {
            var v: AnyObject?
            return AXUIElementCopyAttributeValue(element, name as CFString, &v) == .success ? v : nil
        }
        func has(_ name: String) -> Bool {
            var v: AnyObject?
            return AXUIElementCopyAttributeValue(element, name as CFString, &v) == .success
        }

        // 1. Standard text roles / subroles.
        let role = attr(kAXRoleAttribute) as? String ?? ""
        let textRoles: Set<String> = [kAXTextFieldRole as String, kAXTextAreaRole as String,
                                      kAXComboBoxRole as String, "AXSecureTextField", "AXSearchField"]
        if textRoles.contains(role) { return true }
        if let sub = attr(kAXSubroleAttribute) as? String,
           sub.contains("TextField") || sub.contains("SearchField") || sub.contains("TextInput") {
            return true
        }

        // 2. Text-bearing element: exposes a character count or a selection range.
        //    Catches editable fields (like Pro Tools' transport/nudge counters) that
        //    don't report a standard text role.
        if has(kAXNumberOfCharactersAttribute) { return true }
        if has(kAXSelectedTextRangeAttribute) { return true }
        if has(kAXSelectedTextAttribute) { return true }

        // 3. Editable element: a focused element whose value is a settable string.
        var settable: DarwinBoolean = false
        if AXUIElementIsAttributeSettable(element, kAXValueAttribute as CFString, &settable) == .success,
           settable.boolValue, attr(kAXValueAttribute) is String {
            return true
        }

        return false
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
