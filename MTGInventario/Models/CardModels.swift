import Foundation

/// Una edición/impresión concreta de una carta (equivalente a `Impresion.kt`).
struct Impresion: Identifiable, Equatable {
    var id: String { setCode + "_" + lang }
    let setCode: String
    let setName: String
    let imageUrl: String?
    let foilDisponible: Bool
    let normalDisponible: Bool
    let lang: String
    let nombreLocalizado: String?
    let iconoEdicionUrl: String?

    init(setCode: String, setName: String, imageUrl: String?, foilDisponible: Bool,
         normalDisponible: Bool, lang: String = "en", nombreLocalizado: String? = nil,
         iconoEdicionUrl: String? = nil) {
        self.setCode = setCode
        self.setName = setName
        self.imageUrl = imageUrl
        self.foilDisponible = foilDisponible
        self.normalDisponible = normalDisponible
        self.lang = lang
        self.nombreLocalizado = nombreLocalizado
        self.iconoEdicionUrl = iconoEdicionUrl
    }
}

/// Una sugerencia del buscador de nombres (equivalente a `Sugerencia.kt`).
///
/// `textoMostrado` es lo que ve el usuario (incluye el nombre impreso si la
/// carta es de una edición no inglesa, p. ej. "稲妻 (Lightning Bolt)");
/// `nombreOracle` es siempre el nombre en inglés y es lo que se usa para
/// todo lo demás (buscar impresiones, mandar la carta al servidor), porque
/// Scryfall lo mantiene igual sin importar en qué idioma esté impresa la carta.
struct Sugerencia: Identifiable, Equatable {
    var id: String { textoMostrado + "_" + nombreOracle }
    let textoMostrado: String
    let nombreOracle: String
    /// Idioma de la impresión que produjo esta sugerencia.
    let lang: String

    init(textoMostrado: String, nombreOracle: String, lang: String = "en") {
        self.textoMostrado = textoMostrado
        self.nombreOracle = nombreOracle
        self.lang = lang
    }
}

/// Respuesta del servidor al añadir/incrementar una carta (equivalente a
/// `ResultadoEnvio.kt`).
struct ResultadoEnvio {
    let status: String
    let nombre: String
    let edicion: String
    let idioma: String?
    let color: String?
    let precioEur: Double?
    let cantidad: Int
}
