import SwiftUI
import AVFoundation

/// Envuelve `AVCaptureVideoPreviewLayer` para poder usarlo dentro de
/// SwiftUI (equivalente al `AndroidView { PreviewView(...) }` de la
/// versión Android). Incluye el gesto de pellizco para hacer zoom óptico.
struct CameraPreviewView: UIViewRepresentable {
    let controller: CameraController

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.videoPreviewLayer.session = controller.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill

        let pellizco = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.manejarPellizco(_:)))
        view.addGestureRecognizer(pellizco)
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller)
    }

    final class Coordinator: NSObject {
        let controller: CameraController
        private var zoomInicial: CGFloat = 1

        init(controller: CameraController) {
            self.controller = controller
        }

        @objc func manejarPellizco(_ gesto: UIPinchGestureRecognizer) {
            switch gesto.state {
            case .began:
                zoomInicial = controller.zoomActual
            case .changed:
                controller.aplicarZoom(factor: zoomInicial * gesto.scale)
            default:
                break
            }
        }
    }

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
