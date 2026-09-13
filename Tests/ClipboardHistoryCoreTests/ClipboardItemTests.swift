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

    @Test func hoverInfoIncludesRelativeTimeAndCharacterCount() {
        let reference = Date(timeIntervalSince1970: 1_000_000)
        let item = ClipboardItem(text: "hello", date: reference.addingTimeInterval(-65))
        let info = item.hoverInfo(relativeTo: reference)
        #expect(info == "Copied 1 minute ago • 5 characters")
    }

    @Test func hoverInfoUsesSingularCharacterForLengthOne() {
        let reference = Date(timeIntervalSince1970: 1_000_000)
        let item = ClipboardItem(text: "x", date: reference)
        let info = item.hoverInfo(relativeTo: reference)
        #expect(info.hasSuffix("1 character"))
    }

    @Test func hoverInfoUsesPluralCharactersForLongerText() {
        let reference = Date(timeIntervalSince1970: 1_000_000)
        let item = ClipboardItem(text: "xy", date: reference)
        let info = item.hoverInfo(relativeTo: reference)
        #expect(info.hasSuffix("2 characters"))
    }

    @Test func codableRoundTrip() throws {
        let item = ClipboardItem(text: "round trip me")
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ClipboardItem.self, from: data)
        #expect(item == decoded)
    }

    // MARK: - Image items

    @Test func imageItemHasImageKindAndEmptyText() {
        let item = ClipboardItem(imageData: Data([0x01, 0x02, 0x03]))
        #expect(item.kind == .image)
        #expect(item.text == "")
    }

    @Test func imagePreviewShowsByteSize() {
        let item = ClipboardItem(imageData: Data(repeating: 0, count: 1024))
        #expect(item.preview == "Image (1 KB)")
    }

    @Test func imageHoverInfoIncludesRelativeTimeAndSize() {
        let reference = Date(timeIntervalSince1970: 1_000_000)
        let item = ClipboardItem(imageData: Data(repeating: 0, count: 1024), date: reference.addingTimeInterval(-65))
        let info = item.hoverInfo(relativeTo: reference)
        #expect(info == "Copied 1 minute ago • image, 1 KB")
    }

    @Test func imageCodableRoundTrip() throws {
        let item = ClipboardItem(imageData: Data([0xFF, 0xD8, 0xFF]))
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ClipboardItem.self, from: data)
        #expect(item == decoded)
        #expect(decoded.kind == .image)
    }

    @Test func decodingLegacyTextOnlyJSONDefaultsToTextKind() throws {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1_000_000)
        let legacyJSON = """
        {"id":"\(id.uuidString)","text":"legacy item","date":\(date.timeIntervalSinceReferenceDate)}
        """
        let decoded = try JSONDecoder().decode(ClipboardItem.self, from: Data(legacyJSON.utf8))
        #expect(decoded.kind == .text)
        #expect(decoded.text == "legacy item")
        #expect(decoded.imageData == nil)
    }

    // MARK: - File items

    @Test func fileItemHasFileKindAndEmptyText() {
        let item = ClipboardItem(filePaths: ["/tmp/report.pdf"])
        #expect(item.kind == .file)
        #expect(item.text == "")
    }

    @Test func filePreviewShowsSingleFileName() {
        let item = ClipboardItem(filePaths: ["/Users/me/Documents/report.pdf"])
        #expect(item.preview == "report.pdf")
    }

    @Test func filePreviewSummarizesMultipleFiles() {
        let item = ClipboardItem(filePaths: ["/tmp/a.txt", "/tmp/b.txt"])
        #expect(item.preview == "2 files: a.txt, b.txt")
    }

    @Test func fileHoverInfoUsesSingularForOneFile() {
        let reference = Date(timeIntervalSince1970: 1_000_000)
        let item = ClipboardItem(filePaths: ["/tmp/a.txt"], date: reference)
        #expect(item.hoverInfo(relativeTo: reference).hasSuffix("1 file"))
    }

    @Test func fileHoverInfoUsesPluralForMultipleFiles() {
        let reference = Date(timeIntervalSince1970: 1_000_000)
        let item = ClipboardItem(filePaths: ["/tmp/a.txt", "/tmp/b.txt"], date: reference)
        #expect(item.hoverInfo(relativeTo: reference).hasSuffix("2 files"))
    }

    @Test func fileSearchableTextMatchesFileName() {
        let item = ClipboardItem(filePaths: ["/Users/me/Documents/quarterly-report.pdf"])
        #expect(item.searchableText.localizedCaseInsensitiveContains("quarterly"))
    }

    @Test func fileCodableRoundTrip() throws {
        let item = ClipboardItem(filePaths: ["/tmp/a.txt", "/tmp/b.txt"])
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ClipboardItem.self, from: data)
        #expect(item == decoded)
        #expect(decoded.kind == .file)
    }

    @Test func filePreviewTruncatesLongFileListWithEllipsis() {
        let longName1 = String(repeating: "a", count: 30) + ".txt"
        let longName2 = String(repeating: "b", count: 30) + ".txt"
        let item = ClipboardItem(filePaths: ["/tmp/\(longName1)", "/tmp/\(longName2)"])
        let expectedRaw = "2 files: \(longName1), \(longName2)"
        #expect(item.preview.count == 71) // 70 chars + ellipsis
        #expect(item.preview.hasSuffix("…"))
        #expect(item.preview.dropLast() == expectedRaw.prefix(70))
    }

    @Test func fileKindWithMissingFilePathsFallsBackGracefully() throws {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1_000_000)
        let json = """
        {"id":"\(id.uuidString)","kind":"file","date":\(date.timeIntervalSinceReferenceDate)}
        """
        let decoded = try JSONDecoder().decode(ClipboardItem.self, from: Data(json.utf8))
        #expect(decoded.kind == .file)
        #expect(decoded.filePaths == nil)
        #expect(decoded.preview == "File")
        #expect(decoded.searchableText == "")
        #expect(decoded.hoverInfo(relativeTo: date).hasSuffix("0 files"))
    }
}
