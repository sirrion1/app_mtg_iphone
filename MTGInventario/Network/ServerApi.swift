import Foundation
import os.log

/// Equivalente a `ServerApi.kt`: habla con tu propio servidor de
/// inventario en la red local.
enum ServerApi {
    private static let log = Logger(subsystem: "com.mtginventario.app", category: "ServerApi")

    private static var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 10
        return URLSession(configuration: config)
    }()

    enum Resultado {
        case ok(ResultadoEnvio)
        case error(String)
    }

    enum ResultadoConexion {
        case ok
        case error(String)
    }

    private static func trimEndSlash(_ url: String) -> String {
        var s = url
        while s.hasSuffix("/") { s.removeLast() }
        return s
    }

    /// Comprueba si el servidor configurado responde, para la pantalla de Ajustes.
    static func probarConexion(baseUrl: String) async -> ResultadoConexion {
        if baseUrl.trimmingCharacters(in: .whitespaces).isEmpty {
            return .error("Introduce primero una dirección de servidor")
        }
        guard let url = URL(string: "\(trimEndSlash(baseUrl))/api/ping") else {
            return .error("La dirección del servidor no es válida")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        do {
            let (_, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                return .error("Respuesta inesperada del servidor")
            }
            if (200...299).contains(http.statusCode) {
                return .ok
            } else {
                log.warning("probarConexion '\(baseUrl, privacy: .public)' -> HTTP \(http.statusCode)")
                return .error("El servidor respondió con error (\(http.statusCode))")
            }
        } catch let error as URLError where error.code == .timedOut {
            log.error("Timeout probando conexión a '\(baseUrl, privacy: .public)'")
            return .error("Tiempo de espera agotado. ¿Está el servidor encendido y en la misma red?")
        } catch {
            // El código de URLError es la pista clave:
            // .cannotConnectToHost = no hay nadie escuchando en esa IP:puerto.
            // .cannotFindHost / .dnsLookupFailed = no resuelve esa dirección.
            // .notConnectedToInternet = sin red / permiso de red local denegado.
            log.error("Fallo probando conexión a '\(baseUrl, privacy: .public)': \(error.localizedDescription, privacy: .public)")
            return .error("No se pudo conectar: \(error.localizedDescription)")
        }
    }

    static func enviarCarta(baseUrl: String, nombre: String, edicion: String, foil: Bool, idioma: String) async -> Resultado {
        guard let url = URL(string: "\(trimEndSlash(baseUrl))/api/carta") else {
            return .error("La dirección del servidor no es válida")
        }
        let cuerpo: [String: Any] = [
            "nombre": nombre,
            "edicion": edicion,
            "foil": foil,
            // Idioma de la impresión concreta elegida (lo trae Scryfall en
            // cada resultado de búsqueda, ej. "en", "ja", "es"...). El
            // servidor lo guarda tal cual para poder pintar la bandera
            // correspondiente en la app de escritorio.
            "idioma": idioma
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: cuerpo)
        } catch {
            return .error("No se pudo construir la petición")
        }

        do {
            let (data, response) = try await session.data(for: req)
            let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
            guard let http = response as? HTTPURLResponse else {
                return .error("Respuesta inesperada del servidor")
            }
            guard (200...299).contains(http.statusCode) else {
                let mensaje = (json?["error"] as? String) ?? "Error del servidor (\(http.statusCode))"
                return .error(mensaje)
            }
            guard let carta = json?["carta"] as? [String: Any] else {
                return .error("Respuesta del servidor sin datos de carta")
            }
            let resultado = ResultadoEnvio(
                status: (json?["status"] as? String) ?? "",
                nombre: (carta["nombre"] as? String) ?? "",
                edicion: (carta["edicion"] as? String) ?? "",
                idioma: carta["idioma"] as? String,
                color: carta["color"] as? String,
                precioEur: (carta["precio_eur"] as? Double) ?? (carta["precio_eur"] as? NSNumber)?.doubleValue,
                cantidad: (carta["cantidad"] as? Int) ?? 0
            )
            return .ok(resultado)
        } catch {
            log.error("Fallo enviando carta a '\(baseUrl, privacy: .public)': \(error.localizedDescription, privacy: .public)")
            return .error("No se pudo conectar con el servidor: \(error.localizedDescription)")
        }
    }
}
