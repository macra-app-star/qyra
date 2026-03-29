import SwiftUI
import SwiftData

// MARK: - Shining Text (inline — AI "thinking" indicator)
private struct ShiningText: View {
    let text: String
    var font: Font = .system(size: 15, weight: .medium)
    @State private var phase: CGFloat = 0

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(.clear)
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(UIColor.systemGray), location: 0),
                            Gradient.Stop(color: Color(UIColor.systemGray), location: 0.35),
                            Gradient.Stop(color: Color(UIColor.systemGray3), location: 0.5),
                            Gradient.Stop(color: Color(UIColor.systemGray), location: 0.65),
                            Gradient.Stop(color: Color(UIColor.systemGray), location: 1),
                        ],
                        startPoint: UnitPoint(x: phase - 0.5, y: 0.5),
                        endPoint: UnitPoint(x: phase + 0.5, y: 0.5)
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .mask {
                    Text(text).font(font)
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    phase = 2.0
                }
            }
    }
}

struct AICoachView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: AICoachViewModel?

    var body: some View {
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
        .navigationTitle("Coach")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                viewModel = AICoachViewModel(modelContainer: modelContext.container)
            }
        }
    }

    // MARK: - Chat Content

    private func chatContent(_ vm: AICoachViewModel) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.md) {
                    // Coach intro card
                    coachHeader

                    ForEach(vm.messages) { message in
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
                    .fill(DesignTokens.Colors.aiAccent.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: "brain.head.profile.fill")
                    .font(QyraFont.regular(28))
                    .foregroundStyle(DesignTokens.Colors.aiAccent)
            }

            Text("Qyra AI")
                .font(DesignTokens.Typography.headline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text("AI-powered nutrition guidance")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
        .padding(.vertical, DesignTokens.Spacing.md)
    }

    // MARK: - Message Bubble

    private func messageBubble(_ message: CoachMessage) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            if message.role == .assistant {
                Circle()
                    .fill(DesignTokens.Colors.aiAccent.opacity(0.15))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "brain.head.profile.fill")
                            .font(QyraFont.regular(14))
                            .foregroundStyle(DesignTokens.Colors.aiAccent)
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
                .fill(DesignTokens.Colors.aiAccent.opacity(0.15))
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "brain.head.profile.fill")
                        .font(QyraFont.regular(14))
                        .foregroundStyle(DesignTokens.Colors.aiAccent)
                )

            ShiningText(
                text: "Qyra is thinking...",
                font: DesignTokens.Typography.body
            )
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm + 2)
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))

            Spacer(minLength: 40)
        }
    }

    // MARK: - Input Bar

    private func inputBar(_ vm: AICoachViewModel) -> some View {
        @Bindable var vm = vm
        return VStack(spacing: 0) {
            Divider()
                .foregroundStyle(DesignTokens.Colors.separator)

            HStack(spacing: DesignTokens.Spacing.sm) {
                TextField("Ask about nutrition, meals...", text: $vm.inputText, axis: .vertical)
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineLimit(1...4)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(DesignTokens.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))

                Button {
                    Task { await vm.send() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(QyraFont.regular(32))
                        .foregroundStyle(
                            vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? DesignTokens.Colors.textTertiary
                                : DesignTokens.Colors.brandAccent
                        )
                }
                .disabled(vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isLoading)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(DesignTokens.Colors.background)
        }
    }
}

#Preview {
    NavigationStack {
        AICoachView()
    }
    .modelContainer(for: [MealLog.self, MacroGoal.self, SyncRecord.self])
}
