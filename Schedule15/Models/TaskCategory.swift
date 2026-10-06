import SwiftUI

/// タスクのカテゴリ。色とデフォルトアイコンを持つ。
enum TaskCategory: String, CaseIterable, Identifiable, Codable {
    case study
    case research
    case meeting
    case move
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .study: return "勉強・作業"
        case .research: return "実験・研究"
        case .meeting: return "ミーティング"
        case .move: return "移動"
        case .other: return "その他"
        }
    }

    var color: Color {
        switch self {
        case .study: return Color(red: 0.23, green: 0.55, blue: 0.93)
        case .research: return Color(red: 0.33, green: 0.76, blue: 0.91)
        case .meeting: return Color(red: 0.96, green: 0.58, blue: 0.27)
        case .move: return Color(red: 0.56, green: 0.50, blue: 0.86)
        case .other: return Color(red: 0.55, green: 0.58, blue: 0.63)
        }
    }

    var defaultIcon: String {
        switch self {
        case .study: return "laptopcomputer"
        case .research: return "flask"
        case .meeting: return "person.2"
        case .move: return "bicycle"
        case .other: return "square.grid.2x2"
        }
    }
}

/// タスク作成画面で選べるアイコン（SF Symbols）
enum TaskIcons {
    static let all: [String] = [
        "laptopcomputer", "pencil", "book", "doc.text", "chart.bar", "flask",
        "person.2", "phone", "bicycle", "tram", "figure.walk", "car",
        "fork.knife", "cup.and.saucer", "cart", "house", "dumbbell", "bed.double",
        "music.note", "gamecontroller", "heart", "star", "sparkles", "square.grid.2x2"
    ]
}
