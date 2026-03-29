import SwiftUI

struct UsernameEntryView: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isFocused: Bool
    @State private var checkTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("Choose a username")
                    .font(OnboardingTheme.titleFont)
                    .tracking(OnboardingTheme.titleTracking)
                    .foregroundStyle(OnboardingTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("This is how others will find you in groups.")
                    .font(OnboardingTheme.subtitleFont)
                    .foregroundStyle(OnboardingTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Username input
                HStack(spacing: 4) {
                    Text("@")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(OnboardingTheme.textSecondary)

                    TextField("username", text: $viewModel.username)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(OnboardingTheme.textPrimary)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.username)
                        .focused($isFocused)
                        .onChange(of: viewModel.username) { _, newValue in
                            // Sanitize: lowercase, no spaces
                            let sanitized = newValue.lowercased()
                                .replacingOccurrences(of: " ", with: "_")
                                .filter { $0.isLetter || $0.isNumber || $0 == "_" }
                            if sanitized != newValue {
                                viewModel.username = sanitized
                            }

                            // Debounce availability check
                            viewModel.isUsernameAvailable = nil
                            checkTask?.cancel()
                            checkTask = Task {
                                try? await Task.sleep(for: .milliseconds(600))
                                guard !Task.isCancelled else { return }
                                await viewModel.checkUsernameAvailability()
                            }
                        }
                }
                .padding(.vertical, DesignTokens.Spacing.md)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(underlineColor)
                        .frame(height: 2)
                }

                // Availability status
                availabilityStatus
            }
            .padding(.horizontal, OnboardingTheme.screenPadding)

            Spacer()
            Spacer()

            OnboardingContinueButton(
                isEnabled: viewModel.isUsernameAvailable == true
            ) {
                isFocused = false
                viewModel.advance()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
            // Check pre-filled suggestion
            if !viewModel.username.isEmpty {
                Task { await viewModel.checkUsernameAvailability() }
            }
        }
    }

    // MARK: - Availability Status

    @ViewBuilder
    private var availabilityStatus: some View {
        if viewModel.isCheckingUsername {
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Checking availability...")
                    .font(QyraFont.regular(14))
                    .foregroundStyle(OnboardingTheme.textSecondary)
            }
        } else if let available = viewModel.isUsernameAvailable {
            HStack(spacing: 6) {
                Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(available ? .green : .red)
                Text(available ? "@\(viewModel.username) is available" : usernameErrorMessage)
                    .font(QyraFont.regular(14))
                    .foregroundStyle(available ? .green : .red)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: available)
        } else if !viewModel.username.isEmpty && viewModel.username.count < 3 {
            Text("Username must be at least 3 characters")
                .font(QyraFont.regular(14))
                .foregroundStyle(OnboardingTheme.textSecondary)
        }
    }

    private var underlineColor: Color {
        if let available = viewModel.isUsernameAvailable {
            return available ? .green : .red
        }
        return viewModel.username.isEmpty ? OnboardingTheme.progressEmpty : Color.accentColor
    }

    private var usernameErrorMessage: String {
        let trimmed = viewModel.username.trimmingCharacters(in: .whitespaces)
        if trimmed.count < 3 { return "Too short (min 3 characters)" }
        if trimmed.count > 20 { return "Too long (max 20 characters)" }
        return "@\(trimmed) is taken"
    }
}

#Preview {
    UsernameEntryView(viewModel: .preview)
}
