import SwiftUI

struct LastNameEntryView: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("And your last name?")
                    .font(OnboardingTheme.titleFont)
                    .tracking(OnboardingTheme.titleTracking)
                    .foregroundStyle(OnboardingTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("Last name", text: $viewModel.lastName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(OnboardingTheme.textPrimary)
                    .padding(.vertical, DesignTokens.Spacing.md)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(viewModel.lastName.isEmpty ? OnboardingTheme.progressEmpty : Color.accentColor)
                            .frame(height: 2)
                    }
                    .focused($isFocused)
                    .textContentType(.familyName)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, OnboardingTheme.screenPadding)

            Spacer()
            Spacer()

            OnboardingContinueButton(
                isEnabled: !viewModel.lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ) {
                isFocused = false
                // Auto-suggest username from name
                if viewModel.username.isEmpty {
                    let first = viewModel.firstName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    let last = viewModel.lastName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    viewModel.username = "\(first)\(last.prefix(1))"
                        .replacingOccurrences(of: " ", with: "")
                }
                viewModel.advance()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
        }
    }
}

#Preview {
    LastNameEntryView(viewModel: .preview)
}
