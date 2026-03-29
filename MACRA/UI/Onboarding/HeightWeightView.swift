import SwiftUI

struct HeightWeightView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTitle(text: "Height & weight")
                .padding(.top, DesignTokens.Spacing.lg)
                .fixedSize(horizontal: false, vertical: true)

            OnboardingSubtitle(text: "This will be used to calibrate your custom plan.")

            // Unit toggle
            unitToggle
                .padding(.top, DesignTokens.Spacing.lg)

            Spacer()

            // Pickers
            if viewModel.useMetric {
                metricPickers
            } else {
                imperialPickers
            }

            Spacer()

            OnboardingContinueButton(isEnabled: true) {
                viewModel.advance()
            }
        }
        .animation(OnboardingTheme.defaultSpring, value: viewModel.useMetric)
    }

    // MARK: - Unit Toggle

    private var unitToggle: some View {
        HStack(spacing: DesignTokens.Layout.cardGap) {
            Text("Imperial")
                .font(viewModel.useMetric ? QyraFont.regular(16) : QyraFont.bold(16))
                .foregroundStyle(viewModel.useMetric ? OnboardingTheme.textSecondary : OnboardingTheme.textPrimary)

            ZStack(alignment: viewModel.useMetric ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 15)
                    .fill(viewModel.useMetric ? OnboardingTheme.selectedCardBg : OnboardingTheme.progressEmpty)
                    .frame(width: 52, height: 30)

                Circle()
                    .fill(OnboardingTheme.background)
                    .frame(width: 26, height: 26)
                    .padding(.horizontal, 2)
            }
            .onTapGesture {
                DesignTokens.Haptics.selection()
                withAnimation(OnboardingTheme.defaultSpring) {
                    viewModel.useMetric.toggle()
                }
            }

            Text("Metric")
                .font(viewModel.useMetric ? QyraFont.bold(16) : QyraFont.regular(16))
                .foregroundStyle(viewModel.useMetric ? OnboardingTheme.textPrimary : OnboardingTheme.textSecondary)
        }
    }

    // MARK: - Imperial Pickers

    private var imperialPickers: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // Labels
            HStack {
                Text("Height")
                    .font(QyraFont.bold(15))
                    .foregroundStyle(OnboardingTheme.textPrimary)
                    .frame(maxWidth: .infinity)

                Text("Weight")
                    .font(QyraFont.bold(15))
                    .foregroundStyle(OnboardingTheme.textPrimary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, OnboardingTheme.screenPadding)

            HStack(spacing: 0) {
                // Feet picker
                Picker("Feet", selection: $viewModel.heightFeet) {
                    ForEach(4...7, id: \.self) { ft in
                        Text("\(ft) ft").tag(ft)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                // Inches picker
                Picker("Inches", selection: $viewModel.heightInches) {
                    ForEach(0...11, id: \.self) { inch in
                        Text("\(inch) in").tag(inch)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                // Weight picker
                Picker("Weight", selection: $viewModel.weightLbs) {
                    ForEach(80...400, id: \.self) { lb in
                        Text("\(lb) lb").tag(lb)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
            }
            .frame(height: 180)
            .padding(.horizontal, DesignTokens.Spacing.sm)
        }
    }

    // MARK: - Metric Pickers

    private var metricPickers: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("Height")
                    .font(QyraFont.bold(15))
                    .foregroundStyle(OnboardingTheme.textPrimary)
                    .frame(maxWidth: .infinity)

                Text("Weight")
                    .font(QyraFont.bold(15))
                    .foregroundStyle(OnboardingTheme.textPrimary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, OnboardingTheme.screenPadding)

            HStack(spacing: 0) {
                Picker("Height", selection: $viewModel.heightCm) {
                    ForEach(130...220, id: \.self) { cm in
                        Text("\(cm) cm").tag(cm)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                Picker("Weight", selection: $viewModel.weightKgPicker) {
                    ForEach(30...180, id: \.self) { kg in
                        Text("\(kg) kg").tag(kg)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
            }
            .frame(height: 180)
            .padding(.horizontal, DesignTokens.Spacing.sm)
        }
    }
}

#Preview {
    HeightWeightView(viewModel: OnboardingViewModel.preview)
}
