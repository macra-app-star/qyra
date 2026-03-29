import SwiftUI

struct TimeFilterPills: View {
    let options: [String]
    @Binding var selection: String

    var body: some View {
        Picker("Time filter", selection: $selection) {
            ForEach(options, id: \.self) { option in
                Text(option).tag(option)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    @Previewable @State var selected = "Week"

    VStack(spacing: DesignTokens.Spacing.lg) {
        TimeFilterPills(
            options: ["Day", "Week", "Month"],
            selection: $selected
        )
        .padding(.horizontal, DesignTokens.Spacing.md)

        Text("Selected: \(selected)")
            .font(DesignTokens.Typography.bodyFont(15))
            .foregroundStyle(DesignTokens.Colors.textSecondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignTokens.Colors.background)
}
