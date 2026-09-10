import Foundation
import Testing
@testable import ClipboardHistoryCore

struct ClipboardItemTests {
    @Test func previewLeavesShortTextUnchanged() {
        let item = ClipboardItem(text: "hello world")
        #expect(item.preview == "hello world")
    }

    @Test func previewTruncatesLongTextWithEllipsis() {
        let text = String(repeating: "a", count: 100)
        let item = ClipboardItem(text: text)
        #expect(item.preview.count == 71) // 70 chars + ellipsis
        #expect(item.preview.hasSuffix("…"))
        #expect(item.preview.dropLast() == text.prefix(70))
    }

    @Test func previewDoesNotTruncateAtExactLimit() {
        let text = String(repeating: "b", count: 70)
        let item = ClipboardItem(text: text)
        #expect(item.preview == text)
        #expect(!item.preview.hasSuffix("…"))
    }

    @Test func previewCollapsesNewlines() {
        let item = ClipboardItem(text: "line one\nline two")
        #expect(item.preview == "line one  line two")
    }

    @Test func equalityIsByAllFields() {
        let id = UUID()
        let date = Date()
        let a = ClipboardItem(text: "x", id: id, date: date)
        let b = ClipboardItem(text: "x", id: id, date: date)
        let c = ClipboardItem(text: "y", id: id, date: date)
        #expect(a == b)
        #expect(a != c)
    }

    @Test func codableRoundTrip() throws {
        let item = ClipboardItem(text: "round trip me")
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ClipboardItem.self, from: data)
        #expect(item == decoded)
    }
}
