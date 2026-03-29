import SwiftUI

struct EmptyDataView: View {
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color(.label))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

#Preview {
    VStack(spacing: 24) {
        EmptyDataView(
            title: "No Meals Logged",
            subtitle: "Log your first meal to see it here.",
            actionTitle: "Log a Meal",
            action: {}
        )

        EmptyDataView(
            title: "No Weight Entries",
            subtitle: "Log a weigh-in to start tracking progress."
        )
    }
    .padding()
}
