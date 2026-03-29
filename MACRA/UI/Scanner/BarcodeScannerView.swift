import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: BarcodeScannerViewModel?
    @State private var selectedMode: ScanMode = .scanFood
    @State private var cameraVM = CameraViewModel()
    @State private var showPhotoAnalysis = false
    @State private var capturedImageData: Data?

    enum ScanMode: String, CaseIterable {
        case scanFood
        case barcode

        var title: String {
            switch self {
            case .scanFood: return "Scan Food"
            case .barcode: return "Barcode"
            }
        }

        var icon: String {
            switch self {
            case .scanFood: return "camera"
            case .barcode: return "barcode.viewfinder"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                // Camera content — fills entire screen
                ZStack {
                    switch selectedMode {
                    case .barcode:
                        barcodeContent
                    case .scanFood:
                        foodCameraContent
                    }
                }
                .ignoresSafeArea()

                // Mode selector — floats on top with translucent background
                VStack {
                    modeTabs
                        .padding(.top, DesignTokens.Spacing.sm)
                        .padding(.bottom, DesignTokens.Spacing.sm)
                        .background(.ultraThinMaterial)

                    Spacer()
                }
            }
            .navigationTitle("Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                if viewModel == nil {
                    viewModel = BarcodeScannerViewModel(modelContainer: modelContext.container)
                }
            }
            .onChange(of: viewModel?.didSave ?? false) { _, saved in
                if saved {
                    DesignTokens.Haptics.success()
                    dismiss()
                }
            }
        }
        .tint(.accentColor)
    }

    // MARK: - Mode Tabs

    private var modeTabs: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(ScanMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(DesignTokens.Anim.quick) {
                        selectedMode = mode
                    }
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: mode.icon)
                            .font(DesignTokens.Typography.icon(12))

                        Text(mode.title)
                            .font(DesignTokens.Typography.medium(13))
                    }
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                    .padding(.vertical, DesignTokens.Spacing.xs + 2)
                    .background(
                        selectedMode == mode
                            ? Color.white
                            : Color.white.opacity(0.15)
                    )
                    .foregroundStyle(
                        selectedMode == mode
                            ? Color.black
                            : Color.white.opacity(0.8)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    // MARK: - Barcode Content

    @ViewBuilder
    private var barcodeContent: some View {
        if let vm = viewModel {
            if vm.isScanning {
                #if targetEnvironment(simulator)
                simulatorBarcodeEntry(vm)
                #else
                scannerContent(vm)
                #endif
            } else if vm.isLookingUp {
                LoadingOverlay(message: "Looking up product...")
            } else if let analysis = vm.productAnalysis {
                // Rich product analysis view (Yuka-style)
                ProductAnalysisView(product: analysis)
            } else if let error = vm.errorMessage {
                errorContent(error, vm: vm)
            }
        }
    }

    // MARK: - Simulator Barcode Entry

    #if targetEnvironment(simulator)
    @State private var manualBarcode = ""

    private func simulatorBarcodeEntry(_ vm: BarcodeScannerViewModel) -> some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "barcode.viewfinder")
                .font(DesignTokens.Typography.icon(48))
                .foregroundStyle(DesignTokens.Colors.accent.opacity(0.6))

            Text("Simulator Mode")
                .font(DesignTokens.Typography.semibold(20))
                .foregroundStyle(.white)

            Text("Camera is unavailable on Simulator.\nEnter a barcode manually to test.")
                .font(DesignTokens.Typography.bodyFont(15))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.Spacing.xl)

            TextField("Enter barcode (e.g. 0049000006346)", text: $manualBarcode)
                .font(DesignTokens.Typography.bodyFont(16))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .padding(DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                .keyboardType(.numberPad)
                .padding(.horizontal, DesignTokens.Spacing.xl)

            MonochromeButton("Look Up Barcode", icon: "magnifyingglass", style: .primary) {
                let code = manualBarcode.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !code.isEmpty else { return }
                Task { await vm.onBarcodeDetected(code) }
            }
            .disabled(manualBarcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal, DesignTokens.Spacing.xl)
        }
    }
    #endif

    // MARK: - Food Camera Content

    private var foodCameraContent: some View {
        FoodCameraCapture(
            mode: selectedMode,
            onCapture: { data in
                capturedImageData = data
                showPhotoAnalysis = true
            }
        )
        .sheet(isPresented: $showPhotoAnalysis) {
            if let data = capturedImageData {
                PhotoAnalysisView(imageData: data, modelContainer: modelContext.container)
            }
        }
    }

    // MARK: - Scanner Content

    private func scannerContent(_ vm: BarcodeScannerViewModel) -> some View {
        ZStack {
            BarcodeScannerPreview { barcode in
                Task { await vm.onBarcodeDetected(barcode) }
            }
            .ignoresSafeArea()

            // Scanning overlay
            VStack {
                Spacer()

                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .stroke(DesignTokens.Colors.accent, lineWidth: 2)
                    .frame(width: 280, height: 160)
                    .overlay {
                        ScanLineView()
                    }

                Text("Align barcode within the frame")
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.top, DesignTokens.Spacing.md)

                Spacer()
            }
        }
    }

    private func errorContent(_ message: String, vm: BarcodeScannerViewModel) -> some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(QyraFont.regular(48))
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            Text(message)
                .font(DesignTokens.Typography.callout)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)

            MonochromeButton("Scan Again", icon: "barcode.viewfinder", style: .primary) {
                vm.rescan()
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
        }
        .padding(DesignTokens.Spacing.xl)
    }
}

// MARK: - Scan Line Animation

struct ScanLineView: View {
    @State private var offset: CGFloat = -60

    var body: some View {
        Rectangle()
            .fill(DesignTokens.Colors.accent.opacity(0.6))
            .frame(height: 2)
            .offset(y: offset)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    offset = 60
                }
            }
    }
}

// MARK: - Barcode Scanner UIViewRepresentable (fixed: layerClass pattern)

struct BarcodeScannerPreview: UIViewRepresentable {
    let onBarcodeDetected: (String) -> Void

    func makeUIView(context: Context) -> BarcodeHostView {
        let view = BarcodeHostView()
        view.previewLayer.videoGravity = .resizeAspectFill
        view.onBarcodeDetected = onBarcodeDetected
        return view
    }

    func updateUIView(_ uiView: BarcodeHostView, context: Context) {
        // Preview layer auto-resizes via layerClass
    }

    static func dismantleUIView(_ uiView: BarcodeHostView, coordinator: Coordinator) {
        uiView.stopSession()
    }

    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator {}

    /// UIView whose root layer IS the AVCaptureVideoPreviewLayer.
    /// Session starts in didMoveToWindow to ensure valid bounds.
    class BarcodeHostView: UIView, AVCaptureMetadataOutputObjectsDelegate {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer // swiftlint:disable:this force_cast
        }

        var onBarcodeDetected: ((String) -> Void)?
        private let session = AVCaptureSession()
        private let sessionQueue = DispatchQueue(label: "co.tamras.qyra.barcode.session")
        private var isConfigured = false
        private var lastDetected: String?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil {
                configureAndStart()
            }
        }

        private func configureAndStart() {
            guard !isConfigured else {
                sessionQueue.async { [session] in
                    if !session.isRunning { session.startRunning() }
                }
                return
            }

            previewLayer.session = session

            sessionQueue.async { [weak self] in
                guard let self else { return }

                session.beginConfiguration()
                session.sessionPreset = .photo

                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                      let input = try? AVCaptureDeviceInput(device: device),
                      session.canAddInput(input) else {
                    session.commitConfiguration()
                    return
                }

                session.addInput(input)

                let output = AVCaptureMetadataOutput()
                if session.canAddOutput(output) {
                    session.addOutput(output)
                    output.setMetadataObjectsDelegate(self, queue: .main)
                    output.metadataObjectTypes = [.ean8, .ean13, .upce, .code128, .code39, .interleaved2of5]
                }

                session.commitConfiguration()

                DispatchQueue.main.async {
                    self.isConfigured = true
                }

                session.startRunning()
            }
        }

        func stopSession() {
            sessionQueue.async { [session] in
                if session.isRunning { session.stopRunning() }
            }
        }

        // MARK: - AVCaptureMetadataOutputObjectsDelegate

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let value = object.stringValue,
                  value != lastDetected
            else { return }

            lastDetected = value
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onBarcodeDetected?(value)
        }
    }
}
