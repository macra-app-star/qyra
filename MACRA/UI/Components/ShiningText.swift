import SwiftUI

/// A text view with a shimmering gradient animation — used as the AI "thinking" indicator.
/// SwiftUI port of the shadcn shining-text React component.
struct ShiningText: View {
    let text: String
    var font: Font = .system(size: 15, weight: .medium)

    @State private var phase: CGFloat = 0

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(.clear)
            .overlay {
                GeometryReader { geo in
                    let w = geo.size.width
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(UIColor.systemGray), location: 0),
                            Gradient.Stop(color: Color(UIColor.systemGray), location: 0.35),
                            Gradient.Stop(color: Color(UIColor.systemGray3), location: 0.5),
                            Gradient.Stop(color: Color(UIColor.systemGray), location: 0.65),
                            Gradient.Stop(color: Color(UIColor.systemGray), location: 1),
                        ],
                        startPoint: UnitPoint(x: phase - 0.5, y: 0.5),
                        endPoint: UnitPoint(x: phase + 0.5, y: 0.5)
                    )
                    .frame(width: w, height: geo.size.height)
                }
                .mask {
                    Text(text)
                        .font(font)
                }
            }
            .onAppear {
                withAnimation(
                    .linear(duration: 2.0)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 2.0
                }
            }
    }
}

#Preview {
    ShiningText(text: "Qyra is thinking...")
        .padding()
}
