import Testing
@testable import ClipboardHistory

struct AppAppearanceTests {
    @Test func systemMapsToNilColorScheme() {
        #expect(AppAppearance.system.colorScheme == nil)
    }

    @Test func lightMapsToLightColorScheme() {
        #expect(AppAppearance.light.colorScheme == .light)
    }

    @Test func darkMapsToDarkColorScheme() {
        #expect(AppAppearance.dark.colorScheme == .dark)
    }

    @Test func labelsAreHumanReadable() {
        #expect(AppAppearance.system.label == "System")
        #expect(AppAppearance.light.label == "Light")
        #expect(AppAppearance.dark.label == "Dark")
    }

    @Test func allCasesCoversAllThreeModes() {
        #expect(AppAppearance.allCases.count == 3)
        #expect(AppAppearance.allCases.contains(.system))
        #expect(AppAppearance.allCases.contains(.light))
        #expect(AppAppearance.allCases.contains(.dark))
    }

    @Test func idMatchesRawValue() {
        for mode in AppAppearance.allCases {
            #expect(mode.id == mode.rawValue)
        }
    }
}
