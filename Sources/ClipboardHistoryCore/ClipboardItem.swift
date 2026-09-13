import Foundation

public struct ClipboardItem: Identifiable, Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case text
        case image
        case file
    }

    public let id: UUID
    public let kind: Kind
    public let text: String
    /// PNG-encoded image bytes. Non-nil only when `kind == .image`.
    public let imageData: Data?
    /// Absolute paths of the copied file(s). Non-nil only when `kind == .file`.
    public let filePaths: [String]?
    public let date: Date

    public init(text: String, id: UUID = UUID(), date: Date = Date()) {
        self.id = id
        self.kind = .text
        self.text = text
        self.imageData = nil
        self.filePaths = nil
        self.date = date
    }

    public init(imageData: Data, id: UUID = UUID(), date: Date = Date()) {
        self.id = id
        self.kind = .image
        self.text = ""
        self.imageData = imageData
        self.filePaths = nil
        self.date = date
    }

    public init(filePaths: [String], id: UUID = UUID(), date: Date = Date()) {
        self.id = id
        self.kind = .file
        self.text = ""
        self.imageData = nil
        self.filePaths = filePaths
        self.date = date
    }

    private enum CodingKeys: String, CodingKey {
        case id, kind, text, imageData, filePaths, date
    }

    // Custom decoding so history saved before image/file support (no
    // `kind`/`imageData`/`filePaths` keys) still loads, as plain text items.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        kind = try container.decodeIfPresent(Kind.self, forKey: .kind) ?? .text
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        filePaths = try container.decodeIfPresent([String].self, forKey: .filePaths)
        date = try container.decode(Date.self, forKey: .date)
    }

    /// Text used to match this item against a search query.
    public var searchableText: String {
        switch kind {
        case .text: return text
        case .image: return ""
        case .file: return fileNames.joined(separator: " ")
        }
    }

    public var preview: String {
        Self.truncated(rawPreview)
    }

    private var rawPreview: String {
        switch kind {
        case .text:
            return text.replacingOccurrences(of: "\n", with: "  ")
        case .image:
            return "Image (\(Self.formatByteCount(imageData?.count ?? 0)))"
        case .file:
            let names = fileNames
            guard names.count > 1 else { return names.first ?? "File" }
            return "\(names.count) files: " + names.joined(separator: ", ")
        }
    }

    private var fileNames: [String] {
        (filePaths ?? []).map { ($0 as NSString).lastPathComponent }
    }

    private static func truncated(_ string: String) -> String {
        let limit = 70
        guard string.count > limit else { return string }
        let idx = string.index(string.startIndex, offsetBy: limit)
        return String(string[..<idx]) + "…"
    }

    /// Extra detail shown in a hover tooltip, since the on-screen preview is
    /// truncated to one line. Locale is pinned to en_US so the wording is
    /// deterministic regardless of the runner's system locale.
    public func hoverInfo(relativeTo referenceDate: Date = Date()) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "en_US")
        let relative = formatter.localizedString(for: date, relativeTo: referenceDate)
        switch kind {
        case .image:
            let size = Self.formatByteCount(imageData?.count ?? 0)
            return "Copied \(relative) • image, \(size)"
        case .text:
            let unit = text.count == 1 ? "character" : "characters"
            return "Copied \(relative) • \(text.count) \(unit)"
        case .file:
            let count = filePaths?.count ?? 0
            let unit = count == 1 ? "file" : "files"
            return "Copied \(relative) • \(count) \(unit)"
        }
    }

    private static func formatByteCount(_ count: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(count))
    }
}
