import AppKit
import Combine
import ServiceManagement
import ClipboardHistoryCore

@MainActor
final class ClipboardStore: ObservableObject {
    @Published var history: [ClipboardItem] = []
    @Published var query: String = ""
    @Published var isShowingSettings: Bool = false
    @Published var launchAtLogin: Bool {
        didSet { setLaunchAtLogin(launchAtLogin) }
    }

    /// How many items to keep. Clamped to `Self.maxItemsRange`.
    @Published var maxItems: Int {
        didSet {
            let clamped = Self.maxItemsRange.clamp(maxItems)
            guard clamped == maxItems else {
                maxItems = clamped // re-triggers didSet once, already clamped
                return
            }
            UserDefaults.standard.set(maxItems, forKey: Self.maxItemsKey)
            manager.maxItems = maxItems
            manager.enforceCapacity()
            history = manager.items
            saveHistory()
        }
    }

    /// Longest clipboard text (in characters) to keep. Clamped to `Self.maxItemLengthRange`.
    @Published var maxItemLength: Int {
        didSet {
            let clamped = Self.maxItemLengthRange.clamp(maxItemLength)
            guard clamped == maxItemLength else {
                maxItemLength = clamped // re-triggers didSet once, already clamped
                return
            }
            UserDefaults.standard.set(maxItemLength, forKey: Self.maxItemLengthKey)
            manager.maxItemLength = maxItemLength
            manager.enforceMaxItemLength()
            history = manager.items
            saveHistory()
        }
    }

    @Published var appearance: AppAppearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: Self.appearanceKey)
            applyAppearance()
        }
    }

    static let maxItemsRange = 10...5000
    static let maxItemLengthRange = 100...5_000_000

    private static let maxItemsKey = "maxItems"
    private static let maxItemLengthKey = "maxItemLength"
    private static let appearanceKey = "appearance"

    private var manager: ClipboardHistoryManager
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var timer: Timer?

    private let historyURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ClipboardHistory", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("history.json")
    }()

    init() {
        let defaults = UserDefaults.standard
        let initialMaxItems = Self.maxItemsRange.clamp(
            defaults.object(forKey: Self.maxItemsKey) as? Int ?? 1000
        )
        let initialMaxItemLength = Self.maxItemLengthRange.clamp(
            defaults.object(forKey: Self.maxItemLengthKey) as? Int ?? 200_000
        )
        let initialAppearance = AppAppearance(rawValue: defaults.string(forKey: Self.appearanceKey) ?? "") ?? .system

        manager = ClipboardHistoryManager(maxItems: initialMaxItems, maxItemLength: initialMaxItemLength)
        maxItems = initialMaxItems
        maxItemLength = initialMaxItemLength
        appearance = initialAppearance

        Self.migrateLegacyLoginItemIfNeeded()
        launchAtLogin = SMAppService.mainApp.status == .enabled
        loadHistory()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkClipboard()
            }
        }

        // didSet doesn't fire for a property's first assignment inside init,
        // so apply the restored appearance explicitly (see applyAppearance).
        applyAppearance()
    }

    var filteredHistory: [ClipboardItem] {
        manager.filtered(query: query)
    }

    private func checkClipboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount

        guard let str = pb.string(forType: .string) else { return }
        if manager.add(str) {
            history = manager.items
            saveHistory()
        }
    }

    func copyToClipboard(_ item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(item.text, forType: .string)
        lastChangeCount = pb.changeCount
    }

    func delete(_ item: ClipboardItem) {
        manager.delete(id: item.id)
        history = manager.items
        saveHistory()
    }

    func clear() {
        manager.clear()
        history = manager.items
        saveHistory()
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        try? data.write(to: historyURL, options: .atomic)
    }

    private func loadHistory() {
        guard let data = try? Data(contentsOf: historyURL),
              let saved = try? JSONDecoder().decode([ClipboardItem].self, from: data) else { return }
        manager = ClipboardHistoryManager(items: saved, maxItems: manager.maxItems, maxItemLength: manager.maxItemLength)
        history = saved
    }

    /// SwiftUI's `.preferredColorScheme` does not reliably propagate into a
    /// `MenuBarExtra`'s `.window`-style content or its detached Settings
    /// content — a known SwiftUI-on-macOS gap. Setting the app-wide AppKit
    /// appearance directly is what actually affects every window/panel.
    private func applyAppearance() {
        switch appearance {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("ClipboardHistory: failed to \(enabled ? "register" : "unregister") login item: \(error)")
        }
    }

    /// Earlier versions hand-wrote a LaunchAgent plist instead of using
    /// SMAppService. If it's present, remove it and carry the user's intent
    /// forward through the modern API, once. Static so it can run before
    /// `self` is fully initialized.
    private static func migrateLegacyLoginItemIfNeeded() {
        let url = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LaunchAgents/com.user.clipboardhistory.plist")
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try? FileManager.default.removeItem(at: url)
        try? SMAppService.mainApp.register()
    }
}

private extension ClosedRange where Bound == Int {
    func clamp(_ value: Int) -> Int {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}
