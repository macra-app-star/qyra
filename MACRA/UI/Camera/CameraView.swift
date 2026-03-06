import SwiftUI
import AVFoundation

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var cameraVM = CameraViewModel()
    @State private var hasPermission = false
    @State private var showAnalysis = false
    @State private var capturedData: Data?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if hasPermission {
                cameraContent
            } else {
                permissionDeniedView
            }
        }
        .statusBarHidden()
        .task {
            hasPermission = await CameraViewModel.checkPermission()
            if hasPermission {
                cameraVM.setupCamera()
            }
        }
        .onDisappear {
            cameraVM.stopCamera()
        }
        .fullScreenCover(isPresented: $showAnalysis) {
            if let data = capturedData {
                PhotoAnalysisView(
                    imageData: data,
                    modelContainer: modelContext.container
                )
            }
        }
    }

    // MARK: - Camera Content

    private var cameraContent: some View {
        ZStack {
            CameraPreviewView(session: cameraVM.session)
                .ignoresSafeArea()

            VStack {
                // Top bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    Button {
                        cameraVM.isFlashOn.toggle()
                    } label: {
                        Image(systemName: cameraVM.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(cameraVM.isFlashOn ? .yellow : .white)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.top, DesignTokens.Spacing.sm)

                Spacer()

                // Instruction
                Text("Point at your food")
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.bottom, DesignTokens.Spacing.md)

                // Bottom controls
                HStack(spacing: 60) {
                    // Gallery placeholder
                    Color.clear.frame(width: 44, height: 44)

                    // Capture button
                    Button {
                        Task {
                            if let data = await cameraVM.capturePhoto() {
                                capturedData = data
                                DesignTokens.Haptics.medium()
                                showAnalysis = true
                            }
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(.white, lineWidth: 4)
                                .frame(width: 72, height: 72)

                            Circle()
                                .fill(.white)
                                .frame(width: 60, height: 60)
                        }
                    }
                    .disabled(cameraVM.isCapturing)

                    // Flip camera
                    Button {
                        cameraVM.flipCamera()
                    } label: {
                        Image(systemName: "camera.rotate.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            Text("Camera Access Required")
                .font(DesignTokens.Typography.title2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text("Enable camera access in Settings to scan food.")
                .font(DesignTokens.Typography.callout)
                .foregroundStyle(DesignTokens.Colors.textTertiary)
                .multilineTextAlignment(.center)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(DesignTokens.Typography.headline)
            .foregroundStyle(DesignTokens.Colors.accent)

            Button("Close") { dismiss() }
                .font(DesignTokens.Typography.callout)
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .padding(DesignTokens.Spacing.xl)
    }
}

// MARK: - Camera Preview UIViewRepresentable

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}
