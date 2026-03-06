import SwiftUI

struct WaveformView: View {
    let isRecording: Bool
    let barCount: Int

    @State private var levels: [CGFloat]

    init(isRecording: Bool, barCount: Int = 20) {
        self.isRecording = isRecording
        self.barCount = barCount
        _levels = State(initialValue: Array(repeating: 0.1, count: barCount))
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(DesignTokens.Colors.accent)
                    .frame(width: 4, height: isRecording ? levels[index] * 40 + 4 : 4)
                    .animation(
                        .easeInOut(duration: 0.15).delay(Double(index) * 0.02),
                        value: levels
                    )
            }
        }
        .frame(height: 48)
        .onChange(of: isRecording) { _, recording in
            if recording {
                startAnimating()
            } else {
                levels = Array(repeating: 0.1, count: barCount)
            }
        }
        .onAppear {
            if isRecording { startAnimating() }
        }
    }

    private func startAnimating() {
        guard isRecording else { return }
        withAnimation {
            levels = (0..<barCount).map { _ in CGFloat.random(in: 0.2...1.0) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            startAnimating()
        }
    }
}
