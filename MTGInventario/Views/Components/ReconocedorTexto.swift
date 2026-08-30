import Vision
import UIKit

/// Equivalente a la parte de ML Kit de `EscanearScreen.kt`.
///
/// Android lanzaba 4 reconocedores en paralelo (latino, japonés, chino,
/// coreano) porque el ML Kit de Google no es multi-idioma en una sola
/// pasada. El framework Vision de Apple SÍ soporta varios idiomas en una
/// misma petición (`recognitionLanguages`), así que aquí basta una sola
/// pasada -- es más simple que el original, no una limitación.
///
/// Igual que en Android: las líneas se devuelven ordenadas de mayor a menor
/// tamaño de letra, porque en una carta de Magic el nombre siempre se
/// imprime en el tipo más grande de toda la carta.
enum ReconocedorTexto {
    static func reconocer(en imagen: UIImage) async -> [String] {
        guard let cgImage = imagen.cgImage else { return [] }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil, let resultados = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                var alturaPorLinea: [String: CGFloat] = [:]
                var ordenLineas: [String] = []
                for observacion in resultados {
                    guard let mejor = observacion.topCandidates(1).first else { continue }
                    let contenido = mejor.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard (2...40).contains(contenido.count) else { continue }
                    // El bounding box de Vision viene normalizado (0...1)
                    // respecto a la imagen; usamos su altura como
                    // aproximación del tamaño de letra, igual que
                    // `boundingBox?.height()` en píxeles en la versión
                    // Android.
                    let alto = observacion.boundingBox.height
                    if let previo = alturaPorLinea[contenido] {
                        if alto > previo { alturaPorLinea[contenido] = alto }
                    } else {
                        alturaPorLinea[contenido] = alto
                        ordenLineas.append(contenido)
                    }
                }

                let ordenadas = ordenLineas.sorted { (alturaPorLinea[$0] ?? 0) > (alturaPorLinea[$1] ?? 0) }
                continuation.resume(returning: ordenadas)
            }

            request.recognitionLevel = .accurate
            // Idiomas cubiertos por la versión Android (latino + japonés +
            // chino + coreano), más algunos europeos habituales en cartas
            // de Magic. Vision solo usa los que soporta el dispositivo/iOS
            // instalado; el resto los ignora sin fallar.
            request.recognitionLanguages = ["en-US", "es-ES", "de-DE", "fr-FR", "it-IT", "pt-PT", "ja-JP", "ko-KR", "zh-Hans", "zh-Hant"]
            if #available(iOS 16.0, *) {
                request.automaticallyDetectsLanguage = true
            }
            request.usesLanguageCorrection = false

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }
}
