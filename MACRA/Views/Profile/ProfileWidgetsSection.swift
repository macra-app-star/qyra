import SwiftUI

struct ProfileWidgetsSection: View {
    @State private var showWidgetAlert = false

    private let widgets: [(name: String, icon: String)] = [
        ("Calories", "scalemass"),
        ("Macros", "chart.pie"),
        ("Steps", "figure.walk"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Widgets")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textCase(nil)
                .padding(.horizontal, DesignTokens.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(widgets, id: \.name) { widget in
                        Button {
                            showWidgetAlert = true
                        } label: {
                            VStack(spacing: DesignTokens.Spacing.sm) {
                                Image(systemName: widget.icon)
                                    .font(.title2)
                                    .foregroundStyle(DesignTokens.Colors.accent)

                                Text(widget.name)
                                    .font(.caption)
                                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                            }
                            .frame(width: 140, height: 100)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
        .alert("Widgets", isPresented: $showWidgetAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Add Qyra widgets to your Home Screen from the widget gallery.")
        }
    }
}

#Preview {
    NavigationStack {
        List {
            Section {
                ProfileWidgetsSection()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
    }
}
