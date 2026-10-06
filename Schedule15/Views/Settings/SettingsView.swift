import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppSettings.themeKey) private var themeRaw = ThemeMode.system.rawValue

    @State private var showDeleteAllConfirm = false
    @State private var showSampleAdded = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        PlaceholderSettingView(
                            title: "アカウント",
                            systemImage: "person.crop.circle",
                            message: "現在アカウント機能はありません。\nデータはこの iPhone の中にだけ保存されます。"
                        )
                    } label: {
                        Label("アカウント", systemImage: "person.crop.circle")
                    }

                    NavigationLink {
                        NotificationSettingView()
                    } label: {
                        Label("通知", systemImage: "bell")
                    }

                    NavigationLink {
                        PlaceholderSettingView(
                            title: "カレンダー連携",
                            systemImage: "calendar.badge.plus",
                            message: "iPhone のカレンダーとの連携は今後のアップデートで対応予定です。"
                        )
                    } label: {
                        Label("カレンダー連携", systemImage: "calendar")
                    }
                }

                Section {
                    NavigationLink {
                        DisplaySettingView()
                    } label: {
                        Label("表示設定", systemImage: "rectangle.on.rectangle")
                    }

                    NavigationLink {
                        TaskDefaultsSettingView()
                    } label: {
                        Label("タスクの初期設定", systemImage: "checkmark.square")
                    }
                }

                Section("テーマ") {
                    Picker(selection: $themeRaw) {
                        ForEach(ThemeMode.allCases) { mode in
                            Text(mode.label).tag(mode.rawValue)
                        }
                    } label: {
                        Label("テーマ", systemImage: "circle.lefthalf.filled")
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("データ") {
                    Button {
                        SampleData.insertToday(into: modelContext)
                        showSampleAdded = true
                    } label: {
                        Label("今日のサンプルタスクを追加", systemImage: "wand.and.stars")
                    }

                    Button(role: .destructive) {
                        showDeleteAllConfirm = true
                    } label: {
                        Label("すべてのタスクを削除", systemImage: "trash")
                    }
                }

                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("アプリ情報", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("すべてのタスクを削除しますか？", isPresented: $showDeleteAllConfirm, titleVisibility: .visible) {
                Button("削除", role: .destructive) {
                    SampleData.deleteAll(in: modelContext)
                }
            } message: {
                Text("この操作は取り消せません。")
            }
            .alert("サンプルタスクを追加しました", isPresented: $showSampleAdded) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("ホーム画面で今日のスケジュールを確認できます。")
            }
        }
    }
}

// MARK: - 各設定画面

private struct DisplaySettingView: View {
    @AppStorage(AppSettings.timelineStartHourKey) private var startHour = AppSettings.defaultTimelineStartHour
    @AppStorage(AppSettings.timelineEndHourKey) private var endHour = AppSettings.defaultTimelineEndHour

    var body: some View {
        Form {
            Section {
                Picker("開始時刻", selection: $startHour) {
                    ForEach(0..<23, id: \.self) { hour in
                        Text("\(hour):00").tag(hour)
                    }
                }
                Picker("終了時刻", selection: $endHour) {
                    ForEach(1...24, id: \.self) { hour in
                        Text("\(hour):00").tag(hour)
                    }
                }
            } header: {
                Text("ホームのタイムライン")
            } footer: {
                Text("この範囲外のタスクがある日は、自動的に表示範囲を広げます。")
            }
        }
        .navigationTitle("表示設定")
        .onChange(of: startHour) {
            if endHour <= startHour { endHour = startHour + 1 }
        }
        .onChange(of: endHour) {
            if startHour >= endHour { startHour = endHour - 1 }
        }
    }
}

private struct TaskDefaultsSettingView: View {
    @AppStorage(AppSettings.defaultDurationKey) private var duration = AppSettings.defaultDuration
    @AppStorage(AppSettings.defaultCategoryKey) private var categoryRaw = TaskCategory.study.rawValue

    var body: some View {
        Form {
            Section {
                Picker("所要時間", selection: $duration) {
                    ForEach(AppSettings.durationChoices, id: \.self) { minutes in
                        Text(QuarterHour.durationText(minutes)).tag(minutes)
                    }
                }
                Picker("カテゴリ", selection: $categoryRaw) {
                    ForEach(TaskCategory.allCases) { category in
                        Text(category.label).tag(category.rawValue)
                    }
                }
            } footer: {
                Text("新しいタスクを作るときの初期値です。")
            }
        }
        .navigationTitle("タスクの初期設定")
    }
}

private struct NotificationSettingView: View {
    @AppStorage(AppSettings.notificationsEnabledKey) private var enabled = false

    var body: some View {
        Form {
            Section {
                Toggle("タスク開始前に通知", isOn: $enabled)
                    .disabled(true)
            } footer: {
                Text("通知機能は今後のアップデートで対応予定です。")
            }
        }
        .navigationTitle("通知")
    }
}

private struct PlaceholderSettingView: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        }
        .navigationTitle(title)
    }
}

private struct AboutView: View {
    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "-"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        return "\(short) (\(build))"
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 88, height: 88)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    Text("スケジュール15")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                    Text("15分で整う、わたしの毎日")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }

            Section {
                LabeledContent("バージョン", value: version)
            }
        }
        .navigationTitle("アプリ情報")
    }
}
