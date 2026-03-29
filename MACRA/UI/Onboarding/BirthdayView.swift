import SwiftUI

struct BirthdayView: View {
    @Bindable var viewModel: OnboardingViewModel

    private let monthNames = [
        "January", "February", "March", "April",
        "May", "June", "July", "August",
        "September", "October", "November", "December"
    ]

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTitle(text: "When were you born?")
                .padding(.top, DesignTokens.Spacing.lg)
                .fixedSize(horizontal: false, vertical: true)

            OnboardingSubtitle(text: "This will be used to calibrate your custom plan.")

            Spacer()

            // 3-column native pickers
            HStack(spacing: 0) {
                // Month
                Picker("Month", selection: $viewModel.birthMonth) {
                    ForEach(1...12, id: \.self) { month in
                        Text(monthNames[month - 1]).tag(month)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                // Day
                Picker("Day", selection: $viewModel.birthDay) {
                    ForEach(1...31, id: \.self) { day in
                        Text("\(day)").tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                // Year
                Picker("Year", selection: $viewModel.birthYear) {
                    ForEach(1940...2010, id: \.self) { year in
                        Text("\(year)").tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
            }
            .frame(height: 180)
            .padding(.horizontal, DesignTokens.Spacing.sm)

            Spacer()

            OnboardingContinueButton(isEnabled: true) {
                viewModel.advance()
            }
        }
    }
}

#Preview {
    BirthdayView(viewModel: OnboardingViewModel.preview)
}
