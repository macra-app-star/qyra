import SwiftUI

struct TrackingRemindersView: View {
    @State private var breakfastOn = true
    @State private var lunchOn = true
    @State private var dinnerOn = true
    @State private var snackOn = false
    @State private var endOfDayOn = true

    @State private var breakfastTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var lunchTime = Calendar.current.date(from: DateComponents(hour: 12, minute: 30)) ?? Date()
    @State private var dinnerTime = Calendar.current.date(from: DateComponents(hour: 18, minute: 30)) ?? Date()
    @State private var snackTime = Calendar.current.date(from: DateComponents(hour: 15, minute: 0)) ?? Date()

    @State private var selectedReminder: ReminderID?

    private struct ReminderID: Identifiable {
        let id: String
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Meal Reminders
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Meal reminders")
                        .font(DesignTokens.Typography.medium(13))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)

                    reminderRow(title: "Breakfast", time: breakfastTime, isOn: $breakfastOn, id: "breakfast")
                    reminderRow(title: "Lunch", time: lunchTime, isOn: $lunchOn, id: "lunch")
                    reminderRow(title: "Dinner", time: dinnerTime, isOn: $dinnerOn, id: "dinner")
                    reminderRow(title: "Snack", time: snackTime, isOn: $snackOn, id: "snack")
                }

                // End of Day
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("End of day")
                        .font(DesignTokens.Typography.medium(13))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)

                    HStack {
                        Text("End of Day Summary")
                            .font(DesignTokens.Typography.bodyFont(16))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        Spacer()

                        Toggle("", isOn: $endOfDayOn)
                            .labelsHidden()
                            .tint(DesignTokens.Colors.brandAccent)
                    }
                    .padding(DesignTokens.Spacing.md)
                    .background(DesignTokens.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Tracking Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedReminder) { reminder in
            timePickerSheet(for: reminder.id)
                .presentationDetents([.height(320)])
        }
    }

    private func reminderRow(title: String, time: Date, isOn: Binding<Bool>, id: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignTokens.Typography.medium(16))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Text(time, format: .dateTime.hour().minute())
                    .font(DesignTokens.Typography.bodyFont(13))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(DesignTokens.Colors.brandAccent)
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        .contentShape(Rectangle())
        .onTapGesture {
            selectedReminder = ReminderID(id: id)
        }
    }

    @ViewBuilder
    private func timePickerSheet(for reminder: String) -> some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select Time",
                    selection: bindingForReminder(reminder),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
            }
            .navigationTitle("\(reminder.capitalized) Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectedReminder = nil
                    }
                }
            }
        }
    }

    private func bindingForReminder(_ id: String) -> Binding<Date> {
        switch id {
        case "breakfast": return $breakfastTime
        case "lunch": return $lunchTime
        case "dinner": return $dinnerTime
        case "snack": return $snackTime
        default: return $breakfastTime
        }
    }
}

