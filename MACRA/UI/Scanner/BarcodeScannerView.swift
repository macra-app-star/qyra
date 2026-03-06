import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: BarcodeScannerViewModel?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let vm = viewModel {
                    if vm.isScanning {
                        scannerContent(vm)
                    } else if vm.isLookingUp {
                        LoadingOverlay(message: "Looking up product...")
                    } else if let product = vm.product {
                        BarcodeResultView(viewModel: vm, product: product)
                    } else if let error = vm.errorMessage {
                        errorContent(error, vm: vm)
                    }
                }
            }
            .navigationTitle("Scan Barcode")
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
    }

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
                .font(.system(size: 48))
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

// MARK: - Barcode Scanner UIViewRepresentable

struct BarcodeScannerPreview: UIViewRepresentable {
    let onBarcodeDetected: (String) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let session = AVCaptureSession()

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else { return view }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(context.coordinator, queue: .main)
            output.metadataObjectTypes = [.ean8, .ean13, .upce, .code128, .code39, .interleaved2of5]
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        context.coordinator.session = session

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcodeDetected: onBarcodeDetected)
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.session?.stopRunning()
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var previewLayer: AVCaptureVideoPreviewLayer?
        var session: AVCaptureSession?
        let onBarcodeDetected: (String) -> Void
        private var lastDetected: String?

        init(onBarcodeDetected: @escaping (String) -> Void) {
            self.onBarcodeDetected = onBarcodeDetected
        }

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
            onBarcodeDetected(value)
        }
    }
}
