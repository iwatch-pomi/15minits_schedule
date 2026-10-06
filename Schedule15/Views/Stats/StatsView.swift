import SwiftUI
import SwiftData
import Charts

/// 時間の使い方の見える化（1日単位）
struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TaskItem.start) private var tasks: [TaskItem]
    @State private var date: Date

    private let calendar = Calendar.app

    init(initialDate: Date) {
        _date = State(initialValue: initialDate)
    }

    struct HourEntry: Identifiable {
        let hour: Int
        let category: TaskCategory
        let minutes: Int
        var id: String { "\(hour)-\(category.rawValue)" }
    }

    private var dayTasks: [TaskItem] {
        tasks.filter { calendar.isDate($0.start, inSameDayAs: date) }
    }

    private var totalMinutes: Int {
        dayTasks.reduce(0) { $0 + $1.durationMinutes }
    }

    private var completedMinutes: Int {
        dayTasks.filter(\.isCompleted).reduce(0) { $0 + $1.durationMinutes }
    }

    private var completionRatio: Double {
        totalMinutes == 0 ? 0 : Double(completedMinutes) / Double(totalMinutes)
    }

    struct CategoryTotal: Identifiable {
        let category: TaskCategory
        let minutes: Int
        var id: String { category.rawValue }
    }

    private var minutesByCategory: [CategoryTotal] {
        TaskCategory.allCases.map { category in
            let minutes = dayTasks.filter { $0.category == category }.reduce(0) { $0 + $1.durationMinutes }
            return CategoryTotal(category: category, minutes: minutes)
        }
    }

    /// グラフの縦軸の上限（重なったタスクで 60 分を超える場合に広げる）
    private var chartMaxMinutes: Int {
        var perHour: [Int: Int] = [:]
        for entry in hourlyEntries {
            perHour[entry.hour, default: 0] += entry.minutes
        }
        return max(60, perHour.values.max() ?? 0)
    }

    /// 1時間ごと・カテゴリごとの分数
    private var hourlyEntries: [HourEntry] {
        let dayStart = calendar.startOfDay(for: date)
        var buckets: [String: HourEntry] = [:]
        for task in dayTasks {
            let start = max(0, Int(task.start.timeIntervalSince(dayStart) / 60))
            let end = min(QuarterHour.minutesPerDay, Int(task.end.timeIntervalSince(dayStart) / 60))
            guard end > start else { continue }
            for hour in (start / 60)...((end - 1) / 60) {
                let overlap = min(end, (hour + 1) * 60) - max(start, hour * 60)
                guard overlap > 0 else { continue }
                let key = "\(hour)-\(task.category.rawValue)"
                let current = buckets[key]?.minutes ?? 0
                buckets[key] = HourEntry(hour: hour, category: task.category, minutes: current + overlap)
            }
        }
        return buckets.values.sorted { ($0.hour, $0.category.rawValue) < ($1.hour, $1.category.rawValue) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard
                    categoryCard
                    distributionCard
                }
                .padding(16)
            }
            .background(AppColor.background)
            .navigationTitle("時間の使い方")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .safeAreaInset(edge: .top) { dateSwitcher }
        }
    }

    // MARK: - Parts

    private var dateSwitcher: some View {
        HStack {
            Button { shiftDay(-1) } label: {
                Image(systemName: "chevron.left").frame(width: 44, height: 36)
            }
            Spacer()
            Text(DateText.day(date))
                .font(.headline)
            Spacer()
            Button { shiftDay(1) } label: {
                Image(systemName: "chevron.right").frame(width: 44, height: 36)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.bar)
    }

    private var summaryCard: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 8) {
                Text("総作業時間")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                durationLabel(totalMinutes)
                Text("完了 " + QuarterHour.durationText(completedMinutes) + "・\(dayTasks.count)件")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.15), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: completionRatio)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(Int((completionRatio * 100).rounded()))%")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                    Text("完了率")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 92, height: 92)
            .animation(.easeInOut, value: completionRatio)
        }
        .card()
    }

    private func durationLabel(_ minutes: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            if minutes >= 60 {
                Text("\(minutes / 60)").font(.system(size: 36, weight: .bold, design: .rounded))
                Text("時間").font(.subheadline.weight(.semibold))
            }
            if minutes % 60 != 0 || minutes == 0 {
                Text("\(minutes % 60)").font(.system(size: 36, weight: .bold, design: .rounded))
                Text("分").font(.subheadline.weight(.semibold))
            }
        }
        .foregroundStyle(Color.accentColor)
        .monospacedDigit()
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カテゴリ別の時間")
                .font(.headline)
            ForEach(minutesByCategory) { item in
                VStack(spacing: 6) {
                    HStack {
                        CategoryDot(category: item.category)
                        Text(item.category.label)
                            .font(.subheadline)
                        Spacer()
                        Text(QuarterHour.durationText(item.minutes))
                            .font(.subheadline)
                            .monospacedDigit()
                        Text("\(percent(item.minutes))%")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .frame(width: 44, alignment: .trailing)
                    }
                    GeometryReader { geometry in
                        Capsule()
                            .fill(item.category.color.opacity(0.15))
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(item.category.color)
                                    .frame(width: geometry.size.width * CGFloat(percent(item.minutes)) / 100)
                            }
                    }
                    .frame(height: 6)
                }
            }
        }
        .card()
    }

    private var distributionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("時間の分布")
                .font(.headline)
            if hourlyEntries.isEmpty {
                Text("この日の予定はまだありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart(hourlyEntries) { entry in
                    BarMark(
                        x: .value("時刻", entry.hour),
                        y: .value("分", entry.minutes)
                    )
                    .foregroundStyle(by: .value("カテゴリ", entry.category.label))
                }
                .chartForegroundStyleScale(
                    domain: TaskCategory.allCases.map(\.label),
                    range: TaskCategory.allCases.map(\.color)
                )
                .chartXScale(domain: 0...24)
                .chartXAxis {
                    AxisMarks(values: [0, 3, 6, 9, 12, 15, 18, 21, 24]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let hour = value.as(Int.self) {
                                Text("\(hour):00")
                            }
                        }
                    }
                }
                .chartYScale(domain: 0...chartMaxMinutes)
                .chartYAxis {
                    AxisMarks(values: [0, 30, 60]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let minutes = value.as(Int.self) {
                                Text("\(minutes)分")
                            }
                        }
                    }
                }
                .chartLegend(position: .bottom, spacing: 12)
                .frame(height: 200)
            }
        }
        .card()
    }

    // MARK: - Helpers

    private func percent(_ minutes: Int) -> Int {
        guard totalMinutes > 0 else { return 0 }
        return Int((Double(minutes) / Double(totalMinutes) * 100).rounded())
    }

    private func shiftDay(_ amount: Int) {
        if let newDate = calendar.date(byAdding: .day, value: amount, to: date) {
            withAnimation { date = newDate }
        }
    }
}
