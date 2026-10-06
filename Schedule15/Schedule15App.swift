import SwiftUI
import SwiftData

@main
struct Schedule15App: App {
    @AppStorage(AppSettings.themeKey) private var themeRaw = ThemeMode.system.rawValue

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(ThemeMode(rawValue: themeRaw)?.colorScheme)
                .environment(\.locale, Locale(identifier: "ja_JP"))
        }
        .modelContainer(for: TaskItem.self)
    }
}
