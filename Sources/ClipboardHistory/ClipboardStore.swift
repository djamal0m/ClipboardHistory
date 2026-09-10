import AppKit
import Combine
import ServiceManagement
import ClipboardHistoryCore

@MainActor
final class ClipboardStore: ObservableObject {
    @Published var history: [ClipboardItem] = []
    @Published var query: String = ""
    @Published var launchAtLogin: Bool {
        didSet { setLaunchAtLogin(launchAtLogin) }
    }

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
        manager = ClipboardHistoryManager(maxItems: 1000)
        Self.migrateLegacyLoginItemIfNeeded()
        launchAtLogin = SMAppService.mainApp.status == .enabled
        loadHistory()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkClipboard()
            }
        }
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
        manager = ClipboardHistoryManager(items: saved, maxItems: manager.maxItems)
        history = saved
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
