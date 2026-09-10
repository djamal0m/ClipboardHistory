import SwiftUI

@main
struct ClipboardHistoryApp: App {
    @StateObject private var store = ClipboardStore()

    var body: some Scene {
        MenuBarExtra {
            ClipboardMenuView(store: store)
        } label: {
            Image(systemName: store.history.isEmpty ? "doc.on.clipboard" : "doc.on.clipboard.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
