import SwiftUI

/// 15分 = 1行のタイムライン。タスクをブロックとして重ねて表示する。
struct DayTimelineView: View {
    let date: Date
    let tasks: [TaskItem]
    var onTapSlot: (Date) -> Void
    var onTapTask: (TaskItem) -> Void

    @AppStorage(AppSettings.timelineStartHourKey) private var startHourSetting = AppSettings.defaultTimelineStartHour
    @AppStorage(AppSettings.timelineEndHourKey) private var endHourSetting = AppSettings.defaultTimelineEndHour

    private let rowHeight: CGFloat = 30
    private let labelWidth: CGFloat = 46
    private let blockInset: CGFloat = 8

    /// 表示する時間帯（設定範囲外のタスクがあれば広げる）
    private var visibleRange: (start: Int, end: Int) {
        var start = min(startHourSetting, endHourSetting - 1) * 60
        var end = max(endHourSetting, startHourSetting + 1) * 60
        for task in tasks {
            let span = minuteSpan(of: task)
            start = min(start, (span.start / 60) * 60)
            end = max(end, QuarterHour.ceil(span.end))
        }
        return (max(0, start), min(QuarterHour.minutesPerDay, end))
    }

    private var slots: [Int] {
        let range = visibleRange
        return Array(stride(from: range.start, to: range.end, by: QuarterHour.step))
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                grid
                    .overlay(alignment: .topLeading) { blocks }
                    .overlay(alignment: .topLeading) { nowIndicator }
                    .padding(.top, 8)
                    .padding(.bottom, 96)
            }
            .onAppear { scrollToInitialPosition(proxy) }
            .onChange(of: Calendar.app.startOfDay(for: date)) {
                scrollToInitialPosition(proxy)
            }
        }
    }

    // MARK: - Grid

    private var grid: some View {
        VStack(spacing: 0) {
            ForEach(slots, id: \.self) { minutes in
                HStack(alignment: .top, spacing: 0) {
                    Text(QuarterHour.label(minutes))
                        .font(.caption2.weight(minutes % 60 == 0 ? .semibold : .regular))
                        .foregroundStyle(minutes % 60 == 0 ? Color.primary : Color.secondary)
                        .monospacedDigit()
                        .frame(width: labelWidth, alignment: .trailing)
                        .offset(y: -6)
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(minutes % 60 == 0 ? AppColor.gridLine : AppColor.gridLine.opacity(0.4))
                            .frame(height: minutes % 60 == 0 ? 1 : 0.5)
                        Spacer(minLength: 0)
                    }
                    .padding(.leading, 8)
                }
                .frame(height: rowHeight)
                .contentShape(Rectangle())
                .onTapGesture {
                    onTapSlot(QuarterHour.date(on: date, minutes: minutes))
                }
                .id(minutes)
            }
        }
    }

    // MARK: - Blocks

    private var blocks: some View {
        GeometryReader { geometry in
            let originX = labelWidth + blockInset
            let available = geometry.size.width - originX - 12
            let rangeStart = visibleRange.start
            ForEach(Self.layout(tasks, span: minuteSpan)) { placed in
                let span = minuteSpan(of: placed.task)
                let width = available / CGFloat(placed.columnCount)
                let height = max(CGFloat(span.end - span.start) / CGFloat(QuarterHour.step) * rowHeight - 2, rowHeight - 2)
                TaskBlockView(task: placed.task, height: height)
                    .frame(width: max(width - 2, 0), height: height)
                    .offset(x: originX + width * CGFloat(placed.column),
                            y: CGFloat(span.start - rangeStart) / CGFloat(QuarterHour.step) * rowHeight + 1)
                    .onTapGesture { onTapTask(placed.task) }
            }
        }
    }

    @ViewBuilder
    private var nowIndicator: some View {
        if Calendar.app.isDateInToday(date) {
            let now = QuarterHour.minutes(from: .now)
            let range = visibleRange
            if now >= range.start && now < range.end {
                HStack(spacing: 0) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Rectangle()
                        .fill(Color.red)
                        .frame(height: 1.5)
                }
                .padding(.leading, labelWidth + 4)
                .offset(y: CGFloat(now - range.start) / CGFloat(QuarterHour.step) * rowHeight - 4)
                .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Helpers

    /// タスクの、表示日の 0:00 からの開始・終了（分）
    private func minuteSpan(of task: TaskItem) -> (start: Int, end: Int) {
        let dayStart = Calendar.app.startOfDay(for: date)
        let start = Int(task.start.timeIntervalSince(dayStart) / 60)
        let end = Int(task.end.timeIntervalSince(dayStart) / 60)
        let clampedStart = min(max(start, 0), QuarterHour.minutesPerDay - QuarterHour.step)
        let clampedEnd = min(max(end, clampedStart + QuarterHour.step), QuarterHour.minutesPerDay)
        return (clampedStart, clampedEnd)
    }

    private func scrollToInitialPosition(_ proxy: ScrollViewProxy) {
        let range = visibleRange
        let target: Int
        if Calendar.app.isDateInToday(date) {
            target = QuarterHour.minutes(from: .now) / 60 * 60 - 60
        } else if let first = tasks.map({ minuteSpan(of: $0).start }).min() {
            target = first / 60 * 60
        } else {
            target = range.start
        }
        let clamped = min(max(target, range.start), max(range.end - 60, range.start))
        DispatchQueue.main.async {
            proxy.scrollTo(QuarterHour.floor(clamped), anchor: .top)
        }
    }

    // MARK: - Layout

    struct PlacedTask: Identifiable {
        let task: TaskItem
        let column: Int
        var columnCount: Int
        var id: ObjectIdentifier { ObjectIdentifier(task) }
    }

    /// 重なるタスクを横に並べるための列割り当て
    static func layout(_ tasks: [TaskItem], span: (TaskItem) -> (start: Int, end: Int)) -> [PlacedTask] {
        var result: [PlacedTask] = []
        var cluster: [PlacedTask] = []
        var columnEnds: [Int] = []
        var clusterEnd = Int.min

        let sorted = tasks.sorted { span($0).start < span($1).start }
        for task in sorted {
            let s = span(task)
            if !cluster.isEmpty && s.start >= clusterEnd {
                let count = columnEnds.count
                result += cluster.map { PlacedTask(task: $0.task, column: $0.column, columnCount: count) }
                cluster = []
                columnEnds = []
            }
            if let index = columnEnds.firstIndex(where: { $0 <= s.start }) {
                columnEnds[index] = s.end
                cluster.append(PlacedTask(task: task, column: index, columnCount: 1))
            } else {
                columnEnds.append(s.end)
                cluster.append(PlacedTask(task: task, column: columnEnds.count - 1, columnCount: 1))
            }
            clusterEnd = max(clusterEnd, s.end)
        }
        let count = columnEnds.count
        result += cluster.map { PlacedTask(task: $0.task, column: $0.column, columnCount: count) }
        return result
    }
}

/// タイムライン上の 1 タスク
struct TaskBlockView: View {
    let task: TaskItem
    let height: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(task.category.color)
                .frame(width: 4)
            Image(systemName: task.iconName)
                .font(.subheadline)
                .foregroundStyle(task.category.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .strikethrough(task.isCompleted)
                    .lineLimit(height > 60 ? 2 : 1)
                if height > 50 {
                    Text(task.timeRangeText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            Spacer(minLength: 0)
            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(task.category.color)
            }
        }
        .padding(.vertical, height > 40 ? 6 : 3)
        .padding(.trailing, 8)
        .padding(.leading, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(task.category.color.opacity(task.isCompleted ? 0.08 : 0.16))
        )
        .opacity(task.isCompleted ? 0.7 : 1)
        .contentShape(RoundedRectangle(cornerRadius: 8))
    }
}
