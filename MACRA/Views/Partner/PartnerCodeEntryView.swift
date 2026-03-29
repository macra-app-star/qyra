import SwiftUI

struct PartnerCodeEntryView: View {
    @State private var code = ""
    @State private var partnerService = PartnerService.shared
    @State private var isSuccess = false
    @Environment(\.dismiss) private var dismiss
    var onSuccess: (() -> Void)?

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignTokens.Spacing.xl) {
                Spacer()

                // Icon
                Image(systemName: "building.2.fill")
                    .font(DesignTokens.Typography.icon(48))
                    .foregroundStyle(DesignTokens.Colors.accent)

                // Title
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text("Organization Code")
                        .font(DesignTokens.Typography.headlineFont(24))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text("Enter your employer or membership code to unlock full access")
                        .font(DesignTokens.Typography.bodyFont(15))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignTokens.Spacing.xl)
                }

                // Code input
                TextField("Enter code", text: $code)
                    .font(DesignTokens.Typography.semibold(20))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(DesignTokens.Spacing.md)
                    .background(DesignTokens.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                    .padding(.horizontal, DesignTokens.Spacing.xl)

                // Error message
                if let error = partnerService.validationError {
                    Text(error)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.destructive)
                }

                // Success state
                if isSuccess, let partner = partnerService.currentPartner {
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(DesignTokens.Typography.icon(40))
                            .foregroundStyle(DesignTokens.Colors.healthGreen)

                        Text(partner.welcomeMessage ?? "Welcome!")
                            .font(DesignTokens.Typography.semibold(17))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        Text("Provided by \(partner.partnerName)")
                            .font(DesignTokens.Typography.bodyFont(14))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }

                Spacer()

                // Validate button
                if !isSuccess {
                    Button {
                        validateCode()
                    } label: {
                        if partnerService.isValidating {
                            ProgressView()
                                .tint(DesignTokens.Colors.surfaceElevated)
                        } else {
                            Text("Validate Code")
                                .font(DesignTokens.Typography.semibold(17))
                        }
                    }
                    .foregroundStyle(DesignTokens.Colors.surfaceElevated)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignTokens.Layout.buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Layout.buttonCornerRadius)
                            .fill(code.isEmpty ? DesignTokens.Colors.textTertiary : DesignTokens.Colors.textPrimary)
                    )
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .disabled(code.isEmpty || partnerService.isValidating)
                } else {
                    Button {
                        onSuccess?()
                        dismiss()
                    } label: {
                        Text("Continue")
                            .font(DesignTokens.Typography.semibold(17))
                    }
                    .foregroundStyle(DesignTokens.Colors.surfaceElevated)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignTokens.Layout.buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Layout.buttonCornerRadius)
                            .fill(DesignTokens.Colors.textPrimary)
                    )
                    .padding(.horizontal, DesignTokens.Spacing.md)
                }

                // Skip button
                Button("Skip") {
                    dismiss()
                }
                .font(DesignTokens.Typography.medium(15))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .padding(.bottom, DesignTokens.Spacing.lg)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(DesignTokens.Typography.icon(22))
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }
                }
            }
        }
    }

    private func validateCode() {
        Task {
            let success = await partnerService.validateCode(code)
            if success {
                withAnimation(DesignTokens.Anim.spring) {
                    isSuccess = true
                }
                DesignTokens.Haptics.success()
            } else {
                DesignTokens.Haptics.error()
            }
        }
    }
}
