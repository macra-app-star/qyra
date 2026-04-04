import SwiftUI
import SwiftData

struct AIChatHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AIChatHistoryViewModel()
    @State private var navigateToConversation: UUID?
    @State private var navigateToNew = false

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.conversations.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                conversationList
            }
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Qyra AI")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    let newId = viewModel.createNewConversation()
                    navigateToConversation = newId
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .navigationDestination(item: $navigateToConversation) { conversationId in
            IntelligenceDetailView(conversationId: conversationId)
        }
        .task {
            viewModel.loadConversations(modelContext: modelContext)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.accentColor)
            }

            Text("Qyra AI")
                .font(DesignTokens.Typography.headline)
                .foregroundStyle(Color(.label))

            Text("Your personal AI health specialist")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(Color(.secondaryLabel))
        }
        .padding(.vertical, DesignTokens.Spacing.lg)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Conversation List

    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                headerView

                ForEach(viewModel.groupedConversations) { group in
                    Section {
                        ForEach(group.conversations) { conversation in
                            conversationRow(conversation)
                        }
                    } header: {
                        HStack {
                            Text(group.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color(.secondaryLabel))
                                .textCase(.uppercase)
                            Spacer()
                        }
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.top, DesignTokens.Spacing.md)
                        .padding(.bottom, DesignTokens.Spacing.xs)
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Conversation Row

    private func conversationRow(_ conversation: AIConversation) -> some View {
        Button {
            navigateToConversation = conversation.id
        } label: {
            HStack(spacing: DesignTokens.Spacing.sm) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 40, height: 40)

                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.accentColor)
                }

                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(conversation.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(.label))
                        .lineLimit(1)

                    if let preview = conversation.preview {
                        Text(preview)
                            .font(.system(size: 13))
                            .foregroundStyle(Color(.secondaryLabel))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Metadata
                VStack(alignment: .trailing, spacing: 2) {
                    Text(AIChatHistoryViewModel.relativeTimeString(for: conversation.updatedAt))
                        .font(.system(size: 12))
                        .foregroundStyle(Color(.tertiaryLabel))

                    if conversation.messageCount > 0 {
                        Text("\(conversation.messageCount)")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                viewModel.deleteConversation(conversation, modelContext: modelContext)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.deleteConversation(conversation, modelContext: modelContext)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                headerView

                Text("Start a conversation")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(.label))

                Text("Ask Qyra AI about nutrition, supplements, or health optimization.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                VStack(spacing: DesignTokens.Spacing.sm) {
                    quickActionButton(icon: "chart.bar.fill", text: "Analyze my nutrition this week")
                    quickActionButton(icon: "pill.fill", text: "What supplements should I take?")
                    quickActionButton(icon: "fork.knife", text: "Review my macro balance")
                    quickActionButton(icon: "figure.run", text: "Help me optimize my routine")
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
            }
            .padding(.bottom, 100)
        }
    }

    private func quickActionButton(icon: String, text: String) -> some View {
        Button {
            let newId = viewModel.createNewConversation()
            navigateToConversation = newId
            // The initialPrompt will be passed through the navigation
            // We store it temporarily in UserDefaults for simplicity
            UserDefaults.standard.set(text, forKey: "qyra.initialPrompt")
        } label: {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 20)

                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(.label))

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm + 2)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        AIChatHistoryView()
    }
    .modelContainer(for: [AIConversation.self, AIConversationMessage.self], inMemory: true)
}
