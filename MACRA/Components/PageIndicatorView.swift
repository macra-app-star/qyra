import SwiftUI

struct PageIndicatorView: View {
    let pageCount: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: DesignTokens.Layout.tightGap) {
            ForEach(0..<pageCount, id: \.self) { index in
                Circle()
                    .fill(
                        index == currentPage
                        ? DesignTokens.Colors.textPrimary
                        : DesignTokens.Colors.textTertiary
                    )
                    .frame(
                        width: index == currentPage ? 8 : 6,
                        height: index == currentPage ? 8 : 6
                    )
                    .animation(DesignTokens.Anim.quick, value: currentPage)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(currentPage + 1) of \(pageCount)")
    }
}

#Preview {
    @Previewable @State var page = 0

    VStack(spacing: DesignTokens.Spacing.lg) {
        PageIndicatorView(pageCount: 4, currentPage: page)

        Button("Next") {
            page = (page + 1) % 4
        }
        .font(DesignTokens.Typography.medium(15))
    }
    .padding()
    .background(DesignTokens.Colors.background)
}
