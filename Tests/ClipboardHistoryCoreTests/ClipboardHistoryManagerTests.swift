import Foundation
import Testing
@testable import ClipboardHistoryCore

struct ClipboardHistoryManagerTests {

    // MARK: - add()

    @Test func addInsertsAtFront() {
        var manager = ClipboardHistoryManager()
        manager.add("first")
        manager.add("second")
        #expect(manager.items.map(\.text) == ["second", "first"])
    }

    @Test func addReturnsTrueWhenItemAdded() {
        var manager = ClipboardHistoryManager()
        let added = manager.add("hello")
        #expect(added)
    }

    @Test func addIgnoresBlankText() {
        var manager = ClipboardHistoryManager()
        let addedEmpty = manager.add("")
        let addedWhitespace = manager.add("   \n  ")
        #expect(!addedEmpty)
        #expect(!addedWhitespace)
        #expect(manager.items.isEmpty)
    }

    @Test func addIgnoresImmediateRepeatOfMostRecent() {
        var manager = ClipboardHistoryManager()
        manager.add("same")
        let addedAgain = manager.add("same")
        #expect(!addedAgain)
        #expect(manager.items.count == 1)
    }

    @Test func addAllowsRepeatIfNotMostRecent() {
        var manager = ClipboardHistoryManager()
        manager.add("a")
        manager.add("b")
        let addedAgain = manager.add("a")
        #expect(addedAgain)
        #expect(manager.items.map(\.text) == ["a", "b", "a"])
    }

    @Test func addEvictsOldestWhenOverCapacity() {
        var manager = ClipboardHistoryManager(maxItems: 3)
        manager.add("1")
        manager.add("2")
        manager.add("3")
        manager.add("4")
        #expect(manager.items.map(\.text) == ["4", "3", "2"])
        #expect(manager.items.count == 3)
    }

    @Test func addRejectsTextLongerThanMaxItemLength() {
        var manager = ClipboardHistoryManager(maxItemLength: 10)
        let tooLong = String(repeating: "x", count: 11)
        let added = manager.add(tooLong)
        #expect(!added)
        #expect(manager.items.isEmpty)
    }

    @Test func addAcceptsTextAtExactlyMaxItemLength() {
        var manager = ClipboardHistoryManager(maxItemLength: 10)
        let exact = String(repeating: "x", count: 10)
        let added = manager.add(exact)
        #expect(added)
        #expect(manager.items.count == 1)
    }

    // MARK: - add(imageData:)

    @Test func addImageInsertsAtFront() {
        var manager = ClipboardHistoryManager()
        manager.add("text")
        let added = manager.add(imageData: Data([0x01, 0x02]))
        #expect(added)
        #expect(manager.items.first?.kind == .image)
        #expect(manager.items.map(\.text) == ["", "text"])
    }

    @Test func addImageIgnoresEmptyData() {
        var manager = ClipboardHistoryManager()
        let added = manager.add(imageData: Data())
        #expect(!added)
        #expect(manager.items.isEmpty)
    }

    @Test func addImageIgnoresImmediateRepeatOfMostRecent() {
        var manager = ClipboardHistoryManager()
        let data = Data([0x01, 0x02, 0x03])
        manager.add(imageData: data)
        let addedAgain = manager.add(imageData: data)
        #expect(!addedAgain)
        #expect(manager.items.count == 1)
    }

    @Test func addImageRejectsDataLargerThanMaxItemLength() {
        var manager = ClipboardHistoryManager(maxItemLength: 10)
        let tooLarge = Data(repeating: 0, count: 11)
        let added = manager.add(imageData: tooLarge)
        #expect(!added)
        #expect(manager.items.isEmpty)
    }

    @Test func addImageEvictsOldestWhenOverCapacity() {
        var manager = ClipboardHistoryManager(maxItems: 1)
        manager.add("text")
        let added = manager.add(imageData: Data([0x01]))
        #expect(added)
        #expect(manager.items.count == 1)
        #expect(manager.items.first?.kind == .image)
    }

    // MARK: - add(filePaths:)

    @Test func addFilePathsInsertsAtFront() {
        var manager = ClipboardHistoryManager()
        manager.add("text")
        let added = manager.add(filePaths: ["/tmp/a.txt"])
        #expect(added)
        #expect(manager.items.first?.kind == .file)
        #expect(manager.items.map(\.text) == ["", "text"])
    }

    @Test func addFilePathsIgnoresEmptyArray() {
        var manager = ClipboardHistoryManager()
        let added = manager.add(filePaths: [])
        #expect(!added)
        #expect(manager.items.isEmpty)
    }

    @Test func addFilePathsIgnoresImmediateRepeatOfMostRecent() {
        var manager = ClipboardHistoryManager()
        manager.add(filePaths: ["/tmp/a.txt", "/tmp/b.txt"])
        let addedAgain = manager.add(filePaths: ["/tmp/a.txt", "/tmp/b.txt"])
        #expect(!addedAgain)
        #expect(manager.items.count == 1)
    }

    @Test func addFilePathsAllowsDifferentSelectionEvenIfOverlapping() {
        var manager = ClipboardHistoryManager()
        manager.add(filePaths: ["/tmp/a.txt"])
        let addedAgain = manager.add(filePaths: ["/tmp/a.txt", "/tmp/b.txt"])
        #expect(addedAgain)
        #expect(manager.items.count == 2)
    }

    @Test func addFilePathsEvictsOldestWhenOverCapacity() {
        var manager = ClipboardHistoryManager(maxItems: 1)
        manager.add("text")
        let added = manager.add(filePaths: ["/tmp/a.txt"])
        #expect(added)
        #expect(manager.items.count == 1)
        #expect(manager.items.first?.kind == .file)
    }

    @Test func addFilePathsIsNotSubjectToMaxItemLength() {
        var manager = ClipboardHistoryManager(maxItemLength: 1)
        let added = manager.add(filePaths: ["/tmp/a-very-long-file-name.txt"])
        #expect(added)
        #expect(manager.items.count == 1)
    }

    // MARK: - enforceCapacity() / enforceMaxItemLength()

    @Test func enforceCapacityDropsOldestOverCap() {
        var manager = ClipboardHistoryManager(maxItems: 100)
        manager.add("1")
        manager.add("2")
        manager.add("3")
        manager.maxItems = 2
        manager.enforceCapacity()
        #expect(manager.items.map(\.text) == ["3", "2"])
    }

    @Test func enforceCapacityIsNoOpWhenUnderCap() {
        var manager = ClipboardHistoryManager(maxItems: 100)
        manager.add("1")
        manager.enforceCapacity()
        #expect(manager.items.map(\.text) == ["1"])
    }

    @Test func enforceMaxItemLengthDropsOversizedItems() {
        var manager = ClipboardHistoryManager()
        manager.add("short")
        manager.add(String(repeating: "x", count: 50))
        manager.maxItemLength = 10
        manager.enforceMaxItemLength()
        #expect(manager.items.map(\.text) == ["short"])
    }

    @Test func enforceMaxItemLengthDropsOversizedImages() {
        var manager = ClipboardHistoryManager()
        manager.add(imageData: Data(repeating: 0, count: 5))
        manager.add(imageData: Data(repeating: 0, count: 50))
        manager.maxItemLength = 10
        manager.enforceMaxItemLength()
        #expect(manager.items.count == 1)
        #expect(manager.items.first?.imageData?.count == 5)
    }

    // MARK: - delete()

    @Test func deleteRemovesMatchingItem() {
        var manager = ClipboardHistoryManager()
        manager.add("keep")
        manager.add("remove")
        let target = manager.items.first { $0.text == "remove" }!
        manager.delete(id: target.id)
        #expect(manager.items.map(\.text) == ["keep"])
    }

    @Test func deleteWithUnknownIdIsNoOp() {
        var manager = ClipboardHistoryManager()
        manager.add("keep")
        manager.delete(id: UUID())
        #expect(manager.items.count == 1)
    }

    // MARK: - clear()

    @Test func clearEmptiesHistory() {
        var manager = ClipboardHistoryManager()
        manager.add("a")
        manager.add("b")
        manager.clear()
        #expect(manager.items.isEmpty)
    }

    // MARK: - filtered(query:)

    @Test func filteredWithEmptyQueryReturnsAllItems() {
        var manager = ClipboardHistoryManager()
        manager.add("alpha")
        manager.add("beta")
        #expect(manager.filtered(query: "").count == 2)
    }

    @Test func filteredMatchesCaseInsensitiveSubstring() {
        var manager = ClipboardHistoryManager()
        manager.add("Hello World")
        manager.add("Goodbye")
        #expect(manager.filtered(query: "world").map(\.text) == ["Hello World"])
    }

    @Test func filteredReturnsEmptyWhenNoMatches() {
        var manager = ClipboardHistoryManager()
        manager.add("Hello World")
        #expect(manager.filtered(query: "xyz").isEmpty)
    }

    @Test func filteredMatchesFileNameOfFileItem() {
        var manager = ClipboardHistoryManager()
        manager.add(filePaths: ["/Users/me/Documents/quarterly-report.pdf"])
        manager.add("unrelated text")
        #expect(manager.filtered(query: "quarterly").count == 1)
        #expect(manager.filtered(query: "quarterly").first?.kind == .file)
    }

    @Test func filteredExcludesImageItemsFromTextQuery() {
        var manager = ClipboardHistoryManager()
        manager.add(imageData: Data([0x01]))
        manager.add("hello")
        #expect(manager.filtered(query: "hello").map(\.kind) == [.text])
    }

    // MARK: - init(items:)

    @Test func initWithExistingItemsPreservesOrder() {
        let seed = [ClipboardItem(text: "newest"), ClipboardItem(text: "oldest")]
        let manager = ClipboardHistoryManager(items: seed)
        #expect(manager.items.map(\.text) == ["newest", "oldest"])
    }
}
