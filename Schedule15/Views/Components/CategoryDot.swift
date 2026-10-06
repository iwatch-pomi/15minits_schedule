import SwiftUI

struct CategoryDot: View {
    let category: TaskCategory
    var size: CGFloat = 10

    var body: some View {
        Circle()
            .fill(category.color)
            .frame(width: size, height: size)
    }
}
