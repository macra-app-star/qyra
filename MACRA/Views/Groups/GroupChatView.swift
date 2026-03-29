import SwiftUI
import PhotosUI

struct GroupChatView: View {
    let messages: [GroupMessage]
    var onSend: ((String) -> Void)? = nil

    @State private var messageText = ""
    @State private var selectedPhoto: PhotosPickerItem? = nil

    var body: some View {
        VStack(spacing: 0) {
            if messages.isEmpty {
                emptyState
            } else {
                messagesList
            }

            inputBar
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack {
            Spacer()
            EmptyDataView(
                title: "No Messages",
                subtitle: "Send the first message to start a conversation."
            )
            .padding(.horizontal, DesignTokens.Spacing.md)
            Spacer()
        }
    }

    // MARK: - Messages List

    private var messagesList: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.md) {
                ForEach(messages) { message in
                    messageBubble(message)
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func messageBubble(_ message: GroupMessage) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            // Avatar
            avatarCircle(
                initials: message.senderInitials,
                colorIndex: message.avatarColorIndex,
                size: 36,
                photo: message.profilePhoto
            )

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                // Name + timestamp
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Text(message.senderName)
                        .font(DesignTokens.Typography.semibold(14))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text(message.timestamp, style: .relative)
                        .font(DesignTokens.Typography.bodyFont(11))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }

                // Reply bar
                if let replyText = message.replyTo {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(DesignTokens.Colors.textTertiary)
                            .frame(width: 2)

                        Text(replyText)
                            .font(DesignTokens.Typography.bodyFont(12))
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                            .lineLimit(1)
                    }
                    .padding(.vertical, DesignTokens.Spacing.xxs)
                }

                // Message text
                Text(message.text)
                    .font(DesignTokens.Typography.bodyFont(15))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                // Reactions
                if !message.reactions.isEmpty {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        ForEach(message.reactions) { reaction in
                            reactionPill(reaction)
                        }
                    }
                    .padding(.top, DesignTokens.Spacing.xxs)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func reactionPill(_ reaction: GroupReaction) -> some View {
        HStack(spacing: DesignTokens.Spacing.xxs) {
            Text(reaction.emoji)
                .font(DesignTokens.Typography.bodyFont(12))
            Text("\(reaction.count)")
                .font(DesignTokens.Typography.bodyFont(12))
                .foregroundStyle(
                    reaction.isSelected
                        ? DesignTokens.Colors.brandAccent
                        : DesignTokens.Colors.textSecondary
                )
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(
            Capsule()
                .fill(DesignTokens.Colors.surface)
                .overlay(
                    Capsule()
                        .strokeBorder(
                            reaction.isSelected
                                ? DesignTokens.Colors.brandAccent.opacity(0.3)
                                : Color.clear,
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Image(systemName: "photo")
                    .font(DesignTokens.Typography.icon(22))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            TextField("Message...", text: $messageText)
                .font(DesignTokens.Typography.bodyFont(15))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Button {
                onSend?(messageText)
                messageText = ""
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(DesignTokens.Typography.icon(28))
                    .foregroundStyle(
                        messageText.isEmpty
                            ? DesignTokens.Colors.textTertiary
                            : DesignTokens.Colors.brandAccent
                    )
            }
            .disabled(messageText.isEmpty)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xl))
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
    }

    // MARK: - Avatar Helper

    @ViewBuilder
    private func avatarCircle(initials: String, colorIndex: Int, size: CGFloat, photo: UIImage? = nil) -> some View {
        if let photo {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            let color = DesignTokens.Colors.avatarColors[colorIndex % DesignTokens.Colors.avatarColors.count]
            Text(initials)
                .font(DesignTokens.Typography.semibold(size * 0.36))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(color)
                .clipShape(Circle())
        }
    }
}

#Preview("With Messages") {
    GroupChatView(messages: GroupMessage.sampleMessages)
        .background(DesignTokens.Colors.background)
}

#Preview("Empty") {
    GroupChatView(messages: [])
        .background(DesignTokens.Colors.background)
}
