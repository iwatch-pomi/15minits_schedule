import SwiftUI

/// 右下の丸い「＋」ボタン
struct FloatingAddButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor, in: Circle())
                .shadow(color: Color.accentColor.opacity(0.35), radius: 8, y: 4)
        }
        .accessibilityLabel("タスクを追加")
        .padding(20)
    }
}
