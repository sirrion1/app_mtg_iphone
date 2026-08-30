import AVFoundation
import UIKit

/// Equivalente a la parte de CameraX de `EscanearScreen.kt` (Preview +
/// ImageCapture + zoom óptico por pellizco + enfoque central antes de
/// disparar). En iOS el framework nativo de cámara es AVFoundation.
final class CameraController: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var device: AVCaptureDevice?
    private var captureCompletion: ((UIImage?) -> Void)?

    func configurar() {
        session.beginConfiguration()
        // MAXIMIZE_QUALITY en Android equivale aquí a .photo (prioriza
        // calidad de imagen fija sobre latencia de vídeo).
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }
        self.device = device

        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
        session.commitConfiguration()
    }

    func iniciar() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [session] in
            session.startRunning()
        }
    }

    func detener() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [session] in
            session.stopRunning()
        }
    }

    /// Zoom óptico por pellizco, equivalente a `detectTransformGestures` +
    /// `cameraControl.setZoomRatio` en la versión Android.
    func aplicarZoom(factor: CGFloat) {
        guard let device else { return }
        do {
            try device.lockForConfiguration()
            let nuevoFactor = min(max(factor, device.minAvailableVideoZoomFactor), device.maxAvailableVideoZoomFactor)
            device.videoZoomFactor = nuevoFactor
            device.unlockForConfiguration()
        } catch {
            // Sin soporte de zoom en este dispositivo: se ignora.
        }
    }

    var zoomActual: CGFloat { device?.videoZoomFactor ?? 1 }

    /// Enfoca y mide la exposición en el centro del encuadre, con un
    /// instante para asentarse antes de disparar -- igual que
    /// `FocusMeteringAction` + `delay(450)` en la versión Android.
    func enfocarCentro() async {
        guard let device, device.isFocusPointOfInterestSupported else { return }
        do {
            try device.lockForConfiguration()
            device.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
            device.focusMode = .autoFocus
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = CGPoint(x: 0.5, y: 0.5)
                device.exposureMode = .autoExpose
            }
            device.unlockForConfiguration()
        } catch {
            // Sin soporte de enfoque por puntos: se sigue con el
            // autoenfoque continuo por defecto.
        }
        try? await Task.sleep(nanoseconds: 450_000_000)
    }

    func capturarFoto() async -> UIImage? {
        await withCheckedContinuation { continuation in
            captureCompletion = { imagen in
                continuation.resume(returning: imagen)
            }
            let settings = AVCapturePhotoSettings()
            settings.photoQualityPrioritization = .quality
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation(), let imagen = UIImage(data: data) else {
            captureCompletion?(nil)
            captureCompletion = nil
            return
        }
        captureCompletion?(imagen)
        captureCompletion = nil
    }
}
