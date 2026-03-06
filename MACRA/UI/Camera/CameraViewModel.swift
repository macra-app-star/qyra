import AVFoundation
import UIKit

@Observable
@MainActor
final class CameraViewModel: NSObject {
    var capturedPhoto: Data?
    var isFlashOn = false
    var isFrontCamera = false
    var errorMessage: String?
    var isCapturing = false

    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var continuation: CheckedContinuation<Data?, Never>?

    // MARK: - Session Setup

    var session: AVCaptureSession {
        if let existing = captureSession { return existing }
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        captureSession = session
        return session
    }

    func setupCamera() {
        let session = self.session

        guard let device = cameraDevice else {
            errorMessage = "Camera not available"
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }

            let output = AVCapturePhotoOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                photoOutput = output
            }

            Task.detached { [session] in
                session.startRunning()
            }
        } catch {
            errorMessage = "Failed to setup camera: \(error.localizedDescription)"
        }
    }

    func stopCamera() {
        Task.detached { [weak self] in
            await self?.captureSession?.stopRunning()
        }
    }

    // MARK: - Capture

    func capturePhoto() async -> Data? {
        guard let photoOutput, !isCapturing else { return nil }

        isCapturing = true

        return await withCheckedContinuation { cont in
            continuation = cont

            var settings = AVCapturePhotoSettings()
            if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            }

            if let device = cameraDevice, device.hasFlash {
                settings.flashMode = isFlashOn ? .on : .off
            }

            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    // MARK: - Camera Controls

    func flipCamera() {
        guard let session = captureSession else { return }

        isFrontCamera.toggle()

        session.beginConfiguration()
        for input in session.inputs {
            session.removeInput(input)
        }

        guard let device = cameraDevice,
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)
        session.commitConfiguration()
    }

    private var cameraDevice: AVCaptureDevice? {
        let position: AVCaptureDevice.Position = isFrontCamera ? .front : .back
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }

    static func checkPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
        default: return false
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let data = photo.fileDataRepresentation()
        Task { @MainActor in
            capturedPhoto = data
            isCapturing = false
            continuation?.resume(returning: data)
            continuation = nil
        }
    }
}
