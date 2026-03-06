import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: OnboardingViewModel?
    var onComplete: () -> Void

    // Welcome step animations
    @State private var logoVisible = false
    @State private var taglineVisible = false
    @State private var featuresVisible = false
    @State private var ctaVisible = false

    var body: some View {
        ZStack {
            DesignTokens.Colors.background
                .ignoresSafeArea()

            if let vm = viewModel {
                VStack(spacing: 0) {
                    // Progress bar
                    GeometryReader { geo in
                        Rectangle()
                            .fill(DesignTokens.Colors.accent)
                            .frame(width: geo.size.width * vm.currentStep.progress)
                            .animation(DesignTokens.Anim.standard, value: vm.currentStep)
                    }
                    .frame(height: 3)

                    // Content
                    TabView(selection: Binding(
                        get: { vm.currentStep },
                        set: { _ in }
                    )) {
                        welcomeStep(vm).tag(OnboardingStep.welcome)
                        profileStep(vm).tag(OnboardingStep.profile)
                        goalsStep(vm).tag(OnboardingStep.goals)
                        reviewStep(vm).tag(OnboardingStep.review)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(DesignTokens.Anim.standard, value: vm.currentStep)
                }
                .onChange(of: vm.isComplete) { _, complete in
                    if complete { onComplete() }
                }
            }
        }
        .task {
            if viewModel == nil {
                viewModel = OnboardingViewModel(modelContainer: modelContext.container)
            }
        }
    }

    // MARK: - Welcome Step

    private func welcomeStep(_ vm: OnboardingViewModel) -> some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .scaleEffect(logoVisible ? 1 : 0.6)
                    .opacity(logoVisible ? 1 : 0)

                Text("Welcome to MACRA")
                    .font(DesignTokens.Typography.largeTitle)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .opacity(logoVisible ? 1 : 0)

                Text("Precision macro tracking powered by AI")
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                    .opacity(taglineVisible ? 1 : 0)
                    .offset(y: taglineVisible ? 0 : 8)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                featureRow(icon: "camera.fill", text: "Scan meals with your camera")
                featureRow(icon: "mic.fill", text: "Log by voice in seconds")
                featureRow(icon: "chart.line.uptrend.xyaxis", text: "AI-powered insights")
                featureRow(icon: "target", text: "Personalized nutrition goals")
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .opacity(featuresVisible ? 1 : 0)
            .offset(y: featuresVisible ? 0 : 12)

            Spacer()

            MonochromeButton("Get Started", icon: "arrow.right", style: .primary) {
                vm.advance()
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.bottom, DesignTokens.Spacing.xl)
            .opacity(ctaVisible ? 1 : 0)
            .offset(y: ctaVisible ? 0 : 16)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                logoVisible = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.25)) {
                taglineVisible = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                featuresVisible = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.75)) {
                ctaVisible = true
            }
        }
    }

    // MARK: - Profile Step (Imperial Units)

    private func profileStep(_ vm: OnboardingViewModel) -> some View {
        @Bindable var vm = vm
        return ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("About You")
                    .font(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .padding(.top, DesignTokens.Spacing.xl)

                Text("This helps calculate your macro targets")
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)

                VStack(spacing: DesignTokens.Spacing.md) {
                    onboardingField("Name (optional)", text: $vm.displayName, keyboard: .default)

                    // Weight in pounds
                    onboardingField("Weight (lbs)", text: $vm.weightLbsText, keyboard: .decimalPad)

                    // Height in feet + inches
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("Height")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.textTertiary)

                        HStack(spacing: DesignTokens.Spacing.sm) {
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                TextField("5", text: $vm.heightFeetText)
                                    .keyboardType(.numberPad)
                                    .padding(DesignTokens.Spacing.md)
                                    .background(DesignTokens.Colors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
                                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                                Text("ft")
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                            }

                            HStack(spacing: DesignTokens.Spacing.xs) {
                                TextField("9", text: $vm.heightInchesText)
                                    .keyboardType(.numberPad)
                                    .padding(DesignTokens.Spacing.md)
                                    .background(DesignTokens.Colors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
                                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                                Text("in")
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                            }
                        }
                    }

                    onboardingField("Age", text: $vm.ageText, keyboard: .numberPad)

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("Gender")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.textTertiary)

                        Picker("Gender", selection: $vm.gender) {
                            ForEach(Gender.allCases) { g in
                                Text(g.displayName).tag(g)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)

                Spacer(minLength: DesignTokens.Spacing.xxl)

                HStack(spacing: DesignTokens.Spacing.md) {
                    MonochromeButton("Back", icon: "arrow.left", style: .ghost) {
                        vm.goBack()
                    }
                    MonochromeButton("Next", icon: "arrow.right", style: .primary) {
                        vm.advance()
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.bottom, DesignTokens.Spacing.xl)
            }
        }
    }

    // MARK: - Goals Step

    private func goalsStep(_ vm: OnboardingViewModel) -> some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("Your Goal")
                    .font(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .padding(.top, DesignTokens.Spacing.xl)

                // Goal type
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("What's your focus?")
                        .font(DesignTokens.Typography.headline)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    ForEach(GoalType.allCases) { type in
                        goalOption(type, selected: vm.goalType == type) {
                            vm.goalType = type
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)

                // Activity level
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Activity Level")
                        .font(DesignTokens.Typography.headline)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    ForEach(ActivityLevel.allCases) { level in
                        activityOption(level, selected: vm.activityLevel == level) {
                            vm.activityLevel = level
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)

                Spacer(minLength: DesignTokens.Spacing.xxl)

                HStack(spacing: DesignTokens.Spacing.md) {
                    MonochromeButton("Back", icon: "arrow.left", style: .ghost) {
                        vm.goBack()
                    }
                    MonochromeButton("Next", icon: "arrow.right", style: .primary) {
                        vm.advance()
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.bottom, DesignTokens.Spacing.xl)
            }
        }
    }

    // MARK: - Review Step

    private func reviewStep(_ vm: OnboardingViewModel) -> some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("Your Plan")
                    .font(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .padding(.top, DesignTokens.Spacing.xl)

                Text("Based on your profile, here are your daily targets")
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                    .multilineTextAlignment(.center)

                // Macro summary cards
                VStack(spacing: DesignTokens.Spacing.sm) {
                    macroTargetRow("Calories", value: "\(vm.calculatedCalories)", unit: "cal")
                    macroTargetRow("Protein", value: "\(vm.calculatedProtein)", unit: "g")
                    macroTargetRow("Carbs", value: "\(vm.calculatedCarbs)", unit: "g")
                    macroTargetRow("Fat", value: "\(vm.calculatedFat)", unit: "g")
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)

                Text("You can adjust these anytime in Settings")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)

                Spacer(minLength: DesignTokens.Spacing.xxl)

                HStack(spacing: DesignTokens.Spacing.md) {
                    MonochromeButton("Back", icon: "arrow.left", style: .ghost) {
                        vm.goBack()
                    }
                    MonochromeButton("Start Tracking", icon: "checkmark", style: .primary) {
                        Task { await vm.finish() }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.bottom, DesignTokens.Spacing.xl)
            }
        }
    }

    // MARK: - Components

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .frame(width: 32)

            Text(text)
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
    }

    private func onboardingField(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(placeholder)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textTertiary)

            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .padding(DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
        }
    }

    private func goalOption(_ type: GoalType, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(DesignTokens.Typography.headline)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    Text(type.subtitle)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? DesignTokens.Colors.accent : DesignTokens.Colors.textTertiary)
            }
            .padding(DesignTokens.Spacing.md)
            .background(selected ? DesignTokens.Colors.surfaceElevated : DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                    .stroke(selected ? DesignTokens.Colors.accent : .clear, lineWidth: 1)
            )
        }
    }

    private func activityOption(_ level: ActivityLevel, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(level.displayName)
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(DesignTokens.Colors.accent)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(selected ? DesignTokens.Colors.surfaceElevated : DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
        }
    }

    private func macroTargetRow(_ label: String, value: String, unit: String) -> some View {
        HStack {
            Text(label)
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(DesignTokens.Typography.monoSmall)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            Text(unit)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textTertiary)
                .frame(width: 30, alignment: .leading)
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
    }
}

extension GoalType {
    var subtitle: String {
        switch self {
        case .cut: return "Lose fat, preserve muscle"
        case .maintain: return "Stay at current weight"
        case .bulk: return "Build muscle, gain weight"
        }
    }
}
