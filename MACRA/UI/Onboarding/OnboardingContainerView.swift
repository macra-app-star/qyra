import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: OnboardingViewModel?
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            OnboardingTheme.background
                .ignoresSafeArea()

            if let vm = viewModel {
                contentView(vm)
            }
        }
        .task {
            if viewModel == nil {
                viewModel = OnboardingViewModel(modelContainer: modelContext.container)
            }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private func contentView(_ vm: OnboardingViewModel) -> some View {
        VStack(spacing: 0) {
            // Top bar: back button + progress bar
            if vm.showBackButton || vm.showProgressBar {
                topBar(vm)
            }

            // Screen content with slide transition
            screenContent(vm)
                .id(vm.currentStep)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: vm.currentStep)
        }
        .overlay {
            // Sign-in sheet overlay
            if vm.showSignInSheet {
                SignInSheetView(viewModel: vm)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.25), value: vm.showSignInSheet)
            }
        }
        .onChange(of: vm.isComplete) { _, complete in
            if complete { onComplete() }
        }
    }

    // MARK: - Top Bar

    private func topBar(_ vm: OnboardingViewModel) -> some View {
        VStack(spacing: 12) {
            if vm.showBackButton {
                OnboardingBackButton {
                    vm.goBack()
                }
            }

            if vm.showProgressBar, let step = vm.progressStep {
                OnboardingProgressBar(currentStep: step)
                    .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Screen Router

    @ViewBuilder
    private func screenContent(_ vm: OnboardingViewModel) -> some View {
        switch vm.currentStep {
        case .splash:
            SplashView(viewModel: vm)
        case .welcome, .signIn:
            // Carousel removed — these steps are skipped
            NameEntryView(viewModel: vm)
        case .nameEntry:
            NameEntryView(viewModel: vm)
        case .lastNameEntry:
            LastNameEntryView(viewModel: vm)
        case .usernameEntry:
            UsernameEntryView(viewModel: vm)
        case .gender:
            GenderSelectionView(viewModel: vm)
        case .workouts:
            WorkoutFrequencyView(viewModel: vm)
        case .attribution:
            AttributionSourceView(viewModel: vm)
        case .previousApps:
            PreviousAppsView(viewModel: vm)
        case .longTermResults:
            LongTermResultsView(viewModel: vm)
        case .heightWeight:
            HeightWeightView(viewModel: vm)
        case .birthday:
            BirthdayView(viewModel: vm)
        case .coach:
            CoachQuestionView(viewModel: vm)
        case .goalSelection:
            GoalSelectionView(viewModel: vm)
        case .gainComparison:
            GainComparisonView(viewModel: vm)
        case .desiredWeight:
            DesiredWeightView(viewModel: vm)
        case .motivation:
            MotivationView(viewModel: vm)
        case .accomplishment:
            AccomplishView(viewModel: vm)
        case .weightTransition:
            WeightTransitionView(viewModel: vm)
        case .speedSelection:
            SpeedSelectionView(viewModel: vm)
        case .barriers:
            BarriersView(viewModel: vm)
        case .dietType:
            DietTypeView(viewModel: vm)
        case .caloriesBurned:
            CaloriesBurnedView(viewModel: vm)
        case .trust:
            TrustView(viewModel: vm)
        case .healthKitConnect:
            HealthKitConnectView(viewModel: vm)
        case .wearableConnect:
            WearableConnectOnboardingView(viewModel: vm)
        case .calorieRollover:
            CalorieRolloverView(viewModel: vm)
        case .allDone:
            AllDoneView(viewModel: vm)
        case .planGeneration:
            PlanGenerationView(viewModel: vm)
        case .planResults:
            PlanResultsView(viewModel: vm)
        case .saveProgress:
            SaveProgressView(viewModel: vm)
        case .onboardingPaywall:
            OnboardingPaywallView(viewModel: vm)
        case .trialReminder:
            TrialReminderView(viewModel: vm)
        case .referralCode:
            ReferralCodeView(viewModel: vm)
        case .ratingPrompt:
            RatingPromptView(viewModel: vm)
        }
    }
}

#Preview {
    OnboardingContainerView { }
        .modelContainer(for: MacroGoal.self, inMemory: true)
}
