import SwiftUI

// Toast overlay showing background import progress (exercises, nutrition DB).
// Appears at top of screen, auto-dismisses on completion.

struct ImportProgressToast: View {
    @ObservedObject var exerciseImport = ExerciseImportService.shared

    @State private var showToast = false
    @State private var dismissTask: Task<Void, Never>?

    var body: some View {
        VStack {
            if showToast {
                toastContent
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.horizontal, DesignTokens.Layout.screenMargin)
                    .padding(.top, DesignTokens.Spacing.sm)
            }
            Spacer()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showToast)
        .onChange(of: exerciseImport.isImporting) { _, importing in
            if importing {
                showToast = true
                dismissTask?.cancel()
            }
        }
        .onChange(of: exerciseImport.importProgress) { _, progress in
            if progress >= 1.0 {
                dismissTask = Task {
                    try? await Task.sleep(for: .seconds(2))
                    showToast = false
                }
            }
        }
        .onChange(of: exerciseImport.errorMessage) { _, error in
            if error != nil {
                dismissTask = Task {
                    try? await Task.sleep(for: .seconds(3))
                    showToast = false
                }
            }
        }
    }

    private var toastContent: some View {
        HStack(spacing: DesignTokens.Layout.itemGap) {
            if let error = exerciseImport.errorMessage {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(DesignTokens.Colors.warning)
                Text(error)
                    .font(QyraFont.medium(13))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)
            } else if exerciseImport.importProgress >= 1.0 {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(DesignTokens.Colors.success)
                Text("\(exerciseImport.importedCount) exercises loaded")
                    .font(QyraFont.medium(13))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
            } else {
                ProgressView(value: exerciseImport.importProgress)
                    .tint(DesignTokens.Colors.tint)
                    .frame(width: 40)
                Text("Loading exercise database...")
                    .font(QyraFont.medium(13))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
            }

            Spacer()

            Button {
                showToast = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
        }
        .padding(DesignTokens.Layout.cardInternalPadding)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }
}

#Preview {
    ImportProgressToast()
}
