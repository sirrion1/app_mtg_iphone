import SwiftUI
import WebKit

/// Muestra el icono SVG de una edición (los sirve Scryfall en
/// `svgs.scryfall.io`, no hay versión PNG oficial).
///
/// SwiftUI's `AsyncImage` NO sabe pintar SVG (solo PNG/JPEG/HEIC), así que
/// aquí usamos un `WKWebView` diminuto cargando el SVG con un filtro CSS
/// para teñirlo: los iconos de Scryfall vienen en negro sólido y sobre
/// fondo oscuro quedarían invisibles sin esto (mismo problema que
/// `ColorFilter.tint` resolvía en la versión Android con Coil).
///
/// Nota para cuando lo pruebes: la primera carga de cada icono tarda un
/// pelín (descarga + WKWebView), es normal.
struct SVGIconView: View {
    let url: String?
    var tinta: Color = .primary

    var body: some View {
        if let url, let cargada = URL(string: url) {
            SVGWebView(url: cargada, tinta: tinta)
        } else {
            Color.clear
        }
    }
}

private struct SVGWebView: UIViewRepresentable {
    let url: URL
    let tinta: Color

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let hex = tinta.toHex() ?? "#888888"
        var request = URLRequest(url: url)
        // Scryfall exige un User-Agent propio, igual que en las llamadas de
        // ScryfallApi.swift; sin esto también respondería 400 aquí.
        request.setValue("MTGInventarioApp/1.0 (iOS; personal use)", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data, var svg = String(data: data, encoding: .utf8) else { return }
            // Sustituye cualquier "fill" fijo del SVG por el color de tinte
            // deseado, y añade uno por defecto al <svg> raíz si no tuviera.
            svg = svg.replacingOccurrences(of: "fill=\"#000000\"", with: "fill=\"\(hex)\"")
            svg = svg.replacingOccurrences(of: "fill=\"black\"", with: "fill=\"\(hex)\"")
            let html = """
            <html><head><style>
            html,body { margin:0; padding:0; background:transparent; }
            svg { width:100%; height:100%; display:block; }
            svg * { fill: \(hex) !important; }
            </style></head><body>\(svg)</body></html>
            """
            DispatchQueue.main.async {
                webView.loadHTMLString(html, baseURL: url)
            }
        }.resume()
    }
}

private extension Color {
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else { return nil }
        let r = Int(components[0] * 255), g = Int(components[1] * 255), b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
