import SwiftUI

/// A pure SwiftUI paging carousel that properly coordinates with the parent
/// vertical ScrollView. Uses iOS 17+ scrollTargetBehavior(.paging) to avoid
/// UIKit gesture conflicts that caused the home screen to shift horizontally.
struct CarouselPageView: View {
    let pages: [AnyView]
    @Binding var currentPage: Int

    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                page
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}
