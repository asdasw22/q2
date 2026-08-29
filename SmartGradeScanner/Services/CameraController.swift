import AVFoundation
import SwiftUI
import UIKit
import Combine

final class CameraController: NSObject, ObservableObject {
    @Published var authorizationStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @Published var isSessionRunning = false
    @Published var errorMessage: String?
    @Published var capturedImage: UIImage?

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "smartgrade.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var isConfigured = false

    func requestPermissionAndStart() {
        let current = AVCaptureDevice.authorizationStatus(for: .video)
        authorizationStatus = current
        switch current {
        case .authorized:
            start()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    self?.authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
                    if granted { self?.start() } else { self?.errorMessage = "لم يتم منح إذن الكاميرا. فعّل الإذن من إعدادات iOS." }
                }
            }
        case .denied, .restricted:
            errorMessage = "إذن الكاميرا مرفوض. افتح Settings > SmartGrade Scanner وفعّل Camera."
        @unknown default:
            errorMessage = "تعذر معرفة حالة إذن الكاميرا."
        }
    }

    func start() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            do {
                try self.configureIfNeeded()
                if !self.session.isRunning { self.session.startRunning() }
                DispatchQueue.main.async { self.isSessionRunning = true; self.errorMessage = nil }
            } catch {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription; self.isSessionRunning = false }
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
            DispatchQueue.main.async { self.isSessionRunning = false }
        }
    }

    func capturePhoto() {
        guard authorizationStatus == .authorized else { requestPermissionAndStart(); return }
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    private func configureIfNeeded() throws {
        guard !isConfigured else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) ?? AVCaptureDevice.default(for: .video) else {
            session.commitConfiguration()
            throw CameraError.noCamera
        }
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            session.commitConfiguration()
            throw CameraError.cannotAddInput
        }
        session.addInput(input)

        guard session.canAddOutput(photoOutput) else {
            session.commitConfiguration()
            throw CameraError.cannotAddOutput
        }
        session.addOutput(photoOutput)
        photoOutput.isHighResolutionCaptureEnabled = true
        session.commitConfiguration()
        isConfigured = true
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            Task { @MainActor in self.errorMessage = error.localizedDescription }
            return
        }
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            Task { @MainActor in self.errorMessage = "تعذر تحويل لقطة الكاميرا إلى صورة." }
            return
        }
        Task { @MainActor in self.capturedImage = image }
    }
}

enum CameraError: LocalizedError {
    case noCamera, cannotAddInput, cannotAddOutput
    var errorDescription: String? {
        switch self {
        case .noCamera: return "لم يتم العثور على كاميرا في هذا الجهاز."
        case .cannotAddInput: return "تعذر تهيئة مدخل الكاميرا."
        case .cannotAddOutput: return "تعذر تهيئة مخرج التقاط الصور."
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

