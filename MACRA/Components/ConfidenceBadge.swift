import SwiftUI

struct ConfidenceBadge: View {
    let confidence: Int

    private var color: Color {
        switch confidence {
        case 80...100: return .green.opacity(0.85)
        case 50..<80: return .yellow.opacity(0.85)
        default: return .red.opacity(0.85)
        }
    }

    private var label: String {
        switch confidence {
        case 80...100: return "High"
        case 50..<80: return "Medium"
        default: return "Low"
        }
    }

    var body: some View {
        Text("\(confidence)% \(label)")
            .font(DesignTokens.Typography.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.black)
            .padding(.horizontal, DesignTokens.Layout.tightGap)
            .padding(.vertical, 3)
            .background(color)
            .clipShape(Capsule())
    }
}
