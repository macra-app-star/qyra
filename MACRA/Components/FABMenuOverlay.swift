import SwiftUI

struct FABMenuOverlay: View {
    let onScanFood: () -> Void
    let onQuickAdd: () -> Void
    let onLogExercise: () -> Void
    let onSavedFoods: () -> Void
    let onExerciseLibrary: () -> Void
    let onWorkoutPlanner: () -> Void
    let onVersus: (() -> Void)?
    let onLogMeal: () -> Void
    let onDismiss: () -> Void

    @State private var isShowing = false

    private struct MenuItem {
        let title: String
        let icon: String
        let action: () -> Void
    }

    private var items: [MenuItem] {
        var grid = [
            MenuItem(title: "Quick Add", icon: "bolt.fill", action: onQuickAdd),
            MenuItem(title: "Log Exercise", icon: "figure.run", action: onLogExercise),
            MenuItem(title: "My Food", icon: "heart.text.clipboard", action: onSavedFoods),
            MenuItem(title: "Exercise Library", icon: "dumbbell.fill", action: onExerciseLibrary),
            MenuItem(title: "Workout Plan", icon: "list.clipboard.fill", action: onWorkoutPlanner),
        ]
        if let onVersus {
            grid.append(MenuItem(title: "VERSUS", icon: "bolt", action: onVersus))
        }
        return grid
    }

    var body: some View {
        ZStack {
            // Dimmed background
            DesignTokens.Colors.overlayDim
                .ignoresSafeArea()
                .onTapGesture {
                    dismissOverlay()
                }
                .accessibilityLabel("Close menu")
                .accessibilityAddTraits(.isButton)

            VStack(spacing: DesignTokens.Spacing.md) {
                // Scan Food primary CTA — top position
                Button {
                    onScanFood()
                } label: {
                    Label("Scan Food", systemImage: "camera.fill")
                        .font(DesignTokens.Typography.semibold(17))
                        .foregroundStyle(DesignTokens.Colors.buttonPrimaryText)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                        .background(DesignTokens.Colors.buttonPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Scan food with camera")
                .accessibilityHint("Opens camera to photograph and analyze your meal")
                .frame(width: DesignTokens.FAB.menuItemSize * 3 + DesignTokens.Spacing.sm * 2)
                .opacity(isShowing ? 1.0 : 0.0)
                .animation(
                    DesignTokens.Anim.spring,
                    value: isShowing
                )

                // 2x3 grid of secondary actions
                LazyVGrid(
                    columns: [
                        GridItem(.fixed(DesignTokens.FAB.menuItemSize), spacing: DesignTokens.Spacing.sm),
                        GridItem(.fixed(DesignTokens.FAB.menuItemSize), spacing: DesignTokens.Spacing.sm),
                        GridItem(.fixed(DesignTokens.FAB.menuItemSize), spacing: DesignTokens.Spacing.sm),
                    ],
                    spacing: DesignTokens.Spacing.md
                ) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        menuCard(item: item, index: index)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(DesignTokens.Anim.spring) {
                isShowing = true
            }
        }
    }

    private func menuCard(item: MenuItem, index: Int) -> some View {
        Button {
            item.action()
        } label: {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: item.icon)
                    .font(DesignTokens.Typography.icon(28))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text(item.title)
                    .font(DesignTokens.Typography.medium(14))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: DesignTokens.FAB.menuItemSize, height: DesignTokens.FAB.menuItemSize)
            .background(DesignTokens.Colors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(item.title)
        .opacity(isShowing ? 1.0 : 0.0)
        .animation(
            DesignTokens.Anim.spring,
            value: isShowing
        )
    }

    private func dismissOverlay() {
        withAnimation(DesignTokens.Anim.quick) {
            isShowing = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()

        FABMenuOverlay(
            onScanFood: {},
            onQuickAdd: {},
            onLogExercise: {},
            onSavedFoods: {},
            onExerciseLibrary: {},
            onWorkoutPlanner: {},
            onVersus: nil,
            onLogMeal: {},
            onDismiss: {}
        )
    }
}
