import SwiftUI
@preconcurrency import AVFoundation

/// Self-contained camera view for food/label scanning.
/// Manages its own AVCaptureSession with live preview and photo capture.
struct FoodCameraCapture: View {
    let mode: BarcodeScannerView.ScanMode
    let onCapture: (Data) -> Void

    @StateObject private var camera = FoodCameraModel()

    var body: some View {
        ZStack {
            // Live camera preview — fills entire view
            FoodCameraPreviewLayer(camera: camera)
                .ignoresSafeArea()

            // Capture UI floats on top
            VStack {
                Spacer()

                VStack(spacing: DesignTokens.Spacing.md) {
                    Text(mode == .scanFood ? "Point at food and tap to scan" : "Point at nutrition label and tap to scan")
                        .font(QyraFont.medium(14))
                        .foregroundStyle(.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.5), radius: 2)

                    Button {
                        DesignTokens.Haptics.medium()
                        camera.capturePhoto()
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
                    .disabled(camera.isCapturing)
                    .opacity(camera.isCapturing ? 0.5 : 1)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear { camera.configure() }
        .onDisappear { camera.stop() }
        .onChange(of: camera.capturedData) { _, data in
            if let data { onCapture(data) }
        }
    }
}

// MARK: - Camera Model

@MainActor
final class FoodCameraModel: NSObject, ObservableObject {
    @Published var isCapturing = false
    @Published var capturedData: Data?

    // nonisolated(unsafe) because AVCaptureSession is thread-safe
    // and must be accessed from the sessionQueue, not MainActor
    nonisolated(unsafe) let session = AVCaptureSession()
    nonisolated(unsafe) private let photoOutput = AVCapturePhotoOutput()
    private(set) var isConfigured = false
    private let sessionQueue = DispatchQueue(label: "co.tamras.qyra.camera.session")

    /// Configure the capture session (inputs + outputs) without starting it.
    /// Called from onAppear. The session will start when the preview view
    /// is added to the window hierarchy (via didMoveToWindow).
    func configure() {
        guard !isConfigured else { return }

        let captureSession = session
        let output = photoOutput
        sessionQueue.async {
            captureSession.beginConfiguration()
            captureSession.sessionPreset = .photo

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device),
                  captureSession.canAddInput(input) else {
                captureSession.commitConfiguration()
                return
            }

            captureSession.addInput(input)

            if captureSession.canAddOutput(output) {
                captureSession.addOutput(output)
            }

            captureSession.commitConfiguration()

            Task { @MainActor [weak self] in
                self?.isConfigured = true
            }
        }
    }

    /// Start the capture session. Called by the preview view after layout.
    func startSession() {
        guard isConfigured || !session.inputs.isEmpty else { return }
        let captureSession = session
        sessionQueue.async {
            if !captureSession.isRunning {
                captureSession.startRunning()
            }
        }
    }

    func stop() {
        let captureSession = session
        sessionQueue.async {
            if captureSession.isRunning { captureSession.stopRunning() }
        }
    }

    func capturePhoto() {
        guard !isCapturing else { return }
        isCapturing = true
        capturedData = nil

        var settings = AVCapturePhotoSettings()
        if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension FoodCameraModel: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let data = photo.fileDataRepresentation()
        Task { @MainActor in
            self.capturedData = data
            self.isCapturing = false
        }
    }
}

// MARK: - Preview Layer (UIViewRepresentable)

struct FoodCameraPreviewLayer: UIViewRepresentable {
    let camera: FoodCameraModel

    func makeUIView(context: Context) -> CameraHostView {
        let view = CameraHostView()
        view.previewLayer.session = camera.session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.onWindowAttach = { [weak camera] in
            // Start the session AFTER the view is in the window hierarchy
            // and has valid bounds — this prevents the black screen
            camera?.startSession()
        }
        return view
    }

    func updateUIView(_ uiView: CameraHostView, context: Context) {
        // If the session was configured after makeUIView, start it now
        if camera.isConfigured && !camera.session.isRunning {
            camera.startSession()
        }
    }

    /// UIView subclass whose root layer IS the AVCaptureVideoPreviewLayer.
    /// This guarantees the preview layer always matches the view's bounds —
    /// no manual frame management needed, no black screen from zero-frame layers.
    class CameraHostView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer // swiftlint:disable:this force_cast
        }

        var onWindowAttach: (() -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil {
                // View is now in the window hierarchy with valid bounds
                onWindowAttach?()
                onWindowAttach = nil // Only fire once
            }
        }
    }
}
