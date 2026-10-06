import SwiftUI

struct RootTabView: View {
    @State private var selection: AppTab = .home
    @State private var selectedDate: Date = .now

    enum AppTab: Hashable {
        case home, tasks, calendar, settings
    }

    var body: some View {
        TabView(selection: $selection) {
            HomeView(selectedDate: $selectedDate)
                .tabItem { Label("ホーム", systemImage: "calendar.day.timeline.left") }
                .tag(AppTab.home)

            TaskListView()
                .tabItem { Label("タスク", systemImage: "checkmark.circle") }
                .tag(AppTab.tasks)

            CalendarView(selectedDate: $selectedDate)
                .tabItem { Label("カレンダー", systemImage: "calendar") }
                .tag(AppTab.calendar)

            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
    }
}
