import Foundation
import SwiftData

/// 動作確認用のサンプルタスク（設定画面から追加）
enum SampleData {
    static func insertToday(into context: ModelContext) {
        let today = Date.now
        let items: [(String, Int, Int, TaskCategory, String)] = [
            ("朝食・準備", 8 * 60, 8 * 60 + 30, .other, "cup.and.saucer"),
            ("研究室へ移動", 8 * 60 + 30, 9 * 60, .move, "bicycle"),
            ("実験準備", 9 * 60, 9 * 60 + 45, .research, "flask"),
            ("実験", 9 * 60 + 45, 11 * 60, .research, "flask"),
            ("データ整理", 11 * 60, 11 * 60 + 45, .study, "laptopcomputer"),
            ("ミーティング", 11 * 60 + 45, 12 * 60 + 30, .meeting, "person.2"),
            ("レポート作成", 14 * 60, 15 * 60 + 30, .study, "doc.text"),
            ("解析", 16 * 60, 17 * 60, .research, "chart.bar"),
            ("買い物", 18 * 60, 18 * 60 + 30, .other, "cart")
        ]
        for (title, start, end, category, icon) in items {
            context.insert(TaskItem(
                title: title,
                start: QuarterHour.date(on: today, minutes: start),
                end: QuarterHour.date(on: today, minutes: end),
                category: category,
                iconName: icon
            ))
        }
        try? context.save()
    }

    static func deleteAll(in context: ModelContext) {
        let all = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        for task in all {
            context.delete(task)
        }
        try? context.save()
    }
}
