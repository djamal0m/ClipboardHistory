import Foundation

public struct ClipboardItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let text: String
    public let date: Date

    public init(text: String, id: UUID = UUID(), date: Date = Date()) {
        self.id = id
        self.text = text
        self.date = date
    }

    public var preview: String {
        let collapsed = text.replacingOccurrences(of: "\n", with: "  ")
        let limit = 70
        if collapsed.count > limit {
            let idx = collapsed.index(collapsed.startIndex, offsetBy: limit)
            return String(collapsed[..<idx]) + "…"
        }
        return collapsed
    }

    /// Extra detail shown in a hover tooltip, since the on-screen preview is
    /// truncated to one line. Locale is pinned to en_US so the wording is
    /// deterministic regardless of the runner's system locale.
    public func hoverInfo(relativeTo referenceDate: Date = Date()) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "en_US")
        let relative = formatter.localizedString(for: date, relativeTo: referenceDate)
        let unit = text.count == 1 ? "character" : "characters"
        return "Copied \(relative) • \(text.count) \(unit)"
    }
}
