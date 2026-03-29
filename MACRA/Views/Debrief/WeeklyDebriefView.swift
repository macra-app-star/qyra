import SwiftUI
import UserNotifications

struct WeeklyDebriefView: View {
    let debrief: WeeklyDebrief

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    @State private var appeared: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var shareImage: UIImage?

    private let debriefBackground = Color(
        uiColor: UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 1)
    )

    var body: some View {
        ZStack {
            debriefBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.top, DesignTokens.Spacing.sm)

                // Card pager
                TabView(selection: $currentIndex) {
                    ForEach(Array(debrief.cards.enumerated()), id: \.element.id) { index, card in
                        DebriefCardView(
                            card: card,
                            isLastCard: index == debrief.cards.count - 1,
                            onShare: {
                                shareImage = generateShareImage()
                                if shareImage != nil {
                                    showShareSheet = true
                                }
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(DesignTokens.Anim.spring, value: currentIndex)
            }
        }
        .statusBarHidden(false)
        .preferredColorScheme(.dark)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(DesignTokens.Anim.standard) {
                appeared = true
            }
            configurePageIndicator()
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheetView(image: image)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Weekly Debrief")
                    .font(DesignTokens.Typography.semibold(18))
                    .foregroundColor(.white)

                Text(dateRangeString)
                    .font(DesignTokens.Typography.bodyFont(13))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(DesignTokens.Typography.icon(16))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Date Range

    private var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: debrief.weekStartDate)
        let end = formatter.string(from: debrief.weekEndDate)
        return "\(start) — \(end)"
    }

    // MARK: - Page Indicator

    private func configurePageIndicator() {
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.white
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.3)
    }

    // MARK: - Share Image

    @MainActor
    private func generateShareImage() -> UIImage? {
        let renderer = ImageRenderer(content:
            ZStack {
                debriefBackground

                VStack(spacing: 24) {
                    HStack(spacing: 0) {
                        Text("Qyra")
                            .font(DesignTokens.Typography.headlineFont(20))
                            .foregroundColor(.white.opacity(0.5))
                        Text("\u{00AE}")
                            .font(DesignTokens.Typography.bodyFont(10))
                            .foregroundColor(.white.opacity(0.5))
                            .baselineOffset(10)
                    }

                    if let adherenceCard = debrief.cards.first(where: { $0.type == .adherence }),
                       let metric = adherenceCard.metric {
                        Text(metric)
                            .font(DesignTokens.Typography.numeric(72))
                            .foregroundColor(.white)
                        Text("weekly tracking")
                            .font(DesignTokens.Typography.bodyFont(16))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    if let streakCard = debrief.cards.first(where: { $0.type == .streak }),
                       let streakMetric = streakCard.metric {
                        VStack(spacing: 4) {
                            Text(streakMetric)
                                .font(DesignTokens.Typography.numeric(36))
                                .foregroundColor(DesignTokens.Colors.accent)
                            Text("streak")
                                .font(DesignTokens.Typography.bodyFont(14))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .frame(width: 1080, height: 1920)
        )
        renderer.scale = 1.0
        return renderer.uiImage
    }
}

// MARK: - Share Sheet

private struct ShareSheetView: UIViewControllerRepresentable {
    let image: UIImage

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Notification Scheduling

func scheduleWeeklyDebriefNotification() {
    let content = UNMutableNotificationContent()
    content.title = "Your weekly debrief is ready"
    content.body = "See how your week went and set your focus for next week."
    content.sound = .default

    var dateComponents = DateComponents()
    dateComponents.weekday = 1 // Sunday
    dateComponents.hour = 19
    dateComponents.minute = 0

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    let request = UNNotificationRequest(identifier: "weekly_debrief", content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request)
}
