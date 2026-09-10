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
}
