import SwiftUI
import SwiftData
import PhotosUI

struct IntelligenceDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TabBarState.self) private var tabBarState
    @State private var viewModel: IntelligenceViewModel?
    @State private var isSubscribed = false
    @State private var showPaywall = false

    var body: some View {
        Group {
            if isSubscribed {
                premiumContent
            } else {
                PremiumGateView(
                    featureName: "AI Insights",
                    icon: "brain.head.profile",
                    showPaywall: $showPaywall
                )
            }
        }
        .task {
            isSubscribed = await SubscriptionService.shared.isSubscribed
            #if DEBUG
            if UserDefaults.standard.bool(forKey: "devBypassSubscription") { isSubscribed = true }
            #endif
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("devSubscriptionBypassed"))) { _ in
            isSubscribed = true
        }
        .sheet(isPresented: $showPaywall) {
            OnboardingPaywallView(viewModel: OnboardingViewModel.preview)
        }
    }

    private var premiumContent: some View {
        VStack(spacing: 0) {
            if let vm = viewModel {
                chatContent(vm)
                inputBar(vm)
            } else {
                ProgressView()
                    .frame(maxHeight: .infinity)
            }
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Qyra AI")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { tabBarState.isVisible = false }
        .onDisappear { tabBarState.isVisible = true }
        .task {
            if viewModel == nil {
                viewModel = IntelligenceViewModel(modelContainer: modelContext.container)
            }
        }
    }

    // MARK: - Chat Content

    private func chatContent(_ vm: IntelligenceViewModel) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.md) {
                    coachHeader

                    // Welcome message first (above prompts)
                    if let firstMessage = vm.messages.first {
                        messageBubble(firstMessage)
                            .id(firstMessage.id)
                    }

                    // Suggested prompts below welcome (show only when just the welcome message exists)
                    if vm.messages.count <= 1 {
                        suggestedPrompts(vm)
                    }

                    // Remaining conversation messages
                    ForEach(Array(vm.messages.dropFirst())) { message in
                        messageBubble(message)
                            .id(message.id)
                    }

                    if vm.isLoading {
                        typingIndicator
                            .id("typing")
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: vm.messages.count) {
                withAnimation {
                    if let last = vm.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                    if vm.isLoading {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Coach Header

    private var coachHeader: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.brandAccent.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(DesignTokens.Colors.brandAccent)
            }

            Text("Qyra AI")
                .font(DesignTokens.Typography.headline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text("Your personal AI health specialist")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
        .padding(.vertical, DesignTokens.Spacing.md)
    }

    // MARK: - Suggested Prompts

    private func suggestedPrompts(_ vm: IntelligenceViewModel) -> some View {
        let prompts = [
            ("chart.bar.fill", "Analyze my nutrition this week"),
            ("pill.fill", "What supplements should I take?"),
            ("fork.knife", "Review my macro balance"),
            ("figure.run", "Help me optimize my routine"),
        ]

        return VStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(prompts, id: \.1) { icon, text in
                Button {
                    Task { await vm.sendSuggestion(text) }
                } label: {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: icon)
                            .font(DesignTokens.Typography.icon(14))
                            .foregroundStyle(DesignTokens.Colors.brandAccent)
                            .frame(width: 20)

                        Text(text)
                            .font(DesignTokens.Typography.medium(14))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        Spacer()

                        Image(systemName: "arrow.right")
                            .font(DesignTokens.Typography.icon(12))
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm + 2)
                    .background(DesignTokens.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                }
            }
        }
    }

    // MARK: - Message Bubble

    private func messageBubble(_ message: CoachMessage) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            if message.role == .assistant {
                Circle()
                    .fill(DesignTokens.Colors.brandAccent.opacity(0.15))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "brain.head.profile.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(DesignTokens.Colors.brandAccent)
                    )
            }

            if message.role == .user {
                Spacer(minLength: 60)
            }

            Text(message.content)
                .font(DesignTokens.Typography.body)
                .foregroundStyle(message.role == .user ? .white : DesignTokens.Colors.textPrimary)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm + 2)
                .background(
                    message.role == .user
                        ? DesignTokens.Colors.brandAccent
                        : DesignTokens.Colors.surface
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))

            if message.role == .assistant {
                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            Circle()
                .fill(DesignTokens.Colors.brandAccent.opacity(0.15))
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "brain.head.profile.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignTokens.Colors.brandAccent)
                )

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(DesignTokens.Colors.textTertiary)
                        .frame(width: 6, height: 6)
                        .opacity(0.6)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))

            Spacer(minLength: 40)
        }
    }

    // MARK: - Input Bar (Premium Floating Capsule with Expand Animation)

    @FocusState private var isInputFocused: Bool

    private func inputBar(_ vm: IntelligenceViewModel) -> some View {
        @Bindable var vm = vm
        let isEmpty = vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return VStack(spacing: 0) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                // "+" attachment button
                PhotosPicker(selection: $vm.selectedPhoto, matching: .images) {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 32, height: 32)
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.secondary)
                    }
                }
                .onChange(of: vm.selectedPhoto) { _, _ in
                    Task { await vm.processSelectedPhoto() }
                }

                // Text input
                TextField("Ask Qyra", text: $vm.inputText, axis: .vertical)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .tint(DesignTokens.Colors.brandAccent)

                // Send button
                Button {
                    Task { await vm.send() }
                } label: {
                    ZStack {
                        Circle()
                            .fill(isEmpty ? Color(.systemGray5) : DesignTokens.Colors.brandAccent)
                            .frame(width: 32, height: 32)
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isEmpty ? Color.secondary : .white)
                    }
                }
                .disabled(isEmpty || vm.isLoading)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm + 2)
            .background(
                ZStack {
                    // Light material capsule background
                    Capsule()
                        .fill(.ultraThinMaterial)

                    // Blue glow border on focus
                    Capsule()
                        .strokeBorder(
                            DesignTokens.Colors.brandAccent.opacity(isInputFocused ? 0.5 : 0),
                            lineWidth: 1.5
                        )
                }
            )
            .shadow(
                color: isInputFocused ? DesignTokens.Colors.brandAccent.opacity(0.25) : .clear,
                radius: 16,
                y: 0
            )
            // Expand from compact to full-width on focus
            .padding(.horizontal, isInputFocused ? DesignTokens.Spacing.md : DesignTokens.Spacing.xxl + 16)
            .scaleEffect(isInputFocused ? 1.0 : 0.85)
            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: isInputFocused)
            .padding(.vertical, DesignTokens.Spacing.md)
        }
    }
}

#Preview {
    NavigationStack {
        IntelligenceDetailView()
    }
    .modelContainer(for: [MealLog.self, MacroGoal.self, SyncRecord.self])
}
