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

    // MARK: - init(items:)

    @Test func initWithExistingItemsPreservesOrder() {
        let seed = [ClipboardItem(text: "newest"), ClipboardItem(text: "oldest")]
        let manager = ClipboardHistoryManager(items: seed)
        #expect(manager.items.map(\.text) == ["newest", "oldest"])
    }
}
