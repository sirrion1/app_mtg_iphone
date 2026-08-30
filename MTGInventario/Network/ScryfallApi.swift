import Foundation
import os.log

/// Equivalente a `ScryfallApi.kt`. Usa `URLSession` (el "OkHttp" de iOS) y
/// `JSONSerialization` (el "org.json" de iOS) para no depender de que el
/// JSON de Scryfall encaje perfecto en un `Codable` estricto -- muchos
/// campos son opcionales o solo existen en ciertas cartas.
enum ScryfallApi {
    private static let log = Logger(subsystem: "com.mtginventario.app", category: "ScryfallApi")
    private static let base = "https://api.scryfall.com"

    // Scryfall rechaza con 400 (generic_user_agent) cualquier petición que
    // llegue con el User-Agent por defecto de la librería HTTP. Hay que
    // identificarse con uno propio, y ellos piden explícitamente cabecera
    // Accept para forzar la respuesta en JSON.
    private static let userAgent = "MTGInventarioApp/1.0 (iOS; personal use)"

    private static var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 10
        return URLSession(configuration: config)
    }()

    private static func request(url: URL) -> URLRequest {
        var req = URLRequest(url: url)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        return req
    }

    /// Busca sugerencias de nombre mientras el usuario escribe (typeahead) o
    /// justo después de escanear una carta con la cámara.
    ///
    /// Camino rápido: /cards/autocomplete, pensado específicamente para esto
    /// (nunca da error por texto corto o raro). El problema es que SOLO
    /// conoce nombres en inglés (así lo dice la propia documentación de
    /// Scryfall), así que con una carta en japonés, alemán, etc. nunca
    /// encuentra nada aunque la carta exista.
    ///
    /// Si el camino rápido no da resultados, probamos con /cards/search y
    /// lang:any, que sí compara también contra el nombre impreso
    /// (printed_name) de cada idioma.
    static func buscarPorTexto(_ fragmento: String) async -> [Sugerencia] {
        guard fragmento.count >= 2 else { return [] }

        let enIngles = await autocompletarIngles(fragmento)
        if !enIngles.isEmpty {
            return enIngles.map { Sugerencia(textoMostrado: $0, nombreOracle: $0, lang: "en") }
        }
        return await buscarPorTextoMultilingue(fragmento)
    }

    private static func autocompletarIngles(_ fragmento: String) async -> [String] {
        guard var comps = URLComponents(string: "\(base)/cards/autocomplete") else { return [] }
        comps.queryItems = [URLQueryItem(name: "q", value: fragmento)]
        guard let url = comps.url else { return [] }

        do {
            let (data, response) = try await session.data(for: request(url: url))
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                log.warning("autocomplete '\(fragmento, privacy: .public)' -> HTTP fallo")
                return []
            }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["data"] as? [String] else { return [] }
            var vistos = Set<String>()
            var resultado: [String] = []
            for item in items {
                if vistos.insert(item).inserted {
                    resultado.append(item)
                    if resultado.count >= 15 { break }
                }
            }
            return resultado
        } catch {
            // Si esto aparece en consola como "no está resolviendo DNS" o
            // "no route to host", revisa la conexión Wi-Fi/datos del
            // dispositivo. Un timeout suele indicar tráfico bloqueado o
            // muy lento.
            log.error("Fallo en autocompletarIngles('\(fragmento, privacy: .public)'): \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    private static func buscarPorTextoMultilingue(_ fragmento: String) async -> [Sugerencia] {
        let query = "\(fragmento) lang:any"
        guard var comps = URLComponents(string: "\(base)/cards/search") else { return [] }
        comps.queryItems = [URLQueryItem(name: "q", value: query), URLQueryItem(name: "order", value: "name")]
        guard let url = comps.url else { return [] }

        do {
            let (data, response) = try await session.data(for: request(url: url))
            guard let http = response as? HTTPURLResponse else { return [] }
            // Scryfall responde 404 cuando la búsqueda no encuentra ninguna
            // carta: es la respuesta normal de "sin resultados", no un
            // fallo real.
            if http.statusCode == 404 { return [] }
            guard (200...299).contains(http.statusCode) else {
                log.warning("buscarPorTextoMultilingue '\(fragmento, privacy: .public)' -> HTTP \(http.statusCode)")
                return []
            }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let cartas = json["data"] as? [[String: Any]] else { return [] }

            // La misma carta puede aparecer varias veces (una impresión por
            // edición e idioma que contenga el texto buscado); nos quedamos
            // con una sugerencia por nombre de carta (en inglés), con la
            // primera coincidencia que llega.
            var vistos = Set<String>()
            var resultado: [Sugerencia] = []
            for carta in cartas {
                if resultado.count >= 15 { break }
                guard let nombreOracle = carta["name"] as? String, !nombreOracle.isEmpty,
                      vistos.insert(nombreOracle).inserted else { continue }
                let lang = (carta["lang"] as? String) ?? "en"
                let nombreImpreso = carta["printed_name"] as? String
                let texto: String
                if lang != "en", let nombreImpreso, !nombreImpreso.isEmpty {
                    texto = "\(nombreImpreso) (\(nombreOracle))"
                } else {
                    texto = nombreOracle
                }
                resultado.append(Sugerencia(textoMostrado: texto, nombreOracle: nombreOracle, lang: lang))
            }
            return resultado
        } catch {
            log.error("Fallo en buscarPorTextoMultilingue('\(fragmento, privacy: .public)'): \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    /// URL del icono SVG de una edición, publicado por Scryfall para cada set.
    private static func iconoEdicion(_ setCode: String) -> String {
        "https://svgs.scryfall.io/sets/\(setCode).svg"
    }

    /// Devuelve todas las ediciones (impresiones) publicadas de una carta con
    /// nombre exacto, incluyendo impresiones en otros idiomas
    /// (`include_multilingual=true` y `lang:any`).
    ///
    /// `idiomaPreferido`: idioma detectado al escanear/buscar la carta (p.
    /// ej. "ja", "es"). Cuando una edición tiene impresión tanto en ese
    /// idioma como en inglés, se queda con la del idioma preferido en vez de
    /// forzar siempre inglés.
    static func buscarImpresiones(nombreExacto: String, idiomaPreferido: String? = nil) async -> [Impresion] {
        let query = "!\"\(nombreExacto)\" lang:any"
        guard var comps = URLComponents(string: "\(base)/cards/search") else { return [] }
        comps.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "unique", value: "prints"),
            URLQueryItem(name: "order", value: "released"),
            URLQueryItem(name: "include_multilingual", value: "true")
        ]
        guard var urlPagina = comps.url else { return [] }

        var todas: [Impresion] = []
        var paginas = 0
        // Scryfall pagina /cards/search de 175 en 175 (has_more + next_page).
        // Límite de 10 páginas (1750 impresiones) como tope de seguridad.
        while paginas < 10 {
            paginas += 1
            do {
                let (data, response) = try await session.data(for: request(url: urlPagina))
                guard let http = response as? HTTPURLResponse else { break }
                if http.statusCode == 404 { break }
                guard (200...299).contains(http.statusCode) else {
                    log.warning("buscarImpresiones '\(nombreExacto, privacy: .public)' -> HTTP \(http.statusCode)")
                    break
                }
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let cartas = json["data"] as? [[String: Any]] else { break }

                for carta in cartas {
                    // Las cartas de doble cara (transform, modal DFC...) no
                    // traen "image_uris" en la raíz: cada cara tiene la suya
                    // dentro de "card_faces". Sin este fallback, esas
                    // impresiones se quedaban sin miniatura.
                    var imageUris = carta["image_uris"] as? [String: Any]
                    if imageUris == nil,
                       let caras = carta["card_faces"] as? [[String: Any]],
                       let primera = caras.first {
                        imageUris = primera["image_uris"] as? [String: Any]
                    }
                    let setCode = (carta["set"] as? String) ?? ""
                    let lang = (carta["lang"] as? String) ?? "en"
                    let imageUrl = (imageUris?["small"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                        ?? (imageUris?["normal"] as? String).flatMap { $0.isEmpty ? nil : $0 }

                    let nombreLocalizado: String?
                    if let printedName = carta["printed_name"] as? String, !printedName.isEmpty {
                        nombreLocalizado = printedName
                    } else if lang != "en" {
                        nombreLocalizado = carta["name"] as? String
                    } else {
                        nombreLocalizado = nil
                    }

                    todas.append(Impresion(
                        setCode: setCode,
                        setName: (carta["set_name"] as? String) ?? "",
                        imageUrl: imageUrl,
                        foilDisponible: (carta["foil"] as? Bool) ?? false,
                        normalDisponible: (carta["nonfoil"] as? Bool) ?? false,
                        lang: lang,
                        nombreLocalizado: nombreLocalizado,
                        iconoEdicionUrl: iconoEdicion(setCode)
                    ))
                }

                if (json["has_more"] as? Bool) == true,
                   let nextPage = json["next_page"] as? String, !nextPage.isEmpty,
                   let nextUrl = URL(string: nextPage) {
                    urlPagina = nextUrl
                } else {
                    break
                }
            } catch {
                log.error("Fallo en buscarImpresiones('\(nombreExacto, privacy: .public)'): \(error.localizedDescription, privacy: .public)")
                break
            }
        }

        // Una carta+edición puede venir repetida por cada idioma en el que
        // se imprimió. Nos quedamos con una sola fila por edición
        // (setCode): preferimos el idioma detectado al escanear si esa
        // edición lo tiene; si no, inglés; si tampoco hay inglés, la
        // primera impresión que aparezca.
        func prioridad(_ lang: String) -> Int {
            if lang == idiomaPreferido { return 0 }
            if lang == "en" { return 1 }
            return 2
        }
        var porEdicion: [String: Impresion] = [:]
        var ordenEdiciones: [String] = []
        for impresion in todas {
            if let actual = porEdicion[impresion.setCode] {
                if prioridad(impresion.lang) < prioridad(actual.lang) {
                    porEdicion[impresion.setCode] = impresion
                }
            } else {
                porEdicion[impresion.setCode] = impresion
                ordenEdiciones.append(impresion.setCode)
            }
        }
        return ordenEdiciones.compactMap { porEdicion[$0] }
    }
}
