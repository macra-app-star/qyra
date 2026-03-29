import SwiftUI

struct PhoneMockupView: View {
    @State private var currentSlide = 0
    private let slideCount = 3
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Phone frame (black)
            RoundedRectangle(cornerRadius: OnboardingTheme.phoneMockupCornerRadius)
                .fill(Color.black)
                .frame(
                    width: OnboardingTheme.phoneMockupWidth,
                    height: OnboardingTheme.phoneMockupHeight
                )
                .onboardingShadow(OnboardingTheme.phoneShadow)

            // Inner screen (white)
            RoundedRectangle(cornerRadius: OnboardingTheme.phoneMockupInnerRadius)
                .fill(Color.white)
                .frame(
                    width: OnboardingTheme.phoneMockupWidth - 16,
                    height: OnboardingTheme.phoneMockupHeight - 16
                )
                .overlay {
                    // Screen content
                    ZStack {
                        slideContent(for: currentSlide)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: OnboardingTheme.phoneMockupInnerRadius))
                    .animation(.easeInOut(duration: 0.5), value: currentSlide)
                }

            // Dynamic Island
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black)
                .frame(width: 90, height: 24)
                .offset(y: -(OnboardingTheme.phoneMockupHeight / 2 - 22))
        }
        .onReceive(timer) { _ in
            currentSlide = (currentSlide + 1) % slideCount
        }
    }

    @ViewBuilder
    private func slideContent(for index: Int) -> some View {
        switch index {
        case 0:
            cameraScanSlide
        case 1:
            dashboardSlide
        case 2:
            nutritionDetailSlide
        default:
            EmptyView()
        }
    }

    // MARK: - Slide 1: Camera Scan

    private var cameraScanSlide: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "8B7355"), Color(hex: "5A4A3A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Scan corners
            VStack {
                HStack {
                    scanCorner(rotation: 0)
                    Spacer()
                    scanCorner(rotation: 90)
                }
                Spacer()
                HStack {
                    scanCorner(rotation: 270)
                    Spacer()
                    scanCorner(rotation: 180)
                }
            }
            .padding(40)

            // Bottom toolbar
            VStack {
                Spacer()
                HStack {
                    Text("Scan Food")
                        .font(QyraFont.medium(12))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.bottom, 16)

                // Shutter button
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 44, height: 44)
                    .padding(.bottom, 12)
            }
        }
    }

    private func scanCorner(rotation: Double) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 0))
        }
        .stroke(Color.white, lineWidth: 3)
        .frame(width: 30, height: 30)
        .rotationEffect(.degrees(rotation))
    }

    // MARK: - Slide 2: Dashboard

    private var dashboardSlide: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Qyra")
                    .font(QyraFont.bold(14))
                    .foregroundStyle(OnboardingTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 32)

            // Calorie card
            VStack(spacing: 4) {
                Text("1739")
                    .font(QyraFont.bold(28))
                    .foregroundStyle(OnboardingTheme.textPrimary)
                Text("Calories left")
                    .font(QyraFont.regular(9))
                    .foregroundStyle(OnboardingTheme.textSecondary)
            }
            .padding(.vertical, 8)

            // Macro pills
            HStack(spacing: 6) {
                macroPill(label: "136g", color: OnboardingTheme.macroProtein)
                macroPill(label: "206g", color: OnboardingTheme.macroCarbs)
                macroPill(label: "41g", color: OnboardingTheme.macroFat)
            }
            .padding(.horizontal, 12)

            Spacer()
        }
    }

    private func macroPill(label: String, color: Color) -> some View {
        Text(label)
            .font(QyraFont.semibold(9))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Slide 3: Nutrition Detail

    private var nutritionDetailSlide: some View {
        VStack(spacing: 0) {
            // Food photo placeholder
            Rectangle()
                .fill(Color(hex: "D4A574"))
                .frame(height: 140)

            // Detail card
            VStack(alignment: .leading, spacing: 8) {
                Text("Grilled Chicken Salad")
                    .font(QyraFont.semibold(12))
                    .foregroundStyle(OnboardingTheme.textPrimary)

                HStack(spacing: 8) {
                    nutrientBox(value: "320", label: "cal", color: OnboardingTheme.accentGreen)
                    nutrientBox(value: "28g", label: "protein", color: OnboardingTheme.macroProtein)
                    nutrientBox(value: "18g", label: "carbs", color: OnboardingTheme.macroCarbs)
                    nutrientBox(value: "14g", label: "fat", color: OnboardingTheme.macroFat)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(
                UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16)
            )
            .offset(y: -16)

            Spacer()
        }
    }

    private func nutrientBox(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(QyraFont.bold(10))
                .foregroundStyle(color)
            Text(label)
                .font(QyraFont.regular(7))
                .foregroundStyle(OnboardingTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    ZStack {
        Color.white.ignoresSafeArea()
        PhoneMockupView()
    }
}
