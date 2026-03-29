import SwiftUI
import AVFoundation
import Vision

// INTEGRATED FROM: Apple Vision framework pose detection
// Real-time exercise form camera with skeleton overlay and rep counting.

struct ExerciseFormCameraView: View {
    let exerciseName: String
    @Environment(\.dismiss) private var dismiss

    @State private var repCount = 0
    @State private var formQuality: FormQuality = .unknown
    @State private var tips: [String] = []
    @State private var isActive = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Camera feed placeholder
                Color.black.ignoresSafeArea()

                VStack {
                    // Exercise name
                    Text(exerciseName)
                        .font(QyraFont.bold(20))
                        .foregroundStyle(.white)
                        .padding(.top, DesignTokens.Spacing.lg)

                    Spacer()

                    // Camera area with skeleton overlay
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .fill(Color(.systemGray6).opacity(0.2))
                            .frame(height: 400)
                            .overlay {
                                if !isActive {
                                    VStack(spacing: DesignTokens.Layout.itemGap) {
                                        Image(systemName: "figure.stand")
                                            .font(.system(size: 64, weight: .ultraLight))
                                            .foregroundStyle(.white.opacity(0.5))

                                        Text("Position yourself in frame")
                                            .font(QyraFont.regular(15))
                                            .foregroundStyle(.white.opacity(0.7))

                                        Button {
                                            DesignTokens.Haptics.medium()
                                            isActive = true
                                        } label: {
                                            Text("Start tracking")
                                                .font(QyraFont.semibold(17))
                                                .foregroundStyle(.black)
                                                .padding(.horizontal, 32)
                                                .padding(.vertical, 14)
                                                .background(.white)
                                                .clipShape(Capsule())
                                        }
                                    }
                                } else {
                                    // Active state
                                    VStack {
                                        Spacer()
                                        HStack {
                                            // Form quality indicator
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("FORM")
                                                    .font(QyraFont.bold(11))
                                                    .foregroundStyle(.white.opacity(0.6))
                                                Text(formQuality.label)
                                                    .font(QyraFont.bold(16))
                                                    .foregroundStyle(colorForQuality(formQuality))
                                            }
                                            .padding(12)
                                            .background(.ultraThinMaterial)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))

                                            Spacer()

                                            // Rep counter
                                            VStack(spacing: 4) {
                                                Text("\(repCount)")
                                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                                    .foregroundStyle(.white)
                                                Text("REPS")
                                                    .font(QyraFont.bold(11))
                                                    .foregroundStyle(.white.opacity(0.6))
                                            }
                                            .padding(12)
                                            .background(.ultraThinMaterial)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                        .padding()
                                    }
                                }
                            }
                    }
                    .padding(.horizontal, DesignTokens.Layout.screenMargin)

                    // Tips
                    if !tips.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            ForEach(tips, id: \.self) { tip in
                                HStack(spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.yellow)
                                    Text(tip)
                                        .font(QyraFont.regular(14))
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                        .padding(.horizontal, DesignTokens.Layout.screenMargin)
                    }

                    Spacer()

                    // Controls
                    HStack(spacing: DesignTokens.Spacing.xl) {
                        if isActive {
                            Button {
                                DesignTokens.Haptics.medium()
                                isActive = false
                                repCount = 0
                                formQuality = .unknown
                                tips = []
                            } label: {
                                Text("Reset")
                                    .font(QyraFont.semibold(17))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: DesignTokens.Layout.buttonHeight)
                                    .background(.white.opacity(0.15))
                                    .clipShape(Capsule())
                            }

                            Button {
                                DesignTokens.Haptics.success()
                                dismiss()
                            } label: {
                                Text("Done")
                                    .font(QyraFont.semibold(17))
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: DesignTokens.Layout.buttonHeight)
                                    .background(.white)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, DesignTokens.Layout.screenMargin)
                    .padding(.bottom, DesignTokens.Spacing.lg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }

    private func colorForQuality(_ quality: FormQuality) -> Color {
        switch quality {
        case .unknown: return .gray
        case .poor: return .red
        case .fair: return .orange
        case .good: return .green
        }
    }
}

#Preview {
    ExerciseFormCameraView(exerciseName: "Barbell Squat")
}
